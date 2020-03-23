#!/bin/bash

source /broad/software/scripts/useuse

use Java-1.8
use Picard-Tools
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
run_dir=$(json_extract run_dir "$(cat ${json})")
metafile=$(json_extract metafile "$(cat ${json})")
raw_fq=$(json_extract raw_fq "$(cat ${json})")
trim=$(json_extract trim "$(cat ${json})")
temp_dir=$(json_extract temp_dir "$(cat ${json})")
app=$(json_extract app "$(cat ${json})")
fastqc="${app}/FastQC/fastqc"
trim_galore="${app}/TrimGalore-0.4.5/trim_galore"


# Parse metafile
myline=$(sed -n "${SGE_TASK_ID}"p ${metafile})
read -ra INFO <<<"$myline"

sampleid=${INFO[1]} ## Check against metafile
bampath=${INFO[0]} ## check against metafile

path_to_fq="${temp_dir}/fastq/${sampleid}"

# Bam to fastq
java -Xmx12G -jar $PICARD SamToFastq INPUT=${bampath} \
FASTQ=${path_to_fq}.1.fq \
SECOND_END_FASTQ=${path_to_fq}.2.fq \
VALIDATION_STRINGENCY=LENIENT

# Run fastQC on obtained fq files (optional)
if [ ${raw_fq} -eq 1 ]; then
	${fastqc} ${path_to_fq}.*.fq
else
	echo "Skipping fastqc step as per User request"
fi

# Run Trimgalore
if [ ${trim} -eq 1 ]; then
	${trim_galore} --paired -o ${temp_dir}/fastq/ ${path_to_fq}.1.fq ${path_to_fq}.2.fq
else
	echo "skip trimming as per User request"
fi
