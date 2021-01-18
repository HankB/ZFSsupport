#!/usr/bin/perl
package MyZFS;

=pod
Note: The most recent version of this package accommodates the addition
of hostname to the snapshot name. Fo5r the subs that deal with lists of=
snapshots, it is presumed that they use lists form a single host as produced
by getSnapshots(). This is important in the unit tests. In actual practice 
all snapshot lists will be produced by getSnapshots() (instead of using
contrived test data.)
=cut

our $VERSION = 0.1;

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

use Exporter qw(import);

our @EXPORT_OK = qw( getSnapshots getFilesystems getDestroyableSnaps
  getSnapsToDestroy destroySnapshots findDeletableDumps deleteSnapshotDumps
  processArgs filesystem hostname filterSnapsByHost);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# find the zfs binary
my $bin = $ENV{ZFSBINPATH} // "/sbin/zfs";

# fetch a list of snapshots for a given host and perhaps limited 
# to a particular filesystem
sub getSnapshots {
    my $modName = shift;
    die "must provide hostname" unless my $hostname = shift;
    my $f       = shift;
    my $cmd     = "$bin list -t snap -H -o name";

    if ( defined($f) ) {
        $cmd = $cmd . " -r $f -d 1";
    }
    my $snapshots = `$cmd` || die;
    my @snapshots = split /^/, $snapshots;

    chomp @snapshots;
    return filterSnapsByHost(\@snapshots, $hostname);
}

# Filter snapshots for a specific host
# filterSnapsByHost( snap_list_ref, hostname)
sub filterSnapsByHost {
    die "must provide ref to list of snaps" unless my $snap_list_ref = shift;
    die "must provide hostname" unless my $hostname = shift ;
    return grep { $_ =~ /\@$hostname\./ } @$snap_list_ref;
}

# identify unique filesystems in list of snapshots.
# getFilesystems( snap_list_ref)
sub getFilesystems {
    my $modName = shift;
    die "must provide ref to list of snaps" unless my $snap_list_ref = shift;

    my %f;
    foreach my $s (@$snap_list_ref) {
        $s =~ /(.*)@/;    # isolate the filesystem name
        $f{$1}++;         # count it (to create hash entry)
    }

    my @f = keys %f;
    return @f;
}

# Identify snapshots in the provided list that meet criteria for deletion.
# This includes only the snapshots created by the backup process. Snapshots
# created by `sanoid` will be identified by another sub, if needed.
# Remove from the list any that do not match the pattern
#    "<filesystem>@<hostname>.YYYY-MM-DD"
# as produced by `update-snapshot.sh` or
#    "<filesystem>@YYYY-MM-DD"  produced by an earlier version of that script.

#
# Comments about the regex. Capturing the hostname may not enforce all
# rules that govern a hostname (RFCs 1123 and 1178) but it is believed
# that all valid hostnames will be captured.
sub getDestroyableSnaps {
    my $modName = shift;
    my @candidates =
      grep { $_ =~ /@[a-z0-9\.-]*\.{0,1}[1-2][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]/ } @_;
    return @candidates;
}

# Identify snapshots to delete.
# e.g. all except the last 'n' for each filesystem
# Use the list returned by getDestroyableSnaps(@)
sub getSnapsToDestroy {
    my $modName = shift;
    my $snaps   = shift
      || die "must call getSnapsToDestroy() with ref to snapshot list";
    my $residual = shift
      || die "must call getSnapsToDestroy() with residual count";

    # identify filesystems
    my @filesystems = getFilesystems( "dummy", $snaps );
    my @deletelist  = ();

    # add files to delete for each filesystem
    foreach my $fs (@filesystems) {
        my @candidates = ( sort( grep { $_ =~ /^$fs@/ } @{$snaps} ) );
        push @deletelist, @candidates[ 0 .. scalar(@candidates) - $residual - 1 ]
          if scalar @candidates > $residual;
    }
    return @deletelist;
}

# destroy the list of snapshots
sub destroySnapshots {
    my $modName      = shift;
    my $cmd          = "$bin destroy -v ";
    my $destroyCount = 0;
    foreach my $s (@_) {
        my $result = `$cmd $s`;
        $destroyCount++;

        # TODO - check result for success
    }
    return $destroyCount;
}

# identify dumps in /snapshots - files match "*.snap.xz"
# first argument is directory to search for dumps
# second arg is a reference to a list of snaps to delete
sub findDeletableDumps {
    my $modName       = shift;
    my $dir           = shift;
    my $snaps         = shift;
    my @filesToDelete = ();

    # print "\n\n", join("\nsnap ", @{$snaps}), "\n";
    my @files = glob( "$dir" . "*.snap.xz" );

    # print "\n\n", join("\nfile ", @files), "\n";
    # now search for matches between snapos and files
    foreach my $s ( @{$snaps} ) {

        # first substitute '-' for any '/' in the snapshot name
        $s =~ tr /\//-/;
        foreach my $f (@files) {
            if ( $f =~ $s ) {
                push( @filesToDelete, $f );

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

# used to delete snapshot dumps (or any list of files padded. ;)
sub deleteSnapshotDumps {
    my $modName = shift;
    foreach my $f (@_) {
        unlink $f || die "cannot delete $f";
    }
}

our $filesystem;
our $trial;
our $reserveCount;
our $dumpDirectory;
our $verbosity;
our $hostname;

sub processArgs {

    # assign default values
    $filesystem    = undef;
    $trial         = undef;
    $reserveCount  = 5;
    $dumpDirectory = "/snapshots/";
    $verbosity     = undef;
    $hostname      = undef;

    GetOptions(
        'filesystem=s' => \$filesystem,
        'trial'        => \$trial,
        'reserved=i'   => \$reserveCount,
        'directory=s'  => \$dumpDirectory,
        'verbose'      => \$verbosity,
        'hostname=s'   => \$hostname,
    );
}

# finish with successful status
1;
