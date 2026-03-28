package Debian::AdduserCreateHomedir 3.139;
use 5.36.0;
use utf8;

use strict;
use warnings;
use Debian::AdduserLogging 3.139;

# Adduser module to create home dir and to copy skel
#
# Copyright (C) 2026 Marc Haber <mh+debian-packages@zugschlus.de>
#
# License: GPL-2+

use parent qw(Exporter);

use vars qw(@EXPORT $VAR1);

@EXPORT = (
   'create_homedir',
); 

sub create_homedir {
    my %params = @_;
    my $home_dir = $params{home_dir};
    my $new_uid = $params{uid};
    my $primary_gid = $params{gid};
    my $copy_skeleton = $params{copy_skeleton};
    my $system_user = $params{system_user};
    my $no_create_home = $params{no_create_home};
    my $config = $params{config};

    log_trace("create_homedir(home_dir=%s, new_uid=%s, primary_gid=%s, copy_skeleton=%s, system_user=%s, no_create_home=%s", $home_dir, $new_uid, $primary_gid, $copy_skeleton, $system_user, $no_create_home);

    if ($home_dir =~ /^\/+nonexistent(\/|$)/) {
        log_info(mtx("Not creating `%s'."), $home_dir);
        return 1;
    }

    if ($no_create_home) {
        log_info(mtx("Not creating home directory `%s' as requested."), $home_dir);
        return 1;
    }

    if (-e $home_dir) {
        if (!$system_user) {
            log_warn(mtx("The home directory `%s' already exists. Not touching this directory."), $home_dir);
            my @homedir_stat = stat($home_dir);
            if (($homedir_stat[4] != $new_uid) || ($homedir_stat[5] != $primary_gid)) {
                log_warn(mtx("Warning: The home directory `%s' does not belong to the user you are currently creating."), $home_dir);
            }
        }
        return 1;
    }

    log_info(mtx("Creating home directory `%s' ..."), $home_dir);

    mktree($home_dir) or do {
        log_err(gtx("Couldn't create home directory `%s': %s."), $home_dir, $!);
        return 0;
    };

    chown($new_uid, $primary_gid, $home_dir) or do {
        log_err("chown %s:%s %s: %s", $new_uid, $primary_gid, $home_dir, $!);
        return 0;
    };

    # Determine if setgid bit should be applied
    my $setgid =  (defined $config->{setgid_home} && $config->{setgid_home} =~ /yes/i) ? 1 : 0;

    # Pick the correct dir_mode for the newly created home directory.
    # We can assume that both dir_mode and sys_dir_mode are valid octal,
    # with defaults already applied (AdduserCommon, read_config)
    my $dir_mode = $system_user ? $config->{"sys_dir_mode"} : $config->{"dir_mode"};

    # Convert to numeric octal
    $dir_mode = oct($dir_mode);

    # Apply setgid if requested
    $dir_mode |= 02000 if $setgid;

    chmod($dir_mode, $home_dir) or do {
        log_err("chmod %s %s: %s", $dir_mode, $home_dir, $!);
        return 0;
    };

    if ($config->{skel} && $copy_skeleton) {
        log_info(mtx("Copying files from `%s' ..."), $config->{skel});
        copy_skel(
            $config->{skel},
            $home_dir,
            $new_uid,
            $primary_gid,
            $setgid,
            $config->{skel_ignore_regex}
        ) or return 0;
    }

    return 1;
}

sub mktree {
    my ($tree) = @_;
    log_trace("mktree(tree=%s)", $tree);
    $tree =~ m{^(/[\w./-]*\$?)$} or return 0;
    $tree = $1;
    $tree =~ s{/+$}{};

    my $done = "";
    foreach my $part (split(m{/+}, $tree)) {
        log_trace("mktree tree part %s", $part);
        next if $part eq '';
        $done .= '/' . $part;
        next if -d $done;
        mkdir($done, 0755) or return 0;
    }
    return 1;
}

sub byte_string {
    my ($s) = @_;
    return pack("C*", unpack("C*", $s));  # force raw bytes
}

sub copy_skel {
    my ($skel, $home, $uid, $gid, $sgid, $ignore_re) = @_;
    log_trace("copy_skel(skel=%s, home=%s, uid=%s, gid=%s, sgid=%s, ignore_re=%s)", $skel, $home, $uid, $gid, $sgid, $ignore_re);

    # Convert base paths to raw bytes to prevent double UTF-8 encoding
    my $skel_bytes = byte_string($skel);
    my $home_bytes  = byte_string($home);

    return recurse_copy($skel_bytes, $home_bytes, "", $uid, $gid, $sgid, $ignore_re);
}

