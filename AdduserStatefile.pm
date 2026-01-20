package Debian::AdduserStatefile 3.139;
use 5.36.0;
use utf8;

# AdduserStatefile.pm: Manage persistent state for deleted user accounts
#
# This module provides a simple key-value store for tracking information
# about deleted user accounts. The state is stored in a text file at
# /var/lib/adduser/state in a format similar to /etc/passwd.
#
# File format: username:key1=value1:key2=value2:key3=value3
#
# Copyright (C) 2026 Marc Haber
#
# License: GPL-2+

use parent qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = (
    'set_state_value',
    'get_state_value',
    'get_state_user_data',
    'delete_state_user',
);

use strict;
use warnings;

our $STATE_DIR = '/var/lib/adduser';
our $STATE_FILE = "$STATE_DIR/state";
our $LOCK_FILE = "$STATE_DIR/state.lock";

# init_state_file()
#
# Initialize the state file and its parent directory if they don't exist.
# Creates /var/lib/adduser with mode 0755 and the state file with mode 0644.
# Dies on error.
sub init_state_file {
    # Create the directory if it doesn't exist
    unless (-d $STATE_DIR) {
        mkdir($STATE_DIR, 0755) or die "Cannot create $STATE_DIR: $!";
    }

    # Create the state file if it doesn't exist
    unless (-f $STATE_FILE) {
        open(my $fh, '>', $STATE_FILE) or die "Cannot create $STATE_FILE: $!";
        close($fh);
        chmod(0644, $STATE_FILE);
    }
}

# set_value($username, $key, $value)
#
# Set a key-value pair for the specified username in the state file.
# If the username doesn't exist, it will be created.
# If the key already exists for that user, it will be overwritten.
# If the value is empty or undefined, the key will be deleted instead.
#
# Parameters:
#   $username - The username to store data for
#   $key      - The key name (cannot contain '=', ':', or newlines)
#   $value    - The value to store (cannot contain ':' or newlines)
#               If empty or undef, the key is deleted
#
# Dies if the username, key, or value contain invalid characters.
sub set_state_value {
    my ($username, $key, $value) = @_;

    my $lock_fh = _acquire_lock();
    my %data = _read_state();

    $data{$username} ||= {};
    if (!defined $value || $value eq '') {
        delete $data{$username}{$key};
        if (keys %{$data{$username}} == 0) {
            delete $data{$username};
        }
    } else {
        die "Invalid value" if $value =~ /[:\n]/;
        $data{$username}{$key} = $value;
    }

    _write_state(\%data);
    _release_lock($lock_fh);
}

# get_value($username, $key)
#
# Retrieve a value for a given username and key (or all values if key is undef).
# This is a lock-free read operation. Due to atomic file replacement,
# readers will always see a consistent (though possibly slightly stale)
# version of the state file.
#
# Parameters:
#   $username - The username to look up
#   $key      - The key name to retrieve (optional)
#
# Returns:
#   If $key is provided: the value if found, undef otherwise
#   If $key is undef: a hash reference containing all key-value pairs for the user
sub get_state_value {
    my ($username, $key) = @_;

    # Return undef/empty hash if state file doesn't exist yet
    return undef unless -f $STATE_FILE;

    my %data = _read_state();

    # Return undef/empty hash if user doesn't exist
    if (!exists $data{$username}) {
        return defined $key ? undef : {};
    }

    # Return specific key or all data
    return defined $key ? $data{$username}{$key} : $data{$username};
}

# get_user_data($username)
#
# Retrieve all key-value pairs for a given username.
# This is a convenience wrapper around get_value($username, undef).
#
# Parameters:
#   $username - The username to look up
#
# Returns:
#   A hash reference containing all key-value pairs for the user,
#   or an empty hash reference if the user doesn't exist
sub get_state_user_data {
    my ($username) = @_;
    return get_value($username, undef);
}

# delete_user($username)
#
# Remove all data for a user from the state file.
# This completely removes the user's entry from the state file.
#
# Parameters:
#   $username - The username to delete
#
# Returns silently if the state file doesn't exist or the user isn't found.
sub delete_state_user {
    my ($username) = @_;

    # Nothing to do if state file doesn't exist
    return unless -f $STATE_FILE;

    # Acquire lock, read, modify, write, release lock
    my $lock_fh = _acquire_lock();
    my %data = _read_state();
    delete $data{$username};
    _write_state(\%data);
    _release_lock($lock_fh);
}

