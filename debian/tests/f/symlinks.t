#! /usr/bin/perl -Idebian/tests/lib

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

assert_command_failure("dpkg --listfiles adduser | grep /usr/share/man | xargs -I{} find {} -xtype l -maxdepth 1 -print | grep -q '.'");

# vim: tabstop=4 shiftwidth=4 expandtab
