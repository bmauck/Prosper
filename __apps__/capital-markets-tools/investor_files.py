import pandas as pd
import numpy as np
from tqdm import tqdm
import sqlalchemy
import datetime as dt
from tabulate import tabulate

dest_fld = 'out-files/'
db = 'ReportingProgrammability'
svr = '@dbrpt/{db}?driver=SQL+Server+Native+Client+11.0'.format(db=db)
engine = sqlalchemy.create_engine('mssql+pyodbc://'+svr)
today = (dt.date.today())


def write_file(report, filename):
    
    print('Writing Files...')
    report.to_csv(dest_fld+filename)
    print('Done')


def get_username_and_id(investor_name):
        
    sql = open('sql/current_username.sql', 'r')
    sql = sql.read()
    
    cxn = engine.connect()
    df = pd.read_sql_query(sql.format(investor_name), cxn)
    cxn.close()
    
    return df


class investor:

    def __init__(self, id):
        self.id = id
        
    def tape(self, date=today):
        
        print('Querying...')
    
        staging = open('sql/tape_staging.sql', 'r')
        result = open('sql/tape_result.sql', 'r')
    
        staging_sql = staging.read()
        result_sql = result.read()
    
        cxn = engine.connect()
        cxn.execute(staging_sql.format(date, date, self.id))
        df = pd.read_sql_query(result_sql, cxn)
        cxn.close()
        
        print('Done')
        
        return df

    def trxns(self, date1, date2):
        
        d1 = str('"'+date1+'"')
        d2 = str('"'+date2+'"')

        query = """
        exec Report_DailyLenderPacket_Transactions {}, {}, {}
        """.format(self.id, d1, d2)
        
        print('Querying...')
        cxn = engine.connect()
        df = pd.read_sql_query(query, cxn)
        cxn.close()
        
        print('Done')    
        
        return df
        

    def positions(self, date=today):
        
        d1 = str('"'+date+'"')
        d2 = str('"'+date+'"')

        query = """
        exec Report_DailyLenderPacket_Positions {}, {}, {}
        """.format(self.id, d1, d2)
        
        print('Querying...')
        cxn = engine.connect()
        df = pd.read_sql_query(query, cxn)
        cxn.close()
        
        print('Done')
        
        return df
        
 
    def remits(self, date1, date2):
    
        df = pd.DataFrame()
        dates = pd.date_range(date1, date2).tolist()
        
        print('Querying...')
        
        cxn = engine.connect()
        for day in tqdm(dates):
            d = str('"'+str(day.date())+'"')
            query = 'exec Report_DailyLenderPacket_Remit {}, {}'.format(self.id, d)
            p = pd.read_sql_query(query, cxn)
            df = df.append(p)
        cxn.close()
        
        print('Done')
        
        return df
        

    def pmts(self, date1, date2):
    
        d1 = str('"'+date1+'"')
        d2 = str('"'+date2+'"')

        query = """
        exec Report_DailyLenderPacket_Payments {}, {}, {}
        """.format(self.id, d1, d2)
        
        print('Querying...')
        
        cxn = engine.connect()
        df = pd.read_sql_query(query, cxn)
        cxn.close()
        
        print('Done')
        
        return df
    
    def strats(self, tape):
        tape_metrics = tape.groupby(['Term', 'ProsperRating']).apply(calc_strats)
        tape_metrics = tape_metrics.reindex(['AA', 'A', 'B', 'C', 'D', 'E', 'HR'], level=1)
        tape_metrics['Percent'] = tape_metrics['PrincipalBalance'] / tape_metrics['PrincipalBalance'].sum()

        return tape_metrics


