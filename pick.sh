#!/bin/bash

PERCENTAGE=$1

DATA_IN=data

SITES=$(ls $DATA_IN | sed "s/\(.*\)_.*/\1/g" | uniq)
NUM_SITES=$(echo "$SITES" | wc -l)
NUM_TO_PICK=$(echo "$NUM_SITES /100 * $PERCENTAGE" | bc)

echo "$NUM_SITES sites found"
echo "${PERCENTAGE}% of sites will be picked ($NUM_TO_PICK sites)"


