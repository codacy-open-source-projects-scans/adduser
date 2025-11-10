#! /usr/bin/perl -Idebian/tests/lib

# check first/last uid/gid functionality

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my @quiet=('--stdoutmsglevel=error', '--stderrmsglevel=error');
my $gidcount;
my $uidcount;

my @unames = ( 'flugu01', 'flugu02', 'flugu03', 'flugu04' );
my $unamex = 'flugu05';
my @gnames = ( 'flugg01', 'flugg02', 'flugg03', 'flugg04' );
my $gnamex = 'flugg05';
my $funame = 'fixedu01';
my $fgname = 'fixedg01';
my $user;
my $userbase;
my $fuid;
my $group;
my $groupbase;
my $fgid;
my $prefix;

my $firstuid1;
my $lastuid1;
my $firstgid1;
my $lastgid1;

sub cleanup {
    my $prefix=$_[0] || '';
    foreach $userbase( @unames ) {
        $user=$prefix.$userbase;
        system("/usr/sbin/deluser @quiet --remove-home $user 2>/dev/null");
        assert_user_does_not_exist($user);
    }
    system("/usr/sbin/deluser @quiet --remove-home $prefix$unamex 2>/dev/null");
    assert_user_does_not_exist($prefix.$unamex);
    system("/usr/sbin/deluser @quiet --remove-home $prefix$funame 2>/dev/null");
    assert_user_does_not_exist($prefix.$funame);
    $uidcount=0;
    foreach $groupbase( @gnames ) {
        $group=$prefix.$groupbase;
        system("/usr/sbin/delgroup @quiet $group 2>/dev/null");
        assert_group_does_not_exist($group);
    }
    system("/usr/sbin/delgroup @quiet $prefix$gnamex 2>/dev/null");
    assert_group_does_not_exist($prefix.$gnamex);
    system("/usr/sbin/delgroup @quiet $prefix$fgname 2>/dev/null");
    assert_user_does_not_exist($prefix.$fgname);
    $gidcount=0;
}
cleanup();

# test group U1A: default config, no command line

$prefix = 'u1a';
$fuid = 3750;
$fgid = 3761;
my %confhash=();
apply_config_hash(\%confhash);

foreach $groupbase( @gnames ) {
    $group = $prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet, $group);
    assert_group_exists($group);
    if ($gidcount==0) {
        $gidcount=((getgrnam($group))[2]);
    }
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user = $prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    if ($uidcount==0) {
        $uidcount=((getpwnam($user))[2]);
    }
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_success('/usr/sbin/adduser', @quiet,
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

$prefix='u1a2';
foreach $userbase( @unames ) {
    $user = $prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    assert_group_exists($user);
    if ($uidcount==0) {
        $uidcount=((getpwnam($user))[2]);
    }
    if ($gidcount==0) {
        $gidcount=((getgrnam($user))[2]);
    }
    assert_primary_group_membership_exists($user, $user);
    assert_user_has_uid($user, $uidcount);
    assert_group_has_gid($user, $gidcount);
    $uidcount++;
    $gidcount++;
}
cleanup($prefix);

# test group U2A: default config, uid/gid range requested on command line

$prefix='u2a';
$firstuid1=2000;
$firstgid1=2100;
$fuid = 3750;
$fgid = 3761;
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
       '--firstgid', $firstgid1,
       $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_group_does_not_exist($prefix.$fgname);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--firstgid', $firstgid1,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1, 
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_success('/usr/sbin/adduser', @quiet,
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, 
    '--uid', $fuid,
   $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

$prefix='u2a2';
$firstuid1=2000;
$fuid = 3750;
$uidcount=$firstuid1;
foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1,
        $user);
    assert_user_exists($user);
    assert_group_exists($user);
    assert_primary_group_membership_exists($user, $user);
    assert_user_has_uid($user, $uidcount);
    assert_group_has_gid($user, $uidcount);
    $uidcount++;
}
cleanup($prefix);

# test group U3A: uid range requested by config, no command line

$prefix='u3a';
$firstuid1=2000;
$firstgid1=2100;
$fuid = 3750;
$fgid = 3761;
%confhash=();
$confhash{'FIRST_UID'}="$firstuid1";
$confhash{'FIRST_GID'}="$firstgid1";
apply_config_hash(\%confhash);

