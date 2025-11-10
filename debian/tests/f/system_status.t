#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=559423


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

# how do I use a module from the package in question?
#use AdduserRetvalues;

use constant RET_OK => 0;
use constant RET_OBJECT_EXISTS => 11;
use constant RET_OBJECT_DOES_NOT_EXIST => 12;
use constant RET_WRONG_OBJECT_PROPERTIES => 13;
use constant RET_NO_PRIMARY_GID => 23;


my $name = "sys-stat-t";

# we move through all possible transitions
# number  existing before  operation        result       existing after
# 11      nothing          create system    success      system
# 12      system           create system    success      system
# 13      system           delete system    success      nothing
# 14      nothing          delete system    obj_not_ex   nothing
# 15      nothing          delete nonsys    obj_not_ex   nothing
# 21      nothing          create system    success      system
# 22      system           create nonsys    obj_exists   system
# 23      system           delete nonsys    wrong_prpo   system
# 24      system           delete system    success      nothing
# 31      nothing          create nonsys    success      nonsys
# 32      nonsys           create nonsys    obj_exists   nonsys
# 33      nonsys           delete sys       wrong_prop   nonsys
# 34      nonsys           create sys       wrong_prop   nonsys
# 35      nonsys           delete nonsys    success      nothing

#         existing before  operation        number
#         nothing          create sys       21, 11
#         nothing          create non       31
#         system           create sys       12
#         system           create non       22
#         nonsys           create sys       34
#         nonsys           create non       32
#         nothing          delete sys       14
#         nothing          delete non       15
#         system           delete sys       13, 24
#         system           delete non       23
#         nonsys           delete sys       33
#         nonsys           delete non       35

### USERS ###

# number  existing before  operation        result       existing after
# 11      nothing          create system    success      system
assert_user_does_not_exist($name);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);

# number  existing before  operation        result       existing after
# 12      system           create system    success      system
# above: assert_user_exists($name);
# above: assert_user_is_system($name);
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);

# number  existing before  operation        result       existing after
# 13      system           delete system    success      nothing
# above: assert_user_exists($name);
# above: assert_user_is_system($name);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_does_not_exist($name);

# number  existing before  operation        result       existing after
# 14      nothing          delete system    obj_not_ex   nothing
# above: assert_user_does_not_exist($name);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_does_not_exist($name);

# number  existing before  operation        result       existing after
# 15      nothing          delete nonsys    obj_not_ex   nothing
# above: assert_user_does_not_exist($name);
assert_command_result_silent(RET_OBJECT_DOES_NOT_EXIST,
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_user_does_not_exist($name);

# number  existing before  operation        result       existing after
# 21      nothing          create system    success      system
# above: assert_user_does_not_exist($name);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);

# number  existing before  operation        result       existing after
# 22      system           create nonsys    obj_exists   system
# above: assert_user_is_system($name);
assert_command_result_silent(RET_OBJECT_EXISTS,
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--no-create-home',
    '--comment', '""',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);

# number  existing before  operation        result       existing after
# 23      system           delete nonsys    wrong_prop   system
# in adduser 3.145, this succeeds!
# above: assert_user_is_system($name);
#assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_user_does_not_exist($name);
# recreate again so that the sequence can continue
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);

# number  existing before  operation        result       existing after
# 24      system           delete system    success      nothing
# above: assert_user_is_system($name);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_does_not_exist($name);

# number  existing before  operation        result       existing after
# 31      nothing          create nonsys    success      nonsys
# above: assert_user__does_not_exist($name);
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--no-create-home',
    '--comment', '""',
    $name
);
assert_user_exists($name);
assert_user_is_non_system($name);

# number  existing before  operation        result       existing after
# 32      nonsys           create nonsys    obj_exists   nonsys
# above: assert_user_exists($name);
# above: assert_user_is_non_system($name);
assert_command_result_silent(RET_OBJECT_EXISTS,
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--no-create-home',
    '--comment', '""',
    $name
);
assert_user_exists($name);
assert_user_is_non_system($name);

# number  existing before  operation        result       existing after
# 33      nonsys           delete sys       wrong_prop   nonsys
# above: assert_user_exists($name);
# above: assert_user_is_non_system($name);
assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_non_system($name);

# number  existing before  operation        result       existing after
# 34      nonsys           create sys       wrong_prop   nonsys
# above: assert_user_exists($name);
# above: assert_user_is_non_system($name);
assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_non_system($name);

# number  existing before  operation        result       existing after
# 35      nonsys           delete nonsys    success      nothing
# above: assert_user_exists($name);
# above: assert_user_is_non_system($name);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_user_does_not_exist($name);


### GROUPS ###

# number  existing before  operation        result       existing after
# 11      nothing          create system    success      system
assert_group_does_not_exist($name);

assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

# number  existing before  operation        result       existing after
# 12      system           create system    success      system
# above: assert_group_exists($name);
# above: assert_group_is_system($name);
assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

# number  existing before  operation        result       existing after
# 13      system           delete system    success      nothing
# above: assert_group_exists($name);
# above: assert_group_is_system($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);

# number  existing before  operation        result       existing after
# 14      nothing          delete system    obj_not_ex   nothing
# above: assert_group_does_not_exist($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);

