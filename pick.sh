#!/bin/bash

if [ "$#" -lt 1 ]; then
	echo "Usage: pick.sh percentage > output. " 0>&2
	exit
fi

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
DATA_IN=data_in
# Pull out all the ground-truths
SITES=$(ls $DATA_IN | sed "s/\(.*\)_.*/\1/g" | uniq)
# Count the ground truths
NUM_SITES=$(echo "$SITES" | wc -l)
# Count the number of ground truths to pick
NUM_TO_PICK=$(echo "" | awk "{print int( ($NUM_SITES / 100 * $PERCENTAGE) + 0.5 ) }")
# Assert that we're picking atleast two samples
if [ "$NUM_TO_PICK" -lt 2 ]; then
    echo "Cannot pick $NUM_TO_PICK sites; less than 2 samples." >&2
    exit 1
fi

# Print out information
echo "$NUM_SITES sites found" >&2
echo "${PERCENTAGE}% of sites will be picked ($NUM_TO_PICK sites)" >&2

randArrayElement()
{ 
	arr=("${!1}");
	echo ${arr["$[RANDOM % ${#arr[@]}]"]};
}

ARR=($(echo "$SITES"))

for i in $(seq 1 $NUM_TO_PICK)
do
	VAR=$(randArrayElement "ARR[@]")
	delete=($(echo "${VAR}"))
	ARR=($(echo "${ARR[@]/$delete}"))
	echo $VAR
done
