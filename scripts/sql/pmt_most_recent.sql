with pmt_cte as (
	select 
		lp.CreatedDate
		,lp.LoanID
		,lp.Amount
		,row_number() over 
			(
			partition by 
				lp.LoanID
			order by 
				lp.CreatedDate desc
			) as pmt_rank
		from 
			CircleOne..LoanPayment lp
)
select
	* 
	from 
		pmt_cte pmt
	where
		1=1
		and pmt.LoanID in (select  * from #loans)
		and	pmt_rank = 1 


