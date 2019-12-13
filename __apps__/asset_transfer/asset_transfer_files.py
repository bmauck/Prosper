import pandas as pd

project = 'data-lake-prod-223818'


def get_loans(tape_filename):
    loans = pd.read_csv(tape_filename)
    loans = tuple(loans['LoanNumber'])
    return loans


def get_intent_data(loans):
    sql_intent = open('M:/CapitalMarkets/__apps__/asset_transfer/sql/intent_csv.sql', 'r')
    sql_intent = sql_intent.read()
    
    df_intent = pd.read_gbq(sql_intent.format(loans), project_id=project)
    df_intent.to_csv('M:/CapitalMarkets/__apps__/asset_transfer/out-files/intent.csv', index=False)
    

def get_transfer_data(buyer, loans):
    sql_transfer = open('M:/CapitalMarkets/__apps__/asset_transfer/sql/transfer_csv.sql', 'r')
    sql_transfer = sql_transfer.read()
    
    df_transfer = pd.read_gbq(sql_transfer.format(buyer, loans), project_id=project)
    df_transfer.to_csv('M:/CapitalMarkets/__apps__/asset_transfer/out-files/transfer.csv', index=False)
