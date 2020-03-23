#!/bin/bash

use Java-1.8
use Picard-Tools
use Anaconda

temp_dir=${1}
sampleid=${2}
ref_path=${3}
runid=${4}
tool=${5}

path_to_gatk3="/humgen/gsa-hpprojects/GATK/bin/GenomeAnalysisTK-3.5-0-g36282e4/GenomeAnalysisTK.jar"

Picard Multiple Metrics
java -jar $PICARD CollectMultipleMetrics I=${temp_dir}/${sampleid}.reordered.bam \
O=${temp_dir}/${sampleid}_multiple_metrics \
R=${ref_path}

python ${tool}/QC_subProc.py --sample_path ${temp_dir}/${sampleid}.reordered.bam \
--sampleid ${sampleid} --reference ${ref_path} --path_to_picard $PICARD --path_to_gatk3 $path_to_gatk3 \
--path_to_dir ${temp_dir} --output_file ${temp_dir}/${runid}_qc_summary.txt
