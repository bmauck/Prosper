import datetime as dt
import pandas as pd
import numpy as np
from tqdm import tqdm
import matplotlib.pyplot as plt
from dateutil.relativedelta import relativedelta


def dest_dir(filepath):
    path = filepath
    return path


def add_oq(tape):
    tape.OriginationDate = pd.to_datetime(tape.OriginationDate)
    for index, row in tqdm(tape.iterrows()):
        tape.loc[index, 'RatingTerm'] = str(row.ProsperRating) + str(row.Term)
        tape.loc[index, 'OQ'] = str(row.OriginationDate.year) + 'Q' + str(
                row.OriginationDate.quarter)
    return tape


def gen_loss_curve(tape):

    today = dt.datetime.now()
    today = pd.to_datetime(today.date())

    vintages = tape.OQ.unique()

    cols = ['AA36', 'A36', 'B36', 'C36', 'D36', 'E36', 'HR36', 'AA60', 'A60',
            'B60', 'C60', 'D60', 'E60']

    ratingDict = {}
    for vin in tqdm(vintages):
        rating_sum = tape[tape.OQ == vin].groupby(
                'RatingTerm').PrincipalBalance.sum()
        rating_weights = rating_sum / tape[
                tape.OQ == vin].PrincipalBalance.sum()
        ratingDict[vin] = rating_weights

    rating_weightsDF = pd.DataFrame.from_dict(ratingDict, orient='index')
    rating_weightsDF = rating_weightsDF.reindex(columns=cols)
    rating_weightsDF = rating_weightsDF.fillna(0, axis=1)

    vintage_sum = tape.groupby('OQ').PrincipalBalance.sum()
    vintage_weights = vintage_sum / tape.PrincipalBalance.sum()
    vintage_weightsDF = pd.DataFrame(vintage_weights)

    vintagesDF = pd.DataFrame(tape.OQ.unique(), columns=['OQ'])
    vintagesDF['OQ_DT'] = pd.to_datetime(vintagesDF.OQ)

    for index, row in tqdm(vintagesDF.iterrows()):
        vintagesDF.loc[index, 'Age'] = (relativedelta(
                today, row.OQ_DT).years*12 + relativedelta(
                        today, row.OQ_DT).months)
    vintagesDF = vintagesDF.set_index('OQ')

    curveDF = pd.DataFrame(columns=vintages)

    for qtr in tqdm(vintagesDF.index):
        loss_data = pd.read_excel(
                'D:\\CapitalMarkets\\Performance Curves\\loss_curves.xlsx',
                sheet_name='{}'.format(qtr))

        curve = []
        for index, row in tqdm(loss_data.iterrows()):
            curve_period = np.average(loss_data.loc[index],
                                      weights=rating_weightsDF.loc[qtr])
            curve.append(curve_period)

        curveDF[qtr] = curve
        vintage_weights = vintage_weights.T

    for qtr in tqdm(vintages):
        curve = []
        for index, row in curveDF.iterrows():
            curve_period = np.average(
                    curveDF.loc[index],
                    weights=vintage_weightsDF.PrincipalBalance)
            curve.append(curve_period)
        curve = pd.DataFrame(curve, columns=['Losses'])
    return curve


def gen_prepay_curve(tape):

    today = dt.datetime.now()
    today = pd.to_datetime(today.date())

    vintages = tape.OQ.unique()

    cols = ['AA36', 'A36', 'B36', 'C36', 'D36', 'E36', 'HR36',
            'AA60', 'A60', 'B60', 'C60', 'D60', 'E60']

    ratingDict = {}
    for vin in tqdm(vintages):
        rating_sum = tape[tape.OQ == vin].groupby(
                'RatingTerm').PrincipalBalance.sum()
        rating_weights = rating_sum / tape[
                tape.OQ == vin].PrincipalBalance.sum()
        ratingDict[vin] = rating_weights

    rating_weightsDF = pd.DataFrame.from_dict(ratingDict, orient='index')
    rating_weightsDF = rating_weightsDF.reindex(columns=cols)
    rating_weightsDF = rating_weightsDF.fillna(0, axis=1)

    vintage_sum = tape.groupby('OQ').PrincipalBalance.sum()
    vintage_weights = vintage_sum / tape.PrincipalBalance.sum()
    vintage_weightsDF = pd.DataFrame(vintage_weights)

    vintagesDF = pd.DataFrame(tape.OQ.unique(), columns=['OQ'])
    vintagesDF['OQ_DT'] = pd.to_datetime(vintagesDF.OQ)

    for index, row in tqdm(vintagesDF.iterrows()):
        vintagesDF.loc[index, 'Age'] = (
                relativedelta(today, row.OQ_DT).years*12 + relativedelta(
                        today, row.OQ_DT).months)
    vintagesDF = vintagesDF.set_index('OQ')

    curveDF = pd.DataFrame(columns=vintages)

    for qtr in tqdm(vintagesDF.index):
        loss_data = pd.read_excel(
                'D:\\CapitalMarkets\\Performance Curves\\prepay_curves.xlsx',
                sheet_name='{}'.format(qtr))

        curve = []
        for index, row in tqdm(loss_data.iterrows()):
            curve_period = np.average(loss_data.loc[index],
                                      weights=rating_weightsDF.loc[qtr])
            curve.append(curve_period)

        curveDF[qtr] = curve
        vintage_weights = vintage_weights.T

    for qtr in tqdm(vintages):
        curve = []
        for index, row in tqdm(curveDF.iterrows()):
            curve_period = np.average(
                    curveDF.loc[index],
                    weights=vintage_weightsDF.PrincipalBalance)
            curve.append(curve_period)
    curve = pd.DataFrame(curve, columns=['Prepayments'])
    return curve


def plot_curves(title, curve1, curve2):
    plt.figure(1, figsize=(10, 5))
    plt.suptitle(title, fontsize=15)
    plt.style.use('ggplot')

    for i in range(0, 1):
        plt.subplot(1, 1, i+1)

        curve1.plot(ax=plt.gca())
        curve2.plot(ax=plt.gca())

        plt.ylabel('Percent', fontsize=10)
        plt.xlabel('Month On Book', fontsize=10)
    plt.show()
