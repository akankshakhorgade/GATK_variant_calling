#!/usr/bin/env python

import os
import sys
import warnings
import argparse
import numpy as np
import pandas as pd
#from google.cloud import storage
callableLoci="/seq/plasmodium/data/bed/Miles_2016_Pf3D7_core_only.bed"

def depthOfCoverage(path_to_gatk3, sampleid, ipath, refPath, output_dir):
    opath = output_dir + "/" + sampleid + "_depthofcoverage_summary"
    cmd=" ".join(["java -jar",path_to_gatk3,"-L",callableLoci,"-T DepthOfCoverage","--omitDepthOutputAtEachBase","--summaryCoverageThreshold 5","-I",ipath,"-o",opath,"-R",refPath])
    print (cmd)
    err = os.system(cmd)
    if err:
        return (('Execution of "%s" failed!\n') % cmd)
    else:
        return(opath)


# QC metrics wrapper
def qcheck(bamfile, sampleid, tmp_dir, refPath, path_to_picard, path_to_gatk3, output):
    qc_summary = pd.read_csv(output, sep='\t', nrows=0)
    qc2 = pd.DataFrame({'sampleid':[sampleid]})
    if os.path.isfile(bamfile):
        gc_met = collectGCBiasMetrics(path_to_picard, sampleid, bamfile, refPath, tmp_dir)
        ins_met = collectInsertSizeMetrics(path_to_picard, sampleid, bamfile, tmp_dir)
        doc_met = depthOfCoverage(path_to_gatk3, sampleid, bamfile, refPath, tmp_dir)
        outpath= doc_met+".sample_summary"
        if os.path.isfile(outpath):
            doc_df = pd.read_csv(outpath, sep = '\t')
            doc_5 = doc_df['%_bases_above_5'].iloc[0]
            doc_mean = doc_df['mean'].iloc[0]
            qc2['%_bases_above_5'] = doc_5
            qc2['mean_depth'] = doc_mean
        else:
            warnings.warn('Path to sampleid_depthofcoverage_summary.sample_summary file does not exist')
            qc2['%_bases_above_5'] = "NA"
            qc2['mean_depth'] = "NA"
        if os.path.isfile(gc_met):
            gc_df = pd.read_csv(gc_met, sep = '\t', skiprows = 6)
            maxgc = gc_df['NORMALIZED_COVERAGE'].idxmax()
            qc2['maxCoverage_GC'] = maxgc
        else:
            warnings.warn('Path to GcMetrics output File does not exist')
            qc2['maxCoverage_GC'] = "NA"
        if os.path.isfile(ins_met):
            ins_df = pd.read_csv(ins_met, sep = '\t', skiprows=6, nrows=1)
            qc2['mean_insert_size'] = ins_df['MEAN_INSERT_SIZE'][0]
            qc2['median_insert_size'] = ins_df['MEDIAN_INSERT_SIZE'][0]
        else:
            warnings.warn('Path to InsertsizeMetrics File does not exist')
            qc2['mean_insert_size'] = "NA"
            qc2['median_insert_size'] = "NA"
    else:
    	raise Exception('Input bamfile not found')
    mpath = tmp_dir + "/" + sampleid + "_multiple_metrics.alignment_summary_metrics"
    if os.path.isfile(mpath):
        other_metrics = pd.read_csv(mpath, sep='\t',skiprows=6)
        qc2['total_reads'] = other_metrics['TOTAL_READS'][2]
        qc2['reads_aln'] = other_metrics['PF_READS_ALIGNED'][2]
        qc2['reads_aln_pct'] = other_metrics['PCT_PF_READS_ALIGNED'][2]
    else:
        warnings.warn('Other metrics file not found')
        qc2['total_reads'] = "NA"
        qc2['reads_aln'] = "NA"
        qc2['reads_aln_pct'] = "NA"
    dpath = tmp_dir + "/" + sampleid + ".marked_duplicates.metrics"
    if os.path.isfile(dpath):
        dup_metrics = pd.read_csv(dpath, sep='\t',skiprows=6, nrows=1)
        qc2['read_pair_duplicates'] = dup_metrics['READ_PAIR_DUPLICATES'][0]
        qc2['pct_duplication'] = dup_metrics['PERCENT_DUPLICATION'][0]
        qc2['non_duplicate_reads'] = dup_metrics['READ_PAIRS_EXAMINED'][0] - dup_metrics['READ_PAIR_DUPLICATES'][0]
    else:
        warnings.warn('Duplication metrics file not found')
        qc2['read_pair_duplicates'] = "NA"
        qc2['pct_duplication'] = "NA"
        qc2['non_duplicate_reads'] = "NA"
    qc_summary = qc_summary.append(qc2[['sampleid', 'maxCoverage_GC', 'mean_insert_size', 'median_insert_size','total_reads', 'reads_aln', 'reads_aln_pct', 'read_pair_duplicates', 'pct_duplication', 'non_duplicate_reads','%_bases_above_5', 'mean_depth']])
    qc_summary.to_csv(output, mode='a', sep='\t', header=False,index=False)
    return()

# to compute GC Bias Metrics
def collectGCBiasMetrics(path_to_picard, sampleid, ipath, refPath, output_dir):
    opath = output_dir + "/" + sampleid + "_gc_bias_metrics.txt"
    chart = " CHART_OUTPUT=" + output_dir + "/" + sampleid + "_chart_output.pdf"
    summary = " s=" + output_dir + "/" + sampleid + "_summary_output.txt"
    cmd = "java -jar " + path_to_picard + " CollectGcBiasMetrics I=" + ipath + " O=" + opath + " R=" + refPath + chart + summary
    err = os.system(cmd)
    if err:
        print (('Execution of "%s" failed!\n') % cmd)
    return(opath)

# to compute Insert Size Metrics
def collectInsertSizeMetrics(path_to_picard, sampleid, ipath, output_dir):
    opath = output_dir + "/" + sampleid + "_insert_size_metrics.txt"
    hist = " HISTOGRAM_FILE=" + output_dir + "/" + sampleid + "_hist_file.txt"
    cmd = "java -jar " + path_to_picard + " CollectInsertSizeMetrics I=" + ipath + hist + " O=" + opath
    err = os.system(cmd)
    if err:
        print (('Execution of "%s" failed!\n') % cmd)
    return(opath)
