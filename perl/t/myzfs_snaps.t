#!/usr/bin/perl

use strict;
use warnings;

use diagnostics;    # this gives you more debugging information
use Test::More;     # for the is() and isnt() functions
use Test::Exception;
use Sub::Override;
use File::Touch;

use lib './t';
use myzfs_data;

# use Data::Dumper;

=pod
This was the original test script. As it grew and test needs expanded
it was split into the 4 following files:

* myzfs_snap.t - test pruning snapshots
* myzfs_dumps.t - test pruning dumps
* myzfs_args.t - test processing of command line arguments
* myzfs_data.pm - test data shared between test scripts

=cut

=pod
========================== Test Data Prep ==========================
Naming headaches ...
The component "Test" indicates that the list is test data fed in via
substitute routines and/or used to test against returned lists. Test data
are hard coded and manipulated. The lists of test snapshots are also
relevant WRT which host they come from. A client may have snapshots
recorded by tools such as `sanoid` and these should be left undisturbed.
If these extra snapshots get sent to the server, they will need to be 
managed manually. (It appears they get sent when a filesystem is) 

There are three variants for each 'test' data set of snapshots
 - A list of all snapshots including some that don't match the naming
   pattern of "<filesystem>@<hostname>.yyyy-mm-dd" identified "All"
 - A list of deletable snapshots that match 
   "<filesystem>@<hostname>.yyyy-mm-dd" identified 'Deletable'.
 - A list of shapshots to delete, deletable minus the count of reserved
   snapshots identified 'ToDelete'
Variants have the tag postpended to 'TestSnap'.

The tests involve primarily two filesystems, tank/srv and tank/Archive
identified via 'srv' and 'archive'. Filesystems have the tag 'srv',
'archive' and 'all' prepended to the name. (May no longer be true...)

A further identifier for data sets is to prepend the name of the host
on which they are collected.

Example: @srvTestSnapToDelete is the list of snapshots of the "tank/srv"
filesystem that meet criterial to delete. @allTestSnapAll is the list of
all snapshots including those for other filesystems such as "tank" and/or
not matching the "<filesystem>@yyyy-mm-dd" naming pattern

TODO: Revisit the above description of the naming scheme. It seems that 
"Sample" might better identify sample data than "Test" and it may be more
readable to separate tags with "-" character.

@olive_Sample_Snap_ToDelete

Lists returned form the various subroutines will follow the same naming
pattern except 'Test' will be elided form the name.

=cut



=pod
# the following print statements can be used to manually verify the
# various lists of test data.
print "archiveTestSnapAll\n", join("\n", @archiveTestSnapAll), "\n\n";
print "srvTestSnapAll\n", join("\n", @srvTestSnapAll), "\n\n";
print "allTestSnapAll\n", join("\n", @allTestSnapAll), "\n\n";

print "archiveTestSnapDeletable\n", join("\n", @archiveTestSnapDeletable), "\n\n";
print "srvTestSnapDestroyable\n", join("\n", @srvTestSnapDestroyable), "\n\n";
print "allTestSnapDeletable\n", join("\n", @allTestSnapDeletable), "\n\n";

print "archiveTestSnapToDelete\n", join("\n", @archiveTestSnapToDelete), "\n\n";
print "srvTestSnapToDelete\n", join("\n", @srvTestSnapToDelete), "\n\n";
print "allTestSnapToDelete\n", join("\n", @allTestSnapToDelete), "\n\n";
=cut

#print "archiveTestDumpsToDelete\n", join("\n", @archiveTestDumpsToDelete), "\n\n";

use lib './lib';
use MyZFS qw(:all);

# Verify that getSnapshots() will die if not provided a hostname
# before we replace with a mock

dies_ok { MyZFS->getSnapshots() } 'getSnapshots() dies with no hostname';
# But ... this only tests the mock.


#================== Override Application Functions ==================
my $snapshot_list_ref;

# Point to one or other snapshot list to be used by getSnapshots() override
sub setSnapshotList {
    $snapshot_list_ref = shift;
} 

