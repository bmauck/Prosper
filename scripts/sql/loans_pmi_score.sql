with cte_loans as 
	(
	select
	ltl.LoanID
	from 
		CircleOne.dbo.LoanToLender ltl
	where
		1=1
		and ltl.LenderID = 5513816
		and ltl.OwnershipEndDate is null
	)
select
	l.LoanID
	,l2.ListingID
	,li.PMIScore
	from 
		cte_loans l
	join 
		CircleOne.dbo.Loans l2
		on 
		l2.LoanID = l.LoanID
	join 
		DW.dbo.dim_listing li
		on 
		li.ListingID = l2.ListingID
