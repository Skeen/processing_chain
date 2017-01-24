#!/bin/bash

name=$1
var=0;
for file in `ls`
do
    var=$((var+1))
    echo "Renaming ${file} to ${name}_${var}.raw"
    mv ${file} ${name}_${var}.raw
done
