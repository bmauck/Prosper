select 
	i.Investor as 'Investor'
	,sum(l.OriginalAmountBorrowed) as 'Volume'
	from 
	C1..Loans l
	join 
	C1..LoanToLender ltl
	on 
	l.LoanID = ltl.LoanID 
	inner join 
	Sandbox..bm_investors i 
	on 
	i.InvestorID = ltl.LenderID
	--join 
	--C1..Listings li
	--on 
	--l.ListingID = li.ID
	where
	1=1 
	--and ltl.LenderID = 7841721
	and l.OriginationDate between '2018-10-01' and '2018-11-07'
	and ltl.OwnershipEndDate is null
	--and li.InvestmentTypeID in (2,3)
	group by i.Investor
	order by 2 desc