# this must handle UTF-8 file names just as byte strings without being
# smart. We can't do proper UTF-8 here.
sub recurse_copy {
    my ($src_base, $dst_base, $rel, $uid, $gid, $sgid, $ignore_re) = @_;

    log_trace("recurse_copy(src_base=%s, dst_base=%s, rel=%s, uid=%s, gid=%s, sgid=%s, ignore_re=%s)", $src_base, $dst_base, $rel // '', $uid, $gid, $sgid, $ignore_re);

    my $src = $rel ? "$src_base/$rel" : $src_base;

    # Untaint source path (allow any bytes except / or null)
    $src =~ m{^(/[^/\0]+(?:/[^/\0]+)*)$} or do {
        log_err("Invalid source path: %s", $src);
        return 0;
    };
    $src = $1;
    log_trace("Processing directory: %s", $src);

    opendir(my $dh, $src) or do {
        log_err("opendir %s: %s", $src, $!);
        return 0;
    };

    my @entries = grep { $_ ne '.' && $_ ne '..' && (!$ignore_re || !/$ignore_re/) } readdir($dh);
    closedir($dh);
    log_trace("Found entries: %s", join(", ", @entries));

    foreach my $entry (@entries) {
        log_trace("Processing entry: %s", $entry);

        # Untaint entry (allow any bytes except / or null)
        $entry =~ m{^([^/\0]+)$} or do {
            log_err("Invalid filename: %s", $entry);
            next;
        };
        $entry = $1;

        my $src_path = "$src/$entry";
        my $dst_path = ($rel ? "$dst_base/$rel" : $dst_base) . "/$entry";

        # Untaint destination path
        $dst_path =~ m{^(/[^/\0]+(?:/[^/\0]+)*)$} or do {
            log_err("Invalid destination path: %s", $dst_path);
            return 0;
        };
        $dst_path = $1;
        log_trace("src_path=%s dst_path=%s", $src_path, $dst_path);

        if (-l $src_path) {
            # Symlink
            my $target = readlink($src_path) or do {
                log_err("readlink %s: %s", $src_path, $!);
                return 0;
            };
            $target =~ m{^([^/\0]+(?:/[^/\0]+)*)$} or do {
                log_err("Unsafe symlink: %s", $target);
                return 0;
            };
            my ($cu, $cg) = ($>, $));
            ($>, $)) = ($uid, $gid);
            my $ok = symlink($1, $dst_path);
            my $err = $!;
            ($>, $)) = ($cu, $cg);
            if (!$ok) {
                log_err("symlink %s: %s", $dst_path, $err);
                return 0;
            }
            log_trace("Created symlink: %s -> %s", $dst_path, $target);

        } elsif (-d $src_path) {
            # Directory
            if (!-d $dst_path) {
                mkdir($dst_path, 0700) or do {
                    log_err("mkdir %s: %s", $dst_path, $!);
                    return 0;
                };
                log_trace("Created directory: %s", $dst_path);
            }
            set_perms($src_path, $dst_path, $uid, $gid, $sgid) or return 0;
            recurse_copy($src_base, $dst_base, $rel ? "$rel/$entry" : $entry, $uid, $gid, $sgid, $ignore_re) or return 0;

        } elsif (-f $src_path) {
            # Regular file
            open(my $in, '<', $src_path) or do {
                log_err("open %s: %s", $src_path, $!);
                return 0;
            };
            open(my $out, '>', $dst_path) or do {
                close($in);
                log_err("open %s: %s", $dst_path, $!);
                return 0;
            };
            binmode($in);
            binmode($out);
            print $out $_ while <$in>;
            close($in);
            close($out) or do {
                log_err("close %s: %s", $dst_path, $!);
                return 0;
            };
            set_perms($src_path, $dst_path, $uid, $gid, 0) or return 0;
            log_trace("Copied file: %s", $dst_path);
        }
    }

    log_trace("Finished processing directory: %s", $src);
    return 1;
}


sub set_perms {
    my ($src, $dst, $uid, $gid, $sgid) = @_;
    log_trace("set_perms(src=%s, dst=%s, uid=%s, gid=%s, sgid=%s)", $src, $dst, $uid, $gid, $sgid);
    chown($uid, $gid, $dst) or do {
        log_err("chown %s: %s", $dst, $!);
        return 0;
    };
    my $perm = (stat($src))[2] & 07777;
    $perm |= 02000 if -d $src && ($perm & 010) && $sgid;
    chmod($perm, $dst) or do {
        log_err("chmod %s: %s", $dst, $!);
        return 0;
    };
    return 1;
}

1;

# Local Variables:
# mode:cperl
# End:

# vim: tabstop=4 shiftwidth=4 expandtab
