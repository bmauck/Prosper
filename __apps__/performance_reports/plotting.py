import datetime as dt
import matplotlib.pyplot as plt
import pandas as pd
import tabula
from performance_reports import get_performance_data


def plot_wt_factors():
    tables = tabula.read_pdf('PROSP19_2-DIS-2019-09.pdf', pages=3, multiple_tables=True)
    df = tables[0].T
    df = df.set_index(0, drop=True)
    df = df.T
    df = df.set_index('Notes', drop=True)
    pd.to_numeric(df['Endingx Balancex']).plot(kind='bar')
    plt.title('Bond Factors (1000s)', fontsize=16)
    plt.grid()
    plt.xticks(rotation=0)
    return plt


def plot_page1_charts(df):

    plt.style.use('seaborn-white')
    fig, axs = plt.subplots(2,2, figsize=(20, 10), sharey=False, sharex=True)
    plt.suptitle('PMIT Performance', fontsize=22)
    subplot_font=16
    
    axs1_col = df['AnnualizedNetReturn']
    axs[0,0].set_ylabel('Percent')
    axs[0,0].grid()
    axs[0,0].set_title('Annualized Net Return', fontsize=subplot_font)
    axs[0,0].plot(
            df['ObsMonth']
            , axs1_col
                )

    axs[0,1].set_ylabel('Percent')
    axs[0,1].grid()
    axs[0,1].set_title('Percent Dollars DQ', fontsize=subplot_font)
    axs[0,1].plot(
            df['ObsMonth']
            , df['DPD_31']
            , label='DQ 30+'
                )
    axs[0,1].plot(
            df['ObsMonth']
            , df['DPD_61']
            , label='DQ 60+'
                )
    axs[0,1].plot(
            df['ObsMonth']
            , df['DPD_91']
            , label='DQ 90+'
                )
    axs[0,1].legend()

    axs3_col = df['CumulativeNetLossesPct']
    axs[1,0].set_ylabel('Percent')
    axs[1,0].grid()
    axs[1,0].set_title('Cumulative Net Loss Percent', fontsize=subplot_font)
    axs[1,0].plot(
            df['ObsMonth']
            , axs3_col
                )

    axs4_col = df['CumulPrepay']
    axs[1,1].set_ylabel('Percent')
    axs[1,1].grid()
    axs[1,1].set_title('Cumulative Prepay Percent', fontsize=subplot_font)
    axs[1,1].plot(
            df['ObsMonth']
            , axs4_col
                )
    for ax in fig.axes:
        plt.sca(ax)
        plt.xticks(rotation=45)
        ax.set_yticklabels(['{:,.2%}'.format(y) for y in ax.get_yticks()])

    plt.tight_layout(rect=[0.1, 0.1, 1, 0.95])
    return plt


def plot_page2_charts(df):

    plt.style.use('seaborn-white')
    fig, axs = plt.subplots(2,2, figsize=(20, 10), sharey=False, sharex=False)
    plt.suptitle('PMIT Performance', fontsize=22)
    subplot_font = 16
    
    axs1_col = df['CDR']
    axs[0,0].set_ylabel('Percent')
    axs[0,0].grid()
    axs[0,0].set_title(axs1_col.name, fontsize=subplot_font)
    axs[0,0].set_yticklabels(['{:,.2%}'.format(y) for y in axs[0,1].get_yticks()])
    axs[0,0].plot(
            df['ObsMonth']
            , axs1_col
                )

    axs2_col = df['CPR']
    axs[0,1].set_ylabel('Percent')
    axs[0,1].grid()
    axs[0,1].set_title(axs2_col.name, fontsize=subplot_font)
    axs[0,1].set_yticklabels(['{:,.2%}'.format(y) for y in axs[0,1].get_yticks()])
    axs[0,1].plot(
            df['ObsMonth']
            , axs2_col
                )

    begin_upb = df['PrevUPB'].max()
    cur_upb = df['UPB'].min()

    begin_upb = '${:0,.0f}'.format(begin_upb).replace('$-','-$')
    cur_upb = '${:0,.0f}'.format(cur_upb).replace('$-', '-$')

    table_data = [begin_upb, cur_upb]

    axs[1,0].table(cellText=[
        table_data
    ]
                   ,colWidths=[0.3] * 2
                   ,fontsize=22
                   ,rowLabels=['Principal Balance']
                   ,colLabels=['Closing','Current']
                   ,bbox=[0.2, 0.2, 0.6, 0.5]
                   ,loc='center'

                  )

    axs[1,0].tick_params(axis='x', which='both', bottom=False, top=False, labelbottom=False)
    axs[1,0].tick_params(axis='y', which='both', right=False, left=False, labelleft=False)
    for pos in ['right','top','bottom','left']:
        axs[1,0].spines[pos].set_visible(False)

    axs[1,1] = plot_wt_factors()

    plt.tight_layout(rect=[0.1, 0.1, 1, 0.95])

    return plt