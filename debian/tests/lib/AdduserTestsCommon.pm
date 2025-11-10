use diagnostics;
use strict;
use warnings;
use Encode;
use utf8;
use I18N::Langinfo qw(langinfo CODESET);
use File::Path qw(remove_tree);
use Test::More qw(no_plan);

BEGIN {
    if (! -f '/var/cache/adduser/tests/state.tar') {
        my @conffiles = (
            'etc/adduser.conf',
            'etc/deluser.conf',
            'etc/default/useradd',
            'etc/group',
            'etc/gshadow',
            'etc/login.defs',
            'etc/passwd',
            'etc/shadow',
        );

        mkdir('/var/cache/adduser/tests');
        system('/bin/tar', 'cf', '/var/cache/adduser/tests/state.tar', '--directory=/', @conffiles);
    }
}

END {
    system('/bin/tar', 'xf', '/var/cache/adduser/tests/state.tar', '--directory=/')
    if (-f '/var/cache/adduser/tests/state.tar');
}

my $charset = langinfo(CODESET);
binmode(STDOUT, ":encoding($charset)");
binmode(STDERR, ":encoding($charset)");

sub egetgrnam {
    my ($name) = @_;
    $name = encode($charset, $name);
    return getgrnam($name);
}

sub egetpwnam {
    my ($name) = @_;
    $name = encode($charset, $name);
    return getpwnam($name);
}

sub in_range {
    my ($id, $first, $last) = @_;
    $first = 100 if( !$first );
    $last = 999 if( !$last );
    return 0 if not defined($id);
    return ($id >= $first && $id <= $last);
}

sub assert_command_success {
    system(@_);
    is($? >> 8, 0, "command success: @_");
}

sub assert_command_failure {
    system(@_);
    isnt($? >> 8, 0, "command failure (expected): @_");
}

sub assert_command_result_silent {
    my $expected = shift;
    my $cmd = join(' ', @_);
    my $output = `$cmd >/dev/null 2>&1`;
    my $ret = ($? >> 8);
    is(($ret == $expected), 1, "command result $ret (expected $expected): @_");
}

sub assert_command_failure_silent {
    my $cmd = join(' ', @_);
    my $output = `$cmd >/dev/null 2>&1`;
    isnt($? >> 8, 0, "command failure (expected): @_");
}

sub assert_command_success_silent {
    my $cmd = join(' ', @_);
    my $output = `$cmd >/dev/null 2>&1`;
    is($? >> 8, 0, "command success: @_");
}

sub assert_command_match_output {
    my $match = pop;
    my $cmd = join(' ', @_);
    my $output = `$cmd >/dev/null 2>&1`;
    isnt($? >> 8, 0, "command failure (expected): @_");
}

sub assert_group_does_not_exist {
    my $group = shift;
    is(egetgrnam($group), undef, "group does not exist: $group");
}

sub assert_group_is_system {
    my $group = shift;
    my $id = egetgrnam($group);

    if( defined($id) ) {
        is(in_range($id), 1, "is a system group: $group ($id)");
    } else {
        fail("group does not exist: $group") if not defined($id);
    }
}

sub assert_group_is_non_system {
    my $group = shift;
    my $id = egetgrnam($group);
    if( defined($id) ) {
        isnt(in_range($id), 1, "is not a system group: $group ($id)");
    } else {
        fail("group does not exist: $group") if not defined($id);
    }
}

sub assert_user_is_system {
    my $user = shift;
    my $id = egetpwnam($user);
    if( defined($id) ) {
        is(in_range($id,0), 1, "is a system user: $user ($id)");
    } else {
        fail("user does not exist: $user") if not defined($id);
    }
}

sub assert_user_is_non_system {
    my $user = shift;
    my $id = egetpwnam($user);
    if( defined($id) ) {
        isnt(in_range($id,0), 1, "is not a system user: $user ($id)");
    } else {
        fail("user does not exist: $user") if not defined($id);
    }
}

sub assert_gid_does_not_exist {
    my $gid = shift;
    is(getgrgid($gid), undef, "gid does not exist: $gid");
}

sub assert_group_exists {
    my $group = shift;
    isnt(egetgrnam($group), undef, "group exists: $group");
}

