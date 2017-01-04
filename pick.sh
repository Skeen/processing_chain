#!/bin/bash

# How many percentage to pick out
PERCENTAGE=$1
# Check validity of the argument
if [ "$PERCENTAGE" -lt 1 ]; then
    echo "Cannot pick less than 1%" >&2
    exit 1
elif [ "$PERCENTAGE" -gt 100 ]; then
    echo "Cannot pick more than 100%" >&2
    exit 1
fi
# Data input folder, i.e. where to pull data from
DATA_IN=data
# Pull out all the ground-truths
SITES=$(ls $DATA_IN | sed "s/\(.*\)_.*/\1/g" | uniq)
# Count the ground truths
NUM_SITES=$(echo "$SITES" | wc -l)
# Count the number of ground truths to pick
NUM_TO_PICK=$(echo "$NUM_SITES /100 * $PERCENTAGE" | bc)

# Print out information
echo "$NUM_SITES sites found"
echo "${PERCENTAGE}% of sites will be picked ($NUM_TO_PICK sites)"


