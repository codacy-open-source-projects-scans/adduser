#! /usr/bin/perl -Idebian/tests/lib


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $name="ausbackup";

END {
    remove_tree("/var/mail/$name");
}

test_suffix('gz', 'gzip');
test_suffix('bz2', 'bzip2');
test_suffix('lzo', 'lzop');
test_suffix('xz', 'xz');
test_suffix('zst', 'zstd');

sub test_suffix {
    my ($suffix, $program) = @_;
    my ($archive, $file_list);

    assert_user_does_not_exist($name);
    assert_command_success(
        '/usr/sbin/adduser',
	    '--stdoutmsglevel=error', '--stderrmsglevel=error',
	    '--system',
	    '--home', "/home/$name",
	    $name
    );
    assert_user_exists($name);

    open (FH, '>', "/home/$name/test.txt");
    print FH 'created by adduser/backups.t';
    close (FH);

    assert_command_success_silent(
        '/usr/sbin/deluser',
	    '--stdoutmsglevel=error', '--stderrmsglevel=error',
	    '--remove-home',
	    '--backup-to', '/tmp',
	    '--backup-suffix', $suffix,
	    $name
    );
    assert_user_does_not_exist($name);

    $archive = "/tmp/$name.tar.".((&which($program, 1)) ? $suffix : 'gz');
    assert_path_exists($archive);
    assert_path_has_ownership($archive, 'root:root');
    assert_path_has_mode($archive, "0600");

    $file_list = `tar tf $archive 2>/dev/null`;
    ok($? == 0, "archive $archive ($suffix) listing successful");
    ok($file_list =~ qr{home/$name/test.txt}, 'archive contents are correct');

    unlink($archive);
}

# vim: tabstop=4 shiftwidth=4 expandtab
