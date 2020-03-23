import gspread
import argparse
import pandas as pd
from datetime import datetime
from oauth2client.service_account import ServiceAccountCredentials


def main():
    parser = argparse.ArgumentParser(description='Script to upload final summary QC metrics ouput of the malaria_variant_calling pipeline to Google Sheet')
    parser.add_argument('--qc_metrics_file', required=True, help="Path to final qc_summary_metrics.txt")
    parser.add_argument('--runid', default=None, help="Name of the runid, if not passed defaulted to 'vcp_mdY_HMS'")
    parser.add_argument('--new', action="store_true", help="If 'new' present, will create a new google sheet")
    args = parser.parse_args()

    df_metrics=pd.DataFrame()
    df_metrics=pd.read_csv(args.qc_metrics_file, sep='\t')
    if args.runid:
        df_metrics.insert(0,'runid',args.runid,allow_duplicates=True)
    else:
        df_metrics.insert(0,'runid','vcp_'+dtstamp,allow_duplicates=True)
    list_metrics=df_metrics.values.tolist()
    ss.values_append(sheetName, {'valueInputOption': 'USER_ENTERED'}, {'values': list_metrics})



if __name__ == '__main__': 
   #googlesheet parameters
    JSON_CRED_PATH='/seq/plasmodium/tools/malaria_variant_calling/malaria-variant-calling-904d2f9c9249.json'

    scope = ['https://spreadsheets.google.com/feeds',
    'https://www.googleapis.com/auth/drive']

    gsheetId = '1yWtyLhrNoLnVDydQI86vk-r3vbcj2_62ZaTVf2VfsHU'
    gsheetname = 'malaria_variant_calling' #name of the speadsheet
    sheetName = 'master'   #name of the worksheet within the spreadsheet

    credentials = ServiceAccountCredentials.from_json_keyfile_name(JSON_CRED_PATH, scope)
    gc = gspread.authorize(credentials)
    ss = gc.open_by_key(gsheetId)
    sheetId = ss.worksheet("master")._properties['sheetId']  #master is name of the worksheet

    #for datetimestamp
    now = datetime.now()
    dtstamp=now.strftime("%m%d%Y_%H%M%S")
    main()
