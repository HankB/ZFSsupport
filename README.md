# ZFSsupport

Scripts to support my usage of ZFS (on Linux)

## Summary

This is a collection of scripts intended to mirror a local backup (on a ZFS
filesystem) to a remote server also to a ZFS filesystem. The updates to the
backup are sent as incremental snapshot 'send's. The actual backups are
handled outside of these using `rsync` as the clients backed up are not
presently using ZFS.

## Other

A (not sufficient) search was performed prior to beginning this with the
thought of leveraging existing work but nothing useful was found. Before you
use this, take a look at `simplesnap` (available as a .deb on Debian Stretch)
and `zfSnap` to see if some combination can better meet your needs.

## Motivation

It is thought that sending incremental snapshot dumps to a remote system will
use the least bandwidth. (It turns out that is not always the case. (1))

## Components

### update-snapshot.sh

The script that dumps local snapshots (ZFS send), sends them to the remote and
incorporates them into the remote image.

### lock.sh

A couple Bourne shell functions to provide process interlocks.

### test_lock.sh

Test script for `lock.sh`.

## Errata

  1. It seems that when a lot of files are deleted locally, that results in a
  fairly large snapshot dump.
  1. Any local changes to the remote system will result in an error receiving
  the dump.