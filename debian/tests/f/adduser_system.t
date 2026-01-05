#! /usr/bin/perl -Idebian/tests/lib

# N.B. This test script is intended to serve as living documentation of the
# default behavior one can expect when creating a new system user. It should
# match the behavior as specified in the adduser(8) man page and vice versa.

# user name aust stands for "adduser test"

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

# how do I use a module from the package in question?
#use AdduserRetvalues;

use constant RET_OK => 0;
use constant RET_OBJECT_EXISTS => 11;
use constant RET_OBJECT_DOES_NOT_EXIST => 12;
use constant RET_WRONG_OBJECT_PROPERTIES => 13;
use constant RET_NO_PRIMARY_GID => 23;


END {
    remove_tree('/home/aust');
    remove_tree('/var/mail/aust');
}

my $uid;

# Ref: https://www.debian.org/doc/debian-policy/ch-opersys.html#uid-and-gid-classes
for (100..999) {
    next if defined(getpwuid($_));

    $uid = $_;
    last;
}

# check whether two identical calls in a row do succeed
# result in a policy compliant user
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);
assert_user_does_not_exist('aust');
assert_path_does_not_exist('/nonexistent');

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');
assert_user_has_home_directory('aust', '/nonexistent');

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');
assert_user_has_uid('aust', $uid);

assert_group_does_not_exist('aust');
assert_primary_group_membership_exists('aust', 'nogroup');

assert_user_has_home_directory('aust', '/nonexistent');
assert_path_does_not_exist('/nonexistent');

assert_user_has_login_shell('aust', '/usr/sbin/nologin');

assert_user_has_disabled_password('aust');

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1004710
assert_path_does_not_exist('/var/mail/aust');

while (defined(getpwuid($uid))) {
    $uid++;
}
assert_user_does_not_exist('aust2');
assert_path_does_not_exist('/nonexistent');

# create account with specified shell
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--shell', '/bin/sh',
    'aust2'
);
assert_user_exists('aust2');
assert_user_is_system('aust');
assert_user_has_uid('aust2', $uid);

assert_group_does_not_exist('aust2');
assert_primary_group_membership_exists('aust2', 'nogroup');

assert_user_has_home_directory('aust2', '/nonexistent');
assert_path_does_not_exist('/nonexistent');

assert_user_has_login_shell('aust2', '/bin/sh');

assert_user_has_disabled_password('aust2');

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1004710
assert_path_does_not_exist('/var/mail/aust2');

# Ref: bug #1099470, create and recreate a passwordless account
# (this is actually the same as without --disabled password, but 
# some packages still call that explicitly)
# This might cause some grief when we address #1008082 - #1008084
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);
assert_user_does_not_exist('aust');
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--disabled-password',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--disabled-password',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');

# Ref: bug #1099470, create and recreate a locked account
# This might cause some grief when we address #1008082 - #1008084
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);
assert_user_does_not_exist('aust');
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--disabled-login',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--disabled-login',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');

# create an account, set password to
# *, !, *something, !something
# explicitly, try to recreate account
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);
assert_user_does_not_exist('aust');
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--disabled-login',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');

system('echo "aust:*" | chpasswd --encrypted');
ok(1, "set passwd to *");
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--disabled-login',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');

system('echo "aust:!foobar" | chpasswd --encrypted');
# with #1099734 fixed, this should fail
assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--disabled-login',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');

system('echo "aust:*foobar" | chpasswd --encrypted');
ok(1, "set passwd to *foobar");
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--disabled-login',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);

# ref #100032
# test --home
# we are testing with stdoutmsglevel warn so that we can catch
# non-silence on console.
# nb: adduser with pre-existing home directory with correct owner cannot
#     be tested, and that would also be a coincidence.
# --home /var/lib/aust with directory not present
my $homedir='/var/lib/aust';
unlink($homedir);
rmdir($homedir);
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=warn',
    '--home', $homedir,
    '--no-create-home',
    '--system',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');
assert_path_does_not_exist($homedir);
assert_user_has_home_directory('aust', $homedir);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=warn',
    '--home', $homedir,
    '--system',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');
assert_path_is_a_directory($homedir);
assert_user_has_home_directory('aust', $homedir);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);

# --home /var/lib/aust with directory present and incorrect owner
mkdir($homedir);
chown(0, 0, $homedir);
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=warn',
    '--home', $homedir,
    '--system',
    'aust'
);
assert_user_exists('aust');
assert_user_is_system('aust');
assert_path_is_a_directory($homedir);
assert_user_has_home_directory('aust', $homedir);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);

# clean up
# en passant test delgroup and deluser --group
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust2'
);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust'
);
assert_command_success(
    '/usr/sbin/deluser',
    '--group',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    'aust2'
);
assert_user_does_not_exist('aust');
assert_user_does_not_exist('aust2');
assert_group_does_not_exist('aust');
assert_group_does_not_exist('aust2');

# vim: tabstop=4 shiftwidth=4 expandtab
