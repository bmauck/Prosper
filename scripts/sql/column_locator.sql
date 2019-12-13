
Use CircleOne
SELECT 
	t.name AS table_name
	,SCHEMA_NAME(schema_id) AS schema_name
	,c.name AS column_name
	FROM 
		sys.tables t
	INNER JOIN 
		sys.columns c 
		ON 
		t.OBJECT_ID = c.OBJECT_ID
	where 
		1=1
		and c.name like '%LoanNoteID%'
	

	select 
		top 100 * 
		from
			CircleOne..LoanNote