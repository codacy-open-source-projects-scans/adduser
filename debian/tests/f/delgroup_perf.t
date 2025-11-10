#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=682156

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $startid = 22222;
my $size = 5000;
my $show = 50;
my $maxsecs = 120;
my $setup_secs = 240;
my $groupdel_secs = 60;
my ($secs, $isecs, $tsecs, $id);
my ($fp, $fs, $fg);

END {
}


# at the end of this, we will have 2*N groups, with N!+N memberships

open($fp, ">>", "/etc/passwd");
open($fs, ">>", "/etc/shadow");
open($fg, ">>", "/etc/group");

print "Creating users..\n";
$secs = time();
$tsecs = 0;
$id = $startid;
for (1..$size) {
    my $username = "dgpu_$_";
    $isecs = time();
    print $fp
        join(':', $username,'x', $id, $id, 'x', '/nonexistent', '/usr/sbin/nologin')."\n";
    print $fs
        join(':', $username, '!', $id, '','','','','')."\n";
    print $fg
        join(':', $username, 'x', $id, $username)."\n";

    $isecs = time() - $isecs;
    $tsecs += $isecs;
    $id++;
    print ".";
    print "($_) [ ".($tsecs / $_)."s avg ]\n" if ($_ % $show == 0);
}
$secs = (time() - $secs) || 1;
ok($secs < $setup_secs, "created $size users in $secs seconds (< $setup_secs).");

print "Creating/populating groups..\n";
$secs = time();
$tsecs = 0;
for (1..$size) {
    my $groupname = "dgpg_$_";
    $isecs = time();
    my $group_str = "";
    for (1..$_) {
        $group_str.="," if $group_str;
        $group_str.="dgpu_$_";
    }
    print $fg join(':', $groupname, 'x', $id, $group_str)."\n";
    $isecs = time() - $isecs;
    $tsecs += $isecs;
    $id++;
    print ".";
    print "($_) [ ".($tsecs / $_)."s avg ]\n" if ($_ % $show == 0);
}
$secs = (time() - $secs) || 1;
ok($secs < $setup_secs, "populated $size groups in $secs seconds (< $setup_secs).");

close($fp); close($fs); close($fg);

############ just for posterity; the "right" way is orders of magnitude too slow ##
#
# print "Creating users and groups..\n";
# $secs = time();
# $tsecs = 0;
# for (1..$size) {
#     my $username = "dgpu_$_";
#     my $groupname = "dgpg_$_";
#     $isecs = time();

#     ### ironically, our own tools are far too slow for this :)
#     #
#     # system('/usr/sbin/adduser',
#     #        '--stdoutmsglevel=error', '--stderrmsglevel=error',
#     #        '--comment="x"',
#     #        '--no-create-home',
#     #        '--disabled-password',
#     #        $username);
#     # system('/usr/sbin/addgroup',
#     #        '--stdoutmsglevel=error', '--stderrmsglevel=error',
#     #        $groupname);
#     # system('/usr/sbin/adduser',
#     #        '--stdoutmsglevel=error', '--stderrmsglevel=error',
#     #        "dgpu_$_",
#     #        $groupname)
#     #        for (1..$_);
#     # system("/usr/sbin/groupmod", "-a", "-U", "dgpu_$_", $groupname) for (1..$_);
#     #
#     ##### then again, so is useradd :D
#     system("/usr/sbin/groupadd", $groupname);
#     system("/usr/sbin/useradd", "-M", "-l", $username);
#     $isecs = time() - $isecs;
#     $tsecs += $isecs;
#     print ".";
#     print "($_) [ ".($tsecs / $_)."s avg ]\n" if ($_ % $show == 0);
# }
# $secs = (time() - $secs) || 1;
# ok($secs, "created $size users/groups in $secs seconds.");
#
# print "Populating groups..\n";
# $secs = time();
# $tsecs = 0;
# for (1..$size) {
#     $isecs = time();
#     my $group_str = "";
#     for (1..$_) {
#         $group_str.="," if $group_str;
#         $group_str.="dgpu_$_";
#     }
#     system("/usr/sbin/groupmod", "-U", $group_str, "dgpg_$_");
#     $isecs = time() - $isecs;
#     $tsecs += $isecs;
#     print ".";
#     print "($_) [ ".($tsecs / $_)."s avg ]\n" if ($_ % $show == 0);
# }
# $secs = (time() - $secs) || 1;
# ok($secs, "populated $size groups in $secs seconds.");

# these groups are wildly different sizes
my @groups = (3, int($size / 3), int($size * 2 / 3), $size - 2);

for (@groups) {
    $secs = time();
    my $groupname = "dgpg_$_";
    assert_command_success('/usr/sbin/delgroup',
        '--stdoutmsglevel=error', '--stderrmsglevel=error',
        $groupname);
    $secs = (time() - $secs) || 1;
    ok($secs < $groupdel_secs, "delgroup $groupname took ${secs}s (< $groupdel_secs).");
}

for (@groups) {
    $_ += 1;
    $secs = time();
    my $groupname = "dgpg_$_";
    assert_command_success('/usr/sbin/groupdel', $groupname);
    $secs = (time() - $secs) || 1;
    ok($secs < $groupdel_secs, "groupdel $groupname took ${secs}s (< $groupdel_secs).");
}

# vim: tabstop=4 shiftwidth=4 expandtab
