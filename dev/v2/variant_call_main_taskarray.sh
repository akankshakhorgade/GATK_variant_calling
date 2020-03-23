#!/bin/bash

source /broad/software/scripts/useuse

use BWA
use Bowtie2
use Java-1.8
use Picard-Tools
use Anaconda
use Samtools
use BEDTools

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
cores=$(json_extract cores "$(cat ${json})")
hg19_ref=$(json_extract hg19_ref "$(cat ${json})")
tool=$(json_extract tool "$(cat ${json})")
runid=$(json_extract runid "$(cat ${json})")
ref_path=$(json_extract ref_path "$(cat ${json})")
dict=$(json_extract dict "$(cat ${json})")
gatk=$(json_extract gatk "$(cat ${json})")
temp_dir=$(json_extract temp_dir "$(cat ${json})")

# Parse metafile
myline=$(sed -n "${SGE_TASK_ID}"p ${metafile})
read -ra INFO <<<"$myline"

sampleid=${INFO[1]} ## Check against metafile
bampath=${INFO[0]} ## check against metafile

### hg19 alignment - host removal
# map to Bowtie2 hg19 db index
bowtie2 -x ${hg19_ref} -1 ${temp_dir}/fastq/${sampleid}.1.fq -2 ${temp_dir}/fastq/${sampleid}.2.fq | samtools view -bS -> ${temp_dir}/${sampleid}.mapAndUnmapped.hg19.bam
# filter out reads unmapped to hg19
samtools view -b -f 12 -F 256 ${temp_dir}/${sampleid}.mapAndUnmapped.hg19.bam > ${temp_dir}/${sampleid}.unmapped.bam
# sort BAM file by read name (-n) to have reads next to each other [required by bedtools]
samtools sort -n ${temp_dir}/${sampleid}.unmapped.bam -o ${temp_dir}/${sampleid}.unmapped.sorted.bam
# BAM to FASTQ files
use BEDTools
bedtools bamtofastq -i ${temp_dir}/${sampleid}.unmapped.sorted.bam -fq ${temp_dir}/fastq/${sampleid}.hostRemoved.1.fq -fq2 ${temp_dir}/fastq/${sampleid}.hostRemoved.2.fq

### PFal Alignment
bwa mem -t ${cores} \
-R "@RG\\tID:FLOWCELL_${sampleid}\\tSM:${sampleid}\\tPL:ILLUMINA\\tLB:LIB_${sampleid}" ${ref_path} \
${temp_dir}/fastq/${sampleid}.hostRemoved.1.fq ${temp_dir}/fastq/${sampleid}.hostRemoved.2.fq | samtools view -bS -> ${temp_dir}/${sampleid}.aligned.bam

### Sort BAM
java -Xmx8G -jar $PICARD SortSam I=${temp_dir}/${sampleid}.aligned.bam \
O=${temp_dir}/${sampleid}.sorted.bam \
SO=coordinate

### Mark Duplicates
java -Xmx8G -jar $PICARD MarkDuplicates I=${temp_dir}/${sampleid}.sorted.bam \
O=${temp_dir}/${sampleid}.marked_duplicates.bam \
M=${temp_dir}/${sampleid}.marked_duplicates.metrics

### Re-order BAM
java -Xmx8G -jar $PICARD ReorderSam I=${temp_dir}/${sampleid}.marked_duplicates.bam \
O=${temp_dir}/${sampleid}.reordered.bam R=${ref_path} SD=${dict}
samtools index ${temp_dir}/${sampleid}.reordered.bam

### Read Metrics / Picard Metrics / DepthOfCoverage
# Multiple Metrics
Picard Multiple Metrics
java -jar $PICARD CollectMultipleMetrics I=${temp_dir}/${sampleid}.reordered.bam \
O=${temp_dir}/${sampleid}_multiple_metrics \
R=${ref_path}

# Parse Multiple metrics and add some new ones
python ${tool}/QC_subProc.py --sample_path ${temp_dir}/${sampleid}.reordered.bam \
--sampleid ${sampleid} --reference ${ref_path} --path_to_picard $PICARD \
--path_to_gatk3 ${gatk} \
--path_to_dir ${temp_dir} --output_file ${run_dir}/${runid}_qc_summary.txt

### GATK Variant calling
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


### Cleanup
rm ${temp_dir}/fastq/${sampleid}.1.fq
rm ${temp_dir}/fastq/${sampleid}.2.fq
rm ${temp_dir}/${sampleid}.aligned.bam
rm ${temp_dir}/${sampleid}.sorted.bam
rm ${temp_dir}/${sampleid}.marked_duplicates.bam
rm ${temp_dir}/${sampleid}.unmapped.bam
rm ${temp_dir}/${sampleid}.marked_duplicates.metrics
rm ${temp_dir}/${sampleid}.reordered.bam
rm ${temp_dir}/${sampleid}.reordered.bam.bai
rm ${temp_dir}/${sampleid}.interval_list
rm ${temp_dir}/${sampleid}.indels_realigned.bam
rm ${temp_dir}/${sampleid}.indels_realigned.bam.bai
rm ${temp_dir}/${sampleid}.indels_realigned.bai
rm ${temp_dir}/${sampleid}_recal_report.grp
rm ${temp_dir}/${sampleid}.bqsr.bam
rm ${temp_dir}/${sampleid}.bqsr.bam.bai