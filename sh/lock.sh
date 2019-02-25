#!/bin/sh
#
# provide a kind of semaphore for shell scripts based on creating
# a directory - an atomic test/set operation. The PID of the acquiring 
# process is put in a file named `pid` in the directory created.
acquireLock() # dir minutes
{
    if [ $# -ne 2 ] # proper usage?
    then
        echo >&2 "wrong argument count $#"
        exit 1
    fi

    intervals=`expr $2 \* 4`  # timeout countdown

    # check every 15 seconds
    while
        if mkdir "/tmp/$1" 2>/dev/null
        then
            echo $$ >"/tmp/$1/pid"
            return 0    # acquired lock
        else            # check for dead process
            lock_pid=`cat "/tmp/$1/pid"`
        if ! ps -q  $lock_pid >/dev/null    # process not still running?
            then
                echo $$ >"/tmp/$1/pid"      # if not. claim the lock for ourselves
                return 0                    # acquired lock
           fi
        fi
        sleep 15
        intervals=`expr $intervals - 1`
         [ $intervals -gt 0 ]
    do :; done
    return 1 # could not acquire lock
}

releaseLock() # dir
{
     if [ $# -ne 1 ]  # proper usage?
    then
        echo >&2 "wrong argument count $#"
        exit 1
    fi

   if [ `cat /tmp/$1/pid` = $$ ]
    then
        rm -rf /tmp/$1
    else
        echo >&2 lock $1 held by another process `cat /tmp/$1/pid`
        exit 1
    fi
}
