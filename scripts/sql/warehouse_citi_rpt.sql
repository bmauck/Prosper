with data_cte as 
	(
	select 
		*
		from
			DW.dbo.tfnDailyLenderPacketData_ByDateRangeAndLender 
				(
				getdate()-1, getdate(), 8398085
				) a
		where
			1=1
	)
,agg_cte as 
	(
	select
		 sum(
			a.EndBalance - a.PrincipalPending
			) 'Total Receivables'
		,sum(
			case
				when 1=1
				and a.EndDPD > 0
				and a.EndDPD < 30
			then a.EndBalance
			else 0
			end) 'DPD 1-29'
		,sum(
			case
				when 1=1
				and a.EndDPD > 30
				and a.EndDPD < 60
			then a.EndBalance
			else 0
			end) 'DPD 30-59'
		,sum(
			case
				when 1=1
				and a.EndDPD > 60
				and a.EndDPD < 90
			then a.EndBalance
			else 0
			end) 'DPD 60-89'
		,sum(
			case
				when 1=1
				and a.EndDPD > 90
				and a.EndDPD < 120
			then a.EndBalance
			else 0
			end) 'DPD 90-120'
		,sum(
			case 
				when 1=1 
				and a.ChargeOffPrincipal is not null
				and a.BankruptcyStatus is null
			then a.EndBalance
			else 0
			end) 'Charged Off Receivables'
		,sum(
			case 
				when a.BankruptcyStatus is not null
			then a.EndBalance
			else 0
			end) 'Bankruptcy Receivables'
		from 
			data_cte a
	)
,acct_num as (
		select
			AccountNumber
		from 
			AccountingDataMart..BankAccounts accts
		where
			1=1
			and accts.WellsNickname like '%PWIT%'
			and accts.AccountTypeDescription = 'Funding'
		)
,loan_amt as (
	select 
		sum(round(Amount, -5)) loan_amt
		from 
			AccountingDataMart..vBankDetail bd
		join 
			acct_num 
			on 
			acct_num.AccountNumber = bd.AccountNumber
		where 
			1=1 
			and ContinuationRecord like '%Citi%'
			and CodeGroup = 'CR'
	)
,borrowing_base as (
	select
		*
		,b.[Total Receivables] 
			- b.[DPD 30-59] 
			- b.[DPD 60-89] 
			- b.[DPD 90-120] 
			- b.[Bankruptcy Receivables] 
			- b.[Charged Off Receivables]
		as 'Eligible Receivables'
		,b.[DPD 60-89]
			+ b.[DPD 90-120]
			+ b.[Bankruptcy Receivables]
			+ b.[Charged Off Receivables]
		as 'Ineligible Receivables'
		,b.[Total Receivables] * 0.90
			- b.[DPD 30-59] * 0.75
			- b.[DPD 60-89] 
			- b.[DPD 90-120] 
			- b.[Bankruptcy Receivables] 
			- b.[Charged Off Receivables]
		as 'Borrowing Base'
		,(select loan_amt from loan_amt)
		as 'Loan Balance'
		from 
			agg_cte b
	)
select
	*
	,c.[Borrowing Base] 
		- c.[Loan Balance] 
	as 'Availablility'
	from 
		borrowing_base c