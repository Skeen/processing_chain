#!/bin/bash

RUNS=($(echo $1))

TMP=$(mktemp)

mkdir -p output_resume

for RUN in ${RUNS[@]}
do
	for i in {1..2}
	do
		rm input -rf
		make clean
		./pick.sh $RUN > $TMP
		./picks_copy.sh $TMP
		mkdir input
		ls jobs | sed 's/.jobfile/.raw/g' > input/FILES
		touch input/REGEX
		make -j8 resume
		mv output/render/resume.json output_resume/split${RUN}_index${i}.json
	done
done
