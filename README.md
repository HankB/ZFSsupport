# ZFSsupport

Scripts to support my usage of ZFS (on Linux)

## Summary

This is a collection of scripts intended to mirror a local backup (on a ZFS
filesystem) to a remote server also to a ZFS filesystem. The updates to the
backup are sent as incremental snapshot 'send's. The actual backups are
handled outside of these using `rsync` as the clients backed up are not
presently using ZFS.

## Motivation

Sending incremental snapshot dumps to a remote system will
use the less bandwidth than `rsync`. (It may not always the case. (1))

## Organization

Capturing and sending the snapshots is performed by a shell script (with a 
helper script to provide locking.) These are in the .../sh directory.

Cleanup - removing old snapshots and snapshot dump files is done using Perl
and code for that is in the .../perl directory. 

For more details on these see the READMEs in the respective .../sh and 
.../perl subdirectories.

## Status

`update-snapshot.sh` is working and "in production." It needs:

* further bulletproofing
* a way to annunciate difficulties
* cleanup of output/logging

See also issues related to this script.

`myzfs.pl` and `MyZFS.pm` is in testing in a test environment.

## Errata

A (not sufficient) search was performed prior to beginning this with the
thought of leveraging existing work but nothing useful was found. Before you
use this, take a look at `simplesnap` (available as a .deb on Debian Stretch)
and `zfSnap` to see if some combination can better meet your needs.

Occasional problems arise when 'receiving' the dump file on the remote 
system. The problem may relate to the issue 
https://github.com/zfsonlinux/zfs/issues/3742. It seems wise to not mount the
remote filesystem unless it is necessary to inspect/retrieve files. Should
this issue crop up it can be dealt with by using the '-F' flag when 'receiving'
the dump on the remote. It will overwrite any local changes since the previous
snapshot.

## Requirements

* passwordless ssh login on the remote (`see copy-ssh-id`) For the current
versions of ZFS on Debian 9 and  Ubuntu 16.04 this is required for the user
`root` as a normal user cannot run `zfs` commands. (Later versions of ZFS
support the `zfs allow ...` that will eliminate this need.) For this reason
it is recommended to disable password ssh login on the hosts involved. (Step
5 at https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04.)

* `/shapshots` directory on both local and remote PCs for storing snapshot dumps.
* `pxz` (On Debian, Ubuntu `apt install pxz`) 
## Errata

  1. It seems that when a lot of files are deleted locally, that results in a
  fairly large snapshot dump.
  1. Any local changes to the remote system will result in an error receiving
  the dump. This can happen even if no operations are performed on the remote filesystem. (See second erratum.)
