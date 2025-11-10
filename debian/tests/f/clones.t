#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=701110


use diagnostics;
use strict;
use warnings;

my $name1='ausclone1';
my $name2='ausclone2';

use AdduserTestsCommon;


END {
    remove_tree("/home/$name1");
    remove_tree("/var/mail/$name1");
    remove_tree("/home/$name2");
    remove_tree("/var/mail/$name2");
}

assert_user_does_not_exist($name1);
assert_command_success('/usr/sbin/adduser',
	'--stdoutmsglevel=error', '--stderrmsglevel=error',
       	'--system',
	$name1);

assert_user_does_not_exist($name2);
assert_command_success('/usr/sbin/useradd', '-r',
    '-g', scalar getgrnam('nogroup'),
    '-o', '-u', scalar getpwnam($name1), '-s', '/usr/sbin/nologin', $name2);

assert_command_success('/usr/sbin/adduser',
	'--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name1, 'adm');
assert_command_success('/usr/sbin/adduser', '-q', $name2, 'adm');

assert_group_membership_exists($name1, 'adm');
assert_group_membership_exists($name2, 'adm');

assert_command_success('/usr/sbin/deluser', '-q', $name2, 'adm');

assert_group_membership_exists($name1, 'adm');
assert_group_membership_does_not_exist($name2, 'adm');

# vim: tabstop=4 shiftwidth=4 expandtab
