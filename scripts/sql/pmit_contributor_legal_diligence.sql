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
	un.Name
	,l.OriginationDate
	,ltl.*
	into
		#pmit_ltl
	from
		CircleOne..LoantoLender ltl
	join
		name_cte un
		on
		un.UserID = ltl.LenderID
		and un.Rnk = 1
	join
		CircleOne..Loans l
		on
		ltl.LoanID = l.LoanID
	where
		1=1
		and ltl.LoanID in (select * from #pmit)

select
	count(ltl.LenderID)
	from
		CircleOne..LoanToLender ltl
	where
		1=1
		and ltl.LoanID in (select * from #pmit)
		and ltl.LenderID = 4320761

select
	*
	from
		#pmit_ltl
	order by LoanID, creationDate
