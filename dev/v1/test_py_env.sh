#!/bin/bash
source /broad/software/scripts/useuse
use Anaconda

runid="testrun1"
run_dir="/seq/plasmodium/test/test2"
tool="/seq/plasmodium/tools/malaria_variant_calling"


if [[ -z "$runid" ]]
then
	python ${tool}/gsheet_mal_var_call.py --qc_metrics_file ${run_dir}/${runid}_qc_summary.txt
else
	python ${tool}/gsheet_mal_var_call.py --qc_metrics_file ${run_dir}/${runid}_qc_summary.txt --runid $runid
fi

