#!/bin/bash

path_to_fq=${1}
app="/cil/shed/apps/external"
fastqc="${app}/FastQC/fastqc"

fastqarray=(`find ${path_to_fq} -maxdepth 1 -name "*.fastq"`)
fqarray=(`find ${path_to_fq} -maxdepth 1 -name "*.fq"`)

if [ ${#fastqarray[@]} -gt 0 ]; then 
    chkzip=(`find ${path_to_fq} -maxdepth 1 -name "*.zip"`)
    if [ ${#chkzip[@]} -gt 0 ]; then
    	echo "QC report already found; skipping FastQC step"
    else
    	${fastqc} ${path_to_fq}/*.fastq
    fi
elif [ ${#fqarray[@]} -gt 0  ]; then 
    chkzip=(`find ${path_to_fq} -maxdepth 1 -name "*.zip"`)
    if [ ${#chkzip[@]} -gt 0 ]; then
    	echo "QC report already found; skipping FastQC step"
    else
    	${fastqc} ${path_to_fq}/*.fq
    fi

else
	echo >&2 "Fastq files not found in the directory ${path_to_fq}"
	exit 1
fi

fqcarray=(`find ${path_to_fq} -maxdepth 1 -name "*.zip"`)
if [ ${#fqcarray[@]} -gt 0 ]; then
	source activate "${app}/MultiQC/MultiQC_env"
	multiqc -o ${path_to_fq} ${path_to_fq}
	source deactivate
else 
	echo "skipping multiqc since no fastqc report found"
fi
