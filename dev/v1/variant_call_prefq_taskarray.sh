#!/bin/bash

source /broad/software/scripts/useuse
source /seq/plasmodium/tools/malaria_variant_calling/json_parse.sh

use Java-1.8
use Picard-Tools
use Anaconda

json=$1

run_dir=$(json_extract run_dir "$(cat ${json})")
metafile=$(json_extract metafile "$(cat ${json})")
raw_fq=$(json_extract raw_fq "$(cat ${json})")
trim=$(json_extract trim "$(cat ${json})")

#tool="/seq/plasmodium/tools/malaria_variant_calling"
#run_dir="/seq/plasmodium/test/test2"
temp_dir=${run_dir}/other_files
#raw_fq=1
#trim=1
#metafile=${run_dir}/bam_meta.tsv
app="/cil/shed/apps/external"
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
