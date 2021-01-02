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
========================== Test Data Prep ==========================
Naming headaches ...
The component "Test" indicates that the list is test data fed in via
substitute routines and/or used to test against returned lists. Test data
are hard coded and manipulated.

There are three variants for each 'test' data set of snapshots
 - A list of all snapshots including those that don't match the naming
   pattern of "<filesystem>@yyyy-mm-dd" identified "All"
 - A list of deletable snapshots that match "<filesystem>@yyyy-mm-dd"
   identified 'Deletable'.
 - A list of shapshots to delete, deletable minus the count of reserved
   snapshots identified 'ToDelete'
Variants have the tag postpended to 'TestSnap'.

The tests involve primarily two filesystems, tank/srv and tank/Archive
identified via 'srv' and 'archive'. Filesystems have the tag 'srv',
'archive' and 'all' prepended to the name.

Example: @srvTestSnapToDelete is the list of snapshots of the "tank/srv"
filesystem that meet criterial to delete. @allTestSnapAll is the list of
all snapshots including those for other filesystems such as "tank" and/or
not matching the "<filesystem>@yyyy-mm-dd" naming pattern

Lists returned form the various subroutines will follow the same naming
pattern except 'Test' will be elided form the name.

=cut

# predeclare all collections ...
# lists of all categorized snapshots
my @archiveTestSnapAll;
my @srvTestSnapAll;
my @allTestSnapAll;    # union of the previous two

# deletable snapshots
my @archiveTestSnapDeletable;
my @srvTestSnapDestroyable;
my @allTestSnapDeletable;    # union of the previous two

# snapshots to delete
my @archiveTestSnapToDelete;
my @srvTestSnapToDelete;
my @allTestSnapToDelete;     # union of the previous two

@archiveTestSnapAll = split /^/, $myzfs_data::archiveTestSnapAll;
chomp @archiveTestSnapAll;


@srvTestSnapAll = split /^/, $myzfs_data::srvTestSnapAll;
chomp @srvTestSnapAll;

push @allTestSnapAll, @archiveTestSnapAll, @srvTestSnapAll;

# Prepare deletable snaps by removing any
# that do not look like "<snapshot>@YYYY-MM-DD"
@archiveTestSnapDeletable = @archiveTestSnapAll;
splice @archiveTestSnapDeletable, 0, 1;
@srvTestSnapDestroyable = @srvTestSnapAll;
splice @srvTestSnapDestroyable, 21, 1;
push @allTestSnapDeletable, @archiveTestSnapDeletable, @srvTestSnapDestroyable;

# prepare 'to delete' lists from Deletable lists by removing the last
# RESERVE_COUNT entries
# TODO: test with RESERVE_COUNT equal to and greater than the list length.
use constant RESERVE_COUNT => 5;

