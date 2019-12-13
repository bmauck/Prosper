# -*- coding: utf-8 -*-
"""
Created on Mon Mar 25 10:15:57 2019

@author: bmauck
"""
import pandas as pd
import sqlalchemy
import datetime
from tqdm import tqdm
from dateutil.relativedelta import relativedelta

db = 'dw'
svr = '@dbrpt/{db}?driver=SQL+Server+Native+Client+11.0'.format(db=db)
engine = sqlalchemy.create_engine('mssql+pyodbc://'+svr)

file_date = input('For month starting when? ')
file_date = pd.to_datetime(file_date)

dest_fld = ('D:\\CapitalMarkets\\_Monthly Distribution\\Month End Reporting\\')


def stmt_per():
    stmt_per = input('What period? ')
    return stmt_per


def generate_garrison_fico_bins():

    per = stmt_per()

    connection = engine.connect()

    garrisonID = [2662692, 3624846, 5710889, 3526705,
                  5710903, 4177037, 5710910, 7609282,
                  7635094, 7635050, 7806052, 7806063,
                  8447542, 8447555, 8805443, 8807554,
                  8797142, 8807681, 8805698, 8805563,
                  8805698]

    sql = open('D:\\CapitalMarkets\\Mauck\\scripts\\sql\\garrison_fico.sql',
               'r')
    f = sql.read()
    xlsx_filename = dest_fld + 'Garrison/' + str(per[1:5]) + '_' + str(
            per[-3:-1]) + '_garrison_fico_bins.xlsx'

    writer = pd.ExcelWriter(xlsx_filename, engine='xlsxwriter')
    count = 0
    for i in tqdm(garrisonID):

        fico_bins = pd.read_sql_query(f.format(i, str(per)), connection)

        if not fico_bins.empty:
            fico_bins.to_excel(writer, sheet_name='GarrisonID '+str(i))

        count = count + 1

    writer.save()
    connection.close()


