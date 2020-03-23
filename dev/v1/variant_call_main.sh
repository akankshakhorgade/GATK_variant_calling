#!/bin/bash

source /broad/software/scripts/useuse

use BWA
use Java-1.8
use Picard-Tools
use Anaconda
use Samtools
#source activate /home/unix/akhorgad/.conda/envs/mal_var_call

cores=8
cwd=$(pwd)
gatk="/humgen/gsa-hpprojects/GATK/bin/GenomeAnalysisTK-3.5-0-g36282e4/GenomeAnalysisTK.jar"
run_dir="/seq/plasmodium/test"
ref_path="/seq/plasmodium/panchal/reference_genome/pf3d7_genome.fasta"
dict="/seq/plasmodium/panchal/reference_genome/pf3d7_genome.dict"
outdir=${metadir}
raw_fq=1

# assign columns for summary file
colnames="sampleid\tmaxCoverage_GC\tmean_insert_size\ttotal_reads\treads_aln\treads_aln_pct\tread_pair_duplicates\tpct_duplication"

# make directories
mkdir ${run_dir}/other_files
mkdir ${run_dir}/gvcf
temp_dir=${run_dir}/other_files
mkdir ${temp_dir}/fastq
echo -e  ${colnames} >  ${temp_dir}/qc_summary.txt

# Create meta on bams
#python ${base_path}create_meta.py --path_to_bam ${path_to_bam} --path_to_output ${metadir}
metafile=${run_dir}/bam_meta.tsv

while IFS=$'\t' read -r -a array_meta
do
 bampath="${array_meta[1]}"
 sampleid="${array_meta[2]}"
 
 # Bam to fastq
 java -Xmx12G -jar $PICARD SamToFastq INPUT=${bampath} \
 FASTQ=${temp_dir}/fastq/${sampleid}.1.fq \
 SECOND_END_FASTQ=${temp_dir}/fastq/${sampleid}.2.fq \
 VALIDATION_STRINGENCY=LENIENT

done < ${metafile}

# MultiQC if raw fastqs provided
if [ ${raw_fq} -eq 1 ]; then
    bash multiqc.sh ${temp_dir}/fastq
else
    echo "raw fastq files not mentioned: skipping multiqc"
fi

while IFS=$'\t' read -r -a array_meta
do
 bampath="${array_meta[1]}"
 sampleid="${array_meta[2]}"

 # PFal Alignment
 bwa mem -t ${cores} \
 -R "@RG\\tID:FLOWCELL_${sampleid}\\tSM:${sampleid}\\tPL:ILLUMINA\\tLB:LIB_${sampleid}" ${ref_path} \
 ${temp_dir}/fastq/${sampleid}.1.fq ${temp_dir}/fastq/${sampleid}.2.fq | samtools view -bS -> ${temp_dir}/${sampleid}.aligned.bam

# Sort BAM
java -Xmx8G -jar $PICARD SortSam I=${temp_dir}/${sampleid}.aligned.bam \
O=${temp_dir}/${sampleid}.sorted.bam \
SO=coordinate

# Mark Duplicates
java -Xmx8G -jar $PICARD MarkDuplicates I=${temp_dir}/${sampleid}.sorted.bam \
O=${temp_dir}/${sampleid}.marked_duplicates.bam \
M=${temp_dir}/${sampleid}.marked_duplicates.metrics

# Re-order BAM
java -Xmx8G -jar $PICARD ReorderSam I=${temp_dir}/${sampleid}.marked_duplicates.bam \
O=${temp_dir}/${sampleid}.reordered.bam R=${ref_path} SD=${dict}
samtools index ${temp_dir}/${sampleid}.reordered.bam

# Read Metrics / Picard Metrics / DepthOfCoverage
bash other_metrics.sh ${temp_dir} ${sampleid} ${ref_path}

# GATK RealignerTargetCreator
java -Xmx8G -jar ${gatk} -T RealignerTargetCreator -nct 1 -nt ${cores} \
-R ${ref_path} -I ${temp_dir}/${sampleid}.reordered.bam \
-o ${temp_dir}/${sampleid}.interval_list

# GATK IndelRealigner
java -Xmx4G -jar ${gatk} -T IndelRealigner -nct 1 -nt 1 \
-R ${ref_path} -I ${temp_dir}/${sampleid}.reordered.bam \
-targetIntervals ${temp_dir}/${sampleid}.interval_list \
-o ${temp_dir}/${sampleid}.indels_realigned.bam
samtools index ${temp_dir}/${sampleid}.indels_realigned.bam

# GATK BaseRecalibrator
java -Xmx4G -jar ${gatk} -T BaseRecalibrator -nct 8 -nt 1 \
-R ${ref_path} -I ${temp_dir}/${sampleid}.indels_realigned.bam \
-knownSites /gsap/garage-protistvector/U19_Aim4/Pf3K/7g8_gb4.combined.final.vcf.gz \
-knownSites /gsap/garage-protistvector/U19_Aim4/Pf3K/hb3_dd2.combined.final.vcf.gz \
-knownSites /gsap/garage-protistvector/U19_Aim4/Pf3K/3d7_hb3.combined.final.vcf.gz \
-o ${temp_dir}/${sampleid}_recal_report.grp

# GATK Print Reads (BaseRecalibrator)
java -Xmx4G -jar ${gatk} -T PrintReads -nct 8 -nt 1 \
-R ${ref_path} -I ${temp_dir}/${sampleid}.indels_realigned.bam \
-BQSR ${temp_dir}/${sampleid}_recal_report.grp \
-o ${temp_dir}/${sampleid}.bqsr.bam
samtools index ${temp_dir}/${sampleid}.bqsr.bam

# GATK HaplotypeCaller
java -Xmx8G -jar ${gatk} -T HaplotypeCaller -nt 1 \
-R ${ref_path} --input_file ${temp_dir}/${sampleid}.bqsr.bam \
-ERC GVCF -ploidy 2 --interval_padding 100 -o ${run_dir}/gvcf/${sampleid}.g.vcf \
-variant_index_type LINEAR -variant_index_parameter 128000

# Cleanup
#rm ${temp_dir}/fastq/${sampleid}.1.fq
#rm ${temp_dir}/fastq/${sampleid}.2.fq
#rm ${temp_dir}/${sampleid}.aligned.bam
#rm ${temp_dir}/${sampleid}.sorted.bam
#rm ${temp_dir}/${sampleid}.marked_duplicates.bam
#rm ${temp_dir}/${sampleid}.marked_duplicates.metrics
#rm ${temp_dir}/${sampleid}.reordered.bam
#rm ${temp_dir}/${sampleid}.reordered.bam.bai
#rm ${temp_dir}/${sampleid}.interval_list
#rm ${temp_dir}/${sampleid}.indels_realigned.bam
#rm ${temp_dir}/${sampleid}.indels_realigned.bam.bai
#rm ${temp_dir}/${sampleid}.indels_realigned.bai
#rm ${temp_dir}/${sampleid}_recal_report.grp

done < ${metafile}

