# ZFS support - Perl components

## Components

`myzfs.pl` will cleanup
after (or before) `update-snapshot.sh`. Heavy lifting is put in MyZFS.pm
in order to make testing easier. Other scripts are support and/or testing
scripts. There are hooks in `update-snapshot.sh` to execute external 
commands before or after the other processing.

## Requirements

* Perl module `Sub::Override` (`apt install libsub-override-perl` on Ubuntu 16.04 and Debian 9)
* Perl module  `File::Touch` (`apt install libfile-touch-perl` on Debian Stretch)
* Perl module  `Module::Build` (`apt install libmodule-build-perl`  on Ubuntu 16.04)
* Perl module  `Devel::Cover` (`apt install libdevel-cover-perl` on Ubuntu 16.04)

### myzfs.pl

Logic to destroy older snapshots and delete old snapshot dumps.

### myzfs.t

Test script for `MyZFS.pm`

### MyZFS.pm

Module to implement the lower level logic in a testable form.

## Building

Following guidelines from `https://stackoverflow.com/questions/533553/perl-build-unit-testing-code-coverage-a-complete-working-example`


```cd perl
perl Build manifest
perl Build.PL
perl Build test
perl Build testcover
```

## Unit Testing

Either

```text
perl Build test
```

or

```text
./t/myzfs.t 
```

## Integration testing

In order to test, the executable must be run from cron since that is the environment in which it will be used. The strategy adopted is to create `~/testbin` and `~/testbin/lib` and place `myzfs.pl` and `MyZFS.pm` in their respective directories. Optionally create a script to execute the program with the desired arguments.

Copy the script and library to suitable directories.

```text
mkdir -p ~/testbin/lib
cp lib/MyZFS.pm  ~/testbin/lib
cp myzfs.pl ~/testbin
```

```text
hbarta@olive:~/Programming/ZFSsupport/perl$ cat /home/hbarta/testbin/rpool-Archive-cleanup.sh
#!/bin/sh
# run cleanup scripts from test directory

/home/hbarta/testbin/myzfs.pl -v -h olive > /tmp/rpool-Archive-cleanup.lst 2>&1
#ssh drago /usr/local/sbin/myzfs.pl -v -f tank/Archive > /tmp/tank-Archive-cleanup-drago.lst 2>&1
hbarta@olive:~/Programming/ZFSsupport/perl$ 
```

Next add an entry to `crontab` to execute the driver script.

```text
51 8 * * * /home/hbarta/testbin/rpool-Archive-cleanup.sh >/tmp/testcleanup.lst 2>&1
```

## Installing

Put the module `MyZFS.pm` somewhere convenient. The following command lists possibilities:
`perl -e 'print join "\n", @INC;'` and on my system shows

```perl
hbarta@grandidier:~/Documents/ZFSsupport/perl$ perl -e 'print join "\n", @INC;'
/etc/perl
/usr/local/lib/x86_64-linux-gnu/perl/5.22.1
/usr/local/share/perl/5.22.1
/usr/lib/x86_64-linux-gnu/perl5/5.22
/usr/share/perl5
/usr/lib/x86_64-linux-gnu/perl/5.22
/usr/share/perl/5.22
/usr/local/lib/site_perl
/usr/lib/x86_64-linux-gnu/perl-base
.hbarta@grandidier:~/Documents/ZFSsupport/perl$ 
```

Copy the script `myzfs.pl` to a convenient location such as /usr/local/sbin

### my install commands

```text
cd perl
sudo mkdir /usr/local/lib/site_perl
sudo cp lib/MyZFS.pm /usr/local/lib/site_perl
sudo cp myzfs.pl /usr/local/sbin
```

## First major revision

The overall system is presently only used to mirror a backup server to a remote backup server. A present desire is to also use it to mirror a filesystem on a client PC to a corresponding filesystem on a server. The problem this presents is that snapshot names created on the client and server are indistinguishable. To overcome this, the hostname will be added to the snapshot name. For example, `tank/srv@2018-01-14` will become, `tank/srv@oak.2018-01-14` if it is created on `oak`. The shell script that creates the snapshots and mirrors them to a different site has already meen modified to accomplish this. This cleanup script needs to be modified to work with the new naming scheme. There are a couple wrinkles with this.

1. During a transitory period, snapshots will exist with both naming schemes. The mods to the script will not deal with the older naming scheme due to the ambiguity possibly leaving fewer desired snapshots when the older format remains.
1. Clients may be using some additional process to create snapshotrs such as `sanoid`. These get sent to the backup server and are not there desired. They can be safely deleted on the backup server but must remain on the client server. This will require seperate processing triggered by a command line option.
1. This will require considerable rework and expansion of the test script (`./t/myzfs.t`) in order to test both client and server environments and test with both older and current snapshot and snapshot naming policies. As the test script is already over 500 lines long, it will be split into two scripts, one focused on shapshots and the other on snapshot dumps.

## Errata

During testing I performed multiple tsts in one day by renaming the most recent snapshot by appending `.n` to the name. (e.g. `.0`, `.1` and so on.) As a result fewer than the desired number of snapshot dumps were preserved.
