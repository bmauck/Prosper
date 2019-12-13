import pandas as pd

project = 'data-lake-prod-223818'

tape_file = input('What is the full file path? ')
tape_sheet_name = input('What is the sheet name? ')
buyer = input('What is the buyer userID? ')

tape = pd.read_excel(tape_file, sheet_name=tape_sheet_name)
loans = tape['LoanNumber']

sql_intent = open('scripts/intent_csv.sql', 'r')
sql_intent = sql_intent.read()

df_intent = pd.read_gbq(sql_intent.format(loans), project_id=project)
df_intent.to_csv('out-files/intent.csv', index=False)

sql_transfer = open('scripts/transfer_csv.sql', 'r')
sql_transfer = sql_transfer.read()

df_transfer = pd.read_gqb(sql_transfer.format(buyer, loans), project_id=project)
df_transfer.to_csv('out-files/transfer.csv', index=False)
