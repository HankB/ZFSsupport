#!/bin/sh

# Script to take a snapshot and send to a remote host
# First argument is the filesystem to mirror and second is the remote host

# The process takes a number of steps
# 1) capture snapshot
# 2) copy snapshot to remote system
# 3) receive (e.g. import) snapshot into remote filesystem

# The stages are encoded in /tmp/update-snapshot.sh.host.filesystem along with
# the PID of the script as part of the attempt to provide resiliency. In some
# conditions it is possible that the script may still be running from a previous
# invocation when it is executed again. If the previous process is still running
# the script will wait until it finishes. (A 'sanitized' variant of the 
# filesystem name is used because it usually includes '/')

# useful functions

# check to see if we can ssh to remote system. (May not respond to 'ping')
isRemoteReachable()
{
    ssh $1 exit
    return $?
}

# write some status to /tmp
recordStatus() # (status, host, sanitized_filesystem)
{
    echo $1 $$ >/tmp/update-snapshot.sh.${2}.${3}
}

# remove the status file
removeStatus() # (host, sanitized_filesystem)
{
    rm "/tmp/update-snapshot.sh.${1}.${2}"
}

# get the length of a local file
# get return value by e.g. `L=$(fileLen foo`
fileLen()
{
    if [ -e $1 ]
    then
        LEN=`ls -l|tail -1|awk '{print $5}'`
    else
        LEN=-1
    fi
    echo LEN
}

echo "########################################################################"
date

# check for command line arguments
if [ $# -lt 2 -o $# -gt 3 ]
then
    echo "Usage $0 host filesystem [remote_filesystem]"
    exit 1
fi

# provide memorable command argument names
FILESYSTEM=$2
REMOTE_HOST=$1

if [ $# -eq 3 ]
then
    REMOTE_FILESYSTEM=$3
else
    REMOTE_FILESYSTEM=$FILESYSTEM
fi

# provide variants of inputs w/out '/' characters
FILESYSTEM_F=`echo $FILESYSTEM|tr / -`
REMOTE_FILESYSTEM_F=`echo $REMOTE_FILESYSTEM|tr / -`

# check to see if previous instance is still running
# TODO: Develop a strategy not subject to race conditions
echo checking for $PID_FILE
PID_FILE=/tmp/update-snapshot.sh.${REMOTE_HOST}.${FILESYSTEM_F}
while [ -e /tmp/update-snapshot.sh.${REMOTE_HOST}.${FILESYSTEM_F} ]
do
    PREV_PID=`< $PID_FILE awk '{print $2}'`
    echo PREV_PID $PREV_PID
    if ps -p $PREV_PID >/dev/null
    then
        echo $PREV_PID still running
        sleep 60
    else
        PREV_STATUS=`< $PID_FILE awk '{print $1}'`
        echo $PREV_PID exited abnormally after `stat -c "%y" $PID_FILE`
        removeStatus $REMOTE_HOST $FILESYSTEM_F
    fi
done

recordStatus "starting" $REMOTE_HOST $FILESYSTEM_F

# check to see if we can reach the remote
while ( ! isRemoteReachable $REMOTE_HOST)
do
    echo $REMOTE_HOST not reachable
    sleep 60
done

# report snapshots before we start
# TODO: cache results of 'zfs list' to use to ID the most recent snapshot
echo
echo "On " `hostname`
/sbin/zfs list -t snap -r $FILESYSTEM
echo
echo "On $REMOTE_HOST"
ssh $REMOTE_HOST /sbin/zfs list -t snap -r $REMOTE_FILESYSTEM

# capture newest local and remote snapshots. The date tag is separated 
# from the filesystem part since local and remote filesystems may differ
export REMOTE=`ssh $REMOTE_HOST /sbin/zfs list -t snap -r $REMOTE_FILESYSTEM |\
       tail -1 | awk '{match($1,"@(.*)",a)}END{print a[1]}'`
export LOCAL=`/sbin/zfs list -t snap -r $FILESYSTEM | \
       tail -1 | awk '{match($1,"@(.*)",a)}END{print a[1]}'`

echo REMOTE $REMOTE
echo LOCAL $LOCAL


# see if we need to snap
echo check for "`date +%Y-%m-%d`" against $LOCAL
if [ `date +%Y-%m-%d` = $LOCAL ]
then
    echo
    echo "snapshot already captured today $LOCAL"
    echo
else
    echo
    echo snapshotting $FILESYSTEM
    /usr/bin/time -p /sbin/zfs snap ${FILESYSTEM}@`date +%Y-%m-%d`
    # TODO check status of 'zfs snap'
    export LOCAL=`/sbin/zfs list -t snap -r $FILESYSTEM | \
        tail -1 | awk '{match($1,"@(.*)",a)}END{print a[1]}'`
    echo
fi

date

# see if we need to send
# TODO: check if file is there, not if it is already imported
if [ $LOCAL = $REMOTE ]
then
    echo
    echo "already 'sent' (captured)"
else
    echo
    REMOTE_F=${REMOTE_FILESYSTEM_F}@${REMOTE}
    LOCAL_F=${FILESYSTEM_F}@$LOCAL
    echo saving incremental remote: $REMOTE local: $LOCAL
    echo to /snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz
    echo time -p /sbin/zfs send -L -i ${FILESYSTEM}@${REMOTE} ${FILESYSTEM}@${LOCAL}\
         \| pxz -3 -c - \(direct to /snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz \)
    time -p /sbin/zfs send -L -i ${FILESYSTEM}@${REMOTE} ${FILESYSTEM}@${LOCAL}\
         | pxz -3 -c - \
         >/snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz
    echo rsync to $REMOTE_HOST
    cd /snapshots
    time -p rsync -av --partial --append-verify --progress \
	${REMOTE_F}-${LOCAL_F}.snap.xz ${REMOTE_HOST}:/snapshots/
fi

date

# now 'receive' the snapshot at the remote
# time ssh cashapona 'xzcat /snapshots/pool2TB4K-test@initial-tank@2018-03-08.snap.xz|\
#      zfs receive pool2TB4K/test'
echo time ssh $REMOTE_HOST "xzcat /snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz \| \
         zfs receive $REMOTE_FILESYSTEM" 
time ssh $REMOTE_HOST "xzcat /snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz | \
         zfs receive $REMOTE_FILESYSTEM" 

# report snapshots following send
echo
echo "after send/receive to ${REMOTE_HOST}"
ssh $REMOTE_HOST /sbin/zfs list -t snap -r $REMOTE_FILESYSTEM

date
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
