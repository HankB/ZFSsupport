package myzfs_data;
# myzfs_data.pm

use strict;
use warnings;


=pod
Perl module to hold data that wil be shared among test scripts once
the single test script is split up.
=cut

# results collected recently - all snapshots presently on grandidier.
# `zfs list -t snap -H -o name`
our $archiveTestSnapAll = 'tank@initial
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
our @archiveTestSnapAll = split /^/, $myzfs_data::archiveTestSnapAll;
chomp @archiveTestSnapAll;


our $srvTestSnapAll = 'tank/srv@2018-01-09
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

our @srvTestSnapAll = split /^/, $myzfs_data::srvTestSnapAll;
chomp @srvTestSnapAll;


# all snapshot dumps presently on grandidier
# ls -1 /snapshots
our $grandidier_dumpfiles = 'tank-Archive@2018-03-15-tank-archive@2018-03-20.snap.xz
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
tank-srv@oak.2018-04-10-tank-srv@rowan.2018-04-11.snap.xz';

# all snapshot dumps presently on baobabb
# ls -1 /snapshots
our $baobabb_dumpfiles = 'tank-test@2019-03-01-rpool-test@2019-03-02.snap.xz
tank-test@2019-03-02-rpool-test@2019-03-03.snap.xz
tank-test@2019-03-02-rpool-test@2019-03-04.snap.xz
tank-test@2019-03-02-rpool-test@2019-03-05.snap.xz
tank-test@2019-03-02-rpool-test@2019-03-06.snap.xz
tank-test@2019-03-06-rpool-test@2019-03-07.snap.xz
tank-test@2019-03-08-rpool-test@2019-03-09.snap.xz
tank-test@2019-03-08-rpool-test@2019-03-10.snap.xz
tank-test@2019-03-08-rpool-test@2019-03-11.snap.xz
tank-test@2019-03-11-rpool-test@2019-03-12.snap.xz
tank-test@2019-03-12-rpool-test@2019-03-13.snap.xz
';

our $remainingTestSnapshotDumps =
  'tank-Archive@2018-04-07-tank-Archive@2018-04-08.snap.xz
tank-Archive@2018-04-08-tank-Archive@2018-04-09.snap.xz
tank-Archive@2018-04-09-tank-Archive@2018-04-10.snap.xz
tank-Archive@2018-04-10-tank-Archive@2018-04-11.snap.xz
tank-srv@2018-04-07-tank-srv@2018-04-08.snap.xz
tank-srv@2018-04-08-tank-srv@2018-04-09.snap.xz
tank-srv@2018-04-09-tank-srv@2018-04-10.snap.xz
tank-srv@oak.2018-04-10-tank-srv@rowan.2018-04-11.snap.xz
';

our $rpoolTestSnapAll = 'rpool/srv/test@first
rpool/test@2019-03-07
rpool/test@2019-03-09
rpool/test@2019-03-10
rpool/test@2019-03-11
rpool/test@2019-03-12
rpool/test@2019-03-13
';



# some derived data sets
# snapshots to delete
our @archiveTestSnapToDelete;
our @srvTestSnapToDelete;
our @allTestSnapToDelete;     # union of the previous two

# deletable snapshots
our @archiveTestSnapDeletable;
our @srvTestSnapDestroyable;
our @allTestSnapDeletable;    # union of the previous two

# TODO: eliminate reuse of @dumpfiles
our @grandidier_dumpfiles = split /^/, $grandidier_dumpfiles;
chomp @grandidier_dumpfiles;

our @archiveTestDumpsToDelete = @grandidier_dumpfiles;
splice @archiveTestDumpsToDelete, 16;
splice @archiveTestDumpsToDelete, 10, 4;

our @srvTestDumpsToDelete = @grandidier_dumpfiles;
splice @srvTestDumpsToDelete, 36;
splice @srvTestDumpsToDelete, 0, 16;

#print "srvTestDumpsToDelete\n", join("\n", @srvTestDumpsToDelete), "\n\n";

our @allTestDumpsToDelete;
push @allTestDumpsToDelete, @archiveTestDumpsToDelete, @srvTestDumpsToDelete;

# prepare 'to delete' lists from Deletable lists by removing the last
# RESERVE_COUNT entries
# TODO: test with RESERVE_COUNT equal to and greater than the list length.
use constant RESERVE_COUNT => 5;

# Prepare deletable snaps by removing any
# that do not look like "<snapshot>@YYYY-MM-DD"
@archiveTestSnapDeletable = @archiveTestSnapAll;
splice @archiveTestSnapDeletable, 0, 1; # TODO not needed?

@srvTestSnapDestroyable = @srvTestSnapAll;
splice @srvTestSnapDestroyable, 21, 1;
push @allTestSnapDeletable, @archiveTestSnapDeletable, @srvTestSnapDestroyable;

@archiveTestSnapToDelete =
  @archiveTestSnapDeletable[ 0 .. $#archiveTestSnapDeletable -RESERVE_COUNT ];
@srvTestSnapToDelete =
  @srvTestSnapDestroyable[ 0 .. $#srvTestSnapDestroyable -RESERVE_COUNT ];
push @allTestSnapToDelete, @archiveTestSnapToDelete, @srvTestSnapToDelete;

# predeclare all collections ...
# lists of all categorized snapshots

our @allTestSnapAll;    # union of the previous two
push @allTestSnapAll, @archiveTestSnapAll, @srvTestSnapAll;

# prefix myzfs_data::
# return success
1;