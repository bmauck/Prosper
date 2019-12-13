with fico_cte as (
	
	select 
		li.Amount
		,FICO = case
					when li.FICOScore <= 600 then '<600' 
					when li.FICOScore between 600 and 639 then '600-639'
					when li.FICOScore between 640 and 679 then '640-679'
					when li.FICOScore between 680 and 719 then '680-719'
					when li.FICOScore between 720 and 759 then '720-759'
					when li.FICOScore >= 760 then '760 +'
					else ''
					end
		
		from 
			DW..dm_listing li 
		join 
			CircleOne..Loans l
			on 
			l.ListingID = li.ListingID
		where
			1=1 
			and l.OriginationDate >= '2016-01-01'
			and l.OriginationDate < '2019-01-01'
			and l.LoanProductID = 1
			and li.RatingCode = 'C'
		
)
,state_cte as (
	
	select
		li.BorrowerState
		,li.Amount
		from 
			DW..dm_listing li 
		join 
			CircleOne..Loans l
			on 
			l.ListingID = li.ListingID
		where
			1=1 
			and l.OriginationDate >= '2016-01-01'
			and l.OriginationDate < '2019-01-01'
			and l.LoanProductID = 1
			and li.RatingCode = 'C'
		
)
,dti_cte as(

	select 
		li.Amount
		,DTI = case
					when li.BorrowerDTI <= 0.1 then '< 0.10' 
					when li.BorrowerDTI between 0.10 and 0.35 then '0.10-0.35'
					when li.BorrowerDTI between 0.35 and 0.45 then '0.35-0.45'
					when li.BorrowerDTI between 0.45 and 0.55 then '0.45-0.55'
					when li.BorrowerDTI >= 0.55 then '0.55 +'
					when li.BorrowerDTI is null then 'Null'
					else ''
					end
		
		from 
			DW..dm_listing li 
		join 
			CircleOne..Loans l
			on 
			l.ListingID = li.ListingID
		where
			1=1 
			and l.OriginationDate >= '2016-01-01'
			and l.OriginationDate < '2019-01-01'
			and l.LoanProductID = 1
			and li.RatingCode = 'AA'
)
--select 
--	FICO
--	,sum(Amount) vol

--	from 
--		cte
--	group by 
--		FICO
--select 
--	BorrowerState
--	,sum(Amount) vol
--	from
--		state_cte
--	group by 
--		BorrowerState
--	order by 
--		vol
--		desc
select 
	DTI
	,sum(Amount) vol

	from 
		dti_cte
	group by 
		DTI

select 
	llm.OriginationQuarter
	,sum(li.BorrowerAPR * li.Amount) / sum(li.Amount) AvgAPR
	from 
		DW..dm_listing li
	join 
		DW..vLoanLevelMonthly llm
		on 
		llm.ListingNumber = li.ListingID
		and llm.CycleCounter = 0
	where
		1=1
		and OriginationDate >= '2016-01-01'
		and OriginationDate < '2019-01-01'
		and llm.ProsperRating = 'C'
	group by 
		llm.OriginationQuarter
	order by 
		case 
			when llm.OriginationQuarter = 'Q1 2016' then 1
			when llm.OriginationQuarter = 'Q2 2016' then 2
			when llm.OriginationQuarter = 'Q3 2016' then 3
			when llm.OriginationQuarter = 'Q4 2016' then 4
			when llm.OriginationQuarter = 'Q1 2017' then 5
			when llm.OriginationQuarter = 'Q2 2017' then 6
			when llm.OriginationQuarter = 'Q3 2017' then 7
			when llm.OriginationQuarter = 'Q4 2017' then 8
			when llm.OriginationQuarter = 'Q1 2018' then 9
			when llm.OriginationQuarter = 'Q2 2018' then 10
			when llm.OriginationQuarter = 'Q3 2018' then 11
			when llm.OriginationQuarter = 'Q4 2018' then 12
			end
	
	