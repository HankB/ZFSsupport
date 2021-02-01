#!/bin/sh
# run cleanup scripts from test directory
# Example cleanup script. Executes myzfs.pl locvally and remotely via ssh.

# cleanup on client
/usr/local/sbin/myzfs.pl -v -h client-host -f client-filesystem > /tmp/example-cleanup.lst 2>&1

# cleanup on server
ssh server-host /home/hbarta/testbin/myzfs.pl -v -f server-filesystem -h client-host > /tmp/exanple-cleanup-server-host.lst 2>&1
# Hope this is correct!