# number  existing before  operation        result       existing after
# 15      nothing          delete nonsys    obj_not_ex   nothing
# above: assert_group_does_not_exist($name);
assert_command_result_silent(RET_OBJECT_DOES_NOT_EXIST,
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_group_does_not_exist($name);

# number  existing before  operation        result       existing after
# 21      nothing          create system    success      system
# above: assert_group_does_not_exist($name);

assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

# number  existing before  operation        result       existing after
# 22      system           create nonsys    obj_exists   system
# above: assert_group_is_system($name);
assert_command_result_silent(RET_OBJECT_EXISTS,
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--no-create-home',
    '--comment', '""',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

# number  existing before  operation        result       existing after
# 23      system           delete nonsys    wrong_prop   system
# in addgroup 3.145, this succeeds!
# above: assert_group_is_system($name);
#assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_group_does_not_exist($name);
# recreate again so that the sequence can continue
assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

# number  existing before  operation        result       existing after
# 24      system           delete system    success      nothing
# above: assert_group_is_system($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);

# number  existing before  operation        result       existing after
# 31      nothing          create nonsys    success      nonsys
# above: assert_group__does_not_exist($name);
assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--no-create-home',
    '--comment', '""',
    $name
);
assert_group_exists($name);
assert_group_is_non_system($name);

# number  existing before  operation        result       existing after
# 32      nonsys           create nonsys    obj_exists   nonsys
# above: assert_group_exists($name);
# above: assert_group_is_non_system($name);
assert_command_result_silent(RET_OBJECT_EXISTS,
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password',
    '--no-create-home',
    '--comment', '""',
    $name
);
assert_group_exists($name);
assert_group_is_non_system($name);

# number  existing before  operation        result       existing after
# 33      nonsys           delete sys       wrong_prop   nonsys
# above: assert_group_exists($name);
# above: assert_group_is_non_system($name);
assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_non_system($name);

# number  existing before  operation        result       existing after
# 34      nonsys           create sys       wrong_prop   nonsys
# above: assert_group_exists($name);
# above: assert_group_is_non_system($name);
assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_non_system($name);

# number  existing before  operation        result       existing after
# 35      nonsys           delete nonsys    success      nothing
# above: assert_group_exists($name);
# above: assert_group_is_non_system($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_group_does_not_exist($name);


# following are the older tests. too lazy to remove at this moment
# create system group, create system group => success
$name="aussystat-g-cscs";
assert_group_does_not_exist($name);

assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);
assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

assert_command_success(
    '/usr/sbin/delgroup', 
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);

# create system group, create non-system group => refusal
$name="aussystat-g-csns";
assert_group_does_not_exist($name);

assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);
assert_command_result_silent(RET_OBJECT_EXISTS,
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);

# create system group, delete system group
$name="aussystat1";
assert_group_does_not_exist($name);

assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);
assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

assert_command_success(
    '/usr/sbin/delgroup', 
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_does_not_exist($name);

# create non-system group, create non-system group => success
# create non-system group, create system group => refusal
# create non-system group, delete system group
$name="aussystat2";
assert_group_does_not_exist($name);

assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_group_exists($name);
assert_group_is_non_system($name);

assert_command_failure_silent(
    '/usr/sbin/delgroup', 
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_non_system($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_group_does_not_exist($name);

# create system group, delete non-system group
$name="aussystat3";
assert_group_does_not_exist($name);

assert_command_success(
    '/usr/sbin/addgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_group_exists($name);
assert_group_is_system($name);

# this delete operation succeeds in adduser 3.145
# we are not sure whether this is correct behavior
# discussion pending
#assert_command_result_silent(RET_WRONG_OBJECT_PROPERTIES,
#    '/usr/sbin/delgroup', 
#    '--stdoutmsglevel=error', '--stderrmsglevel=error',
#    $name
#);
assert_group_exists($name);
assert_group_is_system($name);
assert_command_success(
    '/usr/sbin/delgroup',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_group_does_not_exist($name);

# create system user, create system user => success
# create system user, create non-system user => refusal
# create system user, delete system user
$name="aussystat4";
assert_user_does_not_exist($name);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);
assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);

assert_command_success(
    '/usr/sbin/deluser', 
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_does_not_exist($name);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_does_not_exist($name);

# create non-system user, create non-system user => success
# create non-system user, create system user => refusal
# create non-system user, delete system user
$name="aussystat5";
assert_user_does_not_exist($name);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--no-create-home',
    '--disabled-password',
    '--comment', '""',
    $name
);
assert_user_exists($name);
assert_user_is_non_system($name);

assert_command_failure_silent(
    '/usr/sbin/deluser', 
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_non_system($name);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_user_does_not_exist($name);

# create system user, delete non-system user
$name="aussystat6";
assert_user_does_not_exist($name);

assert_command_success(
    '/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--system',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);

assert_command_failure_silent(
    '/usr/sbin/deluser', 
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--no-create-home',
    '--disabled-password',
    '--comment', '""',
    $name
);
assert_user_exists($name);
assert_user_is_system($name);
assert_command_success(
    '/usr/sbin/deluser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    $name
);
assert_user_does_not_exist($name);

# vim: tabstop=4 shiftwidth=4 expandtab
