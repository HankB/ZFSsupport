#!/usr/bin/perl

use strict;
use warnings;

use diagnostics; # this gives you more debugging information
use Test::More qw( no_plan ); # for the is() and isnt() functions
use Sub::Override;

# use Data::Dumper;


# results collected recently
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

require "./myzfs.pl" $isIncluded=1;

# duplicate with test data
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
my $returnedSnaps = join("\n", @testSnaps);
is(@testSnaps, @snapshots, 'Match element count with provided test data');
is($snapshots, $returnedSnaps, 'Match with provided test data');

# test fetch of snapshots for a particular file system
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

@testSnaps =  getSnapshots("tank");
$returnedSnaps = join("\n", @testSnaps);
@snapshots = split /^/, $tankSnapshots;
chomp @snapshots;

is(@testSnaps, @snapshots, 'Match filtered element count with provided test data');
is($tankSnapshots, $returnedSnaps, 'Match with provided test data');


######################## testing script functionality #########################

@testSnaps =  getSnapshots("tank");

my $deleteCount = 5;
my @snapsToDelete =  getDeleteSnaps(@testSnaps, $deleteCount);
is(@snapsToDelete, $deleteCount, 'Match filtered element count with provided test data');


