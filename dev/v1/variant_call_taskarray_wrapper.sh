#!/bin/bash

source /broad/software/scripts/useuse
source /seq/plasmodium/tools/malaria_variant_calling/json_parse.sh

use UGER
use BWA
use Bowtie2
use Java-1.8
use Picard-Tools
use Anaconda
use Samtools

json=$1

run_dir=$(json_extract run_dir "$(cat ${json})")
tool=$(json_extract tool "$(cat ${json})")
temp_dir=${run_dir}/other_files
cores=$(json_extract cores "$(cat ${json})")
tasks=$(json_extract tasks "$(cat ${json})")
hg19_ref=$(json_extract hg19_ref "$(cat ${json})")
runid=$(json_extract runid "$(cat ${json})")
#cores=8
#tool="/seq/plasmodium/tools/malaria_variant_calling"
#app="/cil/shed/apps/external"
#gatk="/humgen/gsa-hpprojects/GATK/bin/GenomeAnalysisTK-3.5-0-g36282e4/GenomeAnalysisTK.jar"
#run_dir="/seq/plasmodium/test/test2"
#runid="testrun1"
#ref_path="/gsap/garage-protistvector/U19_Aim4/REF/PlasmoDB-28_Pfalciparum3D7_Genome.fasta"
#dict="/gsap/garage-protistvector/U19_Aim4/REF/PlasmoDB-28_Pfalciparum3D7_Genome.dict"
#temp_dir=${run_dir}/other_files
#raw_fq=1
#hg19_ref="/seq/plasmodium/data/refs/hg19_db/hg19_db"
#metafile=${run_dir}/bam_meta.tsv

# assign columns for summary file
colnames="sampleid\tmaxCoverage_GC\tmean_insert_size\ttotal_reads\treads_aln\treads_aln_pct\tread_pair_duplicates\tpct_duplication\tnon_duplicate_reads\t%_bases_above_5\tmean_depth"

# make directories
mkdir ${run_dir}/other_files
mkdir ${run_dir}/gvcf
mkdir ${temp_dir}/fastq
echo -e  ${colnames} >  ${run_dir}/${runid}_qc_summary.txt
chmod 777 ${run_dir}/${runid}_qc_summary.txt
### Run Task Array for Bam to Fq conversion
stepone=$( qsub -terse -j y -cwd -l h_vmem=12G -l h_rt=24:00:00 -t 1-${tasks} ${tool}/variant_call_prefq_taskarray.sh ${json} /usr/bin/sleep 60 | awk -F. '{print $1}' ) 
steptwo=$( qsub -terse -pe smp ${cores} -binding linear:${cores} -j y -cwd -hold_jid $stepone -l h_vmem=16G -l h_rt=48:00:00 -t 1-${tasks} ${tool}/variant_call_main_taskarray.sh ${json} /usr/bin/sleep 60 | awk -F. '{print $1}' )
qsub -j y -cwd -hold_jid $steptwo ${tool}/qc_with_gsheets.sh /usr/bin/sleep 60


# Run variant calling workflow task array
#bash ${tool}/variant_call_main_taskarray.sh ${sampleid} ${temp_dir} ${hg19_ref} ${ref_path} ${runid} ${gatk} ${dict} ${tool}
