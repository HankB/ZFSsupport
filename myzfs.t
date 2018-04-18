#!/usr/bin/perl

use strict;
use warnings;

use diagnostics;    # this gives you more debugging information
use Test::More;     # for the is() and isnt() functions
use Sub::Override;
use File::Touch;

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
my @srvTestSnapDeletable;
my @allTestSnapDeletable;    # union of the previous two

# snapshots to delete
my @archiveTestSnapToDelete;
my @srvTestSnapToDelete;
my @allTestSnapToDelete;     # union of the previous two

# results collected recently - all snapshots presently on grandidier.
# `zfs list -t snap -H -o name`
my $archiveTestSnapAll = 'tank@initial
tank/Archive@2018-03-15
tank/Archive@2018-03-20
tank/Archive@2018-03-22
tank/Archive@2018-03-23
tank/Archive@2018-03-24
tank/Archive@2018-03-25
tank/Archive@2018-03-26
tank/Archive@2018-03-27
tank/Archive@2018-03-28
tank/Archive@2018-03-29
tank/Archive@2018-04-01
tank/Archive@2018-04-07
tank/Archive@2018-04-08
tank/Archive@2018-04-09
tank/Archive@2018-04-10
tank/Archive@2018-04-11
';
@archiveTestSnapAll = split /^/, $archiveTestSnapAll;
chomp @archiveTestSnapAll;

my $srvTestSnapAll = 'tank/srv@2018-01-09
tank/srv@2018-01-14
tank/srv@2018-01-17
tank/srv@2018-01-19
tank/srv@2018-01-30
tank/srv@2018-02-12
tank/srv@2018-02-13
tank/srv@2018-02-14
tank/srv@2018-02-16
tank/srv@2018-02-17
tank/srv@2018-02-18
tank/srv@2018-02-19
tank/srv@2018-02-20
tank/srv@2018-02-21
tank/srv@2018-02-22
tank/srv@2018-02-23
tank/srv@2018-02-24
tank/srv@2018-02-25
tank/srv@2018-02-26
tank/srv@2018-02-27
tank/srv@2018-02-28
tank/srv@test
tank/srv@2018-03-03
tank/srv@2018-03-04
tank/srv@2018-03-05
tank/srv@2018-03-06
tank/srv@2018-03-07
tank/srv@2018-03-08
tank/srv@2018-03-11
tank/srv@2018-03-12
tank/srv@2018-03-13
tank/srv@2018-03-14
tank/srv@2018-03-15
tank/srv@2018-03-16
tank/srv@2018-03-17
tank/srv@2018-03-18
tank/srv@2018-03-19
tank/srv@2018-03-20
tank/srv@2018-03-21
tank/srv@2018-03-22
tank/srv@2018-03-23
tank/srv@2018-03-24
tank/srv@2018-03-25
tank/srv@2018-03-26
tank/srv@2018-03-27
tank/srv@2018-03-28
tank/srv@2018-03-29
tank/srv@2018-03-30
tank/srv@2018-03-31
tank/srv@2018-04-01
tank/srv@2018-04-02
tank/srv@2018-04-03
tank/srv@2018-04-04
tank/srv@2018-04-05
tank/srv@2018-04-06
tank/srv@2018-04-07
tank/srv@2018-04-08
tank/srv@2018-04-09
tank/srv@2018-04-10
tank/srv@2018-04-11
';
@srvTestSnapAll = split /^/, $srvTestSnapAll;
chomp @srvTestSnapAll;

push @allTestSnapAll, @archiveTestSnapAll, @srvTestSnapAll;

# Prepare deletable snaps by removing any
# that do not look like "<snapshot>@YYYY-MM-DD"
@archiveTestSnapDeletable = @archiveTestSnapAll;
splice @archiveTestSnapDeletable, 0, 1;
@srvTestSnapDeletable = @srvTestSnapAll;
splice @srvTestSnapDeletable, 21, 1;
push @allTestSnapDeletable, @archiveTestSnapDeletable, @srvTestSnapDeletable;

# prepare 'to delete' lists from Deletable lists by removing the last
# RESERVE_COUNT entries
# TODO: test with RESERVE_COUNT equal to and treater than the list length.
use constant RESERVE_COUNT => 5;

