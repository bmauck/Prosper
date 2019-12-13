"""
Created on Mon Mar 25 10:15:57 2019

@author: bmauck
"""

import pandas as pd
import numpy as np
import os
from datetime import date

if date.today().month == 1:
    year = date.today().year-1
    month = 12
else:
    year = date.today().year
    month = date.today().month-1

if len(str(month)) == 1:
    month = str(0) + str(month)
else:
    month = month

date_string = str(year)+str(month)

output_dir = 'D:\\CapitalMarkets\\_Monthly Distribution\\' + date_string
input_dir = 'D:\\CapitalMarkets\\' \
    '_Monthly Distribution\\Vintage Data\\Quarterly'
input_file = '\\{}_quarterly_vintage_data.xlsx'.format(date_string)
output_file = '\\{}_exhibit_b.xlsx'.format(date_string)

if not os.path.exists(output_dir):
    os.makedirs(output_dir)


quarterly_vintage_data = pd.read_excel(input_dir + input_file, date_string)

ratings = ['AA', 'A', 'B', 'C', 'D', 'E', 'HR']


def generate_average_borrower_rate(quarterly_vintage_data, output_dir, writer):

    terms = pd.unique(quarterly_vintage_data['Term'])

    for t in terms:
        print(str(t))

        coupon = quarterly_vintage_data.loc[(quarterly_vintage_data['Term'] == t), ['ProsperRating', 'OQ', 'AvgBorrowerRate']].groupby(
            by=['ProsperRating', 'OQ']).max().unstack(level=['ProsperRating'])

        coupon2 = coupon.reindex(coupon.index.rename('Quarterly Vintage'))
        coupon2.columns = coupon.columns.droplevel()
        coupon3 = coupon2*100
        coupon3 = coupon3.round(8)
        coupon4 = coupon3.replace(np.nan, 0, regex=True)
        coupon5 = pd.DataFrame(coupon4, dtype=str)
        coupon5 += '%'
        coupon6 = coupon5.replace('0.0%', 'N/A(1)', regex=True)

        ratings = ['AA', 'A', 'B', 'C', 'D', 'E', 'HR']
        ratings_to_print = ratings
        if t == 60:
            ratings_to_print.remove('HR')

        coupon6.loc[:, ratings_to_print].to_excel(
                writer, sheet_name='WA_BR_RATE'+str(t))


