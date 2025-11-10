#! /usr/bin/perl -Idebian/tests/lib

# This test overrides the SYS_DIR_MODE configuration
# to force adduser to use the provided permissions mode
# instead.  Invalid modes are tested against the default
# (0755) (should this warn?  fail?)

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $user_prefix = "addusermodetest";
my @modes = ("750","2751","3333","55555","8888","wtF??");

my $user = $user_prefix . "default";
my $home = "/home/$user";
my $mode = "755";

assert_user_does_not_exist($user);
assert_path_does_not_exist($home);
apply_config();
assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password','--system',
    '--home', $home,
    $user);
assert_user_exists($user);
assert_path_exists($home);
assert_path_has_mode($home, $mode);

foreach (@modes) {
  $mode = $_;
  $user = $user_prefix . ($mode =~ s/[^a-z0-9]//gr);
  $home = "/home/$user";

  assert_user_does_not_exist($user);
  assert_path_does_not_exist($home);

  apply_config('SYS_DIR_MODE', $mode);
  assert_command_success('/usr/sbin/adduser',
    '--stdoutmsglevel=error', '--stderrmsglevel=error',
    '--disabled-password','--system',
    '--home', $home,
    $user);

  assert_user_exists($user);
  assert_path_exists($home);

  if (mode_is_valid($mode)) {
    assert_path_has_mode($home, $mode);
  } else {
    my $def_mode = "755";
    assert_path_has_mode($home, $def_mode, $mode);
  }
  remove_tree($home);
}

sub mode_is_valid {
  my $mode = shift;

  return defined($mode) && ($mode =~ /[0-7]{3}/ || $mode =~ /[0-7]{4}/);
}

# vim: tabstop=4 shiftwidth=4 expandtab
