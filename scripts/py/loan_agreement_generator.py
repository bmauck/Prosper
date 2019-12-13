
# coding: utf-8

# In[2]:


import pandas as pd
import re
from xhtml2pdf import pisa     
import sqlalchemy,datetime 
from sqlalchemy.dialects.mssql import DATE
from sqlalchemy.schema import Table, MetaData
import os


# In[3]:


query = """
set nocount on 

select 
    LoanID
	,at.Title
	,a.IsCorrectedAgreement
	,html = cast(Circleone.dbo.fn_decompress(a.AgreementBodyBinary, len(a.AgreementBodyBinary)) as varchar(max))
	from 
		Circleone..Agreements a
	join 
		Circleone..LoanToAgreement lta
		on 
		lta.AgreementID = a.ID
	join 
		CircleOne..AgreementTypes at
		on 
		at.ID = a.AgreementTypeID
	where
		1=1
		and lta.LoanID in ({})
		and AgreementTypeID in (5555570, 3)
"""


# In[9]:


loan_id = """

"""


# In[5]:


dir = 'U:\\Users\\bmauck\\notebooks'
db = 'CircleOne'
query = query.format(loan_id)
engine = sqlalchemy.create_engine('mssql+pyodbc://@dbrpt/{db}?driver=SQL+Server+Native+Client+11.0'.format(db=db))
connection = engine.connect()
p = pd.read_sql_query(query, connection, index_col='LoanID')
connection.close()


# In[6]:


def convertHtmlToPdf(sourceHtml, outputFilename):
    resultFile = open(outputFilename, "w+b")
    pisaStatus = pisa.CreatePDF(sourceHtml,dest=resultFile)
    resultFile.close()
    
    return pisaStatus.err


# In[7]:


def generate_br_files(p):
    import pandas as pd
    import re
    from xhtml2pdf import pisa     
    import sqlalchemy,datetime 
    from sqlalchemy.dialects.mssql import DATE
    from sqlalchemy.schema import Table, MetaData
    import os
    
    for index, row in p.iterrows():
        if row.IsCorrectedAgreement is True:
            file = dir+'\\output_files\\{} {} (Corrected)'.format(index, row.Title)

            html_file = open(file+'.html', 'w')
            html_file.write(row['html'])
            html_file.close()
        
            with open(file+'.html', 'r')as g:
                sourceHtml = g.read()
            outputFilename = file+'.pdf'
            os.remove(file+'.html')
        
            convertHtmlToPdf(sourceHtml, outputFilename)
        elif row.IsCorrectedAgreement is False:
            file = dir+'\\output_files\\{} {}'.format(index, row.Title)
            
            html_file = open(file+'.html', 'w')
            html_file.write(row['html'])
            html_file.close()
        
            with open(file+'.html', 'r')as g:
                sourceHtml = g.read()
            outputFilename = file+'.pdf'
            os.remove(file+'.html')
        
            convertHtmlToPdf(sourceHtml, outputFilename)
        
        else:
            print('error')


# In[8]:


generate_br_files(p)

