#! /usr/bin/perl -Idebian/tests/lib

# check adduser user group and addgroup user group

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

# create user and group
my $test_user="testuser";
my $test_group="testgroup";
assert_user_does_not_exist($test_user);
assert_group_does_not_exist($test_group);
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--comment', '',
    $test_user);
assert_command_success('/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $test_group);
assert_user_exists($test_user);
assert_group_exists($test_group);

# test addgroup user group (failure)
assert_command_failure_silent('/usr/sbin/addgroup',
	$test_user, $test_group);
assert_group_membership_does_not_exist($test_user, $test_group);

# test adduser user group (success)
assert_command_success('/usr/sbin/adduser',
	$test_user, $test_group);
assert_group_membership_exists($test_user, $test_group);

# end of test
# vim: tabstop=4 shiftwidth=4 expandtab
