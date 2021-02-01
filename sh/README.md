# Replicating a ZFS filesystem to a remote server

The shell script portion of this project sends a snapshot of a local dataset (AKA filesystem) to a remote host using zfs send/receive.

## Usage

```shell
Usage ./update-snapshot.sh [-i] [-b "pre cmd"] [-a "post cmd"] host filesystem [remote_filesystem]
[-i]              - Initialize remote dataset (first run.)
[-b "pre cmd"]    - command to run before the transfer.
[-b "post cmd"]   - command to run after the transfer.
host              - remote host name
filesystem        - local filesystem name (not dir.)
remote_filesystem - remote filesystem name if different from filesystem
v0.4
```

Further comments on usage.

* It is best to have the remote dataset unmounted. In some cases if it is mounted an incremental snapshot may fail to be received. (This can be overcome by logging in to the remote system and running the `zfs receive` command locally and using the `-F` flag to force the receive. Any changes local to the remote will be overwritten.)
* The '-i' option is expected to be run interactively. It will not wait for locks and generally exits if anything is amiss. One of these would be an existing snapshot for the remote filesystem. That will cause the `zfs receive` to fail and seemingly cannot be overridden.
* The script is far from bulletproof. More work needs to be done to insure that.
* At present the script is used on a host (Debian Stretch) which uses ZFS V0.6.5 and does not support the `allow` command so it must run as root and requires passwordless SSH login to the remote host. This can probably be relaxed on systems with newer versions of ZFS tools but that has not been tested.

## Running as non-root

Versions of ZFS since 0.7.x provide the `zfs allow` command to permit non-root users to run the backup script, eliminating the need for passwordless root login on the server. These permissions enable most operations.

```text
sudo zfs allow -u <user> compression,create,mount,mountpoint,send,snapshot,destroy,receive,hold <filesystem>
```

I have not audited these to insure there are none that are not required. I use them on both client and server so obviously `receive` is probably not needed on the client and `send` may not be required on the server. I note the following when transitioning from `root` to `user`.

* The initial send did not succeed as `user` and `zfs receive` had to be repeated as `root`. It may turn out that snapshots and snapshot dumps cannot then be destroyed or deleted by `user` and may require manual intervention.
* Adjust permissions on the snapshot dump directory and older snapshots so `user` can manipulate them.

## Error notification

Where errors (such as disk full, remote not reachable and so on) are identified, notification can be sent using the script `sa.ah`. A "description" is passed to the standard input and "subject" as a command line argument. For example

```shell
echo "'zfs send/dump' failed " | sa.sh "$0 exit 1 on `hostname`"
```

The implementation selected for in house use is

```shell
#!/bin/sh

# Script to send alarm notifications to root via email
# usage 'echo "message to send" | sa.sh "subject"
# bugs - will hang if nothing is sent to STDIN (perhaps die if run from another script)

mail -s "$1" root
```

It is expected that the implementer will provide their own variant if desired. It is only called prior to `exit 1` so it will not terminate when `update-snapshot.sh` is not encountering problems.

## Components

`update-snapshot.sh` will mirror snapshots to a remote system. 
Other scripts are support and/or test scripts.

### update-snapshot.sh

The script that dumps local snapshots (ZFS send), sends them to the remote
and incorporates them into the remote image.

### lock.sh DEPRECATED

A couple Bourne shell functions to provide process interlocks.

The lock related scripts have been moved to https://gitlab.com/HankB/shell-locking. The scripts in this directory still work but it is recommended to use the one in the Gitlab repo.

### test_lock.sh DEPRECATED

Test script for `lock.sh`. (See script for suggested ways to test.)

Se comments above for `lock.sh`.

## Installing

Copy the shell scripts somewhere convenient. Suggested:

```shell
cd sh
sudo cp update-snapshot.sh /usr/local/sbin
```

Unpack the project https://gitlab.com/HankB/shell-locking somewhere convenient and copy `lock.sh` to the same location used for `update-snapshot.sh`

```shell
sudo cp lock.sh /usr/local/sbin
```

Add a cron job to execute the script once daily. Something like:

```shell
/usr/local/sbin/update-snapshot.sh -a /usr/local/sbin/srvpool-srv-cleanup.sh drago srvpool/srv tank/srv >>/tmp/update-shapshot.srv.sh.lst 2>&1
```

The script `/usr/local/sbin/srvpool-srv-cleanup.sh` executes the cleanup script on local and remote hosts.

```shell
root@oak:/srvpool/srv/redwood# cat /usr/local/sbin/srvpool-srv-cleanup.sh
#!/bin/sh

/usr/local/sbin/myzfs.pl -v -f srvpool/srv > /tmp/srvpool-srv-cleanup.lst 2>&1
ssh drago /usr/local/sbin/myzfs.pl -v -f tank/srv > /tmp/tank-srv-cleanup-drago.lst 2>&1

root@oak:/srvpool/srv/redwood# 
```

## Testing

Testing is pretty minimal at this point - sort of "it worked - ship it!" One test exists which is used to test the locking shell functions - `test_lock.sh` It can be invoked from two different windows to verify that locking appears to work.

```shell
./test_lock.sh testlock 10 5
```

## Status

The script is "in production" on my home LAN with the sender running Debian Buster or Debian Stretch (0.8.6 and 0.7.12 respectively) and remote Debian Buster at 0.8.6.

### 2019-02-25

Following daily processing, the script `update-snapshot.sh` in "production" was updated to v0.5 after running several days without issue in a test environment. It will run next on 2019-02-25. A trial run from the console reported "already up to date" as desired.