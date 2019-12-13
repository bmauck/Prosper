with cte_name as 
(
	select 
		und.UserID LenderID
		,und.*
		,row_number() over 
		(
			partition by 
				und.UserID
			order by 
				und.CreationDate desc
		) rnk
		from 
			CircleOne..UserNameDetail und
		join 
			CircleOne..Users u 
			on 
			u.ID = und.UserID
			and u.IsWholeLoansInvestor = 1
		where 
			1=1
			and und.Name like '%{}%'
)
select
	LenderID
	,Name
	from 
		cte_name
	where
		1=1 
		and cte_name.rnk = 1