#! /usr/bin/perl -Idebian/tests/lib

# check group_creation functionality

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

# how do I use a module from the package in question?
#use AddgroupRetvalues;

use constant RET_OK => 0;
use constant RET_OBJECT_EXISTS => 11;
use constant RET_WRONG_OBJECT_PROPERTIES => 13;

my $usergid=40000;
my $sysggid=400;
my $test_name="test1";
my $nextid;

my @quiet=("--stdoutmsglevel=error", '--stderrmsglevel=error');

# non-system group
$test_name="test1";
assert_command_success(
    '/usr/sbin/addgroup', @quiet,
    $test_name);
assert_group_exists($test_name);
assert_command_result_silent(RET_OBJECT_EXISTS,
    '/usr/sbin/addgroup', @quiet,
    $test_name);
assert_group_exists($test_name);

# non-system group
# with explicit --gid
$test_name="test1-a";
$usergid++;
assert_command_success(
    '/usr/sbin/addgroup', @quiet,
    '--gid', "$usergid",
    $test_name);
assert_group_gid_exists($test_name,$usergid);
assert_command_result_silent(RET_OBJECT_EXISTS,
    '/usr/sbin/addgroup', @quiet,
    '--gid', "$usergid",
    $test_name);
assert_group_gid_exists($test_name,$usergid);
$nextid=$usergid+1000;
assert_command_result_silent(RET_OBJECT_EXISTS,
    '/usr/sbin/addgroup', @quiet,
    '--gid', "$nextid",
    $test_name);
assert_group_gid_exists($test_name,$usergid);

# system group
$test_name="systest1";
assert_command_success(
    '/usr/sbin/addgroup', @quiet,
    '--system',
    $test_name);
assert_group_exists($test_name);
assert_command_success(
    '/usr/sbin/addgroup', @quiet,
    '--system',
    $test_name);
assert_group_exists($test_name);

# system group
# with explicit --gid
$test_name="systest1-a";
$sysggid++;
assert_command_success(
    '/usr/sbin/addgroup', @quiet,
    '--system',
    '--gid', "$sysggid",
    $test_name);
assert_group_gid_exists($test_name,$sysggid);
assert_command_success(
    '/usr/sbin/addgroup', @quiet,
    '--system',
    '--gid', "$sysggid",
    $test_name);
assert_group_gid_exists($test_name,$sysggid);
$nextid=$sysggid+1000;
assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
    '/usr/sbin/addgroup', @quiet,
    '--system',
    '--gid', "$nextid",
    $test_name);
assert_group_gid_exists($test_name,$sysggid);

# vim: tabstop=4 shiftwidth=4 expandtab