def generate_bbva_kpis():
    
    loan_query = """
    select distinct
        LoanID
        ,max(DaysPastDue) as DaysPastDue
        ,ProsperRating
        from
            DW..vloanlevelmonthly
        where
            1=1
            and ProsperRating in ('AA','A','B','C')
            and DaysPastDue > 30
            and OrigMID = {}
            and LoanProductID = 1
            and InvestmentProductID = 1
            and ObservationMonth <= {}
        group by
            LoanID
            ,ProsperRating
    """

    mob_6_start = file_date + relativedelta(months=-6)
    mob_6_end = file_date + relativedelta(months=-5)

    mob_9_start = file_date + relativedelta(months=-9)
    mob_9_end = file_date + relativedelta(months=-8)

    mob_12_start = file_date + relativedelta(months=-12)
    mob_12_end = file_date + relativedelta(months=-11)

    mob_6_month = mob_6_start.month
    mob_9_month = mob_9_start.month
    mob_12_month = mob_12_start.month
    file_date_month = file_date.month

    if len(str(mob_6_month)) == 1:
        mob_6_month = str(0) + str(mob_6_month)
    else:
        mob_6_month = mob_6_month

    if len(str(mob_9_month)) == 1:
        mob_9_month = str(0) + str(mob_9_month)
    else:
        mob_9_month = mob_9_month

    if len(str(mob_12_month)) == 1:
        mob_12_month = str(0) + str(mob_12_month)
    else:
        mob_12_month = mob_12_month

    if len(str(file_date_month)) == 1:
        file_date_month = str(0) + str(file_date_month)
    else:
        file_date_month = file_date_month

    mob_6_mid = str(mob_6_start.year) + str(mob_6_month)
    file_date_mid = str(file_date.year) + str(file_date_month)
    cxn = engine.connect()

    i = 5513816

    str_start = str("'" + file_date.date().isoformat() + "'")
    str_end = str("'" + (file_date + relativedelta(months=1, days=3)).date().isoformat() + "'")

    positions_query = 'exec ReportingProgrammability..Report_DailyLenderPacket_Positions {}, {}, {}'.format(
        i, str_start, str_end)

    dq_loans = pd.read_sql_query(loan_query.format(mob_6_mid, file_date_mid), cxn)
    bbva_positions = pd.read_sql_query(positions_query, cxn)    

    bbva_positions = pd.merge(bbva_positions, dq_loans,
                                left_on='LoanNumber', right_on='LoanID',
                                how='left', indicator=True)
    bbva_positions['30+ DPD Ever'] = bbva_positions[
                '_merge'].replace(['left_only', 'both'], ['No', 'Yes'])
    bbva_positions = bbva_positions.drop(columns=['_merge'])
    bbva_positions['ChargeoffDate'] = pd.to_datetime(bbva_positions['ChargeoffDate'])
    bbva_positions['OriginationDate'] = pd.to_datetime(bbva_positions['OriginationDate'])

    mob_6_loans = bbva_positions[(bbva_positions[
            'OriginationDate'] >= mob_6_start.isoformat())
                            & (bbva_positions[
                                    'OriginationDate'] < mob_6_end.isoformat())
                            & (bbva_positions[
                                    'LoanStatusDescription'] != 'CANCELLED')]
    mob_9_loans = bbva_positions[(bbva_positions[
            'OriginationDate'] >= mob_9_start.isoformat())
                            & (bbva_positions[
                                    'OriginationDate'] < mob_9_end.isoformat())
                            & (bbva_positions[
                                    'LoanStatusDescription'] != 'CANCELLED')]
    mob_12_loans = bbva_positions[(bbva_positions[
            'OriginationDate'] >= mob_12_start.isoformat())
                            & (bbva_positions['OriginationDate'
                                            ] < mob_12_end.isoformat())
                            & (bbva_positions['LoanStatusDescription'
                                            ] != 'CANCELLED')]

    ex_1_data = {'Month On Book': ['MOB 6', 'MOB 9', 'MOB 12']
                ,'Total Principal': [mob_6_loans['LoanAmount'].sum()
                                    ,mob_9_loans['LoanAmount'].sum()
                                    ,mob_12_loans['LoanAmount'].sum()]
                ,'Principal At Chargeoff': [mob_6_loans['PrincipalBalanceAtChargeoff'].sum()
                                        ,mob_9_loans['PrincipalBalanceAtChargeoff'].sum()
                                        ,mob_12_loans['PrincipalBalanceAtChargeoff'].sum()]
                ,'Pct Of Principal': [(mob_6_loans['PrincipalBalanceAtChargeoff'].sum() 
                                    / mob_6_loans['LoanAmount'].sum())
                                    ,(mob_9_loans['PrincipalBalanceAtChargeoff'].sum() 
                                    / mob_9_loans['LoanAmount'].sum())
                                    ,(mob_12_loans['PrincipalBalanceAtChargeoff'].sum() 
                                    / mob_12_loans['LoanAmount'].sum())]}
    ex_1 = pd.DataFrame(ex_1_data)
    ex_1 = ex_1.set_index(['Month On Book'], drop=True)

    ex_2_data = {'Early DQ Rate': ['MOB 6 Dollar', 'MOB 6 Count']
                ,'Total': [mob_6_loans['LoanAmount'].sum(), mob_6_loans['LoanAmount'].count()]
                ,'DQ': [mob_6_loans['PrincipalBalance'][
                    (mob_6_loans['DaysPastDue_x'] > 30) & (mob_6_loans['LoanStatusDescription'] == 'CURRENT')].sum()
                    ,mob_6_loans['PrincipalBalance'][
                    (mob_6_loans['DaysPastDue_x'] > 30) & (mob_6_loans['LoanStatusDescription'] == 'CURRENT')].count()]
                }
    ex_2 = pd.DataFrame(ex_2_data)
    ex_2['%DQ'] = ex_2['DQ'] / ex_2['Total']
    ex_2 = ex_2.set_index(['Early DQ Rate'], drop=True)

    ex_3_data = {'Total Balance': bbva_positions.PrincipalBalance[
                        bbva_positions['LoanStatusDescription'] == 'CURRENT'].sum()
                ,'Prin 30+ DPD': bbva_positions.PrincipalBalance[
                        (bbva_positions['LoanStatusDescription'] == 'CURRENT') & (bbva_positions['DaysPastDue_x'] > 30)].sum()  
                ,'Index': ['Total']}
    ex_3 = pd.DataFrame(ex_3_data)
    ex_3['%30+ DPD'] = ex_3['Prin 30+ DPD'] / ex_3['Total Balance']
    ex_3 = ex_3.set_index(['Index'], drop=True)

    ex_4 = pd.DataFrame(index=['AA', 'A', 'B', 'C'])
    ex_4['Ever 30+'] = mob_6_loans[mob_6_loans['30+ DPD Ever'] == 'Yes'].groupby(['ProsperRating_x'])['ProsperRating_x'].count()
    ex_4['Total'] = mob_6_loans.groupby(['ProsperRating_x'])['ProsperRating_x'].count()
    ex_4['Pct Ever 30+ DPD'] = ex_4['Ever 30+'] / ex_4['Total']
    ex_4 = ex_4.fillna(0)

    writer = pd.ExcelWriter('D:\\CapitalMarkets\\_Monthly Distribution\\Month End Reporting\\' + 'BBVA\\' + str(file_date.year) + '_' + str(file_date.month) + '_bbva_kpi.xlsx'
            , engine='xlsxwriter')

    ex_1.to_excel(writer, sheet_name='Exhibit 1')
    ex_2.to_excel(writer, sheet_name='Exhibit 2')
    ex_3.to_excel(writer, sheet_name='Exhibit 3')
    ex_4.to_excel(writer, sheet_name='Exhibit 4')
    bbva_positions.to_excel(writer, sheet_name='Positions')

    writer.save()
    cxn.close()
    


def generate_bbva_manual_verification_report():
    connection = engine.connect()
    sql = open('D://CapitalMarkets//Mauck//scripts//sql//bbva_manual_verification.sql', 'r')
    f = sql.read()
    df = pd.read_sql(f, connection)

    df.to_csv(dest_fld + 'BBVA/' + str(file_date.year) + '_' + str(
            file_date.month) + '_bbva_manual_verification.csv')
    connection.close()


def generate_bbva_mla_report():
    connection = engine.connect()
    sql = open('D://SQL//Investor Support//MLA_BBVA_Query.sql', 'r')
    f = sql.read()
    df = pd.read_sql(f, connection)

    df.to_csv(dest_fld + 'BBVA/' + str(file_date.year) + '_' + str(
            file_date.month) + '_bbva_mla_report.csv')
    connection.close()


def generate_bbva_scra_report():
    connection = engine.connect()
    sql = open('D://SQL//Investor Support//SCRA_BBVA_Query.sql', 'r')
    f = sql.read()
    df = pd.read_sql(f, connection)

    df.to_csv(dest_fld + 'BBVA/' + str(file_date.year) + '_' + str(
            file_date.month) + '_bbva_scra_report.csv')
    connection.close()


def generate_customers_file():
    connection = engine.connect()
    file_date = datetime.date.today().replace(day=1) + relativedelta(months=-1)

    staging_sql = open('D:\\CapitalMarkets\\Mauck\\scripts\\sql\\customers_staging.sql'
                   , 'r', encoding='utf8')
    query_sql = open('D:\\CapitalMarkets\\Mauck\scripts\\sql\\customers_file.sql'
                 , 'r', encoding='utf8')
    connection.execute(staging_sql.read())
    file = pd.read_sql_query(query_sql.read(), connection)

    file.to_csv(dest_fld + "Customer's/" + str(file_date.year) + '_' + str(
            file_date.month) + '_customers_bank_data_management.csv')
    connection.close()


def calc_margin(df):
    if df['CycleCounter'] < 6:
        return '-'
    else:
        return df['Trigger'] - df['CumulativeNetLossesPct']


def run_citi_cnl_test():
    cxn = engine.connect()
    sql = open('D:/CapitalMarkets/Mauck/scripts/sql/vintage_data_monthly.sql', 'r')
    sql = sql.read()
    data = pd.read_sql_query(sql, cxn)
    data = data[['OrigMID', 'CycleCounter', 'CumulativeNetLossesPct']]
    trgr = pd.read_csv('D:/CapitalMarkets/Citi/PWIIT/Performance Triggers/trigger_curve.csv')    
    vintages = data['OrigMID'].unique()

    writer = pd.ExcelWriter(dest_fld + 'Citi/{}_{}_cnl_test.xlsx'.format(
            str(file_date.year), str(file_date.month)), engine='xlsxwriter')

    for vin in tqdm(vintages):

        df = data[data['OrigMID'] == vin]
        df = df.reset_index(drop=True)

        df['Trigger'] = trgr['Trigger Curve']

        df['Margin'] = df.apply(calc_margin, axis=1)

        df.to_excel(writer, sheet_name=str(vin))

    cxn.close()


def complete_monthly_reporting():
    # print('KPIs...')
    # generate_bbva_kpis()
    print('Manual Verifications...')
    generate_bbva_manual_verification_report()
    print('MLA...')
    generate_bbva_mla_report()
    print('SCRA...')
    generate_bbva_scra_report()
    print('Customers...')
    generate_customers_file()
    print('Garrison...')
    generate_garrison_fico_bins()
    print('Citi...')
    run_citi_cnl_test()
    print('Done')
