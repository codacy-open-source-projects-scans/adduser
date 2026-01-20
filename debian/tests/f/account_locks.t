#! /usr/bin/perl -Idebian/tests/lib

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $prefix = "lockedtest";
my $un;

END {
	remove_tree("/home/$prefix-user");
	remove_tree("/var/mail/$prefix-user");
}

## system user

$un = "${prefix}-sys";

assert_user_does_not_exist($un);
assert_command_success('/usr/sbin/adduser',
	'--stdoutmsglevel=error', '--stderrmsglevel=error',
	'--disabled-password',
    '--system',
	$un);
assert_user_exists($un);
assert_user_status($un, EXISTING_LOCKED,       "locked");
assert_user_status($un, EXISTING_HAS_PASSWORD, "not has password");
assert_user_status($un, EXISTING_NOLOGIN,      "set to nologin");
assert_user_status($un, EXISTING_EXPIRED,      "not expired");
assert_command_success('/usr/sbin/deluser',
	'--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', "--lock",
	$un);
assert_user_exists($un);
assert_user_status($un, EXISTING_LOCKED,       "locked");
assert_user_status($un, EXISTING_HAS_PASSWORD, "not has password");
assert_user_status($un, EXISTING_NOLOGIN,      "set to nologin");
assert_user_status($un, EXISTING_EXPIRED,      "expired");
assert_command_success('/usr/sbin/adduser',
	'--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
	$un);
assert_user_status($un, EXISTING_LOCKED,       "locked");
assert_user_status($un, EXISTING_HAS_PASSWORD, "not has password");
assert_user_status($un, EXISTING_NOLOGIN,      "set to nologin");
assert_user_status($un, EXISTING_EXPIRED,      "not expired");
assert_user_exists($un);
assert_command_success('/usr/sbin/deluser',
	'--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', '--force-delete',
	$un);
assert_user_does_not_exist($un);

## normal user

$un = "${prefix}-user";

assert_user_does_not_exist($un);
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--comment', "",
    '--disabled-password',
    $un);
assert_user_exists($un);
assert_user_status($un, EXISTING_LOCKED,       "locked");
assert_user_status($un, EXISTING_HAS_PASSWORD, "not has password");
assert_user_status($un, EXISTING_NOLOGIN,      "not set to nologin");
assert_user_status($un, EXISTING_EXPIRED,      "not expired");
assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    "--lock",
    $un);
assert_user_exists($un);
assert_user_status($un, EXISTING_LOCKED,       "locked");
assert_user_status($un, EXISTING_HAS_PASSWORD, "not has password");
assert_user_status($un, EXISTING_NOLOGIN,      "set to nologin");
assert_user_status($un, EXISTING_EXPIRED,      "expired");
assert_command_failure('/usr/sbin/adduser',
    '--stdoutmsglevel=fatal', '--stderrmsglevel=fatal',
    $un);
assert_user_exists($un);
assert_user_status($un, EXISTING_LOCKED,       "locked");
assert_user_status($un, EXISTING_HAS_PASSWORD, "not has password");
assert_user_status($un, EXISTING_NOLOGIN,      "set to nologin");
assert_user_status($un, EXISTING_EXPIRED,      "expired");
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--unlock',
    $un);
assert_user_exists($un);
assert_user_status($un, EXISTING_LOCKED,       "locked");
assert_user_status($un, EXISTING_HAS_PASSWORD, "not has password");
assert_user_status($un, EXISTING_NOLOGIN,      "not set to nologin");
assert_user_status($un, EXISTING_EXPIRED,      "not expired");
assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--force-delete', '--remove-home',
    $un);
assert_user_does_not_exist($un);

# vim: tabstop=4 shiftwidth=4 expandtab
