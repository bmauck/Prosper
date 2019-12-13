import PySimpleGUI as sg
import os
os.chdir('D:\CapitalMarkets\__apps__\capital-markets-tools\\')
from investor_files import *


tab1_layout = [
    [sg.T('This will return a LenderID based on an investor name')]
    ,[sg.InputText('Input Investor Name Here') #value[1]
    ,sg.Button('Get Info')]
    ]

tab2_layout = [
    [sg.T('This will write investor files to the out-files folder')]
    ,[sg.Listbox(['Positions', 'Payments', 'Remits', 'Transactions'],no_scrollbar=False) #value[2]
    ,sg.InputText('Start Date', size=(10,1)) #value[3]
    ,sg.InputText('End Date', size=(10,1)) #value[4]
    ,sg.Button('Write File')]
    ]

tab3_layout = [
    [sg.T('This will assist in cutting and analyzing loan tapes')]
    ,[sg.InputText('AsOf Date', size=(10,1)) #value[6]
    ,sg.Checkbox('Remove Sold?') #value[7]
    ,sg.Checkbox('Remove Ineligible?') #value[8]
    ,sg.Checkbox('Include Strats?')] #value[9]
    ,[sg.Button('Get Strats')
    ,sg.Button('Write Loan Tape')]
    ]

layout = [
    [sg.Text('This is a suite of capital markets automation tools'
        ,justification='center'
        ,size=(65,1))]
    ,[sg.T('Set LenderID:                 ') 
    ,sg.InputText('LenderID', size=(15,1))] #value[0]
    ,[sg.T('Don\'t know the LenderID?')
    ,sg.InputText('Investor Name', size=(15,1)) #value[1]
    ,sg.Button('Get Info')]
    ,[sg.TabGroup(
            [
            [sg.Tab('Write Investor Files', tab2_layout, tooltip='')
            ,sg.Tab('Loan Tapes', tab3_layout, tooltip='', visible=False)]
            ])]
    ,[sg.Quit()]
    ]

window = sg.Window('Capital Markets Tool Dashboard'
    ,layout
    ,element_padding=((4,4),(4,4))
    )

while True:
    event, values = window.Read()
    print(event, values)
    if event in ('Quit', None):
        break
    elif event == 'Get Info':
        investor_name = values[1]
        LenderIDs = get_username_and_id(investor_name)
        sg.PopupOK(LenderIDs
            , title='Investors and LenderIDs')
    elif event == 'Write File':
        i = values[0]
        d1 = values[3]
        d2 = values[4]
        i = investor(i)
        print(i, d1, d2)
        if values[2] == ['Payments']:
            write_file(i.pmts(d1, d2), str(i.id)+'_payments-'+d2+'.csv')
        elif values[2] == ['Positions']:
            write_file(i.positions(d2), str(i.id)+'_positions-'+d2+'.csv')
        elif values[2] == ['Transactions']:
            write_file(i.trxns(d1, d2), str(i.id)+'_transactions-'+d2+'.csv')
        elif values[2] == ['Remits']:
            write_file(i.remits(d1, d2), str(i.id)+'_remits-'+d2+'.csv')
        else:
            pass
    elif event == 'Write Loan Tape':
        i = values[0]
        d = values[5]
        i = investor(i)
        if (values[6] == False) & (values[7] == False) & (values[8] == False):
            write_file(i.tape(d), str(i.id)+'_loan_tape-'+d+'.csv')
        elif (values[6] == True) & (values[7] == False) & (values[8] == False):
            write_file(remove_sold(i.tape(d)), str(i.id)+'_loan_tape-'+d+'.csv')
        elif (values[6] == False) & (values[7] == True) & (values[8] == False):
            write_file(filter_ineligible(i.tape(d)), str(i.id)+'_loan_tape(elig)-'+d+'.csv')
        elif (values[6] == False) & (values[7] == False) & (values[8] == True):
            write_tape_strats(str(i.id)+'_loan_tape_w/strats-'+d, i.tape(d), str(i.id))
        elif (values[6] == True) & (values[7] == False) & (values[8] == True):
            write_tape_strats(str(i.id)+'_loan_tape_w/strats-'+d, remove_sold(i.tape(d)), str(i.id))
        elif ((values[6] == False) | (values[6] == True)) & (values[7] == True) & (values[8] == True):
            write_tape_strats(str(i.id)+'_loan_tape_w/strats(elig)-'+d, filter_ineligible(i.tape(d)), str(i.id))
        else:
            pass
    elif event == 'Get Strats':
        i = values[0]
        d = values[5]
        i = investor(i)
        if (values[6] == False) & (values[7] == False) & (values[8] == False):
            df = pd.DataFrame(get_tape_strats(i.tape(d)))
            sg.PopupOK(tabulate(df, headers=df.columns, tablefmt='psql'), title=str(i.id)+' Loan Tape Strats')
        else:
            pass
    elif event == 'Return Values':
        print(values)
    elif event == 'Today':
        print(today)