# override getSnapshots() substituting test data
my $overrideGet = Sub::Override->new(
    'MyZFS::getSnapshots' => sub {
        my $modName = shift; # not used
        my $hostname = shift;
        my $f       = shift; 

        die "must provide hostname" unless defined $hostname;

        # filter by hostname
        my @hostsnaps = MyZFS::filterSnapsByHost($snapshot_list_ref, $hostname);

        # filter by filesystem?
        if ( defined $f ) {
            return grep { $_ =~ /^$f\@/ } @hostsnaps;
        }

        return filterSnapsByHost(\@hostsnaps, $hostname);
    }
);

# override destroySnapshots()
my $overrideDelete = Sub::Override->new(
    'MyZFS::destroySnapshots' => sub {
        my $modName      = shift;
        my $destroyCount = 0;

        foreach my $s (@_) {

            #print "asked to destroy ".$s."\n";
            $destroyCount++;
        }
        return $destroyCount;
    }
);

#====================================================================
#================== testing test support functions ==================
#====================================================================

# chiefly a mock for getSnapshots()

setSnapshotList(\@myzfs_data::baobabb_Sample_Snap_All);

# Verify that getSnapshots() will die ifd not provided a hostname

dies_ok { MyZFS->getSnapshots() } 'expecting to die with no hostname';
# But ... this only tests the mock.

# test fetch of all snapshots from `baobabb`
my @baobabb_Test_Snap_All = MyZFS->getSnapshots("baobabb");
# print "baobabb_Test_Snap_All\n  ", join("\n  ", @baobabb_Test_Snap_All), "\n\n";
# filter out just the ones created on `baobabb`
my @baobabbHostSubset = grep { $_ =~ /\@baobabb\./ } @myzfs_data::baobabb_Sample_Snap_All;
# print "baobabbHostSubset\n  ", join("\n  ", @baobabbHostSubset), "\n\n";
ok(
    eq_array( \@baobabb_Test_Snap_All, \@baobabbHostSubset ),
    "verify returned snapshots from MyZFS->getSnapshots(hostname)"
);

# Test specificity of hostname
my @baobabb_Test_Snap_None = MyZFS->getSnapshots("baobab"); # one character short
is( scalar @baobabb_Test_Snap_None, 0,
    "count of invalid host name (baobab), all filesystems" );
@baobabb_Test_Snap_None = MyZFS->getSnapshots("baobabbx"); # extra character
is( scalar @baobabb_Test_Snap_None, 0,
    "count of invalid host name (baobabbx), all filesystems" );

# Now repeat the test, specifying only one filesystem

# test fetch of all snapshots from `baobabb`
my @baobabb_Test_Snap_Archive = MyZFS->getSnapshots("baobabb", "rpool/srv/test/Archive");

# filter out just the ones created on `baobabb`
@baobabbHostSubset = grep { $_ =~ /\@baobabb\./ } @myzfs_data::baobabb_Sample_Snap_All;
# print "baobabbHostSubset\n  ", join("\n  ", @baobabbHostSubset), "\n\n";
# filter the filesystem of interest
@baobabbHostSubset = grep { $_ =~ /^rpool\/srv\/test\/Archive\@/ } @baobabbHostSubset;
# print "baobabbHostSubset\n  ", join("\n  ", @baobabbHostSubset), "\n\n";
ok(
    eq_array( \@baobabb_Test_Snap_Archive, \@baobabbHostSubset ),
    "verify returned snapshots from MyZFS->getSnapshots(hostname, filesystem)"
);


# '~~' experimental feature ok(@testSnaps ~~ @allSnapshots, "verify expected returned snapshots");

#================== testing script functionality ==================

# check some programming error conditions
dies_ok { MyZFS->getFilesystems() }
    'getFilesystems() dies with no snap list ref';
# dies_ok { MyZFS->getFilesystems(\@myzfs_data::baobabb_Sample_Snap_All) }
#    'getFilesystems() dies with no hostname';


# test filesystem filtering for getFilesystems()
# Note: GetFilesystems expects a list of snaps specific to a given host.
my @foundFileSystems = sort( MyZFS->getFilesystems(\@baobabb_Test_Snap_All) );
# print "foundFileSystems\n  ", join("\n  ", @foundFileSystems), "\n\n";
my @expectedFilesystems = 
    sort( "rpool/srv/test", "rpool/srv/test/Archive", "rpool/srv/test/Archive/olive" );
