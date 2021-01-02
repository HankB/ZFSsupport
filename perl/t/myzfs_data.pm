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
tank/Archive@this-host.2018-04-08
tank/Archive@3t.example.net.2018-04-09
tank/Archive@drago2.2018-04-10
tank/Archive@oak.2018-04-11
';

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

# prefix myzfs_data::
# return success
1;