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
runid=$(json_extract runid "$(cat ${json})")
run_dir=$(json_extract run_dir "$(cat ${json})")
tool=$(json_extract tool "$(cat ${json})")
json_cred=$(json_extract json_cred "$(cat ${json})")
gsheetId=$(json_extract gsheetId "$(cat ${json})")
gsheetname=$(json_extract gsheetname "$(cat ${json})")
sheetName=$(json_extract sheetName "$(cat ${json})")

source activate /seq/plasmodium/tools/conda_envs/mal_var_call_env
#calling the python script
if [[ -z "$runid" ]]
then
	python ${tool}/gsheet_mal_var_call.py --qc_metrics_file ${run_dir}/${runid}_qc_summary.txt --json_creds ${json_cred} --gsheet_id ${gsheetId} --gsheet_name ${gsheetname} --gworksheet_name ${sheetName} 
else
	python ${tool}/gsheet_mal_var_call.py --qc_metrics_file ${run_dir}/${runid}_qc_summary.txt --runid ${runid} --json_creds ${json_cred} --gsheet_id ${gsheetId} --gsheet_name ${gsheetname} --gworksheet_name ${sheetName}
fi

source deactivate
