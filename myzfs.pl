#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(GetOptions);


# fetch a list of snapshots
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

sub getDeleteSnaps(\@$) {
    my @snaps = shift || die "must call geDeleteSnaps() with snapshot list and residual count";
    my @residual = shift || die "must call geDeleteSnaps() with snapshot list and residual count";
    return @snaps
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

# finish ith status
1;