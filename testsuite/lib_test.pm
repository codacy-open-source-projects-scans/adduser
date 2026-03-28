#!/usr/bin/perl -w

use strict;
use Debian::AdduserCommon;

# helper routines

my %add_config;
my %del_config;

my @adduserconf=("/etc/adduser.conf");
my @deluserconf=("/etc/deluser.conf");
%add_config = read_config(@adduserconf);
%del_config = read_config(@deluserconf);

use constant {
    SYS_MIN => 100,
    SYS_MAX => 999,
};

sub assert {
    my ($cond) = @_;
    if ($cond) {
        print "Test failed\n";
        exit 1;
    }
}

sub find_unused_uid {
    my ($mode) = @_;
    my $low_uid, my $high_uid;
    if ($mode =~ /"user"/i) {
        $low_uid = $add_config{"first_uid"};
        $high_uid = $add_config{"last_uid"};
    } else {
        $low_uid = $add_config{"first_system_uid"};
        $high_uid = $add_config{"last_system_uid"};
    }
    setpwent();
    my $uid = $low_uid;
    while (($uid <= $high_uid) && (defined(getpwuid($uid)))) {$uid++;}
    endpwent();

   if (($uid <= $high_uid) && (! defined(getpwuid($uid)))) {
        return $uid;
    }
    else {
        print "Cannot find an unused uid in range ($low_uid - $high_uid)\nExiting ...\n";
        return 1;
    }
}

sub find_unused_name {
    my ($user_prefix) = @_;
    $user_prefix //= '';

    my $re = qr/^\Q$user_prefix\E(\d+)$/;

    my $max_user = 0;
    setpwent();
    while (defined(my $name = getpwent())) {
        if ($name =~ $re) {
            $max_user = $1 if $1 > $max_user;
        }
    }
    endpwent();

    my $max_group = 0;
    setgrent();
    while (defined(my $name = getgrent())) {
        if ($name =~ $re) {
            $max_group = $1 if $1 > $max_group;
        }
    }
    endgrent();

    my $next = ($max_user > $max_group ? $max_user : $max_group) + 1;
    return $user_prefix . $next;
}

sub find_unused_gid {
    my ($mode) = @_;
    my $low_gid, my $high_gid;
    if ($mode =~ /"user"/i) {
        $low_gid = $add_config{"first_gid"};
        $high_gid = $add_config{"last_gid"};
    } else {
        $low_gid = $add_config{"first_system_gid"};
        $high_gid = $add_config{"last_system_gid"};
    }
    setgrent();
    my $gid = $low_gid;
    while (($gid <= $high_gid) &&  (defined(getgrgid($gid)))) { $gid++;}
    endgrent();

    if (($gid <= $high_gid) && (! defined(getgrgid($gid)))) {
        return $gid;
    }
    else {
        print "Cannot find an unused gid in range ($low_gid - $high_gid)\nExiting ...\n";
        return 1;
    }
}

# checking routines

sub check_user_exist {
    my ($username,$uid) = @_;

    my @ent = getpwnam ($username);
    if (!@ent) {
        print "user $username does not exist\n";
        return 1;
    }
    if (( defined($uid)) && ($ent[2] != $uid)) {
        printf "uid $uid does not match %s\n",$ent[2];
        return 1;
    }
    print "user $username exists\n";
    return 0;
}

sub check_user_not_exist {
    my ($username) = @_;

    if (defined(getpwnam($username))) {
        print "user $username exists\n";
        return 1;
    }
    print "user $username does not exist\n";
    return 0;
}


#####################
sub check_homedir_exist {
    my ($username, $homedir) = @_;
    my $dir = (getpwnam($username))[7];
    if ((defined($homedir)) && (! $dir eq $homedir)) {
        print "check_homedir_exist: wrong homedir ($homedir != $dir)\n";
        return 1;
    }
    if (! -d $dir) {
        print "check_homedir_exist: there's no home directory $dir\n";
        return 1;
    }
    return 0;
}


sub check_dir_exist {
    my ($dir) = @_;
    if (! -d $dir) {
        print "check_dir_exist: $dir does not exist\n";
        return 1;
    }
    return 0;
}


sub check_homedir_not_exist {
    my ($homedir) = @_;
    if ( -d $homedir) {
        print "check_homedir_not_exist: there's a home directory $homedir\n";
        return 1;
    }
    return 0;
}

sub check_user_homedir_eq {
    my ($username, $dir) = @_;
    my $userdir = (getpwnam($username))[7];

    return ($userdir eq $dir) ? 0 : 1;
}

sub check_user_comment {
    my ($username, $comment) = @_;
    my $usercomment = (getpwnam($username))[6];

    return ($usercomment eq $comment) ? 0 : 1;
}

sub check_user_homedir_not_exist {
    my ($username) = @_;
    my $dir = (getpwnam($username))[7];
    if ( -d $dir) {
        print "check_user_homedir_not_exist: there's a home directory $dir\n";
        return 1;
    }
    return 0;
}

