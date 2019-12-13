if object_id('tempdb..#loanownership1') is not null drop table #loanownership1
select 
	ltl.LoanID
	into 
		#loanownership1
	from 
		CircleOne..LoanToLender ltl 
	where 
		1=1
		and ltl.LenderID = 8787821		
		and OwnershipEndDate is null

select 
	sum(principal + Interest - LP.CollectionFeesChargedLenders - LP.LenderServicingFee + lp.LateFees)
	from 
		CircleOne..LoanPayment lp
	join 
		#loanownership1 lot 
		on 
		lot.LoanID = lp.LoanID
	where
		1=1
		and lp.LoanGroupID <> 142
		and lp.AccountEffectiveDate >= '2019-07-31'
		and lp.CreatedDate > '2019-07-30 00:00:00'