def generate_max_cum_loss(quarterly_vintage_data, output_dir, writer):

    quarterly_vintage_data.loc[:, 'Year'] = pd.to_numeric(
            quarterly_vintage_data['OQ'].str[0:4])
    loan_amounts = quarterly_vintage_data.loc[(
            quarterly_vintage_data['Year'] >= 2012) & (
        quarterly_vintage_data['CycleCounter'] == 0),
            ['ProsperRating', 'Term', 'OQ', 'LoanAmount']]

    # By Rating and Term
    max_cum_loss_rc=quarterly_vintage_data.loc[
            quarterly_vintage_data['Year'] >= 2012
            , ['ProsperRating', 'Term', 'CycleCounter', 'OQ', 'CumulativeGrossLossesPct']].groupby(
        by=['ProsperRating','Term','CycleCounter','OQ']).max().unstack(level=['OQ'])
    #Rename indicies
    mcl = max_cum_loss_rc.reindex(max_cum_loss_rc.index.rename(['Rating','Term', 'Period']))
    mcl2 = mcl*100
    mcl2 = mcl2.round(8)
    mcl3 = mcl2.replace(np.nan, '9876', regex=True)
    mcl4 = pd.DataFrame(mcl3, dtype=str)
    mcl4 += '%'
    mcl5 = mcl4.replace('9876%', '', regex=True)
    mcl5.columns = max_cum_loss_rc.columns.droplevel()

    idx = pd.IndexSlice
    ratings = pd.unique(mcl.index.get_level_values(0))
    terms = pd.unique(mcl.index.get_level_values(1))

    for r in ratings:
        for t in terms:
            print(r, t)

            this_loan_amounts = loan_amounts.loc[(loan_amounts['ProsperRating'] == r) & (
                loan_amounts['Term'] == t), ['OQ', 'LoanAmount']].T
            #make OQ the column index
            this_loan_amounts.columns = this_loan_amounts.loc['OQ', :]
            this_loan_amounts = this_loan_amounts.drop('OQ')
            #grab the mcl for this rating and term
            this_mcl5 = mcl5.loc[idx[r, t, :], :].reset_index(drop=True, level=[0,1])
            #prepend loan amounts as top row
            this_output = pd.concat([this_loan_amounts, this_mcl5], sort=True)
            #transpose and make Loan Amount part of the index then swap the order OQ Loan Amount then transpose back
            this_output = this_output.T.set_index(this_output.loc['LoanAmount',:],append=True).drop(
                ['LoanAmount'],axis=1).swaplevel(0,1).T

            if not this_output.empty:
                this_output.to_excel(writer, sheet_name='MCL_' + str(r) + str(t))

    #By Term
    sum_across_ratings = quarterly_vintage_data.loc[quarterly_vintage_data['Year']>=2012,[
        'Term','CycleCounter','OQ','CumulativeGrossLosses','LoanAmount']].groupby(
        by=['Term','CycleCounter','OQ']).sum()
    max_cum_loss_rc = (sum_across_ratings['CumulativeGrossLosses']/sum_across_ratings['LoanAmount']).unstack(
        level=['OQ'])

    loan_amounts = quarterly_vintage_data.loc[(quarterly_vintage_data['Year']>=2012) & (
        quarterly_vintage_data['CycleCounter'] == 0),:].groupby(
        by=['Term','OQ'])['LoanAmount'].sum().reset_index()

    #Rename indicies
    mcl = max_cum_loss_rc.reindex(max_cum_loss_rc.index.rename(['Term', 'Period']))
    mcl2 = mcl*100
    mcl2 = mcl2.round(8)
    mcl3 = mcl2.replace(np.nan, '9876', regex=True)
    mcl4 = pd.DataFrame(mcl3,dtype=str)
    mcl4 += '%'
    mcl5 = mcl4.replace('9876%', '', regex=True)

    idx = pd.IndexSlice
    #ratings = pd.unique(mcl.index.get_level_values(0))
    terms = pd.unique(mcl.index.get_level_values(0))

    for t in terms:
        print(t)

        this_loan_amounts = loan_amounts.loc[(loan_amounts['Term'] == t),['OQ','LoanAmount']].T
        #make OQ the column index
        this_loan_amounts.columns = this_loan_amounts.loc['OQ',:]
        this_loan_amounts = this_loan_amounts.drop('OQ')
        #grab the mcl for this rating and term
        this_mcl5 = mcl5.loc[idx[t,:],:].reset_index(drop=True, level=[0,1])
        #prepend loan amounts as top row
        this_output = pd.concat([this_loan_amounts,this_mcl5],sort=True)
        #transpose and make Loan Amount part of the index then swap the order OQ Loan Amount then transpose back
        this_output = this_output.T.set_index(this_output.loc['LoanAmount',:],append=True).drop(
            ['LoanAmount'],axis=1).swaplevel(0,1).T

        if not this_output.empty:
            this_output.to_excel(writer, sheet_name='MCL_' + str(t))