sub assert_gid_exists {
    my $gid = shift;
    isnt(getgrgid($gid), undef, "gid exists: $gid");
}

sub assert_group_gid_exists {
    my ($group, $gid) = @_;
    ok(group_gid_exists($group, $gid), "group exists: $group ($gid)");
}

sub group_gid_exists {
    my ($group, $gid) = @_;

    isnt(egetgrnam($group), undef, "group exists: $group");
    my @group_info = egetgrnam($group);

    if (defined($group_info[2])) {
        return 1 if $group_info[2] == $gid;
    }

    return 0;
}

sub assert_group_membership_does_not_exist {
    my ($user, $group) = @_;
    ok(!group_membership_exists($user, $group), "group membership does not exist: $user in $group");
}

sub assert_group_membership_exists {
    my ($user, $group) = @_;
    ok(group_membership_exists($user, $group), "group membership exists: $user in $group");
}

sub group_membership_exists {
    my ($user, $group) = @_;

    my @user_info = egetpwnam($user);
    my @group_info = egetgrnam($group);

    if (defined($user_info[3]) && defined($group_info[2])) {
        return 1 if $user_info[3] == $group_info[2];
    }

    if (defined($group_info[3])) {
        foreach (split(/ /, $group_info[3])) {
            return 1 if $_ eq $user;
        }
    }

    return 0;
}

sub assert_primary_group_membership_exists {
    my ($user, $group) = @_;
    ok(primary_group_membership_exists($user, $group), "primary group membership exists: $user in $group");
}

sub primary_group_membership_exists {
    my ($user, $group) = @_;

    my @user_info = egetpwnam($user);
    my @group_info = egetgrnam($group);

    if (defined($user_info[3]) && defined($group_info[2])) {
        return 1 if $user_info[3] == $group_info[2];
    }

    return 0;
}

sub assert_supplementary_group_membership_exists {
    my ($user, $group) = @_;
    ok(supplementary_group_membership_exists($user, $group), "supplementary group membership exists: $user in $group");
}

sub assert_supplementary_group_membership_does_not_exist {
    my ($user, $group) = @_;
    ok(!supplementary_group_membership_exists($user, $group), "supplementary group membership does not exist: $user in $group");
}

sub supplementary_group_membership_exists {
    my ($user, $group) = @_;

    my @group_info = egetgrnam($group);

    if (defined($group_info[3])) {
        foreach (split(/ /, $group_info[3])) {
            return 1 if $_ eq $user;
        }
    }

    return 0;
}

sub assert_path_does_not_exist {
    my $path = shift;
    ok(! -e $path, "path does not exist: $path");
}

sub assert_path_exists {
    my $path = shift;
    ok(-e $path, "path exists: $path");
}

sub assert_path_has_mode {
    my ($path, $mode, $orig_mode) = @_;
    my $real_mode;
    my $name = "path has mode: $path has mode $mode";
    $name .= " (requested mode $orig_mode)" if $orig_mode;

    my @info = stat($path);

    if (!@info) {
        fail($name);
        return;
    }

    $mode = sprintf('%04o', oct("0$mode") & 07777);
    $real_mode = sprintf('%04o', $info[2] & 07777);
    is($real_mode, $mode, $name);
}

sub assert_path_has_ownership {
    my ($path, $ownership) = @_;
    my $name = "path has ownership: $path is owned by $ownership";

    my @info = stat($path);

    if (!@info) {
        fail($name);
        return;
    }

    my $user = getpwuid($info[4]);
    my $group = getgrgid($info[5]);

    if (!defined($user) || !defined($group)) {
        fail($name);
        return;
    }

    is(sprintf('%s:%s', $user, $group), $ownership, $name);
}

sub assert_path_is_a_file {
    my $path = shift;
    ok(-f $path, "path is a file $path");
}

sub assert_path_is_a_directory {
    my $path = shift;
    ok(-d $path, "path is a directory: $path");
}

sub assert_path_is_an_empty_directory {
    my $path = shift;
    my $name = "path is an empty directory: $path";

    my $dh;
    if (!opendir($dh, $path)) {
        fail($name);
        return;
    }

    my @entries = readdir $dh;

    # Expect $path/. and $path/.. to count for two entries.
    is(scalar(@entries), 2, $name);
}

