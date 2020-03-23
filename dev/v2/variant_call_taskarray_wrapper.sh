#!/bin/bash

source /broad/software/scripts/useuse

use UGER
use BWA
use Bowtie2
use Java-1.8
use Picard-Tools
use Anaconda
use Samtools

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
tool=$(json_extract tool "$(cat ${json})")
temp_dir=$(json_extract temp_dir "$(cat ${json})")
cores=$(json_extract cores "$(cat ${json})")
tasks=$(json_extract tasks "$(cat ${json})")
runid=$(json_extract runid "$(cat ${json})")


# assign columns for summary file
colnames="sampleid\tmaxCoverage_GC\tmean_insert_size\ttotal_reads\treads_aln\treads_aln_pct\tread_pair_duplicates\tpct_duplication\tnon_duplicate_reads\t%_bases_above_5\tmean_depth"

# make directories
mkdir ${run_dir}/other_files
mkdir ${run_dir}/gvcf
mkdir ${temp_dir}/fastq
# Create empty summary file with headers
echo -e  ${colnames} >  ${run_dir}/${runid}_qc_summary.txt
# Grant All permissions to the summary file
chmod 777 ${run_dir}/${runid}_qc_summary.txt

### Submit Task Arrays
stepone=$( qsub -terse -j y -cwd -l h_vmem=12G -l h_rt=24:00:00 -t 1-${tasks} ${tool}/variant_call_prefq_taskarray.sh ${json} /usr/bin/sleep 60 | awk -F. '{print $1}' ) 
steptwo=$( qsub -terse -pe smp ${cores} -binding linear:${cores} -j y -cwd -hold_jid $stepone -l h_vmem=16G -l h_rt=48:00:00 -t 1-${tasks} ${tool}/variant_call_main_taskarray.sh ${json} /usr/bin/sleep 60 | awk -F. '{print $1}' )
qsub -j y -cwd -hold_jid $stepone ${tool}/multiqc.sh ${json} /usr/bin/sleep 60
qsub -j y -cwd -hold_jid $steptwo ${tool}/qc_with_gsheets.sh ${json} /usr/bin/sleep 60
