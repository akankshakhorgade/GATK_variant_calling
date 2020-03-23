#!/bin/bash

source /broad/software/scripts/useuse
source ./json_parse.sh

json=$1

run_dir=$(json_extract run_dir "$(cat ${json})")
tool=$(json_extract tool "$(cat ${json})")
temp_dir=${run_dir}/other_files
cores=$(json_extract cores "$(cat ${json})")
tasks=$(json_extract tasks "$(cat ${json})")

echo ${run_dir}
echo ${tool}
echo ${temp_dir}
echo ${cores}
echo ${tasks}