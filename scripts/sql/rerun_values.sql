DECLARE @FileTypes TABLE (FileTypeID INT)
INSERT INTO @FileTypes
VALUES (1) /* Enter File Type(s) here */
  
DECLARE @Users TABLE (UserID INT)
INSERT INTO @Users (USerID)
VALUES 


(8196710)

  
DECLARE @Clients TABLE (ClientID NVARCHAR(60))
INSERT INTO @Clients (ClientID)
VALUES (N'C19B0E75-D7D3-4665-BEA8-758BA9E5B0AD') /* Enter Client(s) here */
 
/* Set date ranges here */
DECLARE @StartDate DATETIME = '07/30/2019'
DECLARE @EndDate DATETIME = '08/13/2019'

 
 
DECLARE @Dates TABLE (RunDate DATE)
;WITH e1(n) AS
(
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
), -- 10
e2(n) AS (SELECT 1 FROM e1 CROSS JOIN e1 AS b), -- 10*10
e3(n) AS (SELECT 1 FROM e1 CROSS JOIN e2), -- 10*100
e4(n) AS (SELECT 1 FROM e1 CROSS JOIN e3) -- 10*1000
INSERT INTO @Dates (RunDate)
SELECT  DATEADD(d,ROW_NUMBER() OVER (ORDER BY n),'12/1/12')
FROM e4
ORDER BY n
  
select
    ValuesStatement = ',(N'''+convert(varchar(10),d.runDate,120)+''',N'''+c.ClientID+''','+CAST(u.USerID as varchar(12)) +','+CAST(f.FileTypeID as varchar(12))+',-1)'
from @Dates d,@FileTypes f, @Users u, @Clients c
where RunDate between @StartDate and @EndDate


,(N'2019-07-30',N'C19B0E75-D7D3-4665-BEA8-758BA9E5B0AD',8196710,1,-1)