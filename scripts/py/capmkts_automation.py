import pandas as pd
import numpy as np
from tqdm import tqdm
import sqlalchemy
import datetime as dt
from xhtml2pdf import pisa
import os
import matplotlib.pyplot as plt
from tabulate import tabulate as tb

dest_fld = 'D:\\CapitalMarkets\\Output Files\\'
db = 'ReportingProgrammability'
svr = '@dbrpt/{db}?driver=SQL+Server+Native+Client+11.0'.format(db=db)
engine = sqlalchemy.create_engine('mssql+pyodbc://'+svr)
plt.style.use('ggplot')
today = dt.date.isoformat(dt.date.today())


class investor:

    def __init__(self, id):
        self.id = id
        
    def tape(self, date):
        
        print('Querying...')
    
        staging = open('D:/CapitalMarkets/Mauck/scripts/sql/tape_staging.sql', 'r')
        result = open('D:/CapitalMarkets/Mauck/scripts/sql/tape_result.sql', 'r')
    
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
        

    def positions(self, date):
        
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
        
        

def get_username_and_id():
    
    investor_name = input('What investor? ')
    sql = open('D:/CapitalMarkets/Mauck/scripts/sql/current_username.sql', 'r')
    sql = sql.read()
    
    cxn = engine.connect()
    df = pd.read_sql_query(sql.format(investor_name), cxn)
    cxn.close()
    
    return df


def write_file(report, filename):

    filename = filename

    print('Writing Files...')
    report.to_csv(dest_fld+filename)
    print('Done')


def show_agreement_types():
    
    agmt_name = input('What agreement? ')
    sql = """
    select
        AgreementTypes.Title
        ,AgreementTypes.ID
        from
            CircleOne..AgreementTypes
        where
            1=1
            and AgreementTypes.Title like '%{}%'
    """

    cxn = engine.connect()
    p = pd.read_sql_query(sql.format(agmt_name), cxn)
    cxn.close()
    print(tb(p, headers='keys'))


def convert_html2pdf(sourceHtml, outputFilename):
    
    resultFile = open(outputFilename, "w+b")
    pisaStatus = pisa.CreatePDF(sourceHtml, dest=resultFile)
    resultFile.close()
    return pisaStatus.err


def generate_agreements(AgreementTypeID, loans):
    sql = open('D:/CapitalMarkets/Mauck/scripts/sql/agreement.sql', 'r')
    f = sql.read()
    connection = engine.connect()
    print('Querying...')

    p = pd.read_sql_query(f.format(loans, AgreementTypeID, AgreementTypeID
                                   ), connection, index_col='Loan')
    connection.close()

    print('Writing Files...')

    for index, row in tqdm(p.iterrows()):
        if row.IsCorrectedAgreement is True:
            file = dest_fld + '/Agreements/{} {} (Corrected)'.format(
                    index, row.Title)

            html_file = open(file+'.html', 'w')
            html_file.write(row['html'])
            html_file.close()

            with open(file+'.html', 'r')as g:
                sourceHtml = g.read()
            outputFilename = file+'.pdf'
            os.remove(file+'.html')

            convert_html2pdf(sourceHtml, outputFilename)
        
        elif row.IsCorrectedAgreement is not True:
            file = dest_fld + '/Agreements/{} {}'.format(index, row.Title)

            html_file = open(file+'.html', 'w')
            html_file.write(row['html'])
            html_file.close()

            with open(file+'.html', 'r') as g:
                sourceHtml = g.read()
            outputFilename = file+'.pdf'
            os.remove(file+'.html')

            convert_html2pdf(sourceHtml, outputFilename)
            
        else:
            print('error', index, row.IsCorrectedAgreement)
    print('Done')
    return p 


def aggregate_tapes(tapes, label, write_file=False):
    tape = pd.concat(tapes, ignore_index=True, sort=False)
    tape = tape.reset_index(drop=True)

    if write_file is True:
        tape.to_csv('../Output Files/'+label+'.csv')
    else:
        return tape


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
    tape = tape[tape['LoanStatusDescription'] != 'SOLD']
    print('Done')
    return tape


def calc_strats(tape):
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


def generate_validation_file(i, date1, date2, write_file=False):
    print('Querying...')

    result = open('D:/CapitalMarkets/Mauck/scripts/sql/validation_file.sql', 'r')
    result_sql = result.read()

    cxn = engine.connect()
    tape = pd.read_sql_query(result_sql.format(date1, date2, i), cxn)
    cxn.close()

    if write_file is True:
        print('Writing Files...')
        tape.to_csv(dest_fld+str(i)+'_validation_file.csv')
    else:
        return tape
    print('Done')
