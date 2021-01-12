#!/usr/bin/perl

use strict;
use warnings;

use diagnostics;    # this gives you more debugging information
use Test::More;     # for the is() and isnt() functions
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

#================== Override Application Functions ==================

# override getSnapshots() substituting test data
my $overrideGet = Sub::Override->new(
    'MyZFS::getSnapshots' => sub {
        my $modName = shift;
        my $f       = shift;

        if ( defined $f ) {
            return grep { $_ =~ /$f@/ } @myzfs_data::allTestSnapAll;
        }
        return @myzfs_data::allTestSnapAll;
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

###### testing test support functions,  ######
#================== testing test support functions ==================
# chiefly a mock for getSnapshots()

# test fetch of all snapshots
my @allSnapsAll = MyZFS->getSnapshots();
ok(
    eq_array( \@allSnapsAll, \@myzfs_data::allTestSnapAll ),
    "verify expected returned snapshots"
);

# '~~' experimental feature ok(@testSnaps ~~ @allSnapshots, "verify expected returned snapshots");

# test fetch of snapshots for a particular file system 'tank'
my @srvSnapAll = MyZFS->getSnapshots("tank/srv");
ok( eq_array( \@srvSnapAll, \@myzfs_data::srvTestSnapAll ), "match snapshot lists" );

#================== testing script functionality ==================

# test filesystem filtering for getFilesystems()
my @foundFileSystems = sort( MyZFS->getFilesystems(@myzfs_data::allTestSnapAll) );
my @expectedFilesystems = sort( "tank", "tank/Archive", "tank/srv" );
ok( eq_array( \@foundFileSystems, \@expectedFilesystems ),
    "find filesystems from list of snaps" );

# test that getFilesystems() returns only one filesystem when
# there is only one
@foundFileSystems    = MyZFS->getFilesystems(@myzfs_data::srvTestSnapDestroyable);
@expectedFilesystems = ("tank/srv");
ok( eq_array( \@foundFileSystems, \@expectedFilesystems ),
    "find single filesystem" );

# test filtering of destroyable snaps (one fs only)
my @srvSnapDeletable = MyZFS->getDestroyableSnaps(@myzfs_data::srvTestSnapAll);
is( @srvSnapDeletable, @myzfs_data::srvTestSnapDestroyable, "count of deletable snapshots" );
ok( eq_array( \@srvSnapDeletable, \@myzfs_data::srvTestSnapDestroyable ),
    "content of deletable snapshots" );

# test filtering of destroyable snaps (multiple filesystems)
my @allSnapDeletable = MyZFS->getDestroyableSnaps(@myzfs_data::allTestSnapAll);
is( @allSnapDeletable, @myzfs_data::allTestSnapDeletable,
    "count of deletable snapshots, multiple fs" );
ok(
    eq_array( \@allSnapDeletable, \@myzfs_data::allTestSnapDeletable ),
    "content of deletable snapshots, multiple fs"
);

# test identification of snaps to destroy, single fs
my @srvSnapToDestroy =
  sort ( MyZFS->getSnapsToDestroy( \@myzfs_data::srvTestSnapDestroyable, myzfs_data::RESERVE_COUNT ) );
is( @srvSnapToDestroy, @myzfs_data::srvTestSnapToDelete, "count of snapshots to delete" );
ok( eq_array( \@srvSnapToDestroy, \@myzfs_data::srvTestSnapToDelete ),
    "content of snaps to delete, single fs" );

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


done_testing();
