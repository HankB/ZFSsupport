#!/usr/bin/perl

use strict;
use warnings;

use diagnostics;    # this gives you more debugging information
use Test::More;     # for the is() and isnt() functions

use lib './lib';
use MyZFS qw(:all);

# test command line argument processing

=pod
our $filesystem;
our $trial;
our $reserveCount;
our $dumpDirectory;
our $verbosity;
=cut

# first default values
@ARGV = ();
MyZFS->processArgs();
ok(
    !defined $MyZFS::filesystem
      && !defined $MyZFS::trial
      && $MyZFS::reserveCount == 5
      && $MyZFS::dumpDirectory eq "/snapshots/"
      && !defined $MyZFS::verbosity,
    "expected default values"
);

@ARGV = ( "-t", "-d", "./snapshots" );    # some modifications
MyZFS->processArgs();
ok(
    !defined $MyZFS::filesystem
      && defined $MyZFS::trial
      && $MyZFS::reserveCount == 5
      && $MyZFS::dumpDirectory eq "./snapshots"
      && !defined $MyZFS::verbosity,
    "expected -t and -d args"
);

@ARGV = ( "--reserved", "3", "--dir", "/localsnaps" );    # some modifications
MyZFS->processArgs();
ok(
    !defined $MyZFS::filesystem
      && !defined $MyZFS::trial
      && $MyZFS::reserveCount == 3
      && $MyZFS::dumpDirectory eq "/localsnaps"
      && !defined $MyZFS::verbosity,
    "expected --reserved and --dir args"
);

@ARGV = ( "-f", "rpool/var" );                            # some modifications
MyZFS->processArgs();
ok(
    $MyZFS::filesystem eq "rpool/var"
      && !defined $MyZFS::trial
      && $MyZFS::reserveCount == 5
      && $MyZFS::dumpDirectory eq "/snapshots/"
      && !defined $MyZFS::verbosity,
    "expected -f arg"
);

@ARGV = ( "-f", "rpool/var", "-v" );                            # some modifications
MyZFS->processArgs();
ok(
    $MyZFS::filesystem eq "rpool/var"
      && !defined $MyZFS::trial
      && $MyZFS::reserveCount == 5
      && $MyZFS::dumpDirectory eq "/snapshots/"
      && defined $MyZFS::verbosity,
    "expected -f arg -v"
);

@ARGV = ( "-f", "rpool/var", "-verbose" );                            # some modifications
MyZFS->processArgs();
ok(
    $MyZFS::filesystem eq "rpool/var"
      && !defined $MyZFS::trial
      && $MyZFS::reserveCount == 5
      && $MyZFS::dumpDirectory eq "/snapshots/"
      && defined $MyZFS::verbosity,
    "expected -f arg -verbose"
);

done_testing();
