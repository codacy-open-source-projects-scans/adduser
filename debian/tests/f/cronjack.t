#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=940577


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;


END {
    remove_tree('/hacked');
    remove_tree('/home/bob');
}

assert_command_success('sh', '-c', q{/usr/sbin/useradd --badname -d /home/bob -m 'bob;>/hacked' 2>/dev/null});

assert_path_does_not_exist('/hacked');

`/usr/sbin/deluser 'bob;>/hacked' >/dev/null 2>&1`;

assert_path_does_not_exist('/hacked');

# vim: tabstop=4 shiftwidth=4 expandtab
