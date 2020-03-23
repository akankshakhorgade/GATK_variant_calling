# malaria_variant_calling


INTEGRATING GOOGLE SHEETS API:

To install gspread client, we'll need an updated version of setuptools
	pip install --upgrade setuptools

Note: To install 'pip' if required:
	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
	python get-pip.py


#Writing the results from summary metrics to google sheet
echo "Please Note: additional python packages may be installed to upload the results from the run to gsheet.
Please don't exit while the enviornment intiates."
#intiating the python env required
	#using python pip
	pip install -r mal_var_call_requirements.txt 

	#using Anaconda
	conda create --name mal_var_call --file mal_var_call_requirements.txt
	source activate mal_var_cal

