#!/usr/bin/env python
import argparse
import pandas as pd
import numpy as np
import os, fnmatch

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument('--path_to_bam', required=True, help="Path to bam files")
	parser.add_argument('--path_to_output', required=True, help="Path to output meta file")
	#parser.add_argument('--name', required=True, help="Name of the Run")

	args = parser.parse_args()

	pathdir = args.path_to_bam
	odir = args.path_to_output + "/bam_meta.tsv"
	meta_df = pd.DataFrame({'sampleid' : [], 'input_path' : []})
	bamlist = os.listdir(pathdir)
	pattern = "*.bam"
	for entry in bamlist:
		if fnmatch.fnmatch(entry, pattern):
			ipath = pathdir + "/" + entry
			sampleid = entry.split(".",1)[0]
			df = pd.DataFrame({'sampleid' : [sampleid], 'input_path' : [ipath]})
			meta_df = meta_df.append(df, ignore_index=True)
	meta_df.to_csv(odir, sep = "\t")
	print( "meta file generated at " + odir )
	return()

if __name__ == "__main__":
	main()