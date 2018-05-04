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
		[-d|--directory dump_directory (default=\"/snapshots\")]\n";

    # TODO: fully implement all command line arguments

    # warn the user
    if ( $< != 0 ) {
        warn "warning: not running as root\n";
    }

    my @snapshots = MyZFS->getSnapshots($MyZFS::filesystem);
    if ( defined $MyZFS::trial ) {
        print(
            "found ", scalar(@snapshots),
            " snapshots\n\t",
            join( "\n\t", @snapshots ), "\n"
        );
    }

    my @deletableSnaps = MyZFS->getDeletableSnaps(@snapshots);
    if ( defined $MyZFS::trial ) {
        print(
            "found ", scalar(@deletableSnaps),
            " deletable snapshots\n\t",
            join( "\n\t", @deletableSnaps ), "\n"
        );
    }

    my @snapsToDelete =
      MyZFS->getSnapsToDelete( \@deletableSnaps, $MyZFS::reserveCount );
    if ( defined $MyZFS::trial ) {
        print(
            "found ", scalar(@snapsToDelete),
            " snapshots to destroy\n\t",
            join( "\n\t", @snapsToDelete ), "\n"
        );
    }
    else {
        MyZFS->destroySnapshots(@snapsToDelete);
    }

    my @dumpsToDelete =
      MyZFS->findDeletableDumps( $MyZFS::dumpDirectory, \@snapsToDelete );

    if ( defined $MyZFS::trial ) {
        print(
            "found ", scalar(@dumpsToDelete),
            " dumps to destroy\n\t",
            join( "\n\t", @dumpsToDelete ), "\n"
        );
    }
    else {
        MyZFS->deleteSnapshotDumps(@dumpsToDelete);
    }

}

main();

