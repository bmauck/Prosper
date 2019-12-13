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
	--ltl.LenderID
	--,lg.LoanGroupID
	--,ltl.LoanID
	--,l.OriginalAmountBorrowed
	--,l.CreationDate
	Name.Name
	,count(l.LoanID)
	from 
		CircleOne..Loans l 
	join 
		CircleOne..LoanToLender ltl
		on 
		ltl.LoanID = l.LoanID
		and ltl.OwnershipEndDate is null
	join 
		CircleOne..LoanGroup lg 
		on 
		lg.UserID = ltl.LenderID
	join 
		name_cte name 
		on 
		name.UserID = ltl.LenderID
		and Rnk = 1
	where 
		1=1 
		and cast(l.OriginationDate as date) >= '2019-06-01'
		and cast(l.OriginationDate as date) < '2019-07-01'
		and ltl.LenderID in (7221731, 8398085)
		--and l.OriginalAmountBorrowed = 25000
	group by 
		Name.Name
