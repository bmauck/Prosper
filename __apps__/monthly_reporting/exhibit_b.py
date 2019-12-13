# coding: utf-8

import pandas as pd
import datetime as dt

gbq_prj = 'data-lake-prod-223818'

if dt.date.today().month == 1:
    year = dt.date.today().year-1
    month = 12
else:
    year = dt.date.today().year
    month = dt.date.today().month-1

if len(str(month)) == 1:
    month = str(0) + str(month)
else:
    month = month

date_string = str(year)+str(month)

output_file = 'M:/CapitalMarkets/__apps__/monthly_reporting/out-files/{}_exhibit_b.xlsx'.format(date_string)

terms = [36,60]
ratings = ['AA', 'A', 'B', 'C', 'D', 'E', 'HR']

sql = open('M:/CapitalMarkets/__apps__/monthly_reporting/sql/get_vintage_data.sql', 'r')
sql = sql.read()
sql = sql.format(date_string)


def calc_cdr(df):
    smm = (df['CO_Balance'] / df['PrevUPB'])
    cdr = 1 - (1 - smm)**12
    return pd.to_numeric(cdr)

def calc_cpr(df):
    smm = (df['FullPaydowns'] + df['VoluntaryExcessPrin']) / (df['PrevUPB'] - df['ScheduledPeriodicPrin'])
    cpr = 1 - (1 - smm)**12
    return pd.to_numeric(cpr)

def numerize_df(df):
    for c in df.columns:
        try:
            df[c] = pd.to_numeric(df[c])
        except:
            pass
    return df

def loan_amount(df):
    df1 = df[(df['CycleCounter'] == 0)]
    df2 = pd.DataFrame(df1.groupby(['OQ'])['LoanAmount'].sum())
    df2 = df2.T
    return df2

def get_and_clean_data():
    df = pd.read_gbq(sql, project_id=gbq_prj, dialect='standard')
    df = numerize_df(df)
    df = df[df['OQ'] >= '2012-01-01']
    df['Total DQ'] = pd.to_numeric(df['LoanAmount']).values * pd.to_numeric(df['DPD_16']).values
    df['OQ'] = df['OriginationQuarter'].str[3:].map(str) + df['OriginationQuarter'].str[:2].map(str)
    df['CDR'] = calc_cdr(df)
    df['CPR'] = calc_cpr(df)
    return df

df = get_and_clean_data()

def avg_br_rate(writer, df):
              
    for t in terms:
        df1 = df[df['Term'] == t]
        df1 = df1.pivot_table(index='OQ'
                              ,columns='ProsperRating'
                              ,values='AvgBorrowerRate'
                              ,aggfunc='max')
        df1 = df1.reindex_axis(ratings, axis=1)
        if t == 60:
            df1 = df1.drop('HR', axis=1)
        df1.style.format('{:,.2%}')
        df1.to_excel(writer, sheet_name='WTD_AVG_CPN_' + str(t))