@archiveTestSnapToDelete =
  @archiveTestSnapDeletable[ 0 .. $#archiveTestSnapDeletable -RESERVE_COUNT ];
@srvTestSnapToDelete =
  @srvTestSnapDestroyable[ 0 .. $#srvTestSnapDestroyable -RESERVE_COUNT ];
push @allTestSnapToDelete, @archiveTestSnapToDelete, @srvTestSnapToDelete;

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

# TODO: eliminate reuse of @dumpfiles
my @dumpfiles = split /^/, $myzfs_data::grandidier_dumpfiles;
chomp @dumpfiles;
my @archiveTestDumpsToDelete = @dumpfiles;
splice @archiveTestDumpsToDelete, 16;
splice @archiveTestDumpsToDelete, 10, 4;

#print "archiveTestDumpsToDelete\n", join("\n", @archiveTestDumpsToDelete), "\n\n";

my @srvTestDumpsToDelete = @dumpfiles;
splice @srvTestDumpsToDelete, 36;
splice @srvTestDumpsToDelete, 0, 16;

#print "srvTestDumpsToDelete\n", join("\n", @srvTestDumpsToDelete), "\n\n";

my @allTestDumpsToDelete;
push @allTestDumpsToDelete, @archiveTestDumpsToDelete, @srvTestDumpsToDelete;

use lib './lib';
use MyZFS qw(:all);

#================== Override Application Functions ==================

# override getSnapshots() substituting test data
my $overrideGet = Sub::Override->new(
    'MyZFS::getSnapshots' => sub {
        my $modName = shift;
        my $f       = shift;

        if ( defined $f ) {
            return grep { $_ =~ /$f@/ } @allTestSnapAll;
        }
        return @allTestSnapAll;
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
    eq_array( \@allSnapsAll, \@allTestSnapAll ),
    "verify expected returned snapshots"
);

# '~~' experimental feature ok(@testSnaps ~~ @allSnapshots, "verify expected returned snapshots");

# test fetch of snapshots for a particular file system 'tank'
my @srvSnapAll = MyZFS->getSnapshots("tank/srv");
ok( eq_array( \@srvSnapAll, \@srvTestSnapAll ), "match snapshot lists" );

#================== testing script functionality ==================

# test filesystem filtering for getFilesystems()
my @foundFileSystems = sort( MyZFS->getFilesystems(@allTestSnapAll) );
my @expectedFilesystems = sort( "tank", "tank/Archive", "tank/srv" );
ok( eq_array( \@foundFileSystems, \@expectedFilesystems ),
    "find filesystems from list of snaps" );

# test that getFilesystems() returns only one filesystem when
# there is only one
@foundFileSystems    = MyZFS->getFilesystems(@srvTestSnapDestroyable);
@expectedFilesystems = ("tank/srv");
ok( eq_array( \@foundFileSystems, \@expectedFilesystems ),
    "find single filesystem" );

# test filtering of destroyable snaps (one fs only)
my @srvSnapDeletable = MyZFS->getDestroyableSnaps(@srvTestSnapAll);
is( @srvSnapDeletable, @srvTestSnapDestroyable, "count of deletable snapshots" );
ok( eq_array( \@srvSnapDeletable, \@srvTestSnapDestroyable ),
    "content of deletable snapshots" );

# test filtering of destroyable snaps (multiple filesystems)
my @allSnapDeletable = MyZFS->getDestroyableSnaps(@allTestSnapAll);
is( @allSnapDeletable, @allTestSnapDeletable,
    "count of deletable snapshots, multiple fs" );
ok(
    eq_array( \@allSnapDeletable, \@allTestSnapDeletable ),
    "content of deletable snapshots, multiple fs"
);

# test identification of snaps to destroy, single fs
my @srvSnapToDestroy =
  sort ( MyZFS->getSnapsToDestroy( \@srvTestSnapDestroyable, RESERVE_COUNT ) );
is( @srvSnapToDestroy, @srvTestSnapToDelete, "count of snapshots to delete" );
ok( eq_array( \@srvSnapToDestroy, \@srvTestSnapToDelete ),
    "content of snaps to delete, single fs" );

# test count of snaps to destroy, single fs (only one snap to destroy)
@srvSnapToDestroy =
  MyZFS->getSnapsToDestroy( \@srvTestSnapDestroyable, scalar @srvTestSnapDestroyable -1 );
is( scalar @srvSnapToDestroy, 1, "count of snapshots to delete, reserve+1" );

# test count of snaps to destroy, single fs (none to destroy)
@srvSnapToDestroy =
  MyZFS->getSnapsToDestroy( \@srvTestSnapDestroyable, scalar @srvTestSnapDestroyable);
is( scalar @srvSnapToDestroy, 0, "count of snapshots to delete, reserve+1" );

# test identification of snaps to destroy, multiple fs
my @allSnapToDelete =
  sort ( MyZFS->getSnapsToDestroy( \@allTestSnapDeletable, RESERVE_COUNT ) );
is( @allSnapToDelete, @allTestSnapToDelete, "count of snapshots to delete" );
ok( eq_array( \@allSnapToDelete, \@allTestSnapToDelete ),
    "content of snaps to delete, single fs" );

is( MyZFS->destroySnapshots(@allTestSnapToDelete),
    @allTestSnapToDelete, "count snapshots destroyed" );

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

createTestDumps( TESTDIR, @dumpfiles );

# test identification of snapshot dumps to delete
my @archiveDumpsToDelete =
  MyZFS->findDeletableDumps( TESTDIR, \@archiveTestSnapToDelete );
is( @archiveDumpsToDelete, @archiveTestDumpsToDelete,
    "count of dumps to delete, single fs" );

# print "archiveDumpsToDelete\n", join("\n", @archiveDumpsToDelete), "\n\n";
@archiveTestDumpsToDelete = sort @archiveTestDumpsToDelete;
@archiveDumpsToDelete     = sort @archiveDumpsToDelete;
my @archiveTestDumpsToDeleteFullPath = map TESTDIR . $_,
  @archiveTestDumpsToDelete;
ok( eq_array( \@archiveDumpsToDelete, \@archiveTestDumpsToDeleteFullPath ),
    "content of dumps to delete, single fs" );

#print "archiveDumpsToDelete\n", join("\n", @archiveDumpsToDelete), "\n\n";
#print "archiveTestDumpsToDeleteFullPath\n", join("\n", @archiveTestDumpsToDeleteFullPath), "\n\n";

# Now check ID of files to delete for multiple filesystems
my @allDumpsToDelete =
  MyZFS->findDeletableDumps( TESTDIR, \@allTestSnapToDelete );
is( @allDumpsToDelete, @allTestDumpsToDelete,
    "count of dumps to delete, multiple fs" );
@allDumpsToDelete     = sort @allDumpsToDelete;
@allTestDumpsToDelete = sort @allTestDumpsToDelete;
my @allTestDumpsToDeleteFullPath = map TESTDIR . $_, @allTestDumpsToDelete;
ok( eq_array( \@allDumpsToDelete, \@allTestDumpsToDeleteFullPath ),
    "content of dumps to delete, multiple fs" );

#print "allDumpsToDelete\n", join("\n", @allDumpsToDelete), "\n\n";
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
@dumpfiles = split /^/, $myzfs_data::baobabb_dumpfiles;
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
  @rpoolTestSnapDeletable[ 0 .. $#rpoolTestSnapDeletable -RESERVE_COUNT ];
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
