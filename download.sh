#!/bin/bash

# Every step depends on the previous one
set -e

download_dataset()
{
    INPUT_REGEX=$1
    OUTPUT_FOLDER=$2
    echo -e "Downloading file index to $OUTPUT_FOLDER...\c"
    # Download the Set
    ssh root@skeen.website "ls reading_reciever/symlinks/$INPUT_REGEX/" > $OUTPUT_FOLDER/FILES
    echo $INPUT_REGEX > $OUTPUT_FOLDER/REGEX
    echo "OK"
}

usage()
{
    echo "Usage: ./download.sh 'INPUT_REGEX'"
}

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

## Download the datasets
echo ""
echo ""
echo "Downloading datasets"
mkdir -p input/
download_dataset "$INPUT_REGEX" "input"
