#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(GetOptions);


# fetch a list of snapshots, perhaps limited to a particular filesystem
sub getSnapshots {
	my $f = shift;
	my $cmd = "zfs list -t snap -H -o name";
	if (defined($f)) {
		$cmd = $cmd . " -r $f -d 1";
	}
	my @snapshots = `$cmd`;
	#print scalar @snapshots. " snapshots\n";
	chomp @snapshots;
	return @snapshots;
}

# identify unique filesystems in list of snapshot list.
sub getFilesystems(@) {
	my %f;
	foreach my $s (@_) {
		$s =~ /(.*)@/;	# isolate the filesystem name
		$f{$1}++;		# count it (to create hash entry)
	}
	#$my @candidates = grep { $_ =~ /(.*)@/ } @_;
	my @f = keys %f;
	return @f;
	#return \@(keys %f);
}

# identify snapshots that meet criteria for deletion
# Remove any that do not match the pattern "<filesystem>@YYYY-MM-DD" as produced
# by update-snapshot.sh
sub getDeletableSnaps(@) {
	my @candidates = grep { $_ =~ /@[1-2][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]/ } @_;
	return @candidates;
}

# Identify snapshots to delete.
# e.g. all except the last 'n' for each filesystem
# Use the list returned by getDeletableSnaps(@)
sub getSnapsToDelete(\@$) {
    my $snaps = shift
		|| die "must call getSnapsToDelete() with snapshot list and residual count";
    my $residual = shift
		|| die "must call getSnapsToDelete() with snapshot list and residual count";
	# identify filesystems
	my @filesystems = getFilesystems(@{$snaps});
	my @deletelist = ();
	# add files to delete for each filesystem
	foreach my $fs (@filesystems) {
		my @candidates = (sort(grep { $_ =~ /^$fs@/ } @{$snaps}));
		push @deletelist, @candidates[0..$#candidates-$residual]
			if $#candidates > $residual;
	}
	return @deletelist;
}

# destroy the list of snapshots
sub destroySnapshots(@) {
	my $cmd = "zfs destroy -v ";
	my $destroyCount = 0;
	foreach my $s (@_) {
		my $result = `$cmd.$s`;
		$destroyCount++;
		# TODO - check result for success
	}
	return $destroyCount;
}

# identify dumps in /snapshots - files match "*.snap.xz"
# first argument is directory to search for dumps
# second arg is a reference to a list of snaps to delete
sub findDeletableDumps($\@) {
	my $dir = shift;
	my $snaps = shift;
	my @filesToDelete = ();
	# print "\n\n", join("\nsnap ", @{$snaps}), "\n";
	my @files = glob( "$dir"."*.snap.xz" );
	# print "\n\n", join("\nfile ", @files), "\n";
	# now search for matches between snapos and files
	foreach my $s (@{$snaps}) {
		# first substitute '-' for any '/' in the snapshot name
		$s =~ tr /\//-/;
		foreach my $f (@files) {
			if ($f =~ $s) {
				push(@filesToDelete, $f);
				 #print "Matched $f <-> $s\n";
				 }
			
		}
		#print grep { $_ =~ /"$s"/ } @filesToDelete;
		#push(@filesToDelete, grep { $_ =~ /"$s"/ } @files);
	}
	# print "delete\n", join("\n ", @filesToDelete), "\n";
	my %filesToDelete = map { $_, 1 } @filesToDelete;
	return keys %filesToDelete;
}

our $filesystem;
our $trial;
our $reserveCount;
our $dumpDirectory;

sub processArgs() {
	# assign default values
	$filesystem = undef;
	$trial = undef;
	$reserveCount = 5;
	$dumpDirectory = "/snapshots";

	GetOptions(
		'filesystem=s' => \$filesystem,
		'trial' => \$trial,
		'reserved=i' => \$reserveCount,
		'directory=s' => \$dumpDirectory,
	);
}

sub main {

	processArgs() or die "Usage: $0
		[-f|--filesystem filesystem (default=all)]
		[-t|--trial]
		[-r|--reserved reserve_count (default=5)]
		[-d|--directory dump_directory (default=\"/snapshots\")]\n";

	# TODO: fully implement all command line arguments

	# warn the user
	if ( $< != 0 ) {
		warn "warning: not running as root\n";
	}else {
		print "running as root\n";
	}

	my @snapshots = getSnapshots $filesystem;

	my $datecount=0;


	foreach my $s (@snapshots) {
		print ">$s<\n";
		if ($s =~ /[0-9]{4}-[0,1][0-9]-[0-3][0-9]/) {
			print "$s has date\n";
			$datecount++;
		}
		if ($s =~ /[0-9]{4}-[0,1][0-9]-02/) {
			print "$s is second of the month\n";
		}
	}
	print " $datecount dates found\n";
}

# finish with status
1;