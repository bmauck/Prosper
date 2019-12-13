declare @startdate datetime
declare @enddate datetime
declare @investor int

set @startdate	= getdate() -1 
set @enddate	= getdate()  
set @investor	= 7221731
;


with data_cte as 
	(
	select 
		*
		from
			DW.dbo.tfnDailyLenderPacketData_ByDateRangeAndLender 
				(
				@startdate, @enddate, @investor
				) a
		where
			1=1
	)
,agg_cte as 
	(
	select
		sum(
			case 
				when a.EndStatus in ('CURRENT', 'COMPLETED', 'CHARGEDOFF')
				then (a.EndBalance - a.PrincipalPending)
				else 0 
			end) 'Total Receivables'
		,sum(
			case
				when 1=1
				and a.EndDPD > 30
				and a.EndDPD <= 60
				and a.BankruptcyStatus is null
				and a.StatusSold is null
				and a.ExtensionExecutionDate is null
				and a.DefaultReasonDesc is null
			then (a.EndBalance - a.PrincipalPending)
			else 0
			end) 'DPD 31-60'
		,sum(
			case
				when 1=1
				and a.EndDPD > 60
				and a.EndDPD <= 90
				and a.BankruptcyStatus is null
				and a.StatusSold is null
				and a.ExtensionExecutionDate is null
				and a.DefaultReasonDesc is null
			then (a.EndBalance - a.PrincipalPending)
			else 0
			end) 'DPD 61-90'
		,sum(
			case
				when 1=1
				and a.EndDPD > 90
				and a.EndDPD <= 120
				and a.BankruptcyStatus is null
				and a.StatusSold is null
				and a.ExtensionExecutionDate is null
				and a.DefaultReasonDesc is null
			then (a.EndBalance - a.PrincipalPending)
			else 0
			end) 'DPD 91-120'
		--,sum(
		--	case 
		--		when 1=1 
		--		and a.ChargeOffPrincipal is not null
		--		and a.BankruptcyStatus is null
		--	then a.EndBalance
		--	else 0
		--	end) 'Charged Off Receivables'
		,sum(
			case
				when 1=1
				and a.ExtensionExecutionDate is not null
				and a.StatusSold is null
				and a.ChargeOffDate is null
			then a.EndBalance
			else 0 
			end) 'Loan Mod Receivables'
		,sum(
			case
				when 1=1
				and a.BankruptcyStatus is not null
				and a.StatusSold is null
				and a.ChargeOffDate is null
			then a.EndBalance
			else 0 
			end) 'Bankruptcy Receivables'

		,sum(
			case 
				when 1=1
				and a.DefaultReasonDesc = 'Deceased'
				and a.EndStatus = 'CURRENT'
			then a.EndBalance
			else 0 
			end) 'Deceased Receivables'
		
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
		sum(round(Amount, 0)) - 130323888.56 
 loan_amt 
		from 
			AccountingDataMart..vBankDetail bd
		join 
			acct_num 
			on 
			acct_num.AccountNumber = bd.AccountNumber
		where 
			1=1 
			and ContinuationRecord like '%Goldman%'
			and CodeGroup = 'CR'
			and bd.AccountNumber = acct_num.AccountNumber
			and bd.AsOfDate < @enddate
	)
,borrowing_base as (
	select
		*
		,b.[Total Receivables] 
			- b.[DPD 31-60]
			- b.[DPD 61-90]
			- b.[DPD 91-120] 
			- b.[Bankruptcy Receivables] 
			- b.[Loan Mod Receivables]
			- b.[Deceased Receivables]
		as 'Eligible Receivables'
		,b.[DPD 31-60]
			+ b.[DPD 61-90]
			+ b.[DPD 91-120]
			+ b.[Bankruptcy Receivables]
			+ b.[Loan Mod Receivables]
			+ b.[Deceased Receivables]
		as 'Ineligible Receivables'
		,(b.[Total Receivables] 
			- b.[DPD 31-60]
			- b.[DPD 61-90]
			- b.[DPD 91-120] 
			- b.[Bankruptcy Receivables] 
			- b.[Loan Mod Receivables]
			- b.[Deceased Receivables]) * 0.89
		as 'Borrowing Base'
		,(select loan_amt from loan_amt)
		as 'Loan Balance'
		from 
			agg_cte b
	)
select
	*
	,c.[Borrowing Base] - c.[Loan Balance] as 'Availability'
	from 
		borrowing_base c

