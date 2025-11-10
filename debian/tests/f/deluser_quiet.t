#! /usr/bin/perl -Idebian/tests/lib


use diagnostics;
use strict;
use warnings;

my $name='duq';

use AdduserTestsCommon;


END {
    remove_tree("/home/$name");
    remove_tree("/var/mail/$name");
}

assert_user_does_not_exist($name);
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);

my $output = `/usr/sbin/deluser --stdoutmsglevel=error --stderrmsglevel=error $name 2>&1`;
is($output, '', 'option "--stdoutmsglevel=error" silences deluser output under normal use');

assert_user_does_not_exist($name);

# vim: tabstop=4 shiftwidth=4 expandtab
