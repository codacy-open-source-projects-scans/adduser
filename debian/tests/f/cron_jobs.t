#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1006899


use diagnostics;
use strict;
use warnings;

my $name='auscron';

use AdduserTestsCommon;


END {
    remove_tree("/var/spool/cron/crontabs/$name");
}

assert_user_does_not_exist($name);
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', '--no-create-home',
    $name
);
assert_user_exists($name);

my $command;

assert_path_does_not_exist("/var/spool/cron/crontabs/$name");
$command = "/usr/bin/crontab -u $name -l 2>&1"; `$command`;
is($? >> 8, 1, "command failure: $command");

$command = "/usr/bin/printf '* * * * * /bin/true\\n' | /usr/bin/crontab -u $name -"; system($command);
is($? >> 8, 0, "command success: $command");

assert_path_exists("/var/spool/cron/crontabs/$name");
$command = "/usr/bin/crontab -u $name -l 2>&1"; `$command`;
is($? >> 8, 0, "command success: $command");

assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_user_does_not_exist($name);

assert_path_does_not_exist("/var/spool/cron/crontabs/$name");
$command = "/usr/bin/crontab -u $name -l 2>&1"; `$command`;
is($? >> 8, 1, "command failure: $command");

# vim: tabstop=4 shiftwidth=4 expandtab
