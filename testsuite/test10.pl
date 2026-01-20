#!/usr/bin/perl -w

# there is a deluser.conf in the same directory as the tests
# that has SYS_DELETE_ACTION=lock so that we can choose the behavior

use strict;

use lib_test;

my $error;
my $output;

my $cmd;
my $username;
my $susername;
my $num;

$username = find_unused_name();
$num = 0;

assert(check_user_not_exist ($username));
# unlock a non-existing account
$cmd = "adduser --unlock $username";
++$num && print "Testing failing (10.$num) $cmd... ";
$output=`$cmd 2>&1`;
$error = ($?>>8);
if (!$error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_not_exist ($username));

# add the account
$cmd = "adduser --no-create-home --comment '' --disabled-password $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "locked", 1));
assert(check_user_status ($username, "not_haspasswd", 1));
assert(check_user_status ($username, "not_nologin", 1));
assert(check_user_status ($username, "not_expired", 1));

# unlock the account
$cmd = "adduser --unlock $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "locked", 1));
assert(check_user_status ($username, "not_haspasswd", 1));
assert(check_user_status ($username, "not_nologin", 1));
assert(check_user_status ($username, "not_expired", 1));

# lock the account
$cmd = "deluser --lock $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "locked", 1));
assert(check_user_status ($username, "not_haspasswd", 1));
assert(check_user_status ($username, "nologin", 1));
assert(check_user_status ($username, "expired", 1));

# unlock the account
$cmd = "adduser --unlock $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "locked", 1));
assert(check_user_status ($username, "not_haspasswd", 1));
assert(check_user_status ($username, "not_nologin", 1));
assert(check_user_status ($username, "not_expired", 1));

# set a password
$cmd = "usermod --password \$y\$j9T\$6KrIYfSdT/O2rBLrkyzcF/\$pMxfrOqQgNn/jlZZVjSs1ELUZjpFRyjZ5ahXKZ84115 $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "not_locked", 1));
assert(check_user_status ($username, "haspasswd", 1));
assert(check_user_status ($username, "not_nologin", 1));
assert(check_user_status ($username, "not_expired", 1));

# unlock the account
$cmd = "adduser --unlock $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "not_locked", 1));
assert(check_user_status ($username, "haspasswd", 1));
assert(check_user_status ($username, "not_nologin", 1));
assert(check_user_status ($username, "not_expired", 1));

# lock the account
$cmd = "deluser --lock $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "locked", 1));
assert(check_user_status ($username, "haspasswd", 1));
assert(check_user_status ($username, "nologin", 1));
assert(check_user_status ($username, "expired", 1));

# add the account (should fail)
$cmd = "adduser --no-create-home --comment '' --disabled-password $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing failing (10.$num) $cmd... ";
if (!$error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "locked", 1));
assert(check_user_status ($username, "haspasswd", 1));
assert(check_user_status ($username, "nologin", 1));
assert(check_user_status ($username, "expired", 1));

# unlock the account
$cmd = "adduser --unlock $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "not_locked", 1));
assert(check_user_status ($username, "haspasswd", 1));
assert(check_user_status ($username, "not_nologin", 1));
assert(check_user_status ($username, "not_expired", 1));

# deluser with SYS_DELETE_ACTION=lock
$cmd = "deluser --conf ./deluser-delete.conf $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "locked", 1));
assert(check_user_status ($username, "haspasswd", 1));
assert(check_user_status ($username, "nologin", 1));
assert(check_user_status ($username, "expired", 1));

# unlock the account
$cmd = "adduser --unlock $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_exist ($username));
assert(check_user_status ($username, "not_locked", 1));
assert(check_user_status ($username, "haspasswd", 1));
assert(check_user_status ($username, "not_nologin", 1));
assert(check_user_status ($username, "not_expired", 1));

# regular deluser
$cmd = "deluser $username";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok.\n";
assert(check_user_not_exist ($username));



#=======================
# system user
$susername = find_unused_name();

assert(check_user_not_exist ($susername));
# unlock a non-existing system ccount
$cmd = "adduser --unlock --system $susername";
++$num && print "Testing failing (10.$num) $cmd... ";
$output=`$cmd 2>&1`;
$error = ($?>>8);
if (!$error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
assert(check_user_not_exist ($susername));
print "ok\n";

# add system account
$cmd = "adduser --system $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "locked", 1));
assert(check_user_status ($susername, "not_haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "not_expired", 1));


# unlock the account
$cmd = "adduser --system --unlock $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing failing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "locked", 1));
assert(check_user_status ($susername, "not_haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "not_expired", 1));

# lock the account
$cmd = "deluser --system --lock $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "locked", 1));
assert(check_user_status ($susername, "not_haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "expired", 1));

# unlock the account
$cmd = "adduser --system --unlock $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "locked", 1));
assert(check_user_status ($susername, "not_haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "not_expired", 1));

# set a password
$cmd = "usermod --password \$y\$j9T\$6KrIYfSdT/O2rBLrkyzcF/\$pMxfrOqQgNn/jlZZVjSs1ELUZjpFRyjZ5ahXKZ84115 $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "not_locked", 1));
assert(check_user_status ($susername, "haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "not_expired", 1));

# unlock the account
$cmd = "adduser --system --unlock $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "not_locked", 1));
assert(check_user_status ($susername, "haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "not_expired", 1));

# lock the account
$cmd = "deluser --system --lock $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "locked", 1));
assert(check_user_status ($susername, "haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "expired", 1));

# re-enable via add (fails, already exists and has a password)
$cmd = "adduser --system $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if (!$error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "locked", 1));
assert(check_user_status ($susername, "haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "expired", 1));

# unlock the account
$cmd = "adduser --system --unlock $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "not_locked", 1));
assert(check_user_status ($susername, "haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "not_expired", 1));

# unlock already-unlocked
$cmd = "adduser --unlock $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "not_locked", 1));
assert(check_user_status ($susername, "haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "not_expired", 1));

# deluser with SYS_DELETE_ACTION=lock
$cmd = "deluser --conf ./deluser-delete.conf --system $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
assert(check_user_exist ($susername));
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "locked", 1));
assert(check_user_status ($susername, "haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "expired", 1));

# unlock the account
$cmd = "adduser --system --unlock $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_exist ($susername));
assert(check_user_status ($susername, "not_locked", 1));
assert(check_user_status ($susername, "haspasswd", 1));
assert(check_user_status ($susername, "nologin", 1));
assert(check_user_status ($susername, "not_expired", 1));

# regular deluser
$cmd = "deluser --system $susername";
$output=`$cmd 2>&1`;
$error = ($?>>8);
++$num && print "Testing (10.$num) $cmd... ";
if ($error) {
    print "failed\n  $cmd returned errorcode ($error)\n  $output\n";
    exit 1;
}
print "ok\n";
assert(check_user_not_exist ($susername));

# vim: tabstop=4 shiftwidth=4 expandtab
