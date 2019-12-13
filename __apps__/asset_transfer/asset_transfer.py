import PySimpleGUI as sg
import asset_transfer_files as xfer

# Layout the design of the GUI
layout = [[sg.Text('Browse for loan tape and input buyer ID below', auto_size_text=False)]
          , [sg.Text('Browse for Loan Tape')
          , sg.InputText(), sg.FileBrowse()
          , sg.Button('Get Loan Data')]
          
          , [sg.Text('Enter Buyer ID')
          , sg.InputText()
          , sg.Button('Write Hub Files')]
          
          , [sg.Quit()]]

sg.ChangeLookAndFeel('DarkTanBlue')

# Show the Window to the user
window = sg.Window('Asset Transfer', layout)


# Event loop. Read buttons, make callbacks
while True:
    # Read the Window
    event, values = window.Read()
    if event in ('Quit', None):
        break
    elif event in ('Get Loan Data'):
        tape_filename = values[0]
        loans = xfer.get_loans(tape_filename)
        loans_count = len(loans)
        sg.PopupOK('There are {} loans in this pool'.format(loans_count))
    elif event in ('Write Hub Files'):
        xfer.get_intent_data(loans)
        buyer_id = values[1]
        xfer.get_transfer_data(buyer_id, loans)
        sg.PopupOK('Files Written')

window.Close()

    # All done!
# sg.PopupOK('Done')     