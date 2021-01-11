#!/usr/bin/perl

=pod
Test functionality of code that deals with shapshot dump files

=cut

use strict;
use warnings;

use diagnostics;    # this gives you more debugging information
use Test::More;     # for the is() and isnt() functions
# use Sub::Override;
use File::Touch;

use lib './lib';
use MyZFS qw(:all);

use lib './t';
use myzfs_data;

# test delete functionality
# first create some files to delete
sub createTestDumps(@) {
    my $dir = shift;
    mkdir $dir;
    foreach my $f (@_) {
        touch $dir . $f;
    }
}
use constant TESTDIR => "./snapshots/";


createTestDumps( TESTDIR, @myzfs_data::grandidier_dumpfiles );

# test identification of snapshot dumps to delete
my @archiveDumpsToDelete =
  sort MyZFS->findDeletableDumps( TESTDIR, \@myzfs_data::archiveTestSnapToDelete );
is( @archiveDumpsToDelete, @myzfs_data::archiveTestDumpsToDelete,
    "count of dumps to delete, single fs" );

# print "archiveDumpsToDelete\n", join("\n", @archiveDumpsToDelete), "\n\n";
@myzfs_data::archiveTestDumpsToDelete = sort @myzfs_data::archiveTestDumpsToDelete;
# @myzfs_data::archiveDumpsToDelete     = sort @myzfs_data::archiveDumpsToDelete;
my @archiveTestDumpsToDeleteFullPath = map TESTDIR . $_,
  @myzfs_data::archiveTestDumpsToDelete;
ok( eq_array( \@archiveDumpsToDelete, \@archiveTestDumpsToDeleteFullPath ),
    "content of dumps to delete, single fs" );

#print "archiveDumpsToDelete\n  ", join("\n  ", @archiveDumpsToDelete), "\n\n";
#print "archiveTestDumpsToDeleteFullPath\n  ", join("\n  ", @archiveTestDumpsToDeleteFullPath), "\n\n";

# Now check ID of files to delete for multiple filesystems
my @allDumpsToDelete =
  MyZFS->findDeletableDumps( TESTDIR, \@myzfs_data::allTestSnapToDelete );
is( @allDumpsToDelete, @myzfs_data::allTestDumpsToDelete,
    "count of dumps to delete, multiple fs" );
@allDumpsToDelete     = sort @allDumpsToDelete;
@myzfs_data::allTestDumpsToDelete = sort @myzfs_data::allTestDumpsToDelete;
my @allTestDumpsToDeleteFullPath = map TESTDIR . $_, @myzfs_data::allTestDumpsToDelete;
#print "allDumpsToDelete\n  ", join("\n  ", @allDumpsToDelete), "\n\n";
ok( eq_array( \@allDumpsToDelete, \@allTestDumpsToDeleteFullPath ),
    "content of dumps to delete, multiple fs" );

#print "allTestDumpsToDeleteFullPath\n", join("\n", @allTestDumpsToDeleteFullPath), "\n\n";
# TODO: implement and test something to delete dumps
# TODO: delete test directory

MyZFS->deleteSnapshotDumps(@allDumpsToDelete);
# was definition of $remainingTestSnapshotDumps
my @remainingTestSnapshotDumps = split /^/, $myzfs_data::remainingTestSnapshotDumps;
chomp @remainingTestSnapshotDumps;
@remainingTestSnapshotDumps = sort @remainingTestSnapshotDumps;
my @remainingTestSnapshotDumpsFullPath = map TESTDIR . $_,
  @remainingTestSnapshotDumps;

my @remainingSnapshotDumps = glob( TESTDIR . "*.snap.xz" );
@remainingSnapshotDumps = sort @remainingSnapshotDumps;
ok(
    eq_array( \@remainingSnapshotDumps, \@remainingTestSnapshotDumpsFullPath ),
    "undeleted files"
);

# Test to identify problem with dump files not being deleted
# issue #19

my @rpoolTestDumpsToDelete;
my @rpoolTestSnapToDelete;
# deletable snapshots
my @rpoolTestSnapDeletable;

# TODO: eliminate reuse of variable @dumpfiles
my @dumpfiles = split /^/, $myzfs_data::baobabb_dumpfiles;
chomp @dumpfiles;
@rpoolTestDumpsToDelete = @dumpfiles;
splice @rpoolTestDumpsToDelete, 7, 4;

# print "rpoolTestDumpsToDelete\n", join("\n", @rpoolTestDumpsToDelete), "\n\n";

createTestDumps( TESTDIR, @dumpfiles );

# hbarta@baobabb:~/Documents/ZFS/ZFSsupport/perl$ zfs list -t snap -H -o name
my @rpoolTestSnapAll = split /^/, $myzfs_data::rpoolTestSnapAll;
chomp @rpoolTestSnapAll;
@rpoolTestSnapDeletable = @rpoolTestSnapAll;
splice @rpoolTestSnapDeletable, 0, 1;
splice @rpoolTestSnapDeletable, 1;
# print "rpoolTestSnapDeletable\n", join("\n", @rpoolTestSnapDeletable), "\n\n";

@rpoolTestSnapToDelete =
  @rpoolTestSnapDeletable[ 0 .. $#rpoolTestSnapDeletable -myzfs_data::RESERVE_COUNT ];
# print "rpoolTestSnapToDelete\n", join("\n", @rpoolTestSnapToDelete), "\n\n";

# test count of snapshot dumps to delete
my @rpoolDumpsToDelete =
  MyZFS->findDeletableDumps( TESTDIR, \@rpoolTestSnapToDelete );
=pod
See issue #19 for why this test is commented out

is( @rpoolDumpsToDelete, @rpoolTestDumpsToDelete,
    "count of dumps to delete, single fs, issue #19" );
=cut

unlink glob TESTDIR . "*" || die "cannot delete files in " . TESTDIR;
rmdir TESTDIR || die "cannot 'rmdir' " . TESTDIR;

done_testing();
