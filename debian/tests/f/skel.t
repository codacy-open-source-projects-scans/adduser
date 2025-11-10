#! /usr/bin/perl -Idebian/tests/lib


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $name="ausskel";

END {
    remove_tree("/var/mail/$name");
    unlink("/etc/skel/test\ file");
}

system("cp /etc/skel/.bashrc /etc/skel/test\\ file");
assert_path_is_a_file("/etc/skel/test file");

assert_user_does_not_exist($name);
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--comment','""',
    '--disabled-password',
    $name
);
assert_user_exists($name);
assert_user_has_home_directory($name,"/home/$name");
assert_path_is_a_directory("/home/$name");

my $skel_list = `find /etc/skel/ -mindepth 1 -printf "%f %l %m %s\n" | sort`;
my $home_list = `find /home/$name/ -mindepth 1 -printf "%f %l %m %s\n" | sort`;
ok($? == 0, "find /home/$name  successful");
if( !ok($home_list eq $skel_list, 'files copied to home directory correct') ) {
    print("skel_list: $skel_list\n");
    print("home_list $home_list\n");
    system("ls -al /etc/skel");
    system("ls -al /home/$name");
}

# vim: tabstop=4 shiftwidth=4 expandtab
