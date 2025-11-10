#!/usr/bin/perl -w

# expect:
#  - a new system user $USER
#  - added to group nogroup
#  - home directory /home/$USER
#  - removal works

use strict;
use lib_test;

my $file_find_present;

BEGIN {
    local $ENV{PERL_DL_NONLAZY}=1;
    $file_find_present=1;
    eval {
        require File::Find;
    };
    if ($@) {
        $file_find_present = 0;
    }
}

my $groupname = "nogroup";
my $username = find_unused_name();
my $homedir = "/home/$username";
my $cmd;

sub create_user {
    my ($username, $groupname, $system, $homedir) = (@_);
    my $cmd;
    if( $system ) {
        $cmd = "adduser --system --home $homedir $username";
    } else {
        $cmd = "adduser --disabled-password --comment foo --home $homedir $username";
    }

    if (!defined (getpwnam($username))) {
        print "Testing $cmd... ";
        `$cmd`;
        my $error = ($?>>8);
        if ($error) {
            print "failed\n  adduser returned an errorcode != 0 ($error)\n";
            exit $error;
        }
        assert(check_user_exist ($username));
        assert(check_homedir_exist($username, $homedir));
        if( $system ) {
            assert(check_group_exist($groupname));
            assert(check_user_in_group ($username,$groupname));
        } else {
            assert(check_group_exist($username));
            assert(check_user_in_group ($username,$username));
        }
        print "ok\n";
    }
}

create_user($username, $groupname, 1, $homedir);
# deluser without --remove-home _must_ always work
$cmd = "deluser $username";
if (defined (getpwnam($username))) {
    print "Testing $cmd... ";
    `$cmd`;
    my $error = ($?>>8);
    if ($error) {
        print "failed\n  deluser returned an errorcode != 0 ($error)\n";
        exit $error;
    }
    assert(check_user_not_exist ($username));
    assert(check_dir_exist($homedir));	
    `rm -rf $homedir`;
    print "ok\n";
}

create_user($username, $groupname, 0, $homedir);
# deluser without --remove-home _must_ always work
$cmd = "deluser $username";
if (defined (getpwnam($username))) {
    print "Testing $cmd... ";
    `$cmd`;
    my $error = ($?>>8);
    if ($error) {
        print "failed\n  deluser returned an errorcode != 0 ($error)\n";
        exit $error;
    }
    assert(check_user_not_exist ($username));
    assert(check_dir_exist($homedir));	
    `rm -rf $homedir`;
    print "ok\n";
}

create_user($username, $groupname, 1, $homedir);
# deluser --system with --remove-home may spew a warning but must exit successfully
$cmd = "deluser --system --remove-home $username";
if (defined (getpwnam($username))) {
    print "Testing $cmd... ";
    `$cmd`;
    my $error = ($?>>8);
    if ($error) {
        print "failed\n  deluser returned an errorcode != 0 ($error)\n";
        exit $error;
    }
    assert(check_user_not_exist ($username));
    if( $file_find_present ) {
        assert(check_homedir_not_exist($homedir));	
    } else {
        assert(check_dir_exist($homedir));	
        `rm -rf $homedir`;
    }
    print "ok\n";
}

create_user($username, $groupname, 0, $homedir);
# deluser with --remove-home may error out without File::Find
$cmd = "deluser --remove-home $username";
if (defined (getpwnam($username))) {
    print "Testing $cmd... ";
    `$cmd`;
    my $error = ($?>>8);
    if ($error) {
        if( $file_find_present ) {
            print "failed\n  deluser returned an errorcode != 0 ($error)\n";
            exit $error;
        } else {
            if( $error == 56 ) {
                `deluser $username`;
            } else {
                print "failed\n  deluser (file::find not present) returned an errorcode != 0/56 ($error)\n";
            }
            print "failed\n  deluser (file::find not present) returned an errorcode != 0 ($error)\n";
            $error=0;
            `rm -rf $homedir`;
        }
    }
    assert(check_user_not_exist ($username));
    assert(check_homedir_not_exist($homedir));	
    print "ok\n";
}

# vim: tabstop=4 shiftwidth=4 expandtab