sub assert_user_does_not_exist {
    my $user = shift;
    is(egetpwnam($user), undef, "user does not exist: $user");
}

sub assert_user_exists {
    my $user = shift;
    isnt(egetpwnam($user), undef, "user exists: $user");
}

sub assert_uid_does_not_exist {
    my $uid = shift;
    is(getpwuid($uid), undef, "uid does not exist: $uid");
}

sub assert_uid_exists {
    my $uid = shift;
    isnt(getpwuid($uid), undef, "uid exists: $uid");
}

sub assert_user_uid_exists {
    my ($user, $uid) = @_;
    ok(user_uid_exists($user, $uid), "user exists: $user ($uid)");
}

sub user_uid_exists {
    my ($user, $uid) = @_;

    isnt(egetpwnam($user), undef, "user exists: $user");
    my @user_info = egetpwnam($user);

    if (defined($user_info[2])) {
        return 1 if $user_info[2] == $uid;
    }

    return 0;
}

sub assert_user_has_disabled_password {
    # this should be changed to check against the varios ways of
    # checking an account: !, * in shadow, and expiry. It should change
    # to a two-argument variant that checks for certain kind of lock
    my $user = shift;
    my $name = "user has disabled password: $user";

    my $fh;
    if (!open($fh, '<', '/etc/shadow')) {
        fail($name);
        return;
    }

    while (<$fh>) {
        my @info = split(/:/, $_);

        if ($info[0] eq $user && $info[1] eq '!') {
            pass($name);
            return;
        }
    }

    fail($name);
}

sub assert_user_has_home_directory {
    my ($user, $home) = @_;
    is((egetpwnam($user))[7], $home, "user has home directory: ~$user is $home");
}

sub assert_user_has_comment {
    my ($user, $comment) = @_;
    is((egetpwnam($user))[6], $comment, "user has comment: ~$user is $comment");
}

sub assert_dir_group_owner {
    my ($dir, $group) = @_;
    my $gid=(stat($dir))[5];
    is( (getgrgid($gid))[0], $group, "directory $dir has group :$group" );
}

sub assert_user_has_login_shell {
    my ($user, $shell) = @_;
    is((egetpwnam($user))[8], $shell, "user has login shell: $user runs $shell");
}

sub assert_user_has_uid {
    my ($user, $uid) = @_;
    if (egetpwnam($user)) {
        my @pwnam=egetpwnam($user);
        my $isuid=$pwnam[2];
        is(egetpwnam($user), $uid, "user has uid: uid of $user is $isuid (expected $uid)");
    } else {
        fail( "user has uid: user $user does not exist" );
    }
}

sub assert_group_has_gid {
    my ($group, $gid) = @_;
    if (egetgrnam($group)) {
        my @grnam=egetgrnam($group);
        my $isgid=$grnam[2];
        is(egetgrnam($group), $gid, "group has gid: gid of $group is $isgid (expected $gid)");
    } else {
        fail( "group has gid: group $group does not exist" );
    }
}

sub which {
    my ($progname, $nonfatal) = @_ ;
    for my $dir (split /:/, $ENV{"PATH"}) {
        if (-x "$dir/$progname" ) {
            return "$dir/$progname";
        }
    }
    dief(gtx("Could not find program named `%s' in \$PATH.\n"), $progname) unless ($nonfatal);
    return 0;
}

sub apply_config {
    my ($key, $val);
    my $config = '/etc/adduser.conf';
    open(CONF, '>', $config);
    while (@_) {
        $key = shift;
        $val = shift || 
            die "apply_config missing value for key $key";
        print CONF "$key"."="."$val"."\n";
    }
    close(CONF);
}

sub apply_config_hash {
    my $href = shift;
    my $config = '/etc/adduser.conf';
    open(CONF, '>', $config);
    foreach (keys %{$href}) {
        if ($href->{$_} ne '') {
            print CONF $_, "=", $href->{$_}, "\n";
        }
    }
    close(CONF);
}

1;

# vim: tabstop=4 shiftwidth=4 expandtab