def generate_dpd(quarterly_vintage_data, output_dir, writer):

    quarterly_vintage_data.loc[:,'Year'] = pd.to_numeric(quarterly_vintage_data['OQ'].str[0:4])
    loan_amounts = quarterly_vintage_data.loc[(quarterly_vintage_data['Year']>=2012) & (
        quarterly_vintage_data['CycleCounter'] == 0),['ProsperRating','Term','OQ','LoanAmount']]
    # BY RATING AND TERM

    dpd16 = quarterly_vintage_data.loc[quarterly_vintage_data['Year']>=2012,[
        'ProsperRating','Term','CycleCounter','OQ','DPD_16']].groupby(by=[
        'ProsperRating','Term','CycleCounter','OQ']).max().unstack(level=['OQ'])#.reset_index()
    #Rename indicies
    dpd16 = dpd16.reindex(dpd16.index.rename(['Rating','Term', 'Period']))
    dpd16_1 = dpd16*100
    dpd16_1 = dpd16_1.round(8)
    dpd16_2 = dpd16_1.replace(np.nan, '9876', regex=True)
    dpd16_3 = pd.DataFrame(dpd16_2,dtype=str)
    dpd16_3 += '%'
    dpd16_4 = dpd16_3.replace('9876%', '', regex=True)
    dpd16_4.columns = dpd16_3.columns.droplevel()

    idx = pd.IndexSlice
    ratings = pd.unique(dpd16.index.get_level_values(0))
    terms = pd.unique(dpd16.index.get_level_values(1))

    for r in ratings:
        for t in terms:
            print(r,t)

            #select out loan amounts for this rating and term and turn it into a single row by OQ
            this_loan_amounts = loan_amounts.loc[(loan_amounts['ProsperRating'] == r) & (
                loan_amounts['Term'] == t),['OQ','LoanAmount']].T
            #make OQ the column index
            this_loan_amounts.columns = this_loan_amounts.loc['OQ',:]
            this_loan_amounts = this_loan_amounts.drop('OQ')
            #grab the mcl for this rating and term
            this_dpd16_4 = dpd16_4.loc[idx[r,t,:],:].reset_index(drop=True, level=[0,1])
            #prepend loan amounts as top row
            this_output = pd.concat([this_loan_amounts,this_dpd16_4],sort=True)

            #transpose and make Loan Amount part of the index then swap the order OQ Loan Amount then transpose back
            this_output = this_output.T.set_index(this_output.loc['LoanAmount',:],append=True).drop(
                ['LoanAmount'],axis=1).swaplevel(0,1).T

            if not this_output.empty:
                this_output.to_excel(writer, sheet_name='DPD_' + str(r) + str(t))

    # BY RATING

    quarterly_vintage_data.loc[:,'Year'] = pd.to_numeric(quarterly_vintage_data['OQ'].str[0:4])
    loan_amounts = quarterly_vintage_data.loc[(quarterly_vintage_data['Year']>=2012) & (
        quarterly_vintage_data['CycleCounter'] == 0),:].groupby(
        by=['Term','OQ'])['LoanAmount'].sum().reset_index()
    dpd16 = quarterly_vintage_data.loc[quarterly_vintage_data['Year']>=2012,[
        'Term','CycleCounter','OQ','DPD_16']].groupby(
        by=['Term','CycleCounter','OQ']).mean().unstack(level=['OQ'])#.reset_index()
    #Rename indicies
    dpd16 = dpd16.reindex(dpd16.index.rename(['Term', 'Period']))
    dpd16_1 = dpd16*100
    dpd16_1 = dpd16_1.round(8)
    dpd16_2 = dpd16_1.replace(np.nan, '9876', regex=True)
    dpd16_3 = pd.DataFrame(dpd16_2,dtype=str)
    dpd16_3 += '%'
    dpd16_4 = dpd16_3.replace('9876%', '', regex=True)
    dpd16_4.columns = dpd16_3.columns.droplevel()

    idx = pd.IndexSlice
    terms = pd.unique(dpd16.index.get_level_values(0))


    for t in terms:
        print(t)

        #select out loan amounts for this rating and term and turn it into a single row by OQ
        this_loan_amounts = loan_amounts.loc[(loan_amounts['Term'] == t),['OQ','LoanAmount']].T
        #make OQ the column index
        this_loan_amounts.columns = this_loan_amounts.loc['OQ',:]
        this_loan_amounts = this_loan_amounts.drop('OQ')
        #grab the dpd for this rating and term
        this_dpd16_4 = dpd16_4.loc[idx[t,:],:].reset_index(drop=True, level=[0,1])
        #prepend loan amounts as top row
        this_output = pd.concat([this_loan_amounts,this_dpd16_4],sort=True)
        #transpose and make Loan Amount part of the index then swap the order OQ Loan Amount then transpose back
        this_output = this_output.T.set_index(this_output.loc['LoanAmount',:],append=True).drop(
            ['LoanAmount'],axis=1).swaplevel(0,1).T

        if not this_output.empty:
            this_output.to_excel(writer, sheet_name='DPD_' + str(t))