$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet, $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_success('/usr/sbin/adduser', @quiet,
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

$prefix='u3a2';
$firstuid1=2000;
$fuid = 3750;
$uidcount=$firstuid1;
foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    assert_group_exists($user);
    assert_primary_group_membership_exists($user, $user);
    assert_user_has_uid($user, $uidcount);
    assert_group_has_gid($user, $uidcount);
    $uidcount++;
}
cleanup($prefix);

# test group U4A: ranges requested by config, overriden by command line

$prefix='u4a';
$firstuid1=2200;
$firstgid1=2300;
$fuid = 3750;
$fgid = 3761;
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
      '--firstgid', $firstgid1,
      $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--firstgid', $firstgid1,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1, 
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_success('/usr/sbin/adduser', @quiet,
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, 
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

$prefix='u4a2';
$firstuid1=2000;
$fuid = 3750;
$uidcount=$firstuid1;
foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1,
        $user);
    assert_user_exists($user);
    assert_group_exists($user);
    assert_primary_group_membership_exists($user, $user);
    assert_user_has_uid($user, $uidcount);
    assert_group_has_gid($user, $uidcount);
    $uidcount++;
}
cleanup($prefix);

%confhash=();
apply_config_hash(\%confhash);

# test group S1A: default config, no command line

$prefix = 's1a';
$fuid = 200;
$fgid = 210;
%confhash=();
apply_config_hash(\%confhash);