# _acquire_lock()
#
# Internal function to acquire an exclusive lock on the state file.
# Uses a separate lock file to avoid interfering with atomic renames.
#
# Returns:
#   File handle to the lock file (caller must pass to _release_lock)
#
# Dies if the lock file cannot be opened.
sub _acquire_lock {
    # Ensure the directory exists
    unless (-d $STATE_DIR) {
        mkdir($STATE_DIR, 0755) or die "Cannot create $STATE_DIR: $!";
    }

    # Open (or create) the lock file
    open(my $lock_fh, '>>', $LOCK_FILE) or die "Cannot open $LOCK_FILE: $!";

    # Acquire exclusive lock (blocks until available)
    flock($lock_fh, 2) or die "Cannot acquire lock on $LOCK_FILE: $!";  # LOCK_EX

    return $lock_fh;
}

# _release_lock($lock_fh)
#
# Internal function to release the lock and close the lock file.
#
# Parameters:
#   $lock_fh - File handle returned by _acquire_lock()
sub _release_lock {
    my ($lock_fh) = @_;

    # Closing the file handle releases the flock automatically
    close($lock_fh);
}

# _read_state()
#
# Internal function to read and parse the entire state file.
# For write operations, this MUST be called while holding the lock.
# For read-only operations, this can be called without a lock due to
# atomic file replacement via rename().
#
# File format: Each line contains:
#   username:key1=value1:key2=value2:...
#
# Empty lines and lines starting with '#' are ignored.
#
# Returns:
#   A hash where keys are usernames and values are hash references
#   containing the key-value pairs for that user
#
# Dies if the file cannot be opened.
sub _read_state {
    my %data;

    # Return empty hash if state file doesn't exist yet
    return %data unless -f $STATE_FILE;

    open(my $fh, '<', $STATE_FILE) or die "Cannot read $STATE_FILE: $!";

    while (my $line = <$fh>) {
        chomp $line;

        # Skip empty lines and comments
        next if $line =~ /^\s*$/;
        next if $line =~ /^\s*#/;

        # Split on colons - first field is username, rest are key=value pairs
        # Untaint the line by validating it matches our expected format
        next unless $line =~ /^([^:\n]+(?::[^:\n=]+=[^:\n]*)*?)$/;
        $line = $1;  # Now untainted
        my @fields = split(/:/, $line);
        next unless @fields >= 1;

        my $username = shift @fields;
        $data{$username} = {};

        # Parse each key=value pair
        foreach my $pair (@fields) {
            my ($key, $value) = split(/=/, $pair, 2);
            $data{$username}{$key} = $value if defined $key && defined $value;
        }
    }

    close($fh);

    return %data;
}

# _write_state(\%data)
#
# Internal function to write the entire state file atomically.
# MUST be called while holding the lock via _acquire_lock().
# Uses a temporary file and rename() to ensure atomicity.
#
# Parameters:
#   $data_ref - A hash reference in the format returned by _read_state()
#
# The output is sorted by username and by key within each username
# for consistent, diff-friendly output.
#
# Dies if the file cannot be written or renamed.
sub _write_state {
    my ($data_ref) = @_;

    # Use a process-specific temporary file name
    my $temp_file = "$STATE_FILE.tmp.$$";

    open(my $fh, '>', $temp_file) or die "Cannot write to $temp_file: $!";

    # Write each user's data, sorted for consistency
    foreach my $username (sort keys %$data_ref) {
        my @pairs;

        # Build key=value pairs, sorted by key
        foreach my $key (sort keys %{$data_ref->{$username}}) {
            my $value = $data_ref->{$username}{$key};
            push @pairs, "$key=$value";
        }

        # Write the line: username:key1=value1:key2=value2:...
        print $fh "$username:", join(':', @pairs), "\n";
    }

    close($fh);

    # Atomically replace the old state file with the new one
    # This happens while still holding the lock, so no race condition
    rename($temp_file, $STATE_FILE) or die "Cannot rename $temp_file: $!";
    chmod(0644, $STATE_FILE);
}

# Module must return true
1;
