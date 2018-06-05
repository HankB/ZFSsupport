#!/usr/bin/perl

# just call 'main()'

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

use lib './lib';
use MyZFS;

sub main {

    MyZFS->processArgs() or die "Usage: $0
		[-f|--filesystem filesystem (default=all)]
		[-t|--trial]
		[-r|--reserved reserve_count (default=5)]
		[-d|--directory dump_directory (default=\"/snapshots\")]
		[-v|--verbose\n";

    # warn the user
    if ( $< != 0 ) {
        warn "warning: not running as root\n";
    }

    my @snapshots = MyZFS->getSnapshots($MyZFS::filesystem);
    if ( defined $MyZFS::trial || defined $MyZFS::verbosity ) {
        print(
            "found ", scalar(@snapshots),
            " snapshots\n\t",
            join( "\n\t", @snapshots ), "\n"
        );
    }

    my @deletableSnaps = MyZFS->getDeletableSnaps(@snapshots);
    if ( defined $MyZFS::trial || defined $MyZFS::verbosity ) {
        print(
            "found ", scalar(@deletableSnaps),
            " destroyable snapshots\n\t",
            join( "\n\t", @deletableSnaps ), "\n"
        );
    }

    my @snapsToDelete =
      MyZFS->getSnapsToDelete( \@deletableSnaps, $MyZFS::reserveCount );
    if ( defined $MyZFS::trial || defined $MyZFS::verbosity ) {
        print(
            "found ", scalar(@snapsToDelete),
            " snapshots to destroy\n\t",
            join( "\n\t", @snapsToDelete ), "\n"
        );
    }
    if(!defined $MyZFS::trial ) {
        MyZFS->destroySnapshots(@snapsToDelete);
    }

    my @dumpsToDelete =
      MyZFS->findDeletableDumps( $MyZFS::dumpDirectory, \@snapsToDelete );

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

