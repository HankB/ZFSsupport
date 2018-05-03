# ZFSsupport

Scripts to support my usage of ZFS (on Linux)

## Summary

This is a collection of scripts intended to mirror a local backup (on a ZFS
filesystem) to a remote server also to a ZFS filesystem. The updates to the
backup are sent as incremental snapshot 'send's. The actual backups are
handled outside of these using `rsync` as the clients backed up are not
presently using ZFS.

## Status

`update-snapshot.sh` is working and "in production." It needs:

* further bulletproofing
* a way to annunciate difficulties
* cleanup of output/logging

See also issues related to this script.

`myzfs.pl` and `MyZFS.pm` is in preliminary production testing.

## Other

A (not sufficient) search was performed prior to beginning this with the
thought of leveraging existing work but nothing useful was found. Before you
use this, take a look at `simplesnap` (available as a .deb on Debian Stretch)
and `zfSnap` to see if some combination can better meet your needs.

## Motivation

It is thought that sending incremental snapshot dumps to a remote system will
use the least bandwidth. (It turns out that is not always the case. (1))

## Requirements

* Perl module `Sub::Override` (`apt install libsub-override-perl` on Ubuntu 16.04 and Debian 9)
* Perl module  `File::Touch` (`apt install libfile-touch-perl` on Debian Stretch)
* Perl module  `Module::Build` (`apt install libmodule-build-perl`  on Ubuntu 16.04)
* Perl module  `Devel::Cover` (`apt install libdevel-cover-perl` on Ubuntu 16.04)
* passwordless ssh login on the remote (`see copy-ssh-id`)
* `/shapshots` directory on both local and remote PCs for storing snapshot dumps.
* `pxz` (On Debian, `apt install pxz`)

## Components

There are two scripts that will run in production. `update-snapshot.sh`
will mirror snapshots to a remote system. `myzfsMain.pl` will cleanup
after `update-snapshot.sh`. Other scripts are support and/or testing
scripts.

### update-snapshot.sh

The script that dumps local snapshots (ZFS send), sends them to the remote
and incorporates them into the remote image.

### lock.sh

A couple Bourne shell functions to provide process interlocks.

### test_lock.sh

Test script for `lock.sh`. (See script for suggested ways to test.)

### myzfs.pl

Logic to destroy older snapshots and delete old snapshot dumps.

### myzfs.t

Test script for `MyZFS.pm`

### MyZFS.pm

Module to implement the lower level logic in a testable form.

### Building (perl)

Following guidelines from `https://stackoverflow.com/questions/533553/perl-build-unit-testing-code-coverage-a-complete-working-example`

`cd perl`

`perl Build manifest`

`perl Build.PL`

`perl Build test`

`perl Build testcover`

### Installing (perl)

Put the module `MyZFS.pm` somewhere convenient. The following command lists possibilities:
`perl -e 'print join "\n", @INC;'` and on my system shows
``` perl
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

### Installing (sh)


## Errata

  1. It seems that when a lot of files are deleted locally, that results in a
  fairly large snapshot dump.
  1. Any local changes to the remote system will result in an error receiving
  the dump.
