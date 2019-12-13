# -*- coding: utf-8 -*-
"""
Created on Tue Apr  2 14:53:37 2019

@author: bmauck
"""

import datetime as dt
import numpy as np
import pandas as pd
from dateutil.relativedelta import relativedelta
from capmkts_automation import explore_file


def recon_deal(investor, date=dt.date.today()):

    beg_date = date.replace(day=1) + relativedelta(months=-1)
    end_date = date.replace(day=1) + relativedelta(months=0)
    settle_date = end_date + relativedelta(days=14)

    payments = explore_file(investor, str(beg_date), str(end_date), 'Payments')

    positions_1 = explore_file(
            investor, str(beg_date.isoformat()), str(
                    beg_date.isoformat()), 'Positions')
    positions_2 = explore_file(
            investor, str(end_date.isoformat()), str(
                    end_date.isoformat()), 'Positions')

    report = pd.DataFrame()

    report['settlement_date'] = [str(settle_date)]

    report['beg_loan_count'] = [positions_1['LoanNumber'][
            positions_1['LoanStatusDescription'] == 'CURRENT'].count()]
    report['end_loan_count'] = [positions_2['LoanNumber'][
            positions_2['LoanStatusDescription'] == 'CURRENT'].count()]
    report['beg_upb'] = [
            positions_1['PrincipalBalance'].sum()]
    report['end_upb'] = [positions_2['PrincipalBalance'].sum()]

    report['beg_wac'] = [np.average(
            positions_1['BorrowerRate'
                        ], weights=positions_1['PrincipalBalance'])]
    report['end_wac'] = [np.average(
            positions_2['BorrowerRate'
                        ], weights=positions_2['PrincipalBalance'])]
    report['total_prin'] = [payments['PrincipalAmount'][
            payments['PaymentStatus'] == 'Success'].sum()]
    report['fail_prin'] = [payments['PrincipalAmount'][
            payments['PaymentStatus'] == 'Fail'].sum()]
    report['net_prin'] = report[
            'total_prin'].values + report['fail_prin'].values

    report['total_int'] = [payments['InterestAmount'][
            payments['PaymentStatus'] == 'Success'].sum()]
    report['fail_int'] = [payments['InterestAmount'][
            payments['PaymentStatus'] == 'Fail'].sum()]
    report['net_int'] = report['total_int'].values + report['fail_int'].values

    report['late_fees'] = [payments['LateFeeAmount'].sum()]

    report['clx_fees'] = [payments['CollectionFeeAmount'].sum()]

    report['srv_fees'] = [payments['ServiceFeeAmount'].sum()]

    report['cur_count'] = [positions_2['PrincipalBalance'][
        positions_2['DaysPastDue'] == 0].count()]
    report['cur_upb'] = [positions_2['PrincipalBalance'][
        positions_2['DaysPastDue'] == 0].sum()]
    report['dq_15_count'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 0) & (
                positions_2['DaysPastDue'] <= 15)].count()]
    report['dq_15_upb'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 0) & (
                positions_2['DaysPastDue'] <= 15)].sum()]
    report['dq_29_count'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 16) & (
                positions_2['DaysPastDue'] <= 29)].count()]
    report['dq_29_upb'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 16) & (
                positions_2['DaysPastDue'] <= 29)].sum()]
    report['dq_59_count'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 30) & (
                positions_2['DaysPastDue'] <= 59)].count()]
    report['dq_59_upb'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 30) & (
                positions_2['DaysPastDue'] <= 59)].sum()]
    report['dq_89_count'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 60) & (
                positions_2['DaysPastDue'] <= 89)].count()]
    report['dq_89_upb'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 60) & (
                positions_2['DaysPastDue'] <= 89)].sum()]
    report['dq_120_count'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 90) & (
                positions_2['DaysPastDue'] <= 120)].count()]
    report['dq_120_upb'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 90) & (
                positions_2['DaysPastDue'] <= 120)].sum()]
    report['dq_120+_count'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 120)].count()]
    report['dq_120+_upb'] = [positions_2['PrincipalBalance'][
        (positions_2['DaysPastDue'] > 120)].sum()]
    report['canc_count'] = [positions_2['PrincipalBalance'][
        positions_2['LoanStatusDescription'] == 'CANCELLED'].count()]
    report['canc_opb'] = [positions_2['PrincipalBalance'][
        positions_2['LoanStatusDescription'] == 'CANCELLED'].sum()]
    report['chg_off_gross'] = [positions_2[
            'PrincipalBalanceAtChargeoff'].sum()]

    report = report.set_index('settlement_date')
    report = report.T

    return report
