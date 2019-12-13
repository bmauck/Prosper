select 
	* 
	from 
		TabReporting..Subscription_EmailMonthlyLenderStatements
	where 
		1=1 
		--and LenderID in (5790601,3822446,1369480,5788757)
		and RecipientName like '%dv01%'
	order by ID desc

	update 
		TabReporting..Subscription_EmailMonthlyLenderStatements
		
		set RecipientName = 'dv01'
		
		where
			1=1 
			and ID = 279
			and RecipientName = {}

select
	* 
	from 
		TabReporting..Subscription_{}

set identity_insert TabReporting.dbo.Subscription_EmailMonthlyLenderStatements on;
	insert into
		TabReporting.dbo.Subscription_EmailMonthlyLenderStatements (ID, LenderID, AccountName, RecipientName, EmailAddress, RenderFormat)
		values (382, 8447542, 'Garrison 2015-1c', 'Garrison', 'sbisaillon@garrisoninv.com; dxu@garrisoninv.com', 'Excel')
		,(383, 8447542, 'Garrison 2015-1c', 'Garrison', 'sbisaillon@garrisoninv.com; dxu@garrisoninv.com', 'PDF')
		,(384, 8447555, 'Garrison 2015-2c', 'Garrison', 'sbisaillon@garrisoninv.com; dxu@garrisoninv.com', 'Excel')
		,(385, 8447555, 'Garrison 2015-2c', 'Garrison', 'sbisaillon@garrisoninv.com; dxu@garrisoninv.com', 'PDF')

