def generate_files(investors, date1, date2, reports, is_cumul):
    import pandas as pd
    import numpy as np
    import matplotlib.pyplot as plt
    import sqlalchemy,datetime 
    from sqlalchemy.dialects.mssql import DATE
    from sqlalchemy.schema import Table, MetaData
    from tabulate import tabulate 
    import datetime as dt

    global remit

    cumul_file = pd.DataFrame()
    dates = pd.date_range(start, date2).tolist()

    for r in reports:

        for i in investors:

            for day in dates:

                d1 = str('"'+start+'"')
                d2 = str('"'+end.format(day.date())+'"')

                if r == 'Remit':
                    query = 'exec Report_DailyLenderPacket_{} {}, {}'.format(r,i,d2)
                else:
                    query = 'exec Report_DailyLenderPacket_{} {}, {}, {}'.format(r,i,d1,d2)
                db = 'ReportingProgrammability'
                engine = sqlalchemy.create_engine(
                        'mssql+pyodbc://@allocations/{db}?driver=SQL+Server+Native+Client+11.0'.format(db=db))
                connection = engine.connect()
                p = pd.read_sql_query(query, connection)

                cumul_file = cumul_file.append(p)

                d2 = d2.strip("\"")

                file = '{}LenderPacket_{}{}.csv'.format(i,r,d2.strip("\'").replace('-', ''))
                fld = 'D:\\CapitalMarkets\\Output Files\\'

                if is_cumul == 0:
                    p.to_csv(fld+file)
                else:
                    pass
                print(r,i,d1,d2)

            if is_cumul == 1:
                cumul_file.to_csv(fld+'{}_cumul_{}.csv'.format(i, r))
            else:
                pass
    connection.close()