foreach $groupbase( @gnames ) {
    $group = $prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet, '--system', $group);
    assert_group_exists($group);
    if ($gidcount==0) {
        $gidcount=((getgrnam($group))[2]);
    }
    assert_group_has_gid($group, $gidcount);
    while (defined(getgrgid($gidcount))) {
        $gidcount++;
    }
}
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--system',
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user = $prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    if ($uidcount==0) {
        $uidcount=((getpwnam($user))[2]);
    }
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    while (defined(getpwuid($uidcount))) {
        $uidcount++;
    }
}
assert_command_success('/usr/sbin/adduser', @quiet,
    '--system',
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

$prefix='s1a2';
foreach $userbase( @unames ) {
    $user = $prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    if ($uidcount==0) {
        $uidcount=((getpwnam($user))[2]);
    }
    assert_primary_group_membership_exists($user, 'nogroup');
    assert_user_has_uid($user, $uidcount);
    while (defined(getpwuid($uidcount))) {
        $uidcount++;
    }
}
cleanup($prefix);

# test group S2A: default config, uid/gid range requested on command line

$prefix='s2a';
$firstuid1=220;
$firstgid1=230;
$fuid = 950;
$fgid = 960;
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
       '--system',
       '--firstgid', $firstgid1,
       $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_group_does_not_exist($prefix.$fgname);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--system',
    '--firstgid', $firstgid1,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1, 
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_success('/usr/sbin/adduser', @quiet,
    '--system',
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, 
    '--uid', $fuid,
   $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

$prefix='s2a2';
$firstuid1=240;
$fuid = 250;
$uidcount=$firstuid1;
foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1,
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, 'nogroup');
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
cleanup($prefix);

# test group S3A: uid range requested by config, no command line

$prefix='s3a';
$firstuid1=260;
$firstgid1=270;
$fuid = 970;
$fgid = 980;
%confhash=();
$confhash{'FIRST_SYSTEM_UID'}="$firstuid1";
$confhash{'FIRST_SYSTEM_GID'}="$firstgid1";
apply_config_hash(\%confhash);

$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', '--system', @quiet, $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--system',
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_success('/usr/sbin/adduser', @quiet,
    '--system',
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

$prefix='s3a2';
$firstuid1=260;
$fuid = 970;
$uidcount=$firstuid1;
foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, 'nogroup');
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
cleanup($prefix);

# test group S4A: ranges requested by config, overriden by command line

$prefix='s4a';
$firstuid1=290;
$firstgid1=300;
$fuid = 810;
$fgid = 820;
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
      '--system',
      '--firstgid', $firstgid1,
      $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--system',
    '--firstgid', $firstgid1,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1, 
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_success('/usr/sbin/adduser', @quiet,
    '--system',
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, 
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

$prefix='s4a2';
$firstuid1=310;
$fuid = 830;
$uidcount=$firstuid1;
foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1,
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, 'nogroup');
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
cleanup($prefix);

%confhash=();
apply_config_hash(\%confhash);


# tests with last_ options: we set a range and fill it, last creation must fail

# test group U1L: not applicable
# test group U2L: default config, uid/gid range requested on command line

$prefix='u2l';
$firstuid1=2090;
$lastuid1=2093;
$firstgid1=2190;
$lastgid1=2193;
$fuid = 3750;
$fgid = 3761;
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
        '--firstgid', $firstgid1, '--lastgid', $lastgid1,
       $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_failure_silent('/usr/sbin/addgroup', @quiet,
        '--firstgid', $firstgid1, '--lastgid', $lastgid1,
       $prefix.$gnamex);
assert_group_does_not_exist($prefix.$gnamex);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--firstgid', $firstgid1, '--lastgid', $lastgid1,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1, '--lastuid', $lastuid1,
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_failure_silent('/usr/sbin/adduser', @quiet,
    '--ingroup', $prefix.$gnames[0],
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, '--lastuid', $lastuid1,
    $prefix.$unamex);
assert_user_does_not_exist($prefix.$unamex);
assert_command_success('/usr/sbin/adduser', @quiet,
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, '--lastuid', $lastuid1,
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

# test group U3L: uid range requested by config, no command line

$prefix='u3l';
$firstuid1=2090;
$lastuid1=2093;
$firstgid1=2190;
$lastgid1=2193;
$fuid = 3750;
$fgid = 3761;
%confhash=();
$confhash{'FIRST_UID'}="$firstuid1";
$confhash{'FIRST_GID'}="$firstgid1";
$confhash{'LAST_UID'}="$lastuid1";
$confhash{'LAST_GID'}="$lastgid1";
apply_config_hash(\%confhash);
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
       $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_failure_silent('/usr/sbin/addgroup', @quiet,
       $prefix.$gnamex);
assert_group_does_not_exist($prefix.$gnamex);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_failure_silent('/usr/sbin/adduser', @quiet,
    '--ingroup', $prefix.$gnames[0],
    '--comment', '""', '--disabled-password', '--no-create-home',
    $prefix.$unamex);
assert_user_does_not_exist($unamex);
assert_command_success('/usr/sbin/adduser', @quiet,
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

# test group U4L: ranges requested by config, overriden by command line

$prefix='u4l';
$firstuid1=2290;
$lastuid1=2293;
$firstgid1=2390;
$lastgid1=2393;
$fuid = 3750;
$fgid = 3761;
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
        '--firstgid', $firstgid1, '--lastgid', $lastgid1,
       $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_failure_silent('/usr/sbin/addgroup', @quiet,
        '--firstgid', $firstgid1, '--lastgid', $lastgid1,
       $prefix.$gnamex);
assert_group_does_not_exist($prefix.$gnamex);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--firstgid', $firstgid1, '--lastgid', $lastgid1,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1, '--lastuid', $lastuid1,
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_failure_silent('/usr/sbin/adduser', @quiet,
    '--ingroup', $prefix.$gnames[0],
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, '--lastuid', $lastuid1,
    $prefix.$unamex);
assert_user_does_not_exist($prefix.$unamex);
assert_command_success('/usr/sbin/adduser', @quiet,
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, '--lastuid', $lastuid1,
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

%confhash=();
apply_config_hash(\%confhash);

# test group S1L: not applicable
# test group S2L: default config, uid/gid range requested on command line

$prefix='s2l';
$firstuid1=400;
$lastuid1=403;
$firstgid1=500;
$lastgid1=503;
$fuid = 700;
$fgid = 750;
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
        '--system',
        '--firstgid', $firstgid1, '--lastgid', $lastgid1,
       $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_failure_silent('/usr/sbin/addgroup', @quiet,
        '--system',
        '--firstgid', $firstgid1, '--lastgid', $lastgid1,
       $prefix.$gnamex);
assert_group_does_not_exist($prefix.$gnamex);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--system',
    '--firstgid', $firstgid1, '--lastgid', $lastgid1,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1, '--lastuid', $lastuid1,
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_failure_silent('/usr/sbin/adduser', @quiet,
    '--system',
    '--ingroup', $prefix.$gnames[0],
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, '--lastuid', $lastuid1,
    $prefix.$unamex);
assert_user_does_not_exist($prefix.$unamex);
assert_command_success_silent('/usr/sbin/adduser', @quiet,
    '--system',
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, '--lastuid', $lastuid1,
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

# test group S3L: uid range requested by config, no command line

$prefix='s3l';
$firstuid1=410;
$lastuid1=413;
$firstgid1=510;
$lastgid1=513;
$fuid = 710;
$fgid = 760;
%confhash=();
$confhash{'FIRST_SYSTEM_UID'}="$firstuid1";
$confhash{'FIRST_SYSTEM_GID'}="$firstgid1";
$confhash{'LAST_SYSTEM_UID'}="$lastuid1";
$confhash{'LAST_SYSTEM_GID'}="$lastgid1";
apply_config_hash(\%confhash);
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
       '--system',
       $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_failure_silent('/usr/sbin/addgroup', @quiet,
       '--system',
       $prefix.$gnamex);
assert_group_does_not_exist($prefix.$gnamex);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--system',
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_failure_silent('/usr/sbin/adduser', @quiet,
    '--system',
    '--ingroup', $prefix.$gnames[0],
    '--comment', '""', '--disabled-password', '--no-create-home',
    $prefix.$unamex);
assert_user_does_not_exist($unamex);
assert_command_success_silent('/usr/sbin/adduser', @quiet,
    '--system',
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

# test group S4L: ranges requested by config, overriden by command line

$prefix='s4l';
$firstuid1=320;
$lastuid1=323;
$firstgid1=520;
$lastgid1=523;
$fuid = 720;
$fgid = 770;
$gidcount=$firstgid1;
$uidcount=$firstuid1;
foreach $groupbase( @gnames ) {
    $group=$prefix.$groupbase;
    assert_command_success('/usr/sbin/addgroup', @quiet,
        '--system',
        '--firstgid', $firstgid1, '--lastgid', $lastgid1,
       $group);
    assert_group_exists($group);
    assert_group_has_gid($group, $gidcount);
    $gidcount++;
}
assert_command_failure_silent('/usr/sbin/addgroup', @quiet,
        '--system',
        '--firstgid', $firstgid1, '--lastgid', $lastgid1,
       $prefix.$gnamex);
assert_group_does_not_exist($prefix.$gnamex);
assert_command_success('/usr/sbin/addgroup', @quiet,
    '--system',
    '--firstgid', $firstgid1, '--lastgid', $lastgid1,
    '--gid', $fgid,
    $prefix.$fgname);
assert_group_exists($prefix.$fgname);
assert_group_has_gid($prefix.$fgname, $fgid);

foreach $userbase( @unames ) {
    $user=$prefix.$userbase;
    assert_command_success('/usr/sbin/adduser', @quiet,
        '--system',
        '--ingroup', $prefix.$gnames[0],
        '--comment', '""', '--disabled-password', '--no-create-home',
        '--firstuid', $firstuid1, '--lastuid', $lastuid1,
        $user);
    assert_user_exists($user);
    assert_primary_group_membership_exists($user, $prefix.$gnames[0]);
    assert_user_has_uid($user, $uidcount);
    $uidcount++;
}
assert_command_failure_silent('/usr/sbin/adduser', @quiet,
    '--system',
    '--ingroup', $prefix.$gnames[0],
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, '--lastuid', $lastuid1,
    $prefix.$unamex);
assert_user_does_not_exist($prefix.$unamex);
assert_command_success_silent('/usr/sbin/adduser', @quiet,
    '--system',
    '--comment', '""', '--disabled-password', '--no-create-home',
    '--firstuid', $firstuid1, '--lastuid', $lastuid1,
    '--uid', $fuid,
    $prefix.$funame);
assert_user_exists($prefix.$funame);
assert_user_has_uid($prefix.$funame, $fuid);
cleanup($prefix);

%confhash=();
apply_config_hash(\%confhash);
cleanup();

# vim: tabstop=4 shiftwidth=4 expandtab
