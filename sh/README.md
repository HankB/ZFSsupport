# Replicating a ZFS filesystem to a remote server

The shell script portion of this project sends a remote 

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


## Installing (sh)

Copy the shell scripts somewhere convenient. Suggested:

`cp sh/update-snapshot.sh sh/lock.sh /usr/local/sbin`

Add a cron job to execute the script once daily.