def generate_eop_balance(quarterly_vintage_data, output_dir, writer):

    quarterly_vintage_data.loc[:,'Year'] = pd.to_numeric(quarterly_vintage_data['OQ'].str[0:4])
    loan_amounts = quarterly_vintage_data.loc[(quarterly_vintage_data['Year']>=2012) & (
        quarterly_vintage_data['CycleCounter'] == 0),['ProsperRating','Term','OQ','LoanAmount']]
    # BY RATING AND TERM
    eop = quarterly_vintage_data.loc[quarterly_vintage_data['Year']>=2012,[
        'ProsperRating','Term','CycleCounter','OQ','UPB']].groupby(
        by=['ProsperRating','Term','CycleCounter','OQ']).max().unstack(level=['OQ'])#.reset_index()
    #Rename indicies
    eop = eop.reindex(eop.index.rename(['Rating','Term', 'Period']))

    eop1 = eop.replace(np.nan, '', regex=True)
    eop1.columns = eop1.columns.droplevel()

    idx = pd.IndexSlice
    ratings = pd.unique(eop1.index.get_level_values(0))
    terms = pd.unique(eop1.index.get_level_values(1))

    for r in ratings:
        for t in terms:
            print(r,t)

            #select out loan amounts for this rating and term and turn it into a single row by OQ
            this_loan_amounts = loan_amounts.loc[(loan_amounts['ProsperRating'] == r) & (
                loan_amounts['Term'] == t),['OQ','LoanAmount']].T
            #make OQ the column index
            this_loan_amounts.columns = this_loan_amounts.loc['OQ',:]
            this_loan_amounts = this_loan_amounts.drop('OQ')
            #grab the mcl for this rating and term
            this_eop1 = eop1.loc[idx[r,t,:],:].reset_index(drop=True, level=[0,1])
            #prepend loan amounts as top row
            this_output = pd.concat([this_loan_amounts,this_eop1],sort=True)

            #transpose and make Loan Amount part of the index then swap the order OQ Loan Amount then transpose back
            this_output = this_output.T.set_index(this_output.loc['LoanAmount',:],append=True).drop(
                ['LoanAmount'],axis=1).swaplevel(0,1).T

            if not this_output.empty:
                this_output.to_excel(writer, sheet_name='EOP_' + str(r) + str(t))

    #BY TERM

    quarterly_vintage_data.loc[:,'Year'] = pd.to_numeric(quarterly_vintage_data['OQ'].str[0:4])
    loan_amounts = quarterly_vintage_data.loc[(quarterly_vintage_data['Year']>=2012) & (
        quarterly_vintage_data['CycleCounter'] == 0),:].groupby(
        by=['Term','OQ'])['LoanAmount'].sum().reset_index()
    eop=quarterly_vintage_data.loc[quarterly_vintage_data['Year']>=2012,[
        'Term','CycleCounter','OQ','UPB']].groupby(by=['Term','CycleCounter','OQ']).sum().unstack(level=['OQ'])#.reset_index()

    #Rename indicies
    eop = eop.reindex(eop.index.rename(['Term', 'Period']))

    eop1 = eop.replace(np.nan, '', regex=True)
    eop1.columns = eop1.columns.droplevel()

    idx = pd.IndexSlice
    #ratings = pd.unique(mcl.index.get_level_values(0))
    terms = pd.unique(eop.index.get_level_values(0))

    for t in terms:
        print(t)

        #select out loan amounts for this rating and term and turn it into a single row by OQ
        this_loan_amounts = loan_amounts.loc[(loan_amounts['Term'] == t),['OQ','LoanAmount']].T
        #make OQ the column index
        this_loan_amounts.columns = this_loan_amounts.loc['OQ',:]
        this_loan_amounts = this_loan_amounts.drop('OQ')
        #grab the mcl for this rating and term
        this_eop1 = eop1.loc[idx[t,:],:].reset_index(drop=True, level=[0,1])
        #prepend loan amounts as top row
        this_output = pd.concat([this_loan_amounts,this_eop1],sort=True)
        #transpose and make Loan Amount part of the index then swap the order OQ Loan Amount then transpose back
        this_output = this_output.T.set_index(this_output.loc['LoanAmount',:],append=True).drop(
            ['LoanAmount'],axis=1).swaplevel(0,1).T

        if not this_output.empty:
                this_output.to_excel(writer, sheet_name='EOP_' + str(t))

