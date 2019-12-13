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

ram_payable_report_1 as
	(
	select
		LoanID 
		,OriginationDate
		,Originator
		,ContractVersion
		,LoanType
		,PurchaseDate
		,DaysToSale
		,Product
		,LoanProductID
		,Term
		,case 
			when CreditRating <> 'N/A' then CreditRating
			when CreditRating = 'N/A' and CurrentRate < 
				(select min_rate from grade_cte where RatingCodeSortable = '2-A')
			then 'AA'
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '2-A')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '3-B')
			then 'A'
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '3-B')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '4-C')
			then 'B'
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '4-C')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '5-D')
			then 'C'
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '5-D')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '6-E')
			then 'D'
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '6-E')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '7-HR')
			then 'E'
			when CreditRating = 'N/A' and CurrentRate >
				(select min_rate from grade_cte where RatingCodeSortable = '7-HR')  
			then 'HR'
			else 'Error'
			end as 
		CreditRating
		,LoanAmount = OriginalAmountBorrowed
		,CurrentRate
		,case 
			when CreditRating <> 'N/A' then NetChargeOffRate
			when CreditRating = 'N/A' and CurrentRate < 
				(select min_rate from grade_cte where RatingCodeSortable = '2-A')
			then cast(0.0098 as float)
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '2-A')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '3-B')
			then cast(0.02995 as float)
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '3-B')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '4-C')
			then cast(0.04995 as float)
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '4-C')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '5-D')
			then cast(0.07495 as float)
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '5-D')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '6-E')
			then cast(0.10495 as float)
			when CreditRating = 'N/A' and CurrentRate between 
				(select min_rate from grade_cte where RatingCodeSortable = '6-E')  and 
				(select min_rate from grade_cte where RatingCodeSortable = '7-HR')
			then cast(0.13495 as float)
			when CreditRating = 'N/A' and CurrentRate >
				(select min_rate from grade_cte where RatingCodeSortable = '7-HR')  
			then cast(0.15 as float)
			else 'Error'
			end as 
		NetChargeOffRate
		,ServicingFeeRate
		,LTFRate = LoanTrailingFeeRateLender + LoanTrailingFeeRateProsper
		,RAMRate
		,DailyRAMRate
		,RamInterestComponent
		,RamNetChargeOffComponent
		,RamServicingFeeComponent
		,RamLtfComponent
		,RamPayable
		from
			AccountingDataMart..LoanFundings
		where 
			1=1 
			and OriginationDate < dateadd(day,1,eomonth(getdate(),-1))
			and OriginationDate >= dateadd(month, -1, dateadd(day,1,eomonth(getdate(),-1)))
	),
ram_payable_report_2 as 
	(
	select 
		LoanID 
		,OriginationDate
		,Originator
		,ContractVersion
		,LoanType
		,PurchaseDate
		,DaysToSale
		,Product
		,LoanProductID
		,Term	
		,CreditRating
		,LoanAmount
		,CurrentRate
		,NetChargeOffRate
		,ServicingFeeRate
		,LTFRate
		,case 
			when RAMRate is not null then RAMRate 
			when RAMRate is null then (CurrentRate - NetChargeOffRate - ServicingFeeRate)
			else 'Error'
			end as
		RAMRate
		,case 
			when DailyRAMRate is not null then DailyRAMRate
			when DailyRAMRate is null then (CurrentRate - NetChargeOffRate - ServicingFeeRate) / 365
			else 'Error'
			end as
		DailyRAMRate
		,RamInterestComponent		
		,case 
			when RamNetChargeOffComponent is not null then RamNetChargeOffComponent
			when RamNetChargeOffComponent is null then (LoanAmount * DaysToSale * NetChargeOffRate) / 365
			else 'Error'
			end as 
		RamNetChargeOffComponent
		,case 
			when RamServicingFeeComponent is not null then RamServicingFeeComponent
			when RamServicingFeeComponent is null then (LoanAmount * DaysToSale * ServicingFeeRate) / 365
			else 'Error'
			end as 
		RamServicingFeeComponent
		,case 
			when RamLtfComponent is not null then RamLtfComponent
			when RamLtfComponent is null then (LoanAmount * DaysToSale * LTFRate) / 365
			else 'Error'
			end as  
		RamLtfComponent
		,RamPayable
		from 
			ram_payable_report_1
		where
			1=1 
	),
ram_payable_report_3 as 
	(
	select 
		LoanID
		,OriginationDate
		,Originator
		,ContractVersion
		,LoanType
		,PurchaseDate
		,DaysToSale
		,Product
		,LoanProductID
		,Term
		,CreditRating
		,LoanAmount
		,CurrentRate
		,NetChargeOffRate
		,ServicingFeeRate
		,LTFRate
		,RAMRate
		,DailyRAMRate
		,RamInterestComponent
		,RamNetChargeOffComponent
		,RamServicingFeeComponent
		,RamLtfComponent
		,case 
			when RamPayable is not null then RamPayable
			when RamPayable is null then (RamInterestComponent - RamNetChargeOffComponent - RamLtfComponent)
			else 'Error'
			end as  
		RamPayable 
		from 
		ram_payable_report_2
	)
select 
	* 
	from 
		ram_payable_report_3
	order by 
		OriginationDate, LoanID