with perf_cte 
	(
	LoanID
	,Age
	,OrigMonth
	,Amount
	,Losses
	,FICO
	) as
		(
		select 
			llm.LoanID
			,llm.CycleCounter
			,llm.OrigMID
			,llm.LoanAmount
			,(llm.CumulBK + llm.CumulCO)
			,FICO = case
					when llm.FICOScore <= 600 then '600' 
					when llm.FICOScore between 600 and 639 then '600-639'
					when llm.FICOScore between 640 and 679 then '640-679'
					when llm.FICOScore between 680 and 719 then '680-719'
					when llm.FICOScore between 720 and 759 then '720-759'
					when llm.FICOScore >= 760 then '760 +'
					else ''

				end
		from DW..dw_LoanLevelMonthly llm
			inner join 
			(
				select	
					max(llm.ObservationMonth) as LatestMonth
					,llm.LoanID
				from 
					DW..dw_LoanLevelMonthly llm
				where 
					1=1
				group by llm.LoanID
			) DateDT
			on 
			llm.ObservationMonth = DateDT.LatestMonth
			and llm.LoanID = DateDT.LoanID
		where 
		1=1
		and llm.LoanProductID = 1
		and llm.InvestmentProductID = 1
		and llm.OriginationDate >= '2016-01-01'
		and llm.OriginationDate < '2019-01-01'
		and llm.ProsperRating = 'B'

	)


select 
	FICO
	
	,sum(Amount) as 'Volume'
	
	from 
		perf_cte

	group by 
		FICO
	