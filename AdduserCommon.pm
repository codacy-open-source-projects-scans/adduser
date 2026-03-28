package Debian::AdduserCommon 3.139;
use 5.36.0;
use utf8;

# Subroutines shared by the "adduser" and "deluser" utilities.
#
# Copyright (C) 2000-2004 Roland Bauerschmidt <rb@debian.org>
#               2004-2025 Marc Haber <mh+debian-packages@zugschlus.de>
#               2005-2009 Joerg Hoh <joerg@joerghoh.de>
#               2006-2008 Stephen Gran <sgran@debian.org>
#               2016 Nis Martensen <nis.martensen@web.de>
#               2016 Afif Elghraoui <afif@debian.org>
#               2021-2022 Jason Franklin <jason@oneway.dev>
#               2022 Matt Barry <matt@hazelmollusk.org>
#               2023 Guillem Jover <guillem@debian.org>
#
# Someo of the subroutines here are adopted from Debian's
# original "adduser" program.
#
#   Copyright (C) 1997-1999 Guy Maor <maor@debian.org>
#
#   Copyright (C) 1995 Ted Hajek <tedhajek@boombox.micro.umn.edu>
#                      Ian A. Murdock <imurdock@gnu.ai.mit.edu>
#
# License: GPL-2+

use parent qw(Exporter);

use Fcntl qw(:flock SEEK_END);
my $codeset;

use Debian::AdduserLogging 3.139;
use Debian::AdduserRetvalues 3.139;
use Debian::AdduserStatefile 3.139;
BEGIN {
    if ( Debian::AdduserLogging->VERSION != version->declare('3.139') ||
         Debian::AdduserRetvalues->VERSION != version->declare('3.139') ) {
           die "wrong module version in adduser, check your packaging or path";
    }
    local $ENV{PERL_DL_NONLAZY}=1;
    eval {
        require Encode;
        Encode->import(qw(encode decode));
    };
    if ($@) {
        *encode = sub { return $_[1]; };
        *decode = sub { return $_[1]; };
    }
    $codeset="US-ASCII";
    eval {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo CODESET YESEXPR NOEXPR));
        $codeset = I18N::Langinfo->CODESET;
    };
    if ($@) {
        *langinfo = sub { return shift; };
        *YESEXPR  = sub { "^[yY]" };
        *NOEXPR   = sub { "^[nN]" };
    }
}

use vars qw(@EXPORT $VAR1);
my $charset = langinfo($codeset);

BEGIN {
    local $ENV{PERL_DL_NONLAZY}=1;
    eval {
        require Locale::gettext;
        Locale::gettext->import(qw(gettext textdomain LC_MESSAGES));
    };
    if ($@) {
        *gettext = sub { shift };
        *textdomain = sub { "" };
        *LC_MESSAGES = sub { 5 };
    } else {
        Locale::gettext::textdomain("adduser");
    }
}

my $lockfile;
my $lockfile_path = '/run/adduser';