def elig(tape):
    tape = tape.fillna(0)
    if tape['DaysPastDue'] > 30:
        return 0
    elif tape['BankruptcyStatus'] != 0:
        return 0
    elif tape['SettlementStatus'] == 'settlecomp':
        return 0
    elif tape['SettlementStatus'] == 'settlefail':
        return 0
    elif tape['SettlementStatus'] == 'settleproc':
        return 0
    elif tape['SettlementStatus'] == 'settlePend':
        return 0
    elif tape['ExtensionStatus'] == 'extengrant':
        return 0
    elif tape['ExtensionStatus'] == 'extenoffer':
        return 0
    elif tape['IsSCRA'] is True:
        return 0
    elif (tape['LoanStatusDescription'] == 'COMPLETED') & (tape[
            'InProcessPrincipalPayments'] > 0):
        return 0
    elif tape['LoanStatusDescription'] == 'CHARGEOFF':
        return 0
    elif tape['LoanStatusDescription'] == 'DEFAULTED':
        return 0
    elif tape['LoanStatusDescription'] == 'ORIGINATIONDELAYED':
        return 0
    elif tape['LoanStatusDescription'] == 'CANCELLED':
        return 0
    elif tape['LoanStatusDescription'] == 'SOLD':
        return 0
    elif tape['PrincipalBalance'] == 0:
        return 0
    elif tape['OriginationDate'] < '2017-01-01':
        return 0
    elif (tape['BorrowerState'] == 'GA') & (
            tape['OriginalInvestment'] <= 3000):
        return 0
    elif (tape['BorrowerState'] == 'CO') & (
            tape['BorrowerAPR'] > 0.21):
        return 0
    elif (tape['BorrowerState'] == 'NY') & (
            tape['BorrowerAPR'] > 0.16):
        return 0
    elif (tape['BorrowerState'] == 'CT') & (
            tape['BorrowerAPR'] > 0.12):
        return 0
    elif (tape['BorrowerState'] == 'VT') & (
            tape['BorrowerAPR'] > 0.12):
        return 0
    elif tape['InvestmentProductID'] != 1:
        return 0 
    elif tape['LoanProductID'] != 1:
        return 0 
    elif tape['InvestmentTypeID'] == 1:
        return 0 
    else:
        return 1


def filter_ineligible(tape):
    tape['Elig'] = tape.apply(elig, axis=1)
    tape = tape[tape['Elig'] == 1]
    tape = tape.reset_index(drop=True)
    print('Done')
    return tape


def remove_sold(tape):
    tape = tape[~tape['LoanStatusDescription'].isin(['SOLD', 'CANCELLED'])]
    print('Done')
    return tape


def calc_strats(tape):
    tape = tape[tape['PrincipalBalance'] > 0]
    tape['DTIwProsperLoan'][tape['DTIwProsperLoan'] > 1] = 0
    tape['FICOScorePt'] = pd.to_numeric(tape['FICOScorePt'])
    d = {
    'PrincipalBalance' : tape['PrincipalBalance'].sum()
    ,'Wtd Avg Maturity' : np.average(tape['AgeInMonths'], weights=tape['PrincipalBalance'])
    ,'Wtd Avg Cpn' : np.average(tape['BorrowerRate'], weights=tape['PrincipalBalance'])
    ,'Wtd Avg FICO' : np.average(tape['FICOScorePt'], weights=tape['PrincipalBalance'])
    ,'Wtd Avg Annual Income' : (np.average(tape['MonthlyIncome'], weights=tape['PrincipalBalance'])) * 12
    ,'Wtd Avg Annual Debt' : (np.average(tape['MonthlyDebt'], weights=tape['PrincipalBalance'])) * 12
    ,'Wtd Avg DTIwProsperLoan' : np.average(tape['DTIwProsperLoan'], weights=tape['PrincipalBalance'])
    }
    return pd.Series(d)


def get_tape_strats(tape):
    tape_strats = tape.groupby(['Term', 'ProsperRating']).apply(calc_strats)
    tape_strats = tape_strats.reindex(['AA', 'A', 'B', 'C', 'D', 'E', 'HR'], level=1)
    tape_strats['Percent'] = tape_strats['PrincipalBalance'] / tape_strats['PrincipalBalance'].sum()
    return tape_strats


def write_tape_strats(deal_name, tape, label):

    tape_metrics = tape.groupby(['Term', 'ProsperRating'
                                 ]).apply(calc_strats)
    tape_metrics = tape_metrics.reindex(['AA', 'A', 'B', 'C', 'D', 'E', 'HR'
                                         ], level=1)
    tape_metrics['Percent'] = tape_metrics['PrincipalBalance'] / tape_metrics['PrincipalBalance'].sum()

    xlsx_filename = dest_fld+deal_name+'.xlsx'
    writer = pd.ExcelWriter(xlsx_filename, engine='xlsxwriter')

    tape.to_excel(writer, sheet_name=str(label).upper()+' Tape')
    tape_metrics.to_excel(writer, sheet_name=str(label).upper()+' Strats')

    writer.save()
    print('Done')


def hit_sql_server(sql):
    cxn = engine.connect()
    df = pd.read_sql_query(sql, cxn)
    cxn.close()
    return df

