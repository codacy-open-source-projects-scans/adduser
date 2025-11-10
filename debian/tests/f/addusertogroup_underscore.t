#! /usr/bin/perl -Idebian/tests/lib

# check adduser username to group
# Debian Bug #1099397

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

# create user and group
my $test_user="u1099397";
my $test_sysuser="_u1099397";
my $test_group="g1099397";
my $test_sysgroup="_g1099397";
my $nonexistent="/nonexistent";
assert_user_does_not_exist($test_user);
assert_user_does_not_exist($test_sysuser);
assert_group_does_not_exist($test_group);
assert_group_does_not_exist($test_sysgroup);
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    '--home', '/nonexistent',
    '--ingroup', 'nogroup',
    '--disabled-password',
    '--comment', '',
    $test_user);
assert_user_exists($test_user);
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    '--system',
    $test_sysuser);
assert_user_exists($test_sysuser);
assert_command_success('/usr/sbin/addgroup',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    $test_group);
assert_group_exists($test_group);
assert_command_success('/usr/sbin/addgroup',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    '--system',
    $test_sysgroup);
assert_group_exists($test_sysgroup);

assert_group_membership_does_not_exist($test_user, $test_group);
assert_group_membership_does_not_exist($test_user, $test_sysgroup);
assert_group_membership_does_not_exist($test_sysuser, $test_group);
assert_group_membership_does_not_exist($test_sysuser, $test_sysgroup);

assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $test_user,
    $test_group);
assert_group_membership_exists($test_user, $test_group);
assert_group_membership_does_not_exist($test_user, $test_sysgroup);
assert_group_membership_does_not_exist($test_sysuser, $test_group);
assert_group_membership_does_not_exist($test_sysuser, $test_sysgroup);


assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $test_user,
    $test_sysgroup);
assert_group_membership_exists($test_user, $test_group);
assert_group_membership_exists($test_user, $test_sysgroup);
assert_group_membership_does_not_exist($test_sysuser, $test_group);
assert_group_membership_does_not_exist($test_sysuser, $test_sysgroup);

assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $test_sysuser,
    $test_group);
assert_group_membership_exists($test_user, $test_group);
assert_group_membership_exists($test_user, $test_sysgroup);
assert_group_membership_exists($test_sysuser, $test_group);
assert_group_membership_does_not_exist($test_sysuser, $test_sysgroup);

assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $test_sysuser,
    $test_sysgroup);
assert_group_membership_exists($test_user, $test_group);
assert_group_membership_exists($test_user, $test_sysgroup);
assert_group_membership_exists($test_sysuser, $test_group);
assert_group_membership_exists($test_sysuser, $test_sysgroup);

assert_command_success('/usr/sbin/delgroup',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    $test_group);
assert_group_does_not_exist($test_group);
assert_group_membership_does_not_exist($test_user, $test_group);
assert_group_membership_exists($test_user, $test_sysgroup);
assert_group_membership_does_not_exist($test_sysuser, $test_group);
assert_group_membership_exists($test_sysuser, $test_sysgroup);


assert_command_success('/usr/sbin/delgroup',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    $test_sysgroup);
assert_group_does_not_exist($test_sysgroup);
assert_group_membership_does_not_exist($test_user, $test_group);
assert_group_membership_does_not_exist($test_user, $test_sysgroup);
assert_group_membership_does_not_exist($test_sysuser, $test_group);
assert_group_membership_does_not_exist($test_sysuser, $test_sysgroup);

assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    $test_user);
assert_user_does_not_exist($test_user);

assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=warn', '--stderrmsglevel=warn',
    $test_sysuser);
assert_user_does_not_exist($test_sysuser);


# end of test
# vim: tabstop=4 shiftwidth=4 expandtab
