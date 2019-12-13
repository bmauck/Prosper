import PySimpleGUI as sg
import pydata_google_auth
from exhibit_b import generate_dt_data
from historical_platform_performance import write_performance_file
from platform_cnl_test import write_cnl_test

SCOPES = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/drive',
]

credentials = pydata_google_auth.get_user_credentials(
    SCOPES
    , auth_local_webserver=True
)  

# Layout the design of the GUI
layout = [
        [sg.Button('Generate Vintage File')
        , sg.Button('Generate Exhibit B')
        , sg.Button('Generate CNL Test File')]
        , [sg.Quit()]]
sg.ChangeLookAndFeel('DarkTanBlue')
    
# Show the Window to the user
window = sg.Window('Platform Performance Reports', layout)

# Event loop. Read buttons, make callbacks
while True:
    # Read the Window
    event, values = window.Read()
    if event in ('Quit', None):
        break
    elif event in ('Generate Vintage File'):
        write_performance_file()
        sg.PopupOK('Done')
    elif event in ('Generate Exhibit B'):
        generate_dt_data()
        sg.PopupOK('Done')
    elif event in ('Generate CNL Test File'):
        write_cnl_test()
        sg.PopupOK('Done')

window.Close()

    # All done!
# sg.PopupOK('Done')     