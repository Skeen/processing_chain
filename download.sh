#!/bin/bash

# Every step depends on the previous one
set -e

download_dataset()
{
    INPUT_REGEX=$1
    OUTPUT_FOLDER=$2
    echo -e "Downloading $INPUT_REGEX > $OUTPUT_FOLDER/*...\c"
    # Download the Set
    scp root@skeen.website:/root/reading_reciever/symlinks/$INPUT_REGEX $OUTPUT_FOLDER 1>/dev/null
    echo "OK"
}

function timing {
    # Our timing command
    TIME_CMD="date +%s%N"
    # Start timing
    START_TIME=`$TIME_CMD`
    $@ # Run our argument
    END_TIME=`$TIME_CMD`
    # Find time elapsed and report
    RUN_TIME=$((END_TIME - START_TIME))
    echo "--> Took: $(($RUN_TIME/1000000))ms"
}

function ssh_agent {
    # Setup SSH agents
    if [ -z "$SSH_AUTH_SOCK" ] ; then
        # Start up the ssh-agent
        OUTPUT=$(ssh-agent -s)
        # Pick out the PID of the agent
        PID=$(echo "$OUTPUT" | grep "PID=" | sed "s/.*PID=\(.*\); .*/\1/g")
        #echo $PID
        # Evaluate the configuration provided by ssh-agent
        eval $OUTPUT >/dev/null
        # Add / Unlock our key
        ssh-add
    fi
}

function kill_ssh_agent {
    kill $PID
}

usage()
{
    echo "Usage: ./download.sh 'INPUT_REGEX'"
}

# Kill SSH-agent on Ctrl+C
trap kill_ssh_agent 2

# Check arguments provided
if [ $# -lt 1 ]; then
    echo ""
    echo "Fatal Error: Not enough arguments provided ($# < 1)"
    echo ""
    echo ""
    usage
    exit 1
fi

INPUT_REGEX=$1

# Get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Every runs local to the script
cd $DIR

## Start up the SSH-agent
echo ""
echo ""
echo "Starting ssh-agent" | boxes
ssh_agent

# Clean data folder
echo ""
echo ""
echo "Cleaning data folder" | boxes
rm -rf data

## Download the datasets
echo ""
echo ""
echo "Downloading datasets" | boxes
mkdir -p data/
timing download_dataset "$INPUT_REGEX" "data/"
kill_ssh_agent
