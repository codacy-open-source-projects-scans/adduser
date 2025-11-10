#! /usr/bin/perl -Idebian/tests/lib


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

sub create_files_in_homedir{
    my ($acct, $uid, $gid, $acct2, $uid2, $gid2) = @_;
    mkdir ("/home/$acct", 0777);
    mkdir ("/home/$acct/mnt", 0777);
    mkdir ("/home/$acct/dir", 0777);
    mkdir ("/tmp/$acct", 0777);
    unlink("/tmp/deluserfiles.txt");
    for ("/home/$acct/extra.txt", "/tmp/$acct/extra2.txt", "/tmp/deluserfiles.txt", "/home/$acct2/not-utf-8-but-possible-\x7F", "/home/$acct/not-utf-8-but-possible-\x7F", "/home/$acct2/still-not-utf-8-but-possible-\x7F") {
        open (XTRA, '>', $_) || die ("could not open file $_: $!");
        print XTRA "extra file";
        close (XTRA) || die ('could not close file!');
    }
    system ('mkfifo', "/home/$acct/pipe");
    chown ($uid, $gid, 
        "/home/$acct", 
        "/home/$acct/extra.txt",
        "/tmp/$acct/extra2.txt",
        "/home/$acct/mnt",
        "/home/$acct/dir",
        "/tmp/deluserfiles.txt",
        "/home/$acct/pipe",
        "/home/$acct/not-utf-8-but-possible-\x7F",
        "/home/$acct2/still-not-utf-8-but-possible-\x7F");
    chown ($uid2, $gid2, "/home/$acct2/not-utf-8-but-possible-\x7F");
    assert_command_success('mount','-o','bind',"/tmp/$acct","/home/$acct/mnt");
}

END {
    # remove_tree('/home/deluserfiles');
    # remove_tree('/var/mail/deluserfiles');
    system("umount /home/deluserfiles-extra/mnt >/dev/null 2>/dev/null");
    remove_tree('/home/deluserfiles-extra');
    remove_tree('/tmp/deluserfiles-extra');
    unlink('/tmp/deluserfiles.tar.gz'); 
    unlink('/tmp/deluserfiles.txt');
    assert_user_exists('deluserfiles2');
    assert_command_success('/usr/sbin/deluser',
        '--stdoutmsglevel=error', '--stderrmsglevel=error',
        'deluserfiles2');
    assert_user_does_not_exist('deluserfiles2');
    remove_tree('/home/deluserfiles2');
}

assert_user_does_not_exist('deluserfiles2');
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--home', '/home/deluserfiles2',
    '--comment', '',
    '--disabled-password',
    'deluserfiles2');
assert_user_exists('deluserfiles2');

assert_user_does_not_exist('deluserfiles');
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', 
    '--home', '/home/deluserfiles',
    'deluserfiles');
assert_user_exists('deluserfiles');

my ($login, $pass, $uid, $gid) = getpwnam('deluserfiles');
my ($login2, $pass2, $uid2, $gid2) = getpwnam('deluserfiles2');
create_files_in_homedir("deluserfiles-extra", $uid, $gid, "deluserfiles2", $uid2, $gid2);

assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--backup-suffix', 'gz',
    '--remove-all-files',
    '--backup-to', '/tmp',
    'deluserfiles');
system("umount /home/deluserfiles-extra/mnt >/dev/null 2>/dev/null");
assert_user_does_not_exist('deluserfiles');
assert_path_does_not_exist('/home/deluserfiles');
assert_path_does_not_exist('/home/deluserfiles-extra/extra.txt');
assert_path_does_not_exist('/home/deluserfiles-extra/pipe');
#FIXME
#assert_path_does_not_exist('/tmp/deluserfiles-extra/extra2.txt');
assert_path_exists('/tmp/deluserfiles.txt');
assert_path_exists('/home/deluserfiles-extra/mnt');
assert_path_does_not_exist('/home/deluserfiles-extra/dir');

# check backup archive
assert_path_exists('/tmp/deluserfiles.tar.gz');
my $tar_files = `tar tf /tmp/deluserfiles.tar.gz`;
is($? >> 8, 0, 'successfully listed backup files');
like($tar_files, qr{home/deluserfiles-extra/extra.txt}, 'archive contains expected file: extra.txt');

# create new user and delete again, backing up to /nonexistent
# this succeeds when there are no files to back up
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', 
    '--home', '/home/deluserfiles',
    'deluserfiles');
assert_user_exists('deluserfiles', $uid, $gid);
assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--remove-all-files',
    '--backup-to', '/nonexistent',
    'deluserfiles');
# create new user, put files in and delete again, backing up to /nonexistent
# this must fail
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system', 
    '--home', '/home/deluserfiles',
    'deluserfiles');
assert_user_exists('deluserfiles', $uid, $gid);
($login, $pass, $uid, $gid) = getpwnam('deluserfiles');
create_files_in_homedir("deluserfiles-extra", $uid, $gid, "deluserfiles2", $uid2, $gid2);
assert_command_failure_silent('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--remove-all-files',
    '--backup-to', '/nonexistent',
    'deluserfiles');
assert_user_exists('deluserfiles');
assert_path_exists('/home/deluserfiles');
assert_path_exists('/home/deluserfiles-extra/extra.txt');
assert_path_exists('/home/deluserfiles-extra/pipe');
#FIXME
#assert_path_does_not_exist('/tmp/deluserfiles-extra/extra2.txt');
assert_path_exists('/tmp/deluserfiles.txt');
assert_path_exists('/home/deluserfiles-extra/mnt');
assert_path_exists('/home/deluserfiles-extra/dir');
assert_command_success('/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    '--remove-all-files',
    '--backup-to', '/tmp',
    'deluserfiles');
system("umount /home/deluserfiles-extra/mnt >/dev/null 2>/dev/null");
assert_user_does_not_exist('deluserfiles');
assert_path_does_not_exist('/home/deluserfiles');
assert_path_does_not_exist('/home/deluserfiles-extra/extra.txt');
assert_path_does_not_exist('/home/deluserfiles-extra/pipe');
#FIXME
#assert_path_does_not_exist('/tmp/deluserfiles-extra/extra2.txt');
assert_path_exists('/tmp/deluserfiles.txt');
assert_path_exists('/home/deluserfiles-extra/mnt');
assert_path_does_not_exist('/home/deluserfiles-extra/dir');

# vim: tabstop=4 shiftwidth=4 expandtab
