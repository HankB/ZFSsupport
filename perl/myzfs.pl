#!/usr/bin/perl

# just call 'main()'

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename qw(dirname);

my $dir;
BEGIN {
  $dir = dirname($0);
}

use lib "./lib";          # lib path for unit testing
use lib "$dir/lib";       # lib path to faciliate integration testing
use MyZFS;

sub main {

    MyZFS->processArgs() or die "Usage: $0
		[-f|--filesystem filesystem (default=all)]
		[-h|--hostname hostname (required, no default)]
		[-t|--trial]
		[-r|--reserved reserve_count (default=5)]
		[-d|--directory dump_directory (default=\"/snapshots\")]
		[-v|--verbose]\n";

    # warn the user
    if ( $< != 0 ) {
        warn "warning: not running as root\n";
    }

    die "must specify hostname" unless defined $MyZFS::hostname;

    my @snapshots = MyZFS->getSnapshots($MyZFS::hostname, $MyZFS::filesystem);
    if ( defined $MyZFS::trial || defined $MyZFS::verbosity ) {
        print(
            "found ", scalar(@snapshots),
            " snapshots\n\t",
            join( "\n\t", @snapshots ), "\n"
        );
    }

    my @destroyableSnaps = MyZFS->getDestroyableSnaps(@snapshots);
    if ( defined $MyZFS::trial || defined $MyZFS::verbosity ) {
        print(
            "found ", scalar(@destroyableSnaps),
            " destroyable snapshots\n\t",
            join( "\n\t", @destroyableSnaps ), "\n"
        );
    }

    my @snapsToDestroy =
      MyZFS->getSnapsToDestroy( \@destroyableSnaps, $MyZFS::reserveCount );
    if ( defined $MyZFS::trial || defined $MyZFS::verbosity ) {
        print(
            "found ", scalar(@snapsToDestroy),
            " snapshots to destroy\n\t",
            join( "\n\t", @snapsToDestroy ), "\n"
        );
    }
    if(!defined $MyZFS::trial ) {
        MyZFS->destroySnapshots(@snapsToDestroy);
    }

    my @dumpsToDelete =
      MyZFS->findDeletableDumps( $MyZFS::dumpDirectory, \@snapsToDestroy );

    if ( defined $MyZFS::trial || defined $MyZFS::verbosity ) {
        print(
            "found ", scalar(@dumpsToDelete),
            " snapshot dumps to delete\n\t",
            join( "\n\t", @dumpsToDelete ), "\n"
        );
    }
    if(!defined $MyZFS::trial ) {
        MyZFS->deleteSnapshotDumps(@dumpsToDelete);
    }

}

main();

