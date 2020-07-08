#!/usr/bin/env python
### Parses args that we provide to the shell - assigns a variable to the args provided
### REQUIRED


import argparse
import os

from variant_calling_modules_repo \
import collectGCBiasMetrics, \
collectInsertSizeMetrics, \
qcheck


def main():
    # init cmd-line parser
    parser = argparse.ArgumentParser()
    parser.add_argument('--sample_path', required=True, help="Path to sample bam file to run QC metrics")
    parser.add_argument('--sampleid', required=True, help="sampleid assigned to the bamfile")
    parser.add_argument('--reference', required=True, help="Path to the reference genome fasta file")
    parser.add_argument('--path_to_picard', required=True, help="Path to picard cmd line tools")
    parser.add_argument('--path_to_gatk3', required=True, help="Path to gatk3 cmd line tools")
    parser.add_argument('--path_to_dir', required=True, help="Path to intermediate files")
    parser.add_argument('--output_file', required=True, help="Path to the output directory")
    args = parser.parse_args()

    bamfile = args.sample_path
    sampleid = args.sampleid
    ref = args.reference
    picard = args.path_to_picard
    gatk3 = args.path_to_gatk3
    tmp_dir = args.path_to_dir
    outfile = args.output_file

    qcheck(bamfile, sampleid, tmp_dir, ref, picard, gatk3, outfile)

    return()
    
if __name__ == "__main__":
    main()
