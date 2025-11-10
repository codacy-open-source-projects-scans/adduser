#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=558260


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $name='ausquiet';

END {
    remove_tree("/var/mail/$name");
}

assert_user_does_not_exist($name);
assert_group_does_not_exist($name);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-login',
    '--comment', '""',
    '--no-create-home',
    $name
);

assert_user_exists($name);
assert_group_exists($name);
assert_path_does_not_exist("/home/$name");

assert_group_membership_exists($name, $name);
assert_primary_group_membership_exists($name, $name);

assert_group_membership_does_not_exist($name, 'adm');

my $command = "/usr/sbin/adduser --stdoutmsglevel=error --stderrmsglevel=error $name adm 2>&1";
my $output = `$command`;

is($? >> 8, 0, "command success: $command");
is($output, '', 'option "--stdoutmsglevel=error" silences output when adding user to group');

assert_group_membership_exists($name, 'adm');

assert_primary_group_membership_exists($name, $name);
assert_supplementary_group_membership_exists($name, 'adm');

# vim: tabstop=4 shiftwidth=4 expandtab
