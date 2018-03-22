#!/bin/sh
# required arguments lock_name time_to_wait_min time_to_hold_sec

# suggeted test command
# ./test_lock.sh lock_test 1 10 &  ./test_lock.sh lock_test 1 10
# ./test_lock.sh lock_test 1 70 &  ./test_lock.sh lock_test 1 70

if [ $# -ne 3 ]
then
    echo "Usage $0 lock_name time_to_wait_min time_to_hold_sec"
    exit 1
fi

DIR=$1
WAIT=$2
HOLD=$3

echo DIR $DIR WAIT $WAIT HOLD $HOLD

. `dirname $0`/lock.sh || exit 1


cleanup()
{
  echo "Removing /tmp/test_dir"
  rm  -rf /tmp/$DIR
  exit 1
}

trap cleanup 1 2 3 6

echo $$ request $DIR at `date +%Y-%m-%d\ %H:%M:%S`
if acquireLock $DIR $WAIT
then
    echo $$ got lock at `date +%Y-%m-%d\ %H:%M:%S`
else
    echo $$ cannot get lock
    exit 1
fi

sleep $HOLD

releaseLock $DIR
echo $$ release $DIR at `date +%Y-%m-%d\ %H:%M:%S`
exit 0


