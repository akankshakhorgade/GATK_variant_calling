import os
import gspread
import argparse
import pandas as pd
from datetime import datetime
from oauth2client.service_account import ServiceAccountCredentials


def main():
    parser = argparse.ArgumentParser(description='Script to upload final summary QC metrics ouput of the malaria_variant_calling pipeline to Google Sheet')
    parser.add_argument('--qc_metrics_file', required=True, help="Path to final qc_summary_metrics.txt")
    parser.add_argument('--runid', default=None, help="Name of the runid, if not passed defaulted to 'vcp_mdY_HMS'")
    parser.add_argument('--json_creds', required=True, help="Path to the JSON credentials file for the Google Service Account linked" )
    parser.add_argument('--gsheet_id', required=True, help="Google Sheet identification number" )
    parser.add_argument('--gsheet_name', required=True, help="Google Sheet identification name" )
    parser.add_argument('--gworksheet_name', required=True, help="Google Worksheet name" )
    parser.add_argument('--new', action="store_true", help="If 'new' present, will create a new google sheet")
    args = parser.parse_args()


    if (os.path.exists(args.json_creds)):
    	JSON_CRED_PATH = args.json_creds
    else:
    	print(os.path.basename(JSON_CRED_PATH) + ": file doesn't exist.")
    	print("Please provide a valid JSON credentials file.")

    scope = ['https://spreadsheets.google.com/feeds', 
    'https://www.googleapis.com/auth/drive']

    #googlesheet parameters
    gsheetId = args.gsheet_id
    gsheetname = args.gsheet_name #name of the speadsheet
    sheetName = args.gworksheet_name   #name of the worksheet within the spreadsheet

    credentials = ServiceAccountCredentials.from_json_keyfile_name(JSON_CRED_PATH, scope)
    gc = gspread.authorize(credentials)
    ss = gc.open_by_key(gsheetId)
    sheetId = ss.worksheet("master")._properties['sheetId']  #master is name of the worksheet

    df_metrics=pd.DataFrame()
    df_metrics=pd.read_csv(args.qc_metrics_file, sep='\t')
    if args.runid:
        df_metrics.insert(0,'runid',args.runid,allow_duplicates=True)
    else:
        df_metrics.insert(0,'runid','vcp_'+dtstamp,allow_duplicates=True)
    list_metrics=df_metrics.values.tolist()
    ss.values_append(sheetName, {'valueInputOption': 'USER_ENTERED'}, {'values': list_metrics})


if __name__ == '__main__': 
    #for datetimestamp
    now = datetime.now()
    dtstamp=now.strftime("%m%d%Y_%H%M%S")
    main()
