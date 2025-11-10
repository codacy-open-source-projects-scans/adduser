#! /usr/bin/perl -Idebian/tests/lib

use diagnostics;
use strict;
use warnings;

use Fcntl qw(:flock SEEK_END);

use AdduserTestsCommon;

my $name1='auslocks1';
my $name2='auslocks2';

my $lockfile;

ok(open($lockfile, '>>', '/run/adduser'), 'open lockfile');
ok(flock($lockfile, LOCK_EX), 'lock established');
assert_path_exists('/run/adduser', 'lockfile exists');
assert_command_failure_silent('/usr/bin/adduser', '--system', $name1);
assert_command_failure_silent('/usr/bin/addgroup', '--system', $name2);
assert_command_failure_silent('/usr/bin/adduser', $name1, $name2);
assert_command_failure_silent('/usr/bin/adduser', '--system', $name1);
assert_command_failure_silent('/usr/bin/deluser', '--system', $name1);
ok(flock($lockfile, LOCK_UN), 'lock released');

assert_command_success('rm', '-f', '/run/adduser');
assert_command_success('mkdir', '/run/adduser');
assert_command_failure_silent('/usr/bin/adduser', '--system', $name1);
assert_command_success('rmdir', '/run/adduser');

close($lockfile);

# vim: tabstop=4 shiftwidth=4 expandtab