def generate_original_balance(quarterly_vintage_data, output_dir, writer):

    terms = pd.unique(quarterly_vintage_data['Term'])

    for t in terms:

        origbal = quarterly_vintage_data.loc[(quarterly_vintage_data['Term']==t),[
            'ProsperRating','OQ','LoanAmount']].groupby(by=['ProsperRating','OQ']).max().unstack(
            level=['ProsperRating'])#.reset_index()
        origbal2 = origbal.reindex(origbal.index.rename('Quarterly Vintage'))
        origbal2.columns = origbal.columns.droplevel()

        ratings = ['AA','A','B','C','D','E','HR']
        ratings_to_print = ratings#.copy()
        if t == 60:
            ratings_to_print.remove('HR')

        origbal2.loc[:,ratings_to_print].to_excel(writer, sheet_name = 'OPB_' + str(t))

def generate_voluntary_prepay(quarterly_vintage_data, output_dir, writer):

    quarterly_vintage_data.loc[:,'Year'] = pd.to_numeric(quarterly_vintage_data['OQ'].str[0:4])
    loan_amounts = quarterly_vintage_data.loc[(quarterly_vintage_data['Year']>=2012) & (
        quarterly_vintage_data['CycleCounter'] == 0),['ProsperRating','Term','OQ','LoanAmount']]

    # BY RATING AND TERM
    quarterly_vintage_data.loc[:,'prepay'] = (quarterly_vintage_data['FullPaydowns'] +
                                              quarterly_vintage_data['VoluntaryExcessPrin']) / (
        quarterly_vintage_data['PrevUPB'] - quarterly_vintage_data['ScheduledPeriodicPrin'])
    quarterly_vintage_data.loc[:,'voluntary_prepay'] = 1.0-((1.0-quarterly_vintage_data['prepay'])**12.0)

    pp = quarterly_vintage_data.loc[quarterly_vintage_data['Year']>=2012,[
        'ProsperRating','Term','CycleCounter','OQ','voluntary_prepay']].groupby(
        by=['ProsperRating','Term','CycleCounter','OQ']).max().unstack(level=['OQ'])#.reset_index()
    #Rename indicies
    pp = pp.reindex(pp.index.rename(['Rating','Term', 'Period']))
    pp1 = pp*100
    pp1 = pp1.round(8)
    pp2 = pp1.replace(np.nan, '9876', regex=True)
    pp3 = pd.DataFrame(pp2,dtype=str)
    pp3 += '%'
    pp4 = pp3.replace('9876%', '', regex=True)
    pp4.columns = pp3.columns.droplevel()

    idx = pd.IndexSlice
    ratings = pd.unique(pp1.index.get_level_values(0))
    terms = pd.unique(pp1.index.get_level_values(1))

    for r in ratings:
        for t in terms:
            print(r,t)

            #select out loan amounts for this rating and term and turn it into a single row by OQ
            this_loan_amounts = loan_amounts.loc[(loan_amounts['ProsperRating'] == r) & (
                loan_amounts['Term'] == t),['OQ','LoanAmount']].T
            #make OQ the column index
            this_loan_amounts.columns = this_loan_amounts.loc['OQ',:]
            this_loan_amounts = this_loan_amounts.drop('OQ')
            #grab the mcl for this rating and term
            this_pp4 = pp4.loc[idx[r,t,:],:].reset_index(drop=True, level=[0,1])
            #prepend loan amounts as top row
            this_output = pd.concat([this_loan_amounts,this_pp4],sort=True)

            #transpose and make Loan Amount part of the index then swap the order OQ Loan Amount then transpose back
            this_output = this_output.T.set_index(this_output.loc['LoanAmount',:],append=True).drop(
                ['LoanAmount'],axis=1).swaplevel(0,1).T

            if not this_output.empty:
                this_output.to_excel(writer, sheet_name='CPR_' + str(r) + str(t))

    # BY RATING

    quarterly_vintage_data.loc[:,'Year'] = pd.to_numeric(quarterly_vintage_data['OQ'].str[0:4])
    loan_amounts = quarterly_vintage_data.loc[(quarterly_vintage_data['Year']>=2012) & (
        quarterly_vintage_data['CycleCounter'] == 0),:].groupby(
        by=['Term','OQ'])['LoanAmount'].sum().reset_index()

    sum_across_ratings = quarterly_vintage_data.loc[quarterly_vintage_data['Year']>=2012,[
        'Term','CycleCounter','OQ','FullPaydowns','VoluntaryExcessPrin','PrevUPB','ScheduledPeriodicPrin']
                                                   ].groupby(by=['Term','CycleCounter','OQ']).sum()
    sum_across_ratings.loc[:,'prepay'] = (sum_across_ratings['FullPaydowns'] + sum_across_ratings[
        'VoluntaryExcessPrin']) / (sum_across_ratings['PrevUPB'] - sum_across_ratings['ScheduledPeriodicPrin'])
    sum_across_ratings.loc[:,'prepay'] = (sum_across_ratings['FullPaydowns'] + sum_across_ratings[
        'VoluntaryExcessPrin']) / (sum_across_ratings['PrevUPB'])

    sum_across_ratings.loc[:,'voluntary_prepay'] = 1.0-((1.0-sum_across_ratings['prepay'])**12.0)

    pp = sum_across_ratings['voluntary_prepay'].unstack(level=['OQ'])#.reset_index()
    pp = pp.reindex(pp.index.rename(['Term', 'Period']))
    pp1 = pp*100
    pp1 = pp1.round(8)
    pp2 = pp1.replace(np.nan, '9876', regex=True)
    pp3 = pd.DataFrame(pp2,dtype=str)
    pp3 += '%'
    pp4 = pp3.replace('9876%', '', regex=True)

    idx = pd.IndexSlice
    terms = pd.unique(pp1.index.get_level_values(0))


    for t in terms:
        print(t)

         #select out loan amounts for this rating and term and turn it into a single row by OQ
        this_loan_amounts = loan_amounts.loc[(loan_amounts['Term'] == t),['OQ','LoanAmount']].T
            #make OQ the column index
        this_loan_amounts.columns = this_loan_amounts.loc['OQ',:]
        this_loan_amounts = this_loan_amounts.drop('OQ')
        #grab the mcl for this rating and term
        this_pp4 = pp4.loc[idx[t,:],:].reset_index(drop=True, level=[0,1])
        #prepend loan amounts as top row
        this_output = pd.concat([this_loan_amounts,this_pp4],sort=True)
        #transpose and make Loan Amount part of the index then swap the order OQ Loan Amount then transpose back
        this_output = this_output.T.set_index(this_output.loc['LoanAmount',:],append=True).drop(
            ['LoanAmount'],axis=1).swaplevel(0,1).T

        if not this_output.empty:
                this_output.to_excel(writer, sheet_name='CPR_' + str(t))

def generate_dt_data():
    writer = pd.ExcelWriter(output_dir+output_file, engine='xlsxwriter')

    generate_average_borrower_rate(quarterly_vintage_data, output_dir, writer)
    generate_max_cum_loss(quarterly_vintage_data, output_dir, writer)
    generate_dpd(quarterly_vintage_data, output_dir, writer)
    generate_eop_balance(quarterly_vintage_data, output_dir, writer)
    generate_original_balance(quarterly_vintage_data, output_dir, writer)
    generate_voluntary_prepay(quarterly_vintage_data, output_dir, writer)
