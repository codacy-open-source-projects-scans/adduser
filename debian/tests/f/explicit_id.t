#! /usr/bin/perl -Idebian/tests/lib

# check functionality of setting explicit UID

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my @quiet=("--stdoutmsglevel=error", '--stderrmsglevel=error');

my @testsysuid;
my @testsysgid;
my @testuid;
my @testgid;
my $numofids=10;

my $i=200;
my $maxuidgid=900;
while( $i++ < $maxuidgid ) {
    if( !defined( getpwuid($i) ) ) {
        push(@testsysuid,$i);
        if( $#testsysuid > $numofids ) {
            last;
        }
    }
}
if( $#testsysuid <= $numofids ) {
    fail( "cannot find enough free system uids below $maxuidgid" );
}

$i=200;
while( $i++ < $maxuidgid ) {
    if( !defined( getgrgid($i) ) ) {
        push(@testsysgid,$i);
        if( $#testsysgid > $numofids ) {
            last;
        }
    }
}
if( $#testsysgid <= $numofids ) {
    fail( "cannot find enough free system gids below $maxuidgid" );
}

$i=20000;
$maxuidgid=29000;
while( $i++ < $maxuidgid ) {
    if( !defined( getpwuid($i) ) ) {
        push(@testuid,$i);
        if( $#testuid > $numofids ) {
            last;
        }
    }
}
if( $#testuid <= $numofids ) {
    fail( "cannot find enough free uids below $maxuidgid" );
}

$i=20000;
while( $i++ < $maxuidgid ) {
    if( !defined( getgrgid($i) ) ) {
        push(@testgid,$i);
        if( $#testgid > $numofids ) {
            last;
        }
    }
}
if( $#testgid <= $numofids ) {
    fail( "cannot find enough free gids below $maxuidgid" );
}

my $gid;
my $uid;

# create empty system group with set gid
my $test1="mygroup1";
$gid=pop(@testsysgid);
assert_command_success('/usr/sbin/addgroup', @quiet,
     '--system', '--gid', $gid, $test1);
assert_group_exists($test1);
assert_gid_exists($gid);
assert_group_gid_exists($test1, $gid);


# create empty group with set gid
my $test2="mygroup2";
$gid=pop(@testgid);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--gid', $gid, $test2);
assert_group_exists($test2);
assert_gid_exists($gid);
assert_group_gid_exists($test2, $gid);


# create system user with set uid
my $test3="myuser3";
$uid=pop(@testsysuid);
assert_command_success('/usr/sbin/adduser', @quiet,
    '--system', '--uid', $uid, $test3);
assert_user_exists($test3);
assert_uid_exists($uid);
assert_user_uid_exists($test3, $uid);


# create user with set uid
my $test4="myuser4";
$uid=pop(@testuid);
assert_command_success('/usr/sbin/adduser', @quiet,
    '--no-create-home',
    '--comment', '""', '--disabled-password',
    '--ingroup', $test1,
    '--uid', $uid, $test4);
assert_user_exists($test4);
assert_uid_exists($uid);
assert_user_uid_exists($test4, $uid);

# create user in non existing group
my $test5="myuser5";
$uid=pop(@testuid);
assert_command_failure_silent('/usr/sbin/adduser', @quiet,
    '--no-create-home',
    '--ingroup', "does-not-exist",
    '--comment', '""', '--disabled-password',
    $test5);
assert_user_does_not_exist($test5);
assert_group_does_not_exist($test5);

# create user with set uid, allowing group creation
my $test6="myuser6";
$uid=pop(@testuid);
assert_command_success('/usr/sbin/adduser', @quiet,
    '--no-create-home',
    '--comment', '""', '--disabled-password',
    '--uid', $uid, $test6);
assert_user_exists($test6);
assert_uid_exists($uid);
assert_user_uid_exists($test6, $uid);
assert_group_exists($test6);

# vim: tabstop=4 shiftwidth=4 expandtab
