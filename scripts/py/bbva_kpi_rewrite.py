
# coding: utf-8

# In[1]:


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

dest_fld = ('../../_Monthly Distribution/Month End Reporting/')


# In[57]:


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


# In[59]:


cxn = engine.connect()

i = 5513816

str_start = str(file_date.date().isoformat())
str_end = str((file_date + relativedelta(months=1)).date().isoformat())

positions_query = 'exec ReportingProgrammability..Report_DailyLenderPacket_Positions {}, {}, {}'.format(
    i, str_start, str_end)

dq_loans = pd.read_sql_query(loan_query.format(mob_6_mid, file_date_mid), cxn)
bbva_positions = pd.read_sql_query(positions_query, cxn)    


# In[60]:


bbva_positions = pd.merge(bbva_positions, dq_loans,
                              left_on='LoanNumber', right_on='LoanID',
                              how='left', indicator=True)
bbva_positions['30+ DPD Ever'] = bbva_positions[
            '_merge'].replace(['left_only', 'both'], ['No', 'Yes'])
bbva_positions = bbva_positions.drop(columns=['_merge'])
bbva_positions['ChargeoffDate'] = pd.to_datetime(bbva_positions['ChargeoffDate'])
bbva_positions['OriginationDate'] = pd.to_datetime(bbva_positions['OriginationDate'])


# In[61]:


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


# In[62]:


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


# In[63]:


ex_1 = pd.DataFrame(ex_1_data)
ex_1 = ex_1.set_index(['Month On Book'], drop=True)


# In[65]:


ex_2_data = {'Early DQ Rate': ['MOB 6 Dollar', 'MOB 6 Count']
            ,'Total': [mob_6_loans['LoanAmount'].sum(), mob_6_loans['LoanAmount'].count()]
            ,'DQ': [mob_6_loans['PrincipalBalance'][
                (mob_6_loans['DaysPastDue_x'] > 30) & (mob_6_loans['LoanStatusDescription'] == 'CURRENT')].sum()
                   ,mob_6_loans['PrincipalBalance'][
                (mob_6_loans['DaysPastDue_x'] > 30) & (mob_6_loans['LoanStatusDescription'] == 'CURRENT')].count()]
            }


# In[66]:


ex_2 = pd.DataFrame(ex_2_data)


# In[67]:


ex_2['%DQ'] = ex_2['DQ'] / ex_2['Total']
ex_2 = ex_2.set_index(['Early DQ Rate'], drop=True)


# In[69]:


ex_3_data = {'Total Balance': bbva_positions.PrincipalBalance[
                    bbva_positions['LoanStatusDescription'] == 'CURRENT'].sum()
            ,'Prin 30+ DPD': bbva_positions.PrincipalBalance[
                    (bbva_positions['LoanStatusDescription'] == 'CURRENT') & (bbva_positions['DaysPastDue_x'] > 30)].sum()  
            ,'Index': ['Total']}


# In[70]:


ex_3 = pd.DataFrame(ex_3_data)
ex_3['%30+ DPD'] = ex_3['Prin 30+ DPD'] / ex_3['Total Balance']
ex_3 = ex_3.set_index(['Index'], drop=True)


# In[79]:


ex_4 = pd.DataFrame(index=['AA', 'A', 'B', 'C'])


# In[80]:


ex_4['Ever 30+'] = mob_6_loans[mob_6_loans['30+ DPD Ever'] == 'Yes'].groupby(['ProsperRating_x'])['ProsperRating_x'].count()


# In[82]:


ex_4['Total'] = mob_6_loans.groupby(['ProsperRating_x'])['ProsperRating_x'].count()


# In[84]:


ex_4['Pct Ever 30+ DPD'] = ex_4['Ever 30+'] / ex_4['Total']


# In[86]:


ex_4 = ex_4.fillna(0)


# In[ ]:


writer = pd.ExcelWriter('D:\\CapitalMarkets\\_Monthly Distribution\\Month End Reporting\\' + 'BBVA\\' + str(file_date.year) + '_' + str(file_date.month) + '_bbva_kpi.xlsx'
        , engine='xlsxwriter')

ex_1.to_excel(writer, sheet_name='Exhibit 1')
ex_2.to_excel(writer, sheet_name='Exhibit 2')
ex_3.to_excel(writer, sheet_name='Exhibit 3')
ex_4.to_excel(writer, sheet_name='Exhibit 4')
bbva_positions.to_excel(writer, sheet_name='Positions')

writer.save()
cxn.close()

