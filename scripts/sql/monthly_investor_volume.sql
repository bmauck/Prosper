select 
	i.Investor
	,sum(l.OriginalAmountBorrowed) as 'Volume'
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
	join 
	C1..Listings li
	on 
	l.ListingID = li.ID
	where
	1=1 
	--and ltl.LenderID = 
	and l.OriginationDate between '2018-11-01' and '2018-12-01'
	and ltl.OwnershipEndDate is null
	and li.InvestmentTypeID = 3
	group by i.Investor

