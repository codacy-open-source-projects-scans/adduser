#! /usr/bin/perl -Idebian/tests/lib

# check adduser with --home /nonexistent and explicit --no-create-home
# Debian Bug #1099073

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

# create user and group
my $test_user="u1099073";
my $test_home="/nonexistent";
assert_user_does_not_exist($test_user);
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    '--home', '/nonexistent',
    '--system',
    $test_user);
assert_user_exists($test_user);
assert_user_has_home_directory($test_user, $test_home);
assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $test_user);

assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    '--home', '/nonexistent',
    '--no-create-home',
    '--system',
    $test_user);
assert_user_exists($test_user);
assert_user_has_home_directory($test_user, $test_home);
assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $test_user);
assert_user_does_not_exist($test_user);


# end of test
# vim: tabstop=4 shiftwidth=4 expandtab