sub check_group_exist {
    my ($groupname) = @_;
    if (!defined(getgrnam($groupname))) {
        print "check_group_exist: Group $groupname does not exist\n";
        return 1;
    }
    return 0;
}

sub check_user_in_group {
    my ($user,$group) = @_;
    my ($name,$passwd,$gid,$members) = getgrnam ($group);
    #print "check_user_in_group: group $group = $members\n";
    foreach  my $u (split(" ",$members)) {
        #print "check_user_in_group: Testing user $u for group $group\n";
        if ( $u eq $user) { return 0; }
    }
    # ok, but $group is maybe $user's primary group ...
    my @pw = getpwnam($user);
    my $primary_gid = $pw[3];
    if (getgrgid($primary_gid) eq $group) {
        return 0;
    }

    print "check_user_in_group: User $user not in group $group\n";
    return 1;
}


sub check_user_has_gid {
    my ($user,$gid) = @_;
    my ($name,$passwd,$group_gid,$members) = getgrgid($gid);
    #print "check_user_has_gid: group $group = $members\n";
    foreach  my $u (split(" ",$members)) {
        #print "check_user_has_gid: Testing user $u for group $group\n";
        if ( $u eq $user) { return 0; }
    }
    # ok, but $group is maybe $user's primary group ...
    my @pw = getpwnam($user);
    my $primary_gid = $pw[3];
    if (getgrgid($primary_gid) eq $name) {
        return 0;
    }

    print "check_user_has_gid: User $user has no gid $gid\n";
    return 1;
}

# Map human-readable status names to bitmask constants
my %USER_STATUS_MASK = (
    locked      => EXISTING_LOCKED,
    haspasswd   => EXISTING_HAS_PASSWORD,
    nologin     => EXISTING_NOLOGIN,
    expired     => EXISTING_EXPIRED,
);

sub check_user_status {
    my ($username, $check, $do_print) = @_;
    $do_print //= 0;

    my $invert = 0;
    my $result;

    # Check for negative prefix "not_"
    if ($check =~ /^not_(.+)$/) {
        $invert = 1;
        $check = $1;
    }

    my $mask = $USER_STATUS_MASK{$check}
        or die "Unknown user status '$check'";

    my $status = testsuite_existing_user_status($username);
    # returns 0 if status is as desired so that it can be used in assertion
    $result = (($status & $mask) == $mask) ? 0 : 1;

    if ($do_print) {
        my $msg = $result
                ? "User '$username' $check"
                : "User '$username' NOT $check";
        print "$msg";
    }

    $result = !$result if $invert;
    print " (status $status, returning ", $result ? 1 : 0, ")\n";
    return $result;
}

sub testsuite_existing_user_status {
    my ($user_name,$user_uid) = @_;
    my $ret = EXISTING_NOT_FOUND;

    my (
        $egpwn_name, $egpwn_passwd, $egpwn_uid, $egpwn_gid, $egpwn_quota,
        $egpwn_comment, $egpwn_gcos, $egpwn_dir, $egpwn_shell, $egpwn_expire,
        $egpwn_rest
    ) = getpwnam($user_name);

    if (defined $egpwn_uid) {
        $ret |= EXISTING_FOUND;
        $ret |= EXISTING_ID_MISMATCH if (defined($user_uid) && $egpwn_uid != $user_uid);
        $ret |= EXISTING_SYSTEM if \
            ($egpwn_uid >= SYS_MIN && $egpwn_uid <= SYS_MAX);

        $ret |= EXISTING_NOLOGIN if ($egpwn_shell =~ /bin\/nologin/);
        $ret |= EXISTING_HAS_PASSWORD if
            (defined $egpwn_passwd && $egpwn_passwd ne '' && ($egpwn_passwd =~ s/^[!*]+//r ne ''));
        $ret |= EXISTING_LOCKED if
            (defined $egpwn_passwd && $egpwn_passwd =~ /^[!*]/);

        # this is deliberately implemented differently from the actual program
        my $age = `chage -l $user_name`;

        if ($age =~ /Account expires\s*:\s*(.+)/i) {
            my $exp = $1;
            if ($exp ne 'never') {
                chomp $exp;
                # Convert to epoch using GNU date
                my $expiry_epoch = `date -d "$exp" +%s 2>/dev/null`;
                chomp $expiry_epoch;

                if (defined $expiry_epoch && $expiry_epoch =~ /^\d+$/) {
                    $ret |= EXISTING_EXPIRED if ($expiry_epoch < time);
                } else {
                    warn "Failed to parse expiry date '$exp' with date command\n";
                }
            }
        }
    } elsif ($user_uid && getpwuid($user_uid)) {
        $ret |= EXISTING_ID_MISMATCH;
    }
    return $ret;
}

return 1

# vim: tabstop=4 shiftwidth=4 expandtab
