import pandas as pd
import sqlalchemy
import datetime as dt

dest_fld = 'D:\\CapitalMarkets\\Output Files\\'
db = 'ReportingProgrammability'
svr = '@dbrpt/{db}?driver=SQL+Server+Native+Client+11.0'.format(db=db)
engine = sqlalchemy.create_engine('mssql+pyodbc://'+svr)

today = dt.date.isoformat(dt.date.today())


class investor:

    def __init__(self, id):
        self.id = id
        
    def tape(self, date):
        
        print('Querying...')
    
        staging = open('D:/CapitalMarkets/Mauck/scripts/sql/tape_staging.sql', 'r')
        result = open('D:/CapitalMarkets/Mauck/scripts/sql/tape_result.sql', 'r')
    
        staging_sql = staging.read()
        result_sql = result.read()
    
        cxn = engine.connect()
        cxn.execute(staging_sql.format(date, date, self.id))
        df = pd.read_sql_query(result_sql, cxn)
        cxn.close()
        
        print('Done')
        
        return df

    def trxns(self, date1, date2):
        
        d1 = str('"'+date1+'"')
        d2 = str('"'+date2+'"')

        query = """
        exec Report_DailyLenderPacket_Transactions {}, {}, {}
        """.format(self.id, d1, d2)
        
        print('Querying...')
        cxn = engine.connect()
        df = pd.read_sql_query(query, cxn)
        cxn.close()
        
        print('Done')    
        
        return df
        

    def positions(self, date):
        
        d1 = str('"'+date+'"')
        d2 = str('"'+date+'"')

        query = """
        exec Report_DailyLenderPacket_Positions {}, {}, {}
        """.format(self.id, d1, d2)
        
        print('Querying...')
        cxn = engine.connect()
        df = pd.read_sql_query(query, cxn)
        cxn.close()
        
        print('Done')
        
        return df
        
 
    def remits(self, date1, date2):
    
        df = pd.DataFrame()
        dates = pd.date_range(date1, date2).tolist()
        
        print('Querying...')
        
        cxn = engine.connect()
        for day in tqdm(dates):
            d = str('"'+str(day.date())+'"')
            query = 'exec Report_DailyLenderPacket_Remit {}, {}'.format(
                    self.id, d)
            p = pd.read_sql_query(query, cxn)
            df = df.append(p)
        cxn.close()
        
        print('Done')
        
        return df
        

    def pmts(self, date1, date2):
    
        d1 = str('"'+date1+'"')
        d2 = str('"'+date2+'"')

        query = """
        exec Report_DailyLenderPacket_Payments {}, {}, {}
        """.format(self.id, d1, d2)
        
        print('Querying...')
        
        cxn = engine.connect()
        df = pd.read_sql_query(query, cxn)
        cxn.close()
        
        print('Done')
        
        return df
        

def get_username_and_id():
    
    investor_name = input('What investor? ')
    sql = open('D:/CapitalMarkets/Mauck/scripts/sql/current_username.sql', 'r')
    sql = sql.read()
    
    cxn = engine.connect()
    df = pd.read_sql_query(sql.format(investor_name), cxn)
    cxn.close()
    
    return df


def write_file(report, filename):

    filename = filename

    print('Writing Files...')
    report.to_csv(dest_fld+filename)
    print('Done')
