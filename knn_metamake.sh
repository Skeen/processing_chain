#!/bin/bash

RUNS=($(echo $1))

TMP=$(mktemp)

for RUN in ${RUNS[@]}
do
	rm input -rf
	make clean
	./pick.sh $RUN > $TMP
	./picks_copy.sh $TMP
	mkdir input
	ls data > input/FILES
	touch input/REGEX
	make -j8
	mv output/render/resume.json output_resume_${RUN}_$RANDOM.json
done
