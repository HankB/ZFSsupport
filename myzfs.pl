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
	print scalar @snapshots. " snapshots\n";
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
# Must match the pattern "filesystem>@YYYY-MM-DD" as produced
# by update-snapshot.sh
sub getDeletableSnaps(@) {
	my @candidates = grep { $_ =~ /@[1-2][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]/ } @_;
	return @candidates;
}

# filter out 
sub getDeleteSnaps(\@$) {
    my $snaps = shift || die "must call geDeleteSnaps() with snapshot list and residual count";
    my $residual = shift || die "must call geDeleteSnaps() with snapshot list and residual count";
	my @deleteList = @{$snaps}[$#{$snaps}-($residual-1) .. $#{$snaps}];
	return @deleteList;
}

sub main {
	my $filesystem;
	my $trial = 0;
	my $snapshotNumber = 5;

	GetOptions(
		'filesystem=s' => \$filesystem,
		'trial' => \$trial,
	) or die "Usage: $0 [-f|--filesystem] NAME\n";

    print "$filesystem, $trial, $snapshotNumber\n";

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