use constant {
    filenamere => qr/[-_\.+!\$%&()\]\[;0-9a-zA-Z]+/,
    simplefilenamere => qr/[-_\.0-9a-zA-Z]+/,
    pathre => qr/[- \p{Graph}_\.+!\$%&()\]\[;0-9a-zA-Z\/{}>*'@]+/,
    simplepathre => qr/[-_\$\.0-9a-zA-Z\/]+/,
    commentre => qr/[-"_\.+!\$%&()\]\[;\/'’ A-Za-z0-9ß\x{a1}-\x{ac}\x{ae}-\x{ff}\p{L}\p{Nd}\p{Zs}]*/,
    numberre => qr/[0-9]+/,
    namere => qr/^([^-+~:,\s\/][^:,\s\/]*)$/aa,
    anynamere => qr/^([^-+~:,\s\/][^:,\s\/]*)$/aa,
    def_name_regex => qr/^[a-zA-Z][a-zA-Z0-9_-]*\$?$/aa,
    def_sys_name_regex => qr/^[a-zA-Z_][a-zA-Z0-9_-]*\$?$/aa,
    def_ieee_name_regex => qr/^[a-zA-Z0-9_.][a-zA-Z0-9_.-]*\$?$/aa,
    def_min_regex => qr(^[^-+~:,\s/][^:,\s/]*$)aa,
};

# constants used in existing_*_status
use constant {
    EXISTING_NOT_FOUND => 0,
    EXISTING_FOUND => 1,
    EXISTING_SYSTEM => 2,
    EXISTING_ID_MISMATCH => 4,
    EXISTING_LOCKED => 8,
    EXISTING_HAS_PASSWORD => 16,
    EXISTING_EXPIRED => 32,
    EXISTING_NOLOGIN => 64,
};

use constant {
    STDOUTDEFLEVEL => "warn",
    STDERRDEFLEVEL => "warn",
    LOGMSGDEFLEVEL => "info",
};

@EXPORT = (
    'get_group_members',
    'read_config',
    'read_pool',
    'systemcall_useradd',
    'systemcall',
    'systemcall_or_warn',
    'systemcall_silent',
    'systemcall_silent_error',
    'acquire_lock',
    'release_lock',
    'sanitize_string',
    'egetgrnam',
    'egetpwnam',
    'which',
    "filenamere",
    "simplefilenamere",
    "pathre",
    "simplepathre",
    "commentre",
    "numberre",
    'namere',
    'anynamere',
    'def_name_regex',
    'def_sys_name_regex',
    'def_ieee_name_regex',
    'def_min_regex',
    'EXISTING_NOT_FOUND',
    'EXISTING_FOUND',
    'EXISTING_SYSTEM',
    'EXISTING_ID_MISMATCH',
    'EXISTING_LOCKED',
    'EXISTING_HAS_PASSWORD',
    'EXISTING_EXPIRED',
    'EXISTING_NOLOGIN',
    'STDOUTDEFLEVEL',
    'STDERRDEFLEVEL',
    'LOGMSGDEFLEVEL',
    'existing_user_status',
    'existing_group_status',
);

sub sanitize_string {
    my ($input, $pattern, $replace) = @_;
    return unless defined $input;

    $pattern //= '[a-zA-Z0-9 _]+';
    $replace //= 0;

    log_trace("sanitize_string %s against %s (replace=%s)", $input, $pattern, $replace);

    # Full match check
    if ($input =~ /^($pattern)\z/) {
        log_trace("sanitize_string returning %s", $1);
        return $1;  # Untainted
    }
    elsif ($replace) {
        # Replace disallowed substrings with underscores
        my $safe = '';
        my $pos = 0;

        while ($input =~ /$pattern/g) {
            my $start = $-[0];  # start of match
            my $end   = $+[0];  # end of match
            # fill in underscores for skipped portion
            $safe .= '_' x ($start - $pos) if $start > $pos;
            # append allowed portion
            $safe .= substr($input, $start, $end - $start);
            $pos = $end;
        }

        # any trailing disallowed chars
        $safe .= '_' x (length($input) - $pos) if $pos < length($input);

        log_trace("sanitize_string replaced invalid chars, returning %s", $safe);
        return $safe;
    }
    else {
        die sprintf("sanitize_string: invalid characters in '%s'", $input);
    }
}


sub egetgrnam {
    my ($name) = @_;
    log_trace("egetgrnam called with %s", $name);
    $name = encode($charset, $name);
    return getgrnam($name);
}

sub egetpwnam {
    my ($name) = @_;
    log_trace("egetpwnam called with %s", $name);
    $name = encode($charset, $name);
    return getpwnam($name);
}

# parse the configuration file
# parameters:
#  -- filename of the configuration file
#  -- a hash for the configuration data
sub read_configfile {
    my $conf_file = shift;
    my %config = @_;
    my ($var, $lcvar, $val);

    $conf_file = sanitize_string( $conf_file, simplepathre );
    if (! -f $conf_file) {
        log_warn( mtx("`%s' does not exist. Using defaults."), $conf_file );
        return;
    }

    my $conffh;
    unless( open ($conffh, q{<}, $conf_file) ) {
       log_fatal( mtx("cannot open configuration file %s: `%s'\n"), $conf_file, $! );
       exit( RET_CONFFILE );
    }
    while (<$conffh>) {
        chomp;
        $_ = decode($charset, $_);
        next if /^#/ || /^\s*$/;

        log_trace("read from config file: %s", $_);
        if ((($var, $val) = m/^\s*([_a-zA-Z0-9]+)\s*=\s*([-a-zA-Z0-9_\/\.^\$\]\[*?+\|@\\^":\)\(~,\s]*)/) != 2) {
            log_warn( mtx("Couldn't parse `%s', line %d."), $conf_file, $. );
            next;
        }
        $lcvar = lc $var;
        if (!exists($config{$lcvar})) {
            log_warn( mtx("Unknown variable `%s' at `%s', line %d."), $var, $conf_file, $. );
            next;
        }

        log_trace("lcvar, val: %s, %s", $lcvar, $val);
        if( $lcvar =~ /^(first|last).*_[ug]id$/ ) {
            $val = sanitize_string( $val, qr/[0-9]*/ );
        }

        $val =~ s/^"(.*)"$/$1/;
        $val =~ s/^'(.*)'$/$1/;

        log_debug("importing config value for %s: %s", $lcvar, $val);
        $config{$lcvar} = $val;
    }

    close $conffh || die "$!";
    return %config;
}

# read names and IDs from a pool file
# parameters:
#  -- filename of the pool file, or directory containing files
#  -- a hash for the pool data
sub read_pool {
    my ($pool_file, $type, $poolref) = @_;
    my ($name, $id, $comment, $home, $shell);
    my %ids = ();
    my %new;

    $pool_file = decode($charset, $pool_file);
    if (-d $pool_file) {
        my $dir;
        unless( opendir( $dir, $pool_file) ) {
            log_fatal( mtx("Cannot read directory `%s'"), $pool_file );
            exit( RET_POOLFILE );
        }
        my @files = readdir ($dir);
        closedir ($dir);
        foreach (sort @files) {
            next if (/^\./);
            next if (!/\.conf$/);
            my $file = "$pool_file/$_";
            next if (! -f $file);
            read_pool ($file, $type, $poolref);
        }
        return;
    }
    if (! -f $pool_file) {
        log_warn( mtx("`%s' does not exist."), $pool_file );
        return;
    }
    my $pool;
    unless( open( $pool, q{<}, $pool_file) ) {
        log_fatal( mtx("Cannot open pool file %s: `%s'"), $pool_file, $!);
        exit( RET_POOLFILE );
    }
    while (<$pool>) {
        chomp;
        $_ = decode($charset, $_);
        next if /^#/ || /^\s*$/;

        my $new;

        if ($type eq "uid") {
            ($name, $id, $comment, $home, $shell) = split (/:/);
            if (!$name || $name !~ /^([_a-zA-Z0-9-]+)$/ ||
                !defined($id) || $id !~ /^(\d+)$/) {
                log_warn( mtx("Couldn't parse `%s', line %d."), $pool_file, $.);
                next;
            }
            if( defined $name ) {
                $name = sanitize_string($name, namere);
            }
            if( defined $id ) {
                $id = sanitize_string($id, numberre);
            }
            if( defined $comment ) {
                $comment = sanitize_string($comment, commentre);
            }
            if( defined $home ) {
                $home = sanitize_string($home, simplepathre);
            }
            if( defined $shell ) {
                $shell = sanitize_string($shell, simplepathre);
            }
            $new = {
                'id' => $id,
                'comment' => $comment,
                'home' => $home,
                'shell' => $shell
            };
        } elsif ($type eq "gid") {
            ($name, $id) = split (/:/);
            if (!$name || $name !~ /^([_a-zA-Z0-9-]+)$/ ||
                !defined($id) || $id !~ /^(\d+)$/) {
                log_warn( mtx("Couldn't parse `%s', line %d."), $pool_file, $. );
                next;
            }
            if( defined $name ) {
                $name = sanitize_string($name, namere);
            }
            if( defined $id ) {
                $id = sanitize_string($id, numberre);
            }
            $new = {
                'id' => $id,
            };
        } else {
            log_fatal( mtx("Illegal pool type `%s' reading `%s'."), $type, $pool_file );
            exit( RET_POOLFILE_FORMAT );
        }
        if (defined($poolref->{$name})) {
            log_fatal( mtx("Duplicate name `%s' at `%s', line %d."), $name, $pool_file, $. );
            exit( RET_POOLFILE_FORMAT );
        }
        if (defined($ids{$id})) {
            log_fatal( mtx("Duplicate ID `%s' at `%s', line %d."), $id, $pool_file, $. );
            exit( RET_POOLFILE_FORMAT );
        }

        $poolref->{$name} = $new;
    }

    close $pool || die "$!";
}

sub get_group_members {
    my $group = shift;

    my @members;

    foreach my $member (split(/ /, (egetgrnam($group))[3])) {
        push(@members, $member) if defined(egetpwnam($member));
    }

    return @members;
}

sub systemcall_useradd {
    my $name_check_level = shift;
    my $command = join(' ', @_);
    my $ret;
    log_debug( "executing systemcall_useradd (%s): %s", $name_check_level, $command );
    $ret = system(@_);
    if ($ret != 0) {
        my $exitcode = $ret>>8;
        if ($exitcode != 0) {
            if ($exitcode == 19 ) {
                # we should never get here. It is our expectation that we catch
                # an invalid user name before useradd gets to reject it. So
                # we consider getting here a bug in our regexps. We can safely
                # bomb out here.
                if( $name_check_level == 2 ) {
                    log_warn( mtx("`%s' refused the given user name, but --allow-all-names is given. Continueing."), $command );
                    return( RET_INVALID_NAME_FROM_USERADD );
                } else {
                    log_err( mtx("`%s' refused the given user name. This is a bug in adduser. Please file a bug report."), $command );
                    exit( RET_INVALID_NAME_FROM_USERADD ); 
                };
            } else {
                log_fatal( mtx("`%s' returned error code %d. Exiting."), $command, $exitcode );
                exit( RET_SYSTEMCALL_ERROR );
            }
        }
        log_fatal( mtx("`%s' exited from signal %d. Exiting."), $command, $ret&127 );
        exit( RET_SYSTEMCALL_SIGNAL );
    }
}

sub systemcall {
    my $command = join(' ', @_);
    log_debug( "executing systemcall: %s", $command );
    if (system(@_)) {
        if ($?>>8) {
            log_fatal( mtx("`%s' returned error code %d. Exiting."), $command, $?>>8 );
            exit( RET_SYSTEMCALL_ERROR );
        }
        log_fatal( mtx("`%s' exited from signal %d. Exiting."), $command, $?&127 );
        exit( RET_SYSTEMCALL_SIGNAL );
    }
}

sub systemcall_or_warn {
    my $command = join(' ', @_);
    log_debug( "executing systemcall_or_warn: %s", $command );
    system(@_);
    my $ret = $?;

    if ($ret == -1) {
        log_warn( mtx("`%s' failed to execute. %s. Continuing."), $command, $! );
    } elsif ($? & 127) {
        log_warn( mtx("`%s' killed by signal %d. Continuing."), $command, ($ret & 127) );
    } elsif ($? >> 8) {
        log_warn( mtx("`%s' failed with status %d. Continuing."), $command, ($ret >> 8) );
    }

    return $ret;
}

sub systemcall_silent {
    my $command = join(' ', @_);
    log_debug( "executing systemcall_silent: %s", $command );
    my $pid = fork();

    if( !defined($pid) ) {
        return -1;
    }

    if ($pid) {
        wait;
        return $?;
    }

    open(STDOUT, '>>', '/dev/null');
    open(STDERR, '>>', '/dev/null');

    # TODO: report exec() failure to parent
    exec(@_) or exit(1);
}

sub systemcall_silent_error {
    my $command = join(' ', @_);
    log_debug( "executing systemcall_silent_error: %s", $command );
    my $output = `$command >/dev/null 2>&1`;
    return $?;
}

sub which {
    my ($progname, $nonfatal) = @_ ;
    for my $dir (split /:/, $ENV{"PATH"}) {
        if (-x "$dir/$progname" ) {
            return sanitize_string( "$dir/$progname", simplepathre );
        }
    }
    unless( $nonfatal ) {
        log_fatal( mtx("Could not find program named `%s' in \$PATH."), $progname );
        exit( RET_EXEC_NOT_FOUND );
    }
    return 0;
}


# preseed the configuration variables
# then read the config file /etc/adduser and overwrite the data hardcoded here
# we cannot give defaults for users_gid and users_group here since this will
# probably lead to double defined users_gid and users_group.
sub read_config {
    my @configfiles = @_;

    # Initialize configuration with defaults
    my %config = (
        system           => 0,
        only_if_empty    => 0,
        remove_home      => 0,
        home             => "",
        remove_all_files => 0,
        backup           => 0,
        backup_to        => ".",
        dshell           => "/bin/bash",
        first_system_uid => 100,
        last_system_uid  => 999,
        first_uid        => 1000,
        last_uid         => 59999,
        first_system_gid => 100,
        last_system_gid  => 999,
        first_gid        => 1000,
        last_gid         => 59999,
        dhome            => "/home",
        skel             => "/etc/skel",
        usergroups       => "yes",
        users_gid        => undef,
        users_group      => undef,
        dir_mode         => "0700",
        sys_dir_mode     => "0755",
        no_del_paths     => "^/bin\$ ^/boot\$ ^/dev\$ ^/etc\$ ^/initrd ^/lib ^/lost+found\$ ^/media\$ ^/mnt\$ ^/opt\$ ^/proc\$ ^/root\$ ^/run\$ ^/sbin\$ ^/srv\$ ^/sys\$ ^/tmp\$ ^/usr\$ ^/var\$ ^/vmlinu",
        name_regex       => def_name_regex,
        sys_name_regex   => def_sys_name_regex,
        sys_delete_action => "delete",
        exclude_fstypes  => "(proc|sysfs|usbfs|devpts|devtmpfs|devfs|afs)",
        skel_ignore_regex => "\.(dpkg|ucf)-(old|new|dist)\$",
        extra_groups     => "users",
        add_extra_groups => 0,
        uid_pool         => "",
        gid_pool         => "",
        reserve_uid_pool => "yes",
        reserve_gid_pool => "yes",
        loggerparms      => "",
        stdoutmsglevel   => "warn",
        stderrmsglevel   => "warn",
        logmsglevel      => "info",
    );

    # Read configuration files, overriding defaults
    foreach my $e (@configfiles) {
        my $configfile = sanitize_string($e, simplepathre);
        log_debug("read configuration file %s\n", $configfile);
        %config = read_configfile($configfile, %config);
    }

    $config{'dir_mode'} = check_octal($config{'dir_mode'}, '0700');
    $config{'sys_dir_mode'} = check_octal($config{'sys_dir_mode'}, '0755');

    return %config;
}

sub check_octal {
    my ($value, $default) = @_;

    # A valid octal is 0-7 digits only, optionally with leading zero
    if (defined $value && $value =~ /\A[0-7]+\z/) {
        return $value;
    } else {
        return $default;
    }
}


sub acquire_lock {
    my @notify_secs = (1, 3, 8, 18, 28);
    my ($wait_secs, $timeout_secs) = (0, 30);

    unless( open($lockfile, '>>', $lockfile_path) ) {
        log_fatal( mtx("could not open lock file %s!"), $lockfile_path );
        exit( RET_LOCKFILE );
    }

    while (!flock($lockfile, LOCK_EX | LOCK_NB)) {
        if ($wait_secs == $timeout_secs) {
            log_fatal( mtx("Could not obtain exclusive lock, please try again shortly!") );
            exit( RET_LOCKFILE );
        } elsif (grep @notify_secs, $wait_secs) {
            log_warn( mtx("Waiting for lock to become available...") );
        }
        sleep 1;
        $wait_secs++;
    }

    unless( seek($lockfile, 0, SEEK_END) ) {
        log_fatal( mtx("could not seek - %s!"), $lockfile_path );
        exit( RET_LOCKFILE );
    }
}

sub release_lock {
    my $nonfatal = shift || 0;
    return if ($nonfatal && !$lockfile);
    unless( $lockfile ) {
        log_fatal( mtx("could not find lock file!") );
        exit( RET_LOCKFILE );
    }
    if( defined(fileno($lockfile)) ) {
        unless( flock($lockfile, LOCK_UN) or $nonfatal ) {
            log_fatal( mtx("could not unlock file %s: %s"), $lockfile_path, $! );
            exit( RET_LOCKFILE );
        }
    }
    unless( close($lockfile) or $nonfatal ) {
        log_fatal( mtx("could not close lock file %s: %s"), $lockfile_path, $! );
        exit( RET_LOCKFILE );
    }
}

END {
    release_lock(1);
}

# existing_user_status: check if there is already a user present
# on the system which satisfies the requirements
# parameter:
#   new_name: the name of the user to check
#   new_uid : the UID of the user
# return value:
#   bitwise combination of the EXISTING_ constants
sub existing_user_status {
    my ($config, $user_name,$user_uid) = @_;
    my $ret = EXISTING_NOT_FOUND;
    log_trace( "existing_user_status called with user_name %s, user_uid %s, first_system_uid %s, last_system_uid %s", $user_name, $user_uid, $config->{"first_system_uid"}, $config->{"last_system_uid"} );

    # collect user data
    my (
        $egpwn_name, $egpwn_passwd, $egpwn_uid, $egpwn_gid, $egpwn_quota,
        $egpwn_comment, $egpwn_gcos, $egpwn_dir, $egpwn_shell, $egpwn_expire,
        $egpwn_rest
    ) = egetpwnam($user_name);
    my $shadow_line = `getent shadow $user_name`;
    chomp $shadow_line;
    my @shadow_fields = split /:/, $shadow_line;
    if (defined $egpwn_uid) {
        # user with the name exists
        log_trace( "egetpwnam(%s) returns %s, %s, %s, %s", $user_name, $egpwn_passwd, $egpwn_uid, $egpwn_dir, $egpwn_shell );
        $ret |= EXISTING_FOUND;
        $ret |= EXISTING_ID_MISMATCH if (defined($user_uid) && $egpwn_uid != $user_uid);
        $ret |= EXISTING_SYSTEM if
            (($egpwn_uid >= $config->{"first_system_uid"}) && ($egpwn_uid <= $config->{"last_system_uid"}));
        $ret |= EXISTING_HAS_PASSWORD if
            (defined $egpwn_passwd && $egpwn_passwd ne '' && ($egpwn_passwd =~ s/^[!*]+//r ne ''));

        my $password_field = $shadow_fields[1] // '';
        $ret |= EXISTING_LOCKED if $password_field =~ /^[!*]/ && (get_state_value($user_name, "locked") // "") eq "1";

        $ret |= EXISTING_NOLOGIN if ($egpwn_shell =~ /bin\/nologin/);

        my $acct_exp = $shadow_fields[7] // '';
        if ($acct_exp && $acct_exp > 0) {
            my $today_days = int(time / 86400);
            $ret |= EXISTING_EXPIRED if $acct_exp < $today_days;
        }

    } elsif (defined($user_uid) && getpwuid($user_uid)) {
        # user with the uid exists
        $ret |= EXISTING_ID_MISMATCH;
    }
    log_trace( "existing_user_status( %s, %s ) returns %s (%s)", $user_name, $user_uid, $ret, existing_value_desc($ret) );
    return $ret;
}

# existing_group_status: check if there is already a group which satisfies the requirements
# parameter:
#   new_name: the name of the group
#   new_gid : the GID of the group
# return value:
#   bitwise combination of these constants:
#       EXISTING_NOT_FOUND => 0
#       EXISTING_FOUND => 1
#       EXISTING_SYSTEM => 2
#       EXISTING_ID_MISMATCH => 4
sub existing_group_status {
    my ($config, $new_name,$new_gid) = @_;
    my ($gid);
    my $ret = EXISTING_NOT_FOUND;
    log_trace( "existing_group_status called with new_name %s, new_gid %s", $new_name, $new_gid );
    if ((undef,undef,$gid) = egetgrnam($new_name)) {
        # group with the name exists
        log_trace("egetgrnam %s returned successfully, gid = %s", $new_name, $gid);
        $ret |= EXISTING_FOUND;
        $ret |= EXISTING_ID_MISMATCH if (defined($new_gid) && $gid != $new_gid);
        $ret |= EXISTING_SYSTEM if
            (($gid >= $config->{"first_system_gid"}) && ($gid <= $config->{"last_system_gid"}));
    } elsif (defined($new_gid) && getgrgid($new_gid)) {
        $ret |= EXISTING_ID_MISMATCH;
    }
    log_trace( "existing_group_status( %s, %s ) returns %s (%s)", $new_name, $new_gid, $ret, existing_value_desc($ret) );
    return $ret;
}

sub existing_value_desc {
    my ($val) = @_;
    my @flags = ();
    push @flags, "found" if ($val & EXISTING_FOUND);
    push @flags, "wrongid" if $val & EXISTING_ID_MISMATCH;
    push @flags, "system" if ($val & EXISTING_SYSTEM);
    push @flags, "locked" if $val & EXISTING_LOCKED;
    push @flags, "haspass" if $val & EXISTING_HAS_PASSWORD;
    push @flags, "nologin" if $val & EXISTING_NOLOGIN;
    push @flags, "expired" if $val & EXISTING_EXPIRED;
    push @flags, "notfound" unless $#flags > 0;
    return join '|',@flags
}

1;

# Local Variables:
# mode:cperl
# End:

# vim: tabstop=4 shiftwidth=4 expandtab
