#!/bin/bash
# Author: Robert Nevanen <me@drox.in>

# Set the threshold for array usage (in percentage)
UPPER_THRESHOLD=90
LOWER_THRESHOLD=60

# Get current array usage
ARRAY_USAGE=$(df -h | grep '/mnt/cache' | awk '{print $5}' | cut -d'%' -f1)
PARITY_CHECK_STATUS=$(/usr/local/sbin/mdcmd status | sed -n 's/mdResync=//p')

IS_PARITY_CHECK_STARTED_1=$(/usr/local/sbin/mdcmd status | sed -n 's/mdResyncPos=//p')
IS_PARITY_CHECK_STARTED_2=$(/usr/local/sbin/mdcmd status | sed -n 's/mdResyncAction=//p')

# Check if array parity check is running
if [[ $IS_PARITY_CHECK_STARTED_1 -gt 0 && $IS_PARITY_CHECK_STARTED_2 == "check P" ]]; then
    # Check if cache usage exceeds the upper threshold
    if [[ "$ARRAY_USAGE" -ge "$UPPER_THRESHOLD" ]]; then
        # Check if parity check is paused
        if [[ "$PARITY_CHECK_STATUS" -gt 0 ]]; then
            echo "Pausing parity check"
            /usr/local/sbin/mdcmd nocheck pause
        fi
        # Invoke mover
        echo "Invoking mover"
        /usr/local/sbin/mover
    # Check if cache usage is under the lower threshold
    elif [[ "$ARRAY_USAGE" -lt "$LOWER_THRESHOLD" ]]; then
        if [[ "$PARITY_CHECK_STATUS" == 0 ]]; then
            echo "Resuming parity check"
            /usr/local/sbin/mdcmd check resume
        fi
    fi
fi
