import pandas as pd
import numpy as np
import datetime as dt
import pandas_gbq

project = 'data-lake-prod-223818'
scripts_file_path = 'D:/CapitalMarkets/Mauck/scripts/'
today = dt.date.today()

def one_month_back_str():
    if today.month == 1:
        oneMonthBackStr = str(today.year - 1) + '12'
    elif today.month <= 10:
        oneMonthBackStr = str(today.year) + '0' + str(today.month - 1)
    else:
        oneMonthBackStr = str(today.year) + str(today.month -1)
    return oneMonthBackStr

def two_months_back_str():
    if today.month == 1:
        twoMonthsBackStr = str(today.year - 1) + '11'
    elif today.month == 2:
        twoMonthsBackStr = str(today.year - 1) + '12'
    elif today.month <= 11:
        twoMonthsBackStr = str(today.year) + '0' + str(today.month - 2)
    else:
        twoMonthsBackStr = str(today.year) + str(today.month - 2)
    return twoMonthsBackStr

def write_gbq_performance_table():
    sql = open(scripts_file_path+'sql/historical_platform_performance_gbq.sql', 'r')
    sql = sql.read()
    df = pd.read_gbq(sql.format(one_month_back_str(), two_months_back_str()), project, dialect='standard')
    df['OQ'] = df['OriginationQuarter'].str[3:].map(str) + df['OriginationQuarter'].str[:2].map(str)
    pandas_gbq.to_gbq(df, 'Group_CapMarkets.{}_vintage_data'.format(
        one_month_back_str())
        , project_id=project
        , if_exists='replace')

def write_performance_file():
    write_gbq_performance_table()
    output_fld = 'D:/CapitalMarkets/_Monthly Distribution/Vintage Data/Quarterly/'
    output_filename = '{}_quarterly_vintage_data.xlsx'
    sql = 'select * from Group_CapMarkets.{}_vintage_data'.format(one_month_back_str())
    df = pd.read_gbq(sql, project, dialect='standard')
    df.to_excel(output_fld+output_filename.format(one_month_back_str()), sheet_name=one_month_back_str())

write_gbq_performance_table()
write_performance_file()