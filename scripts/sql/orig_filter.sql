select 
	i.Investor
	,sum(l.OriginalAmountBorrowed) as 'OrigVolume'
	from 
	C1..Loans l
	join 
	C1..LoanToLender ltl
	on 
	l.LoanID = ltl.LoanID 
	join 
	Sandbox..bm_investors i 
	on 
	i.InvestorID = ltl.LenderID
	where
	1=1 
	--and ltl.LenderID in (
	--	select 
	--	InvestorID
	--	from 
	--	Sandbox..bm_investors
	--	where
	--	1=1 
	--	and Investor like '%Warehouse%'
	--	)
	and l.OriginationDate > '2018-10-01'
	group by i.Investor