ok( eq_array( \@foundFileSystems, \@expectedFilesystems ),
    "find filesystems from list of snaps" );

# test for the other host that sends snapshots to `baobabb`
my @baobabb_Test_Snap_olive = MyZFS->getSnapshots("olive");
# print "baobabb_Test_Snap_olive\n  ", join("\n  ", @baobabb_Test_Snap_olive), "\n\n";
@foundFileSystems = sort( MyZFS->getFilesystems(\@baobabb_Test_Snap_olive) );
# print "foundFileSystems\n  ", join("\n  ", @foundFileSystems), "\n\n";
@expectedFilesystems = ("rpool/srv/test/Archive/olive");
ok( eq_array( \@foundFileSystems, \@expectedFilesystems ),
    "find filesystems from list of snaps" );

# test filtering of destroyable snaps (all filesystems)
my @candidateSnaps = MyZFS->getSnapshots("baobabb");
my @srvSnapDeletable = MyZFS->getDestroyableSnaps(@candidateSnaps);
#print "srvSnapDeletable\n  ", join("\n  ", @srvSnapDeletable), "\n\n";
#print "myzfs_data::baobabb_Sample_Snap_Deletable\n  ", join("\n  ", @myzfs_data::baobabb_Sample_Snap_Deletable), "\n\n";
is( @srvSnapDeletable, @myzfs_data::baobabb_Sample_Snap_Deletable,
    "count of deletable snapshots" );
ok( eq_array( \@srvSnapDeletable, \@myzfs_data::baobabb_Sample_Snap_Deletable),
    "content of deletable snapshots" );

# Same test, single filesystem
@candidateSnaps = MyZFS->getSnapshots("baobabb", "rpool/srv/test");
@srvSnapDeletable = MyZFS->getDestroyableSnaps(@candidateSnaps);
#print "srvSnapDeletable\n  ", join("\n  ", @srvSnapDeletable), "\n\n";
#print "myzfs_data::baobabb_rpool_srv_test_Sample_Snap_Deletable\n  ",
#    join("\n  ", @myzfs_data::baobabb_rpool_srv_test_Sample_Snap_Deletable), "\n\n";
is( @srvSnapDeletable,
    @myzfs_data::baobabb_rpool_srv_test_Sample_Snap_Deletable, "count of deletable snapshots" );
ok( eq_array( \@srvSnapDeletable,
    \@myzfs_data::baobabb_rpool_srv_test_Sample_Snap_Deletable),
    "content of deletable snapshots, single fs" );

my @srvSnapToDestroy =
  MyZFS->getSnapsToDestroy( \@myzfs_data::baobabb_rpool_srv_test_Sample_Snap_Deletable,
    scalar @myzfs_data::baobabb_rpool_srv_test_Sample_Snap_Deletable -1 );
is( scalar @srvSnapToDestroy, 1, "count of snapshots to delete, reserve+1" );

=pod
# test count of snaps to destroy, single fs (only one snap to destroy)
@srvSnapToDestroy =
  MyZFS->getSnapsToDestroy( \@myzfs_data::srvTestSnapDestroyable, scalar @myzfs_data::srvTestSnapDestroyable -1 );
is( scalar @srvSnapToDestroy, 1, "count of snapshots to delete, reserve+1" );

# test count of snaps to destroy, single fs (none to destroy)
@srvSnapToDestroy =
  MyZFS->getSnapsToDestroy( \@myzfs_data::srvTestSnapDestroyable, scalar @myzfs_data::srvTestSnapDestroyable);
is( scalar @srvSnapToDestroy, 0, "count of snapshots to delete, reserve+1" );

# test identification of snaps to destroy, multiple fs
my @allSnapToDelete =
  sort ( MyZFS->getSnapsToDestroy( \@myzfs_data::allTestSnapDeletable, myzfs_data::RESERVE_COUNT ) );
is( @allSnapToDelete, @myzfs_data::allTestSnapToDelete, "count of snapshots to delete" );
ok( eq_array( \@allSnapToDelete, \@myzfs_data::allTestSnapToDelete ),
    "content of snaps to delete, single fs" );

is( MyZFS->destroySnapshots(@myzfs_data::allTestSnapToDelete),
    @myzfs_data::allTestSnapToDelete, "count snapshots destroyed" );
=cut

done_testing();
