import pandas as pd
import datetime as dt
gbq_prj = 'data-lake-prod-223818'

sql_params = open('performance_reports\\sql\\loan_params.sql', 'r')
sql_params = sql_params.read()
sql_params = sql_params.format(input('LenderID? '))

sql_performance = open('performance_reports\\sql\\portfolio_performance.sql', 'r')
sql_performance = sql_performance.read()
sql_performance = sql_performance.format(sql_params)

sql_performance_agg = open('performance_reports\\sql\\portfolio_performance_agg.sql', 'r')
sql_performance_agg = sql_performance_agg.read()
sql_performance_agg = sql_performance_agg.format(sql_params)

sql_performance_all_vins = open('performance_reports\\sql\\portfolio_performance_agg_all_vins.sql', 'r')
sql_performance_all_vins = sql_performance_all_vins.read()
sql_performance_all_vins = sql_performance_all_vins.format(sql_params)


def calc_net_return(df):
    net_return = (1+ (pd.to_numeric(df['InterestPaid'])
       + pd.to_numeric(df['TotalFees'])
       + pd.to_numeric(df['RecoveryPrinPaid'])
       + pd.to_numeric(df['NetCashToInvestorsFromDebtSale'])
       - pd.to_numeric(df['CO_Balance']))
    / pd.to_numeric(df['LoanAmount']))**12 - 1
    return net_return


def calc_cumul_prepay(df):
    cpp = (df['FullPaydowns'] + df['VoluntaryExcessPrin']).cumsum() / df['LoanAmount']
    return pd.to_numeric(cpp)


def calc_cdr(df):
    smm = (df['CO_Balance'] / df['UPB'])
    cdr = 1 - (1 - smm)**12
    return pd.to_numeric(cdr)


def calc_cpr(df):
    smm = (df['FullPaydowns'] + df['VoluntaryExcessPrin']) / (df['UPB'] - df['ScheduledPeriodicPrin'])
    cpr = 1 - (1 - smm)**12
    return pd.to_numeric(cpr)


def get_performance_data(strat='inception to date'):
    if strat=='by rating and term':
        df = pd.read_gbq(sql_performance, project_id=gbq_prj, dialect='standard')
        df['OriginationQuarter'] = pd.to_datetime(df['OriginationQuarter'].str[-4:] + df['OriginationQuarter'].str[:2])
        df['OriginationQuarter'] = df['OriginationQuarter'].dt.to_period("Q")
        df['AnnualizedNetReturn'] = calc_net_return(df)
        df['CumulPrepay'] = calc_cumul_prepay(df)
        df['CPR'] = calc_cpr(df)
        df['CDR'] = calc_cdr(df)
        return df

    elif strat=='inception to date':
        df = pd.read_gbq(sql_performance_all_vins, project_id=gbq_prj, dialect='standard')
        df['AnnualizedNetReturn'] = calc_net_return(df)
        df['CumulPrepay'] = calc_cumul_prepay(df)
        df['CPR'] = calc_cpr(df)
        df['CDR'] = calc_cdr(df)
        return df

    else:
        df = pd.read_gbq(sql_performance_agg, project_id=gbq_prj, dialect='standard')
        df['OriginationQuarter'] = pd.to_datetime(df['OriginationQuarter'].str[-4:] + df['OriginationQuarter'].str[:2])
        df['OriginationQuarter'] = df['OriginationQuarter'].dt.to_period("Q")
        df['AnnualizedNetReturn'] = calc_net_return(df)
        df['CumulPrepay'] = calc_cumul_prepay(df)
        df['CPR'] = calc_cpr(df)
        df['CDR'] = calc_cdr(df)
        return df
