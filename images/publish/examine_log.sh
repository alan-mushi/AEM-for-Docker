#!/bin/bash

# Examine the log file passed as $1 and wait for the $2 expression to match, then quit.

tail -F "$1" | while read LOGLINE ; do
	echo "$LOGLINE" | grep -q "$2"

	if [ $? -eq 0 ] ; then
		pkill -P $$ tail 
		break
	fi
done

echo "exiting call $@"