@archiveTestSnapToDelete =
  @archiveTestSnapDeletable[ 0 .. $#archiveTestSnapDeletable -RESERVE_COUNT ];
@srvTestSnapToDelete =
  @srvTestSnapDeletable[ 0 .. $#srvTestSnapDeletable -RESERVE_COUNT ];
push @allTestSnapToDelete, @archiveTestSnapToDelete, @srvTestSnapToDelete;

=pod
# the following print statements can be used to manually verify the
# various lists of test data.
print "archiveTestSnapAll\n", join("\n", @archiveTestSnapAll), "\n\n";
print "srvTestSnapAll\n", join("\n", @srvTestSnapAll), "\n\n";
print "allTestSnapAll\n", join("\n", @allTestSnapAll), "\n\n";

print "archiveTestSnapDeletable\n", join("\n", @archiveTestSnapDeletable), "\n\n";
print "srvTestSnapDeletable\n", join("\n", @srvTestSnapDeletable), "\n\n";
print "allTestSnapDeletable\n", join("\n", @allTestSnapDeletable), "\n\n";

print "archiveTestSnapToDelete\n", join("\n", @archiveTestSnapToDelete), "\n\n";
print "srvTestSnapToDelete\n", join("\n", @srvTestSnapToDelete), "\n\n";
print "allTestSnapToDelete\n", join("\n", @allTestSnapToDelete), "\n\n";
=cut

# all snapshot dumps presently on grandidier
# ls -1 /snapshots
my $dumpfiles = 'tank-Archive@2018-03-15-tank-archive@2018-03-20.snap.xz
tank-Archive@2018-03-20-tank-Archive@2018-03-22.snap.xz
tank-Archive@2018-03-22-tank-Archive@2018-03-23.snap.xz
tank-Archive@2018-03-23-tank-Archive@2018-03-24.snap.xz
tank-Archive@2018-03-24-tank-Archive@2018-03-25.snap.xz
tank-Archive@2018-03-25-tank-Archive@2018-03-26.snap.xz
tank-Archive@2018-03-26-tank-Archive@2018-03-27.snap.xz
tank-Archive@2018-03-27-tank-Archive@2018-03-28.snap.xz
tank-Archive@2018-03-28-tank-Archive@2018-03-29.snap.xz
tank-Archive@2018-04-01-tank-Archive@2018-04-07.snap.xz
tank-Archive@2018-04-07-tank-Archive@2018-04-08.snap.xz
tank-Archive@2018-04-08-tank-Archive@2018-04-09.snap.xz
tank-Archive@2018-04-09-tank-Archive@2018-04-10.snap.xz
tank-Archive@2018-04-10-tank-Archive@2018-04-11.snap.xz
tank-Archive@initial-tank-Archive@2018-03-29.snap.xz
tank-Archive@-tank-Archive@2018-03-29.snap.xz
tank-srv@2018-03-18-tank-srv@2018-03-19.snap.xz
tank-srv@2018-03-19-tank-srv@2018-03-20.snap.xz
tank-srv@2018-03-20-tank-srv@2018-03-21.snap.xz
tank-srv@2018-03-21-tank-srv@2018-03-22.snap.xz
tank-srv@2018-03-22-tank-srv@2018-03-23.snap.xz
tank-srv@2018-03-23-tank-srv@2018-03-24.snap.xz
tank-srv@2018-03-24-tank-srv@2018-03-25.snap.xz
tank-srv@2018-03-25-tank-srv@2018-03-26.snap.xz
tank-srv@2018-03-26-tank-srv@2018-03-27.snap.xz
tank-srv@2018-03-27-tank-srv@2018-03-28.snap.xz
tank-srv@2018-03-28-tank-srv@2018-03-29.snap.xz
tank-srv@2018-03-29-tank-srv@2018-03-30.snap.xz
tank-srv@2018-03-30-tank-srv@2018-03-31.snap.xz
tank-srv@2018-03-31-tank-srv@2018-04-01.snap.xz
tank-srv@2018-04-01-tank-srv@2018-04-02.snap.xz
tank-srv@2018-04-02-tank-srv@2018-04-03.snap.xz
tank-srv@2018-04-03-tank-srv@2018-04-04.snap.xz
tank-srv@2018-04-04-tank-srv@2018-04-05.snap.xz
tank-srv@2018-04-05-tank-srv@2018-04-06.snap.xz
tank-srv@2018-04-06-tank-srv@2018-04-07.snap.xz
tank-srv@2018-04-07-tank-srv@2018-04-08.snap.xz
tank-srv@2018-04-08-tank-srv@2018-04-09.snap.xz
tank-srv@2018-04-09-tank-srv@2018-04-10.snap.xz
tank-srv@2018-04-10-tank-srv@2018-04-11.snap.xz';
my @dumpfiles = split /^/, $dumpfiles;
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

use lib '.';
use MyZFS;

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
        my $modName = shift;
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
@foundFileSystems    = MyZFS->getFilesystems(@srvTestSnapDeletable);
@expectedFilesystems = ("tank/srv");
ok( eq_array( \@foundFileSystems, \@expectedFilesystems ),
    "find single filesystem" );

# test filtering of deletable snaps (one fs only)
my @srvSnapDeletable = MyZFS->getDeletableSnaps(@srvTestSnapAll);
is( @srvSnapDeletable, @srvTestSnapDeletable, "count of deletable snapshots" );
ok( eq_array( \@srvSnapDeletable, \@srvTestSnapDeletable ),
    "content of deletable snapshots" );

# test filtering of deletable snaps (multiple filesystems)
my @allSnapDeletable = MyZFS->getDeletableSnaps(@allTestSnapAll);
is( @allSnapDeletable, @allTestSnapDeletable,
    "count of deletable snapshots, multiple fs" );
ok(
    eq_array( \@allSnapDeletable, \@allTestSnapDeletable ),
    "content of deletable snapshots, multiple fs"
);

# test identification of snaps to delete, single fs
my @srvSnapToDelete =
  sort ( MyZFS->getSnapsToDelete( \@srvTestSnapDeletable, RESERVE_COUNT ) );
is( @srvSnapToDelete, @srvTestSnapToDelete, "count of snapshots to delete" );
ok( eq_array( \@srvSnapToDelete, \@srvTestSnapToDelete ),
    "content of snaps to delete, single fs" );

# test identification of snaps to delete, multiple fs
my @allSnapToDelete =
  sort ( MyZFS->getSnapsToDelete( \@allTestSnapDeletable, RESERVE_COUNT ) );
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
my @allDumpsToDelete = MyZFS->findDeletableDumps( TESTDIR, \@allTestSnapToDelete );
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
my $remainingTestSnapshotDumps =
  'tank-Archive@2018-04-07-tank-Archive@2018-04-08.snap.xz
tank-Archive@2018-04-08-tank-Archive@2018-04-09.snap.xz
tank-Archive@2018-04-09-tank-Archive@2018-04-10.snap.xz
tank-Archive@2018-04-10-tank-Archive@2018-04-11.snap.xz
tank-srv@2018-04-07-tank-srv@2018-04-08.snap.xz
tank-srv@2018-04-08-tank-srv@2018-04-09.snap.xz
tank-srv@2018-04-09-tank-srv@2018-04-10.snap.xz
tank-srv@2018-04-10-tank-srv@2018-04-11.snap.xz
';
my @remainingTestSnapshotDumps = split /^/, $remainingTestSnapshotDumps;
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

unlink glob TESTDIR."*" || die "cannot delete files in ".TESTDIR;
rmdir TESTDIR || die "cannot 'rmdir' ".TESTDIR;

# test command line argument processing
=pod
our $filesystem;
our $trial;
our $reserveCount;
our $dumpDirectory;
=cut

# first default values
MyZFS->processArgs();
ok(
    !defined $MyZFS::filesystem
      && !defined $MyZFS::trial
      && $MyZFS::reserveCount == 5
      && $MyZFS::dumpDirectory eq "/snapshots",
    "expected default values"
);

@ARGV = ( "-t", "-d", "./snapshots" );    # some modifications
MyZFS->processArgs();
ok(
    !defined $MyZFS::filesystem
      && defined $MyZFS::trial
      && $MyZFS::reserveCount == 5
      && $MyZFS::dumpDirectory eq "./snapshots",
    "expected -t and -d args"
);

@ARGV = ( "--reserved", "3", "--dir", "/localsnaps" );    # some modifications
MyZFS->processArgs();
ok(
    !defined $MyZFS::filesystem
      && !defined $MyZFS::trial
      && $MyZFS::reserveCount == 3
      && $MyZFS::dumpDirectory eq "/localsnaps",
    "expected --reserved and --dir args"
);

@ARGV = ( "-f", "rpool/var" );                            # some modifications
MyZFS->processArgs();
ok(
    $MyZFS::filesystem eq "rpool/var"
      && !defined $MyZFS::trial
      && $MyZFS::reserveCount == 5
      && $MyZFS::dumpDirectory eq "/snapshots",
    "expected -f arg"
);

done_testing();
