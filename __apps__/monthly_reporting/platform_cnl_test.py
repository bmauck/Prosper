import pandas as pd
import numpy as np
import datetime as dt
from historical_platform_performance import get_monthly_vintage_data, get_monthly_vintage_data_no_ratingterm

ratings = ['AA', 'A', 'B', 'C', 'D', 'E', 'HR']
output_fld = 'out-files/'

def get_platform_data(beginOrigMID=201806):
    df = get_monthly_vintage_data()
    df = df[df['OrigMID'] >= beginOrigMID]

    return df


def get_platform_data_no_ratingterm(beginOrigMID=201806):
    df = get_monthly_vintage_data_no_ratingterm()
    df = df[df['OrigMID'] >= beginOrigMID]

    return df

def group_and_clean_platform_mix(df, vin):
    
    df_grouped = df[df['OrigMID'] == vin].groupby(['Term', 'ProsperRating'])['LoanAmount'].sum()
    df_grouped = df_grouped.reindex(ratings, level=1)
    df_grouped = pd.DataFrame(df_grouped)
    df_grouped['Percent'] = df_grouped['LoanAmount'] / df_grouped['LoanAmount'].sum()
    df_grouped['LoanAmount'] = pd.to_numeric(df_grouped['LoanAmount'])
    df_grouped['Percent'] = pd.to_numeric(df_grouped['Percent'])
    df_grouped = df_grouped.reset_index()

    return df_grouped


def group_and_clean_actual_cnl(df, vin):
    
    df_actual_cnl = df[df['OrigMID'] == vin].groupby(['Term', 'ProsperRating'])['CumulativeNetLossesPct'].max()
    df_actual_cnl = df_actual_cnl.reindex(ratings, level=1)
    df_actual_cnl = pd.DataFrame(df_actual_cnl)
    df_actual_cnl['CumulativeNetLossesPct'] = pd.to_numeric(df_actual_cnl['CumulativeNetLossesPct'])

    return df_actual_cnl


def weighted_vintage_cnl(df, vin):
    df_grouped = group_and_clean_platform_mix(df, vin)
    df_actual_cnl = group_and_clean_actual_cnl(df, vin)
    actual_cnl = np.average(df_actual_cnl['CumulativeNetLossesPct'], weights=df_grouped['Percent'])

    return actual_cnl


def weighted_base_cnl(df, vin):
    df_grouped = group_and_clean_platform_mix(df, vin)
    df_base_cnl = pd.read_excel('base_cnl.xlsx')
    base_cnl = np.average(df_base_cnl['BaseCNL'], weights=df_grouped['Percent'])

    return base_cnl


def get_cnl_df():
    df = get_platform_data()
    cnl_dict = {}
    df_timing = pd.read_excel('timing_curve.xlsx')
    df_trigger = pd.read_excel('trigger_curve.xlsx')

    for vin in df['OrigMID'].unique():
        actual_cnl = weighted_vintage_cnl(df, vin)
        base_cnl = weighted_base_cnl(df, vin)
        
        # Base CNL 
        dt_now_str = str(dt.datetime.now().year) + str(dt.datetime.now().month)
        dt_now = pd.to_datetime(dt_now_str, format='%Y%m')
        dt_diff = round((dt_now - pd.to_datetime(vin, format='%Y%m')) / np.timedelta64(1, 'M'), 0) - 1
        
        if dt_diff <= 3:
            timing_adj_cnl = 0
        else:
            timing_adj_cnl = df_timing['Timing Curve'][df_timing['Elapsed Period'] == dt_diff].values * base_cnl
        
        if dt_diff <= 6:
            trigger_value = 0
        else:
            trigger_value = df_trigger['Trigger Curve'][df_trigger['Elapsed Period'] == dt_diff].values
               
        cnl_dict[vin] = [dt_diff, actual_cnl, float(timing_adj_cnl), float(trigger_value)]
    
    df_cnl = pd.DataFrame.from_dict(cnl_dict)
    df_cnl = df_cnl.rename(index={0:'MonthOnBook', 1:'ActualCNL', 2:'BaseCNL', 3:'TriggerCNL'})
    df_cnl = df_cnl.T
    df_cnl['CNLSpreadVsBase'] = df_cnl['BaseCNL'] - df_cnl['ActualCNL']
    df_cnl['CNLSpreadVsTrigger'] = df_cnl['TriggerCNL'] - df_cnl['ActualCNL']
    df_cnl['CNLSpreadVsTrigger'][df_cnl['MonthOnBook'] <=6] = None
    df_cnl['TriggerCNL'][df_cnl['MonthOnBook'] <=6] = None
    df_cnl['MonthOnBook'] = df_cnl['MonthOnBook'].map(int)
    df_cnl = df_cnl.fillna('-')

    return df_cnl


def write_cnl_test():
    dt_now_str = str(dt.datetime.now().year) + str(dt.datetime.now().month)
    df = get_cnl_df()
    df.to_csv(output_fld+dt_now_str+'_platform_cnl_test.csv')