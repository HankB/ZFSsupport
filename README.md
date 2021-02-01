# ZFSsupport

Scripts to support my usage of ZFS (on Linux)

## Summary

This is a collection of scripts intended to mirror a local backup (on a ZFS
filesystem) to a remote server also to a ZFS filesystem. The updates to the
backup are sent as incremental snapshot 'send's. The actual backups are
handled outside of these using `rsync` as the clients backed up are not
presently using ZFS.

## Contributing

If you look at this and see opportunities for improvement, feel free to let me know. If you find bugs, file an issue! If you have questions, feel free to email me or file an issue. I would generally be open to PRs as long as they improve the result in some way. Thanks!

NB: There are probably better projects for doing this and my code is probably highly specific to how I do things but if it looks like a fit for you, go for it.

## Motivation

Sending incremental snapshot dumps to a remote system will
use the less bandwidth than `rsync`. (It may not always the case. (1))

## Organization

Capturing and sending the snapshots is performed by a shell script (with a 
helper script to provide locking.) These are in the .../sh directory. The
shell script runs locally on the host that is pushing data to the remnote.

Cleanup - removing old snapshots and snapshot dump files is done using Perl
and code for that is in the .../perl directory. Cleanup is triggered by the
shell script on the local host but requires the Perl script installed on the
remote host.

For more details on these see the READMEs in the respective .../sh and 
.../perl subdirectories.

## Status

`update-snapshot.sh` is working and "in production." It needs:

* further bulletproofing
* a way to annunciate difficulties
* cleanup of output/logging

See also issues related to this script.

`myzfs.pl` and `MyZFS.pm` is in testing in a ~test! production environment.

### (tardy) status update

The scripts have been in use for years in a home lab production environment and generally perform well. There were some issues with bandwidth usage (due to stupid creation of a huge test file in a directory that gets backed up) and for that reason, code was added to prevent transmission of a dump file to the remote if it exceeded a specified size.

The other problem is that as my `~Documents` directory grew, the first of the month backup also grew. A solution to this was to create an `~Archive` directory where files not in active use could be moved. The plan is to use ZFS send/receive to mirror the `~Archive` directory from the client to the server. This will keep them out of the first of the month copy and they will then not be duplicated monthly on the server. This is the first time ZFS is used client -> server and introduces another complication in that there is no way to differentiate client -> server snapshots from server ->  remote snapshots. For this purpose the host name (where the snapshot is recorded) is being added to the snapshot name. \<filesystem\>.yyyy-mm-dd becomes \<filesystem\>.\<hostname\>.yyyy-mm-dd.

### 2021-01-31 hostname changes comnplete

this work is complete and has run two days w/out difficulty in production (from a test directory) and in a tetst environment for severla days longer. It is not w/out issues but is deemed ready to roll out. 

In addition to the upgrades to the scripts, all involved hosts have been upgraded to a version of ZFS that supports `allow` in order that the scripts can be run as a normal user. See the README.md in `../sh`  for further information.

It will likely be necessary for some manual cleanup following the transition to 1.0.0 due to naming changes in snapshots and dumps.

## Errata

A (not sufficient) search was performed prior to beginning this with the
thought of leveraging existing work but nothing useful was found. Before you
use this, take a look at `simplesnap` (available as a .deb on Debian Stretch)
and `zfSnap` to see if some combination can better meet your needs. Also
check out `sanoid` https://github.com/jimsalterjrs/sanoid.

Occasional problems arise when 'receiving' the dump file on the remote 
system. The problem may relate to the issue 
https://github.com/zfsonlinux/zfs/issues/3742. It seems wise to not mount the
remote filesystem unless it is necessary to inspect/retrieve files. Should
this issue crop up it can be dealt with by using the '-F' flag when 'receiving'
the dump on the remote. It will overwrite any local changes since the previous
snapshot.

It seems that when a lot of files are deleted locally, that results in a
fairly large snapshot dump.

## Requirements

* passwordless ssh login on the remote (`see copy-ssh-id`) For the current
versions of ZFS on Debian 9 and  Ubuntu 16.04 this is required for the user
`root` as a normal user cannot run `zfs` commands. (Later versions of ZFS
support the `zfs allow ...` that will eliminate this need.) For this reason
it is recommended to disable password ssh login on the hosts involved. (Step
5 at https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04.)

* `/snapshots` directory on both local and remote PCs for storing snapshot dumps.
* `pxz` (On Debian, Ubuntu `apt install pxz`) Note: No longer used as of 1.0.0 and no longer packaged for Debian Buster. (Using `xz -T` instead.)
* `rsync` (on Debian, Ubuntu `apt install rsync`)
