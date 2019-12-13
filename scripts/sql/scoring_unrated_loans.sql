with 
grade_cte as 
	(
	select
		RatingCodeSortable
		,min(li.BorrowerInterestRate) as 'min_rate'
		,max(li.BorrowerInterestRate) as 'max_rate'
		from
			DW..dm_listing li
		where
			1=1 
			and li.CreatedTimeStamp > dateadd(month, -3, getdate())
			and RatingCodeSortable not in ('??', '8-N/A')
		group by
			RatingCodeSortable
		),
lender_cte as 
	(
	select 
		ltl.LoanID 
		from 
			C1..LoanToLender ltl
		where 
			1=1 
			and ltl.LenderID = 8309412
			and OwnershipEndDate is null	
	),
approx_rating_cte as 
	(
	select 
		
		LoanID
		,CurrentRate
		,case 
			when 
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '1-AA'
							) 
					and
				CurrentRate <  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '2-A'
							) 
			then cast(sum(1.99+0)/2 as varchar)
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '2-A'
							) 
					and
				CurrentRate <  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '3-B'
							) 
			then cast(sum(3.99+2)/2 as varchar)
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '3-B'
							) 
					and
				CurrentRate <  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '4-C'
							) 
			then cast(sum(5.99+4)/2 as varchar)
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '4-C'
							) 
					and
				CurrentRate <  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '5-D'
							) 
			then cast(sum(8.99+6)/2 as varchar)
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '5-D'
							) 
					and
				CurrentRate <  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '6-E'
							) 
			then cast(sum(11.99+8)/2 as varchar)
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '6-E'
							) 
					and
				CurrentRate <  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '7-HR'
							) 
			then cast(sum(14.99+12)/2 as varchar)
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '7-HR'
							) 
					
			then cast(15.00 as varchar)
			else 'Error'
			end 
			as 'Losses'
		,case 
			when 
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '1-AA'
							) 
					and
				CurrentRate <=  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '2-A'
							) 
			then 'AA'
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '2-A'
							) 
					and
				CurrentRate <=  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '3-B'
							) 
			then 'A'
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '3-B'
							) 
					and
				CurrentRate <=  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '4-C'
							) 
			then 'B'
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '4-C'
							) 
					and
				CurrentRate <=  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '5-D'
							) 
			then 'C'
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '5-D'
							) 
					and
				CurrentRate <=  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '6-E'
							) 
			then 'D'
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '6-E'
							) 
					and
				CurrentRate <=  (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '7-HR'
							) 
			then 'E'
			when
				CurrentRate > (
					select 
						min_rate
						from 
							grade_cte
						where 
							1=1
							and RatingCodeSortable = '7-HR'
							) 
				
			then 'HR'
							
			else 'Error'
			
			end
				as 'Grade'
		from 
			AccountingDataMart.dbo.LoanFundings
		where
			1=1 
			and RAMRate is NULL
			and OriginationDate between '2019-01-31' and '2019-02-01'
		group by 
		LoanID
		,CurrentRate
		)
select
	* 
	from 
		approx_rating_cte



