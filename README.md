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

Cleanup scripts are presently a work in progress. Not presently passing all tests.

## Other

A (not sufficient) search was performed prior to beginning this with the
thought of leveraging existing work but nothing useful was found. Before you
use this, take a look at `simplesnap` (available as a .deb on Debian Stretch)
and `zfSnap` to see if some combination can better meet your needs.

## Motivation

It is thought that sending incremental snapshot dumps to a remote system will
use the least bandwidth. (It turns out that is not always the case. (1))

## Requirements

* Sub::Override (`apt install libsub-override-perl`on Ubuntu)

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

Logic to delete older snapshots. ()Eventually to delete old snapshot dumps.)

### myzfs.t

Test script for `myzfs.pl`

### myzfsMain.pl

'Main' to execute logic in `myzfs.pl`

## Errata

  1. It seems that when a lot of files are deleted locally, that results in a
  fairly large snapshot dump.
  1. Any local changes to the remote system will result in an error receiving
  the dump.