def max_cumul_loss(writer, df):
    
    for t in terms:
        df1 = df[(df['Term'] == t)]
        loan_amt = loan_amount(df1)
        pivot1= df1.pivot_table(index='CycleCounter'
                                ,columns='OQ'
                                ,values='CumulativeGrossLosses'
                                ,aggfunc='sum'
                                ,fill_value='')
        pivot2 = df1.pivot_table(index='CycleCounter'
                                ,columns='OQ'
                                ,values='LoanAmount'
                                ,aggfunc='sum'
                                ,fill_value='')
        df2 = numerize_df(pivot1).div(numerize_df(pivot2))
        df2.fillna('', axis=1, inplace=True)
        df2 = pd.concat([loan_amt, df2], sort=True)
        df2 = df2.T.set_index(df2.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
        if not df2.empty:
            df2.to_excel(writer, sheet_name='MCL_' + str(t))

    for t in terms:
        for r in ratings:
            df1 = df[(df['Term'] == t) & (df['ProsperRating'] == r)]
            loan_amt = loan_amount(df1)
            df1 = df1.pivot_table(index='CycleCounter'
                                  ,columns='OQ'
                                  ,values='CumulativeGrossLossesPct'
                                  ,aggfunc='max'
                                  ,fill_value='')
            df1.fillna('', axis=1, inplace=True)
            df1 = pd.concat([loan_amt, df1], sort=True)
            df1 = df1.T.set_index(df1.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
            if not df1.empty:
                df1.to_excel(writer, sheet_name='MCL_' + str(r) + str(t))


def days_past_due(writer, df):

    for t in terms:
        df1 = df[(df['Term'] == t)]
        loan_amt = loan_amount(df1)
        pivot1= df1.pivot_table(index='CycleCounter'
                                ,columns='OQ'
                                ,values='Total DQ'
                                ,aggfunc='sum'
                                ,fill_value='')
        pivot2 = df1.pivot_table(index='CycleCounter'
                                ,columns='OQ'
                                ,values='LoanAmount'
                                ,aggfunc='sum'
                                ,fill_value='')
        df2 = numerize_df(pivot1).div(numerize_df(pivot2))
        df2.fillna('', axis=1, inplace=True)
        df2 = pd.concat([loan_amt, df2], sort=True)
        df2 = df2.T.set_index(df2.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
        if not df2.empty:
            df2.to_excel(writer, sheet_name='DPD_' + str(t))

    for t in terms:
        for r in ratings:
            df1 = df[(df['Term'] == t) & (df['ProsperRating'] == r)]
            loan_amt = loan_amount(df1)
            df1 = df1.pivot_table(index='CycleCounter'
                                  ,columns='OQ'
                                  ,values='DPD_16'
                                  ,aggfunc='max'
                                  ,fill_value='')
            df1.fillna('', axis=1, inplace=True)
            df1 = pd.concat([loan_amt, df1], sort=True)
            df1 = df1.T.set_index(df1.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
            if not df1.empty:
                df1.to_excel(writer, sheet_name='DPD_' + str(r) + str(t))


def end_prin_bal(writer, df):

    for t in terms:
        df1 = df[(df['Term'] == t)]
        loan_amt = loan_amount(df1)
        df1 = df1.pivot_table(index='CycleCounter'
                              ,columns='OQ'
                              ,values='UPB'
                              ,aggfunc='sum'
                              ,fill_value='')
        df1.fillna('', axis=1, inplace=True)
        df1 = pd.concat([loan_amt, df1], sort=True)
        df1 = df1.T.set_index(df1.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
        if not df1.empty:
            df1.to_excel(writer, sheet_name='EOP_' + str(t))

    for t in terms:
        for r in ratings:
            df1 = df[(df['Term'] == t) & (df['ProsperRating'] == r)]
            loan_amt = loan_amount(df1)
            df1 = df1.pivot_table(index='CycleCounter'
                                  ,columns='OQ'
                                  ,values='UPB'
                                  ,aggfunc='sum'
                                  ,fill_value='')
            df1.fillna('', axis=1, inplace=True)
            df1 = pd.concat([loan_amt, df1], sort=True)
            df1 = df1.T.set_index(df1.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
            if not df1.empty:
                df1.to_excel(writer, sheet_name='EOP_' + str(r) + str(t))


def orig_prin_bal(writer, df):

    for t in terms:
        df1 = df[df['Term'] == t]
        df1 = df1.pivot_table(index='OQ'
                              ,columns='ProsperRating'
                              ,values='LoanAmount'
                              ,aggfunc='max')
        df1 = df1.reindex_axis(ratings, axis=1)
        if t == 60:
            df1 = df1.drop('HR', axis=1)
        df1.style.format('${:,.2f}')
        df1.to_excel(writer, sheet_name='OPB_' + str(t))


def cpr(writer, df):
    
    for t in terms:
        df1 = df[(df['Term'] == t)]
        loan_amt= loan_amount(df1)
        df1 = df1.pivot_table(index='CycleCounter'
                              ,columns='OQ'
                              ,values='CPR'
                              ,aggfunc='max'
                              ,fill_value='')
        df1.fillna('', axis=1, inplace=True)
        df1 = pd.concat([loan_amt, df1], sort=True)
        df1 = df1.T.set_index(df1.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
        if not df1.empty:
            df1.to_excel(writer, sheet_name='CPR_' + str(t))

    for t in terms:
        for r in ratings:
            df1 = df[(df['Term'] == t) & (df['ProsperRating'] == r)]
            loan_amt = loan_amount(df1)
            df1 = df1.pivot_table(index='CycleCounter'
                                  ,columns='OQ'
                                  ,values='CPR'
                                  ,aggfunc='max'
                                  ,fill_value='')
            df1.fillna('', axis=1, inplace=True)
            df1 = pd.concat([loan_amt, df1], sort=True)
            df1 = df1.T.set_index(df1.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
            if not df1.empty:
                df1.to_excel(writer, sheet_name='CPR_' + str(r) + str(t))


def cdr(writer, df):
    
    for t in terms:
        df1 = df[(df['Term'] == t)]
        loan_amt = loan_amount(df1)
        df1 = df1.pivot_table(index='CycleCounter'
                              ,columns='OQ'
                              ,values='CDR'
                              ,aggfunc='max'
                              ,fill_value='')
        df1.fillna('', axis=1, inplace=True)
        df1 = pd.concat([loan_amt, df1], sort=True)
        df1 = df1.T.set_index(df1.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
        df1.to_excel(writer, sheet_name='CDR_' + str(t))
        
    for t in terms:
        for r in ratings:
            df1 = df[(df['Term'] == t) & (df['ProsperRating'] == r)]
            loan_amt = loan_amount(df1)
            df1 = df1.pivot_table(index='CycleCounter'
                                  ,columns='OQ'
                                  ,values='CDR'
                                  ,aggfunc='max'
                                  ,fill_value='')
            df1.fillna('', axis=1, inplace=True)
            df1 = pd.concat([loan_amt, df1], sort=True)
            df1 = df1.T.set_index(df1.T['LoanAmount'], append=True).drop(['LoanAmount'], axis=1).swaplevel(0,1).T
            
            if not df1.empty:
                df1.to_excel(writer, sheet_name='CDR_' + str(r) + str(t))


def generate_dt_data():
    writer = pd.ExcelWriter(output_file, engine='xlsxwriter')
    avg_br_rate(writer, df)
    max_cumul_loss(writer, df)
    days_past_due(writer, df)
    end_prin_bal(writer, df)
    orig_prin_bal(writer, df)
    cpr(writer, df)
    cdr(writer, df)
    writer.save()
