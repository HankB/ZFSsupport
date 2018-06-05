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

# Much of the processing is demanding on either disk and/or CPU resources. To
# provide better performance, these sections are interlocked such that if mutiple
# copies of the script are launched, only one will execute the code in the
# interlocked section. Some sections which use specific resources or remote
# resources can proceed in parallel. Interlocks are named
#
# collect - 'send' incremental snapshot to a disk file (disk and CPU)
# transmit - deliver the resulting file to the remote system (network bandwidth)
# receive - 'receive' incremental snapshot on remote system. (remote disk,CPU)

# useful functions

# check to see if we can ssh to remote system. (May not respond to 'ping')
isRemoteReachable()
{
    ssh $1 exit
    return $?
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

show_help()
{
    echo "Usage $0 [-b \"pre cmd\"] [-a \"post cmd\"] host filesystem [remote_filesystem]"
    echo "v0.3"

}
# external code

. `dirname $0`/lock.sh || exit 1

echo "########################################################################"
date +%Y-%m-%d\ %H:%M:%S

# process command line arguments
# from https://stackoverflow.com//questions192249/how-do-i-parse-command-line-arguments-in-bash
BEFORE_HOOK=""
AFTER_HOOK=""

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "h?b:a:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    b)  BEFORE_HOOK=$OPTARG
        ;;
    a)  AFTER_HOOK=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# check for command line arguments
if [ $# -lt 2 -o $# -gt 3 ]
then
    show_help
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

echo "filesystem        " $FILESYSTEM
echo "remote host       " $REMOTE_HOST
echo "remote filesystem " $REMOTE_FILESYSTEM

if [ "$BEFORE_HOOK" != "" ]
then
    echo executing BEFORE_HOOK $BEFORE_HOOK
    $BEFORE_HOOK
fi

# provide variants of inputs w/out '/' characters
FILESYSTEM_F=`echo $FILESYSTEM|tr / -`
REMOTE_FILESYSTEM_F=`echo $REMOTE_FILESYSTEM|tr / -`


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
/sbin/zfs list -d 1 -t snap -r $FILESYSTEM
echo
echo "On $REMOTE_HOST"
ssh $REMOTE_HOST /sbin/zfs list -d 1 -t snap -r $REMOTE_FILESYSTEM

# capture newest local and remote snapshots. The date tag is separated 
# from the filesystem part since local and remote filesystems may differ
export REMOTE=`ssh $REMOTE_HOST /sbin/zfs list -d 1 -t snap -r $REMOTE_FILESYSTEM |\
       tail -1 | \
       awk '{match($1,"@(.*)")}END{print substr($1, RSTART+1, RLENGTH)}'`
export LOCAL=`/sbin/zfs list -d 1 -t snap -r $FILESYSTEM | \
       tail -1 | \
       awk '{match($1,"@(.*)")}END{print substr($1, RSTART+1, RLENGTH)}'`

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
    echo /usr/bin/time -p /sbin/zfs snap ${FILESYSTEM}@`date +%Y-%m-%d`
    /usr/bin/time -p /sbin/zfs snap ${FILESYSTEM}@`date +%Y-%m-%d`

    PREV_LOCAL=$LOCAL
    LOCAL=`/sbin/zfs list -d 1 -t snap -r $FILESYSTEM | tail -1 | \
        awk '{match($1,"@(.*)")}END{print substr($1, RSTART+1, RLENGTH)}'`
    
    # check to see if the snapshot operation worked, $LOCAL should change
    echo  test "$PREV_LOCAL = $LOCAL"
    if [ $PREV_LOCAL = $LOCAL  ]
    then
        echo snapshot failed
        exit 1 # no obvious recoveryzpool create
    fi
    echo
fi

date +%Y-%m-%d\ %H:%M:%S

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

    # wait for up to 5 hours for this stage
    if ! acquireLock "collecting" 300
    then
        echo $$ cannot lock "collecting"
        exit 1
    fi

    echo time -p /sbin/zfs send -L -i ${FILESYSTEM}@${REMOTE} ${FILESYSTEM}@${LOCAL}\
         \| pxz -3 -c - \(direct to /snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz \)
    time -p /sbin/zfs send -L -i ${FILESYSTEM}@${REMOTE} ${FILESYSTEM}@${LOCAL}\
         | pxz -3 -c - \
         >/snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz

    releaseLock "collecting"

    # wait for up to 5 hours for this stage
    if ! acquireLock "transmit" 300
    then
        echo $$ cannot lock "transmit"
        exit 1
    fi

    echo rsync to $REMOTE_HOST
    cd /snapshots
    time -p rsync -av --partial --append-verify --progress \
	${REMOTE_F}-${LOCAL_F}.snap.xz ${REMOTE_HOST}:/snapshots/
    releaseLock "transmit"
fi

date +%Y-%m-%d\ %H:%M:%S

# now 'receive' the snapshot at the remote
# time ssh cashapona 'xzcat /snapshots/pool2TB4K-test@initial-tank@2018-03-08.snap.xz|\
#      zfs receive pool2TB4K/test'
# wait for up to 5 hours for this stage
if ! acquireLock "receive" 300
then
    echo $$ cannot lock "receive"
    exit 1
fi

echo time -p ssh $REMOTE_HOST "xzcat /snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz \| \
         zfs receive $REMOTE_FILESYSTEM" 
time -p ssh $REMOTE_HOST "xzcat /snapshots/${REMOTE_F}-${LOCAL_F}.snap.xz | \
         zfs receive $REMOTE_FILESYSTEM" 

releaseLock "receive"

# report snapshots following send
echo
echo "after send/receive to ${REMOTE_HOST}"
ssh $REMOTE_HOST /sbin/zfs list
ssh $REMOTE_HOST /sbin/zfs list -d 1 -t snap -r $REMOTE_FILESYSTEM

echo "locally"
/sbin/zfs list
/sbin/zfs list -d 1 -t snap -r $FILESYSTEM

date +%Y-%m-%d\ %H:%M:%S

if [ "$AFTER_HOOK" != "" ]
then
    echo executing AFTER_HOOK $AFTER_HOOK
    $AFTER_HOOK
fi
date +%Y-%m-%d\ %H:%M:%S

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
