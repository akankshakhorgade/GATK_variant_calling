#!/bin/bash

source /broad/software/scripts/useuse

use Anaconda

raw_fq=1
app="/cil/shed/apps/external"
runid="testrun1"
run_dir="/seq/plasmodium/test/test2"
temp_dir=${run_dir}/other_files
tool="/seq/plasmodium/tools/malaria_variant_calling"

# Run MultiQC (optional)
if [ ${raw_fq} -eq 1 ]; then
    source activate "${app}/MultiQC/MultiQC_env"
	multiqc -o ${temp_dir} ${temp_dir}/fastq/
	source deactivate
else
    echo "raw fastq files not mentioned: skipping multiqc"
fi

#calling the python script
if [[ -z "$runid" ]]
then
	python ${tool}/gsheet_mal_var_call.py --qc_metrics_file ${run_dir}/${runid}_qc_summary.txt
else
	python ${tool}/gsheet_mal_var_call.py --qc_metrics_file ${run_dir}/${runid}_qc_summary.txt --runid $runid
fi
