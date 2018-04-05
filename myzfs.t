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

require "./myzfs.pl";

# duplicate getSnapshots() substituting test data
my $override = Sub::Override->new(
	getSnapshots =>sub {
		my $f = shift;

		if (defined $f) {
			return grep { $_ =~ /$f@/ } @snapshots;
		}
		return @snapshots;
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
ok(eq_array(\@tankTestSnaps, \@tankSnapshots), "match snapshot lists");


######################## testing script functionality #########################

# test filesystem filtering
my @foundFileSystems = sort(getFilesystems(@testSnaps));
my @expectedFilesystems = sort("tank", "tank/Archive");
ok(eq_array(\@foundFileSystems, \@expectedFilesystems), "find filesystems from list of snaps");

=begin GHOSTCODE
@foundFileSystems = getFilesystems(getSnapshots("tank"));
@expectedFilesystems = ("tank");
ok(eq_array(\@foundFileSystems, \@expectedFilesystems), "find filesystems from list of snaps");
=cut

@testSnaps = getSnapshots("tank");

my $deleteCount = 5;
my @snapsToDelete =  getDeleteSnaps(\@testSnaps, $deleteCount);
is(@snapsToDelete, $deleteCount, 'Match \'to delete\' element count with provided test data');

#TODO test command line argument processing
done_testing();
