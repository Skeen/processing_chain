#!/bin/bash

if [ "$#" -lt 1 ]; then
	echo "Usage: picks_copy.sh input " 0>&2
	exit
fi

INPUT=$(cat $1)
DATA_FOLDER="data"

rm $DATA_FOLDER -rf
mkdir $DATA_FOLDER

for SITE in ${INPUT[@]}
do
	cp data_in/${SITE}* $DATA_FOLDER/
done

