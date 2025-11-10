#!/usr/bin/perl -w

# expect:
#  - a new non-system group $groupname
#  - reading the group fails
#  - reading the group as a system group fails
#  - a new system group $groupname
#  - reading the group succeeds
#  - reading the group as a non-system group fails

use strict;

use lib_test;

my $error;
my $output;
my $groupname = find_unused_name();
my $cmd = "addgroup $groupname";

if (!defined (getgrnam($groupname))) {
	print "Testing (9.1) $cmd... ";
	$output=`$cmd 2>&1`;
	$error = ($?>>8);
	if ($error) {
	  print "failed\n  $cmd returned an errorcode != 0 ($error)\n";
	  exit $error;
	}
	assert(check_group_exist ($groupname));

	print "ok\n";
}

# now testing whether adding the group again fails as it should

print "Testing (9.2) $cmd... ";
$output=`$cmd 2>&1`;
$error = ($?>>8);
if ($error ne 11) {
  print "failed\n  $cmd returned an errorcode != 11 ($error)\n";
  exit 1;
}
if ($output !~ /^fatal: The group `addusertest\d+' already exists\.\n$/ ) {
  print "failed\n  $cmd returned unexpected output ($output)\n";
  exit 1;
}
print "ok\n";

# now testing whether adding the group again (as a system group)
# fails as it should (#405905)

$cmd = "addgroup --system $groupname";
print "Testing (9.3) $cmd... ";
$output=`$cmd 2>&1`;
$error = ($?>>8);
if ($error ne 13) {
  print "failed\n  $cmd returned an errorcode != 13 ($error)\n";
  exit $error;
}
if ($output !~ /^err: The group `addusertest\d+' already exists and is not a system group. Exiting.$/ ) {
  print "failed\n  $cmd returned unexpected output ($output)\n";
  exit 1;
}
print "ok\n";

# now testing whether trying to delete the group with --remove-home
# fails as it should

$cmd = "delgroup --system --remove-home $groupname";
print "Testing (9.4) $cmd... ";
$output=`$cmd 2>&1`;
$error = ($?>>8);
if ($error ne 53) {
  print "failed\n  $cmd returned an errorcode != 53 ($error)\n";
  exit $error;
}
print "ok\n";

my $sysgroupname = find_unused_name();
$cmd = "addgroup --system $sysgroupname";

if (!defined (getgrnam($sysgroupname))) {
	print "Testing (9.5) $cmd... ";
	$output=`$cmd 2>&1`;
	$error = ($?>>8);
	if ($error) {
	  print "failed\n  $cmd returned an errorcode != 0 ($error)\n";
	  exit $error;
	}
	assert(check_group_exist ($sysgroupname));

	print "ok\n";
}

# now testing whether adding the group again passes as it should
# ("already exists as a system group")

$cmd = "addgroup --system $sysgroupname" ;
print "Testing (9.6) $cmd... ";
$output=`$cmd 2>&1`;
$error = ($?>>8);
if ($error) {
  print "failed\n  $cmd returned an errorcode != 0 ($error)\n";
  exit $error;
}
print "ok\n";

# now testing whether adding the group again (as a regular group)
# fails as it should

$cmd = "addgroup $sysgroupname";
print "Testing (9.7) $cmd... ";
$output=`$cmd 2>&1`;
$error = ($?>>8);
if ($error ne 11) {
  print "failed\n  $cmd returned an errorcode != 11 ($error)\n";
  exit 1;
}
if ($output !~ /^fatal: The group `addusertest\d+' already exists\.$/ ) {
  print "failed\n  $cmd returned unexpected output ($output)\n";
  exit 1;
}
print "ok\n";

