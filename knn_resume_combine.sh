#!/bin/bash

RUNS=($(echo $1))

IN=output_resume
OUT=../resume_out

mkdir -p $OUT
cd $IN

for RUN in ${RUNS[@]}
do
	echo "data" > ${OUT}/${RUN}.csv
	ls | grep split${RUN} | xargs cat | grep -Po '"accuracy":.*?,' | grep -o ":.*" | sed "s/^.//g" | sed 's/.$//g' >> ${OUT}/${RUN}.csv
done
