declare @start datetime		= '2018-01-01' --dateadd(month, -1, dateadd(day,1,eomonth(getdate(),-1)))
declare @end datetime		= '2019-01-01' --dateadd(day,1,eomonth(getdate(),-1))
;

with cte_ext_loans as 
	(
	select
		*
		from 
			DW.dbo.dim_loan_type2 t2
		where
			1=1 
			and t2.IsCurrentRecord = 1
			and t2.ExtensionExecutionDate is not null
	)
,cte_ext_ubp as 
	(
	select 
		sum(ext.PrinBal) ext_outstanding_upb
		,count(ext.LoanID) ext_outstanding_count
		from 
			cte_ext_loans ext
		where
			1=1
			and ext.AccountStatusDesc = 'OPEN'
	)
,cte_ext_opb as 
	(
	select 
		sum(l.OriginalAmountBorrowed) ext_opb
		,count(ext.LoanID) ext_count
		from 
			cte_ext_loans ext
		join 
			CircleOne.dbo.Loans l 
			on 
			l.LoanID = ext.LoanID
		where
			1=1 
			and l.OriginationDate >= @start
			and l.OriginationDate < @end
	)
,cte_total_loans as 
	(
	select 
		sum(l.OriginalAmountBorrowed) total_opb
		,count(l.LoanID) total_count
		from 
			CircleOne.dbo.Loans l 
		where
			1=1 
			and l.OriginationDate >= @start
			and l.OriginationDate < @end
	)

select
	total_opb
	,total_count
	,ext_opb = (select ext_opb from cte_ext_opb)
	,ext_count = (select ext_count from cte_ext_opb)
	,ext_upb = (select ext_outstanding_upb from cte_ext_ubp)
	,ext_count = (select ext_outstanding_count from cte_ext_ubp)

	from 
		cte_total_loans

	
