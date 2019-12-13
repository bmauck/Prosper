import pandas as pd
import sqlalchemy
import datetime as dt
from tqdm import tqdm

dest_fld = 'D:\\CapitalMarkets\\Output Files\\'
db = 'ReportingProgrammability'
svr = '@dbrpt/{db}?driver=SQL+Server+Native+Client+11.0'.format(db=db)
engine = sqlalchemy.create_engine('mssql+pyodbc://'+svr)

today = dt.date.isoformat(dt.date.today())

class loan:
    
    def __init__(self, id):
        self.id = id
        self.investor = int(input('What investor? '))
        self.d1 = str(input('What start date? '))
        self.d2 = str(input('What end date? '))
    
    
    def trxns(self):

        print('Querying...')
        sql = """
        EXEC	[TabReporting].[C1\\bmauck].[loan_trxns_file] '{}', '{}', {}, {}
        """        
        cxn = engine.connect()
        df = pd.read_sql_query(sql.format(self.d1, self.d2, self.investor, self.id), cxn)
        cxn.close()

        print('Done')    
        return df
    
    
    def pmts(self):

        print('Querying...')
        sql = """
        EXEC	[TabReporting].[C1\\bmauck].[loan_pmts_file] {}, '{}', '{}', {}
        """        
        cxn = engine.connect()
        df = pd.read_sql_query(sql.format(self.investor, self.d1, self.d2, self.id), cxn)
        cxn.close()

        print('Done')    
        return df
    
    
    def positions(self):

        df = pd.DataFrame()
        print('Querying...')
        for d in tqdm(pd.date_range(self.d1, self.d2)):
            d = str(d.date())
            sql = """
            EXEC	[TabReporting].[C1\\bmauck].[loan_pos_file] '{}', {}, {}
            """
            cxn = engine.connect()
            df1 = pd.read_sql_query(sql.format(d, self.investor, self.id), cxn)
            df = df.append(df1)
        cxn.close()

        print('Done')    
        return df
    
    
    def write_loan_packet(self):
        
        writer = pd.ExcelWriter(dest_fld+str(self.id)+'_LoanReportingPacket.xlsx', engine='xlsxwriter')
        
        self.positions().to_excel(writer, sheet_name='Positions')
        self.pmts().to_excel(writer, sheet_name='Payments')
        self.trxns().to_excel(writer, sheet_name='Transactions')
        
        writer.save()