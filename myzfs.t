#!/usr/bin/perl

use strict;
use warnings;

use diagnostics; # this gives you more debugging information
use Test::More;  # for the is() and isnt() functions
use Sub::Override;

# use Data::Dumper;


# results collected recently - all snapshots.
my $snapshots = 
'tank@initial
tank@2018-03-05
tank@2018-03-08
tank@2018-03-09
tank@2018-03-10
tank@2018-03-11
tank@2018-03-12
tank@2018-03-13
tank@2018-03-14
tank@2018-03-15
tank@2018-03-16
tank@2018-03-17
tank@2018-03-18
tank@2018-03-19
tank@2018-03-21
tank@2018-03-22
tank@2018-03-23
tank@2018-03-24
tank@2018-03-25
tank@2018-03-26
tank@2018-04-02
tank/Archive@initial
tank/Archive@2018-03-14
tank/Archive@2018-03-15
tank/Archive@2018-03-17
tank/Archive@2018-03-18
tank/Archive@2018-03-19
tank/Archive@2018-03-21
tank/Archive@2018-03-22
tank/Archive@2018-03-23
tank/Archive@2018-03-24
tank/Archive@2018-03-25
tank/Archive@2018-03-26';

my @snapshots = split /^/, $snapshots;
chomp @snapshots;
my @deletableSnapshots = @snapshots;
splice(@deletableSnapshots, 21, 1);
splice(@deletableSnapshots, 0, 1);
# print join("\n", @deletableSnapshots), "\n\n";

require "./myzfs.pl";

# override getSnapshots() substituting test data
my $overrideGet = Sub::Override->new(
	getSnapshots =>sub {
		my $f = shift;

		if (defined $f) {
			return grep { $_ =~ /$f@/ } @snapshots;
		}
		return @snapshots;
	}
);

# override destroySnapshots()
my $overrideDelete = Sub::Override->new(
	destroySnapshots =>sub (@) {
		my $destroyCount = 0;

		foreach my $s (@_) {
			#print "asked to destroy ".$s."\n";
			$destroyCount++;
		}
		return $destroyCount;
	}
);

###### testing test support functions, chiefly a mock for getSnapshots() ######

# test fetch of all snapshots
my @testSnaps =  getSnapshots();
ok(eq_array(\@testSnaps, \@snapshots), "verify expected returned snapshots");
# '~~' esperimental feature ok(@testSnaps ~~ @snapshots, "verify expected returned snapshots");

# test fetch of snapshots for a particular file system 'tank'
my $tankSnapshots = 
'tank@initial
tank@2018-03-05
tank@2018-03-08
tank@2018-03-09
tank@2018-03-10
tank@2018-03-11
tank@2018-03-12
tank@2018-03-13
tank@2018-03-14
tank@2018-03-15
tank@2018-03-16
tank@2018-03-17
tank@2018-03-18
tank@2018-03-19
tank@2018-03-21
tank@2018-03-22
tank@2018-03-23
tank@2018-03-24
tank@2018-03-25
tank@2018-03-26
tank@2018-04-02';

my @tankTestSnaps =  getSnapshots("tank");
my @tankSnapshots = split /^/, $tankSnapshots;
chomp @tankSnapshots;
my @deletableTestSnapshots = sort @tankSnapshots[1..$#tankSnapshots];

ok(eq_array(\@tankTestSnaps, \@tankSnapshots), "match snapshot lists");


######################## testing script functionality #########################

# test filesystem filtering for getFilesystems()
my @foundFileSystems = sort(getFilesystems(@testSnaps));
my @expectedFilesystems = sort("tank", "tank/Archive");
ok(eq_array(\@foundFileSystems, \@expectedFilesystems), "find filesystems from list of snaps");

# test that getSnapshots() returns only specified filesystem
@foundFileSystems = getFilesystems(@tankTestSnaps);
@expectedFilesystems = ("tank");
ok(eq_array(\@foundFileSystems, \@expectedFilesystems), "find specific filesystems");

# test filtering of deletable snaps (one fs only)
my @deletebleSnaps =  getDeletableSnaps(@tankTestSnaps);
is(@deletebleSnaps, @deletableTestSnapshots, "count of deletable snapshots");
ok(eq_array(\@deletebleSnaps, \@deletableTestSnapshots), "content of deletable snapshots");

# test filtering of deletable snaps (multiple filesystems)
@deletebleSnaps =  getDeletableSnaps(@testSnaps);
is(@deletebleSnaps, @deletableSnapshots, "count of deletable snapshots, multiple fs");
ok(eq_array(\@deletebleSnaps, \@deletableSnapshots), "content of deletable snapshots, multiple fs");

# test identification of snaps to delete, single fs
@deletebleSnaps =  getDeletableSnaps(@tankTestSnaps);
my @snapsToDelete = sort (getSnapsToDelete(\@deletebleSnaps, 5));
#print join("\n", @snapsToDelete), "\n\n";
my @tankTestSnapsToDelete = sort @tankSnapshots[1..$#tankSnapshots-5];
is(@snapsToDelete, @tankTestSnapsToDelete, "count of snapshots to delete");
ok(eq_array(\@snapsToDelete, \@tankTestSnapsToDelete), "content of snaps to delete, single fs");

# test identification of snaps to delete, multiple fs
my @multipleTestSnapsToDelete = ();
push(@multipleTestSnapsToDelete, @snapshots[22..27]);
push(@multipleTestSnapsToDelete, @tankTestSnapsToDelete);
@multipleTestSnapsToDelete = sort @multipleTestSnapsToDelete;
#print join("\n", @multipleTestSnapsToDelete), "\n\n";
@deletebleSnaps =  getDeletableSnaps(@testSnaps);
@snapsToDelete = sort (getSnapsToDelete(\@deletebleSnaps, 5));
is(@snapsToDelete, @multipleTestSnapsToDelete, "count of snapshots to delete, multiple fs");
#print join("\n", @snapsToDelete), "\n\n";
#print join("\n", @multipleTestSnapsToDelete), "\n\n";
ok(eq_array(\@snapsToDelete, \@multipleTestSnapsToDelete), "content of snaps to delete, multiple fs");

is(destroySnapshots(@snapsToDelete), @snapsToDelete, "count snapshots destroyed");

#TODO test command line argument processing
done_testing();
