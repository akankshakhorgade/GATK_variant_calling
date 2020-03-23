#!/bin/bash

source /broad/software/scripts/useuse

use Anaconda

# Utility for Parsing JSON File
function json_extract() {
  local key=$1
  local json=$2

  local string_regex='"([^"\]|\\.)*"'
  local number_regex='-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?'
  local value_regex="${string_regex}|${number_regex}|true|false|null"
  local pair_regex="\"${key}\"[[:space:]]*:[[:space:]]*(${value_regex})"

  if [[ ${json} =~ ${pair_regex} ]]; then
    echo $(sed 's/^"\|"$//g' <<< "${BASH_REMATCH[1]}")
  else
    return 1
  fi
    }

# Extract Variables 
json=$1
app=$(json_extract app "$(cat ${json})")
temp_dir=$(json_extract temp_dir "$(cat ${json})")

source activate "${app}/MultiQC/MultiQC_env"
multiqc -o ${temp_dir} ${temp_dir}/fastq/
source deactivate