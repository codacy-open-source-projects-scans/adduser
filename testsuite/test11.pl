#!/usr/bin/perl -w


use strict;
use lib_test;

my $username = find_unused_name(); 
my $comment;
my $cmd;

sub testusercomment {
    my ($username, $comment, $fail_expected) = @_;
    $fail_expected ||= 0;
    $cmd = 'adduser --comment="'. $comment. '" --home=/nonexistent --disabled-password '. "$username";
    if (!defined (getpwnam($username))) {
        print "Testing $cmd... ";
        `$cmd`;
        my $error = ($?>>8);
        if( $fail_expected > 0 ) {
            assert(check_user_not_exist ($username));
        } else {
            if ($error) {
                print "failed\n  adduser returned an errorcode != 0 ($error)\n";
                exit $error;
            }
            assert(check_user_exist ($username));
            assert(check_user_comment ($username, $comment));
        }

    }

    $cmd = "deluser $username";
    if (defined (getpwnam($username))) {
        print "Testing $cmd... ";
        `$cmd`;
        my $error = ($?>>8);
        if ($error) {
            print "failed\n  adduser returned an errorcode != 0 ($error)\n";
            exit $error;
        }
        assert(check_user_not_exist ($username));
        print "ok\n";
    }
}

testusercomment($username, "Tom");
testusercomment($username, "Tom Omalley");
testusercomment($username, "Tom O\'Malley");
testusercomment($username, "Tom O\'Mälléy");
testusercomment($username, "Tomaß O\'Mälléy");
testusercomment($username, "Éom O\'Mälléy");
testusercomment($username, "Éoœm O\'Mälléy");
testusercomment($username, "Tom:Malley", 1);

# vim: tabstop=4 shiftwidth=4 expandtab

