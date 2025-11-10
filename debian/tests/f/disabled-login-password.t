#! /usr/bin/perl -Idebian/tests/lib

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $name1='ausdlp1';
my $name2='ausdlp2';
my $name3='ausdlp3';
my $name4='ausdlp4';

END {
    remove_tree("/home/$name1");
    remove_tree("/var/mail/$name1");
    remove_tree("/home/$name2");
    remove_tree("/var/mail/$name2");
}

my $uid;

# --- disabled-login
assert_user_does_not_exist($name1);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-login',
    '--comment', '',
    $name1
);
assert_user_exists($name1);

assert_user_has_login_shell($name1, '/usr/sbin/nologin');
assert_user_has_disabled_password($name1);

# --- disabled-login with explicit shell

assert_user_does_not_exist($name2);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-login',
    '--comment', '',
    '--shell', '/bin/sh',
    $name2
);
assert_user_exists($name2);

assert_user_has_login_shell($name2, '/bin/sh');
assert_user_has_disabled_password($name2);

# --- disabled-password
assert_user_does_not_exist($name3);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--comment', '',
    $name3
);
assert_user_exists($name3);

assert_user_has_login_shell($name3, '/bin/bash');
assert_user_has_disabled_password($name3);

# --- disabled-password with explicit shell

assert_user_does_not_exist($name4);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--comment', '',
    '--shell', '/bin/bash',
    $name4
);
assert_user_exists($name4);

assert_user_has_login_shell($name4, '/bin/bash');
assert_user_has_disabled_password($name4);

# vim: tabstop=4 shiftwidth=4 expandtab
