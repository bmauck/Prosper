with name_cte as 
(
	select 
		und.UserID
		,und.Name as 'Name'
		,row_number() over 
		(
			partition by 
				und.UserID
			order by 
				und.CreationDate desc
		) as Rnk
		from 
			CircleOne..UserNameDetail und
		where 
			1=1 
)
select 
	comp.ID 
	,l.LoanID
	,n.Name
	,ls.Name
	from 
		Sandbox..JuneComplaints comp
	inner join 
		CircleOne..Loans l 
		on 
		l.BorrowerID = comp.ID
	inner join 
		CircleOne..LoanDetail ld 
		on 
		ld.LoanID = l.LoanID
		and ld.VersionValidBit = 1
		and ld.VersionEndDate is null
	inner join 
		CircleOne..LoanStatusTypes ls
		on
		ls.ID = ld.LoanStatusTypesID
	inner join 
		CircleOne..Listings li 
		on 
		li.LoanID = l.LoanID
	inner join 
		CircleOne..LoanToLender ltl
		on 
		ltl.LoanID = l.LoanID
		and ltl.OwnershipEndDate is null
	join 
		name_cte n
		on 
		n.UserID = ltl.LenderID
		and n.Rnk = 1
	where
		1=1 
		and li.InvestmentTypeID <> 1
	order by 
		n.Name
		
		