#!/usr/bin/perl -w

# expect:
#  - a new system user $USER
#  - Second execution of command does not return an error.

use strict;
use lib_test;

my $username = find_unused_name("adduser07test");

my $cmd = "adduser --system $username";

if (!defined (getpwnam($username))) {
	print "Testing $cmd... ";
	`$cmd`;
	my $error = ($?>>8);
	if ($error) {
	  print "failed\n  adduser returned an errorcode != 0 ($error)\n";
	  exit $error;
	}
	`$cmd`;
	$error = ($?>>8);
	if ($error) {
          print "failed\n double execution with same parameters showed an error (return code $error)\n";
	  exit $error;
	}

	assert(check_user_exist ($username));
	assert(check_user_homedir_not_exist ($username));
	print "ok\n";
}

# vim: tabstop=4 shiftwidth=4 expandtab
