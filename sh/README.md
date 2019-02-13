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


## Components

`update-snapshot.sh` will mirror snapshots to a remote system. 
Other scripts are support and/or test scripts.

### update-snapshot.sh

The script that dumps local snapshots (ZFS send), sends them to the remote
and incorporates them into the remote image.

### lock.sh

A couple Bourne shell functions to provide process interlocks.

### test_lock.sh

Test script for `lock.sh`. (See script for suggested ways to test.)


## Installing

Copy the shell scripts somewhere convenient. Suggested:

```
cd sh
sudo cp update-snapshot.sh lock.sh /usr/local/sbin
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

The script is "in production" on my home LAN with the sender running Debian Stretch and remote Ubuntu 16.04.