if object_id('tempdb..#loanownership1') is not null drop table #loanownership1
select 
	*
	into 
		#loanownership1
	from 
		c1.dbo.loanownershiptransfer (nolock)
	where 
		1=1
		and ownerid in 
		(
		8269336
		,8326266
		,8379573
		,8451729
		,8507420
		
		)
		and cast(EffectiveDate as date) = '06/28/2019'
		and LoanOwnershipTransferTypeID <> 2


select sum(principal + interest + latefees - CollectionFeesChargedLenders - LenderServicingFee)
select *
from c1..loanpayment lp
join #loanownership1 lo
	on lo.loanid = lp.loanid
where 
1=1 
and lp.loangroupid <> 141
and lp.AccountEffectiveDate <= '6/26/2019' --and lp.CreatedDate < '5/22/2019 17:00:00'
order by lp.CreatedDate


if object_id('tempdb..#loanownership2') is not null drop table #loanownership2
select 
	lot.*
	into 
		#loanownership2
	from	
		c1.dbo.LoanOwnershipTransfer (nolock) lot
	join 
		#loanownership1 l1
		on 
		l1.loanid = lot.loanid
			and lot.RecipientID = 8609673
			and cast(lot.EffectiveDate as date) = '05/23/2019'
			and lot.LoanOwnershipTransferTypeID <> 2

select 
	lot.EffectiveDate
	,RecipientGroupID = case 
							when lg.LoanGroupID is null 
							then 3 
							else lg.loangroupid 
							end
	,lp.*
	from 
		c1..LoanPayment (nolock) lp
	join 
		#loanownership2 lot
		on 
		lot.loanid = lp.LoanID
		and lp.AccountEffectiveDate between '05/17/2019' and '07/09/2019'
	join 
		c1..LoanPaymentRecipient (nolock) lpr
		on 
		lpr.LoanPaymentID = lp.LoanPaymentID
	left join 
		c1..LoanGroup (nolock) lg
		on 
			lg.userid = lpr.LenderID
	where 
		1=1
		--and lp.LoanGroupID = 136
		and case 
				when lg.LoanGroupID is null 
				then 3 
				else lg.loangroupid 
				end = 136
	order by 
		CreatedDate

select
	RecipientID = lpr.LenderID
	,lp.LoanPaymentTypeID
	,lp.LoanPaymentCategoryID
	,sum(principal+interest+latefees-CollectionFeesChargedLenders-LenderServicingFee)
	,count(*)
	
	from 
		c1..LoanPayment (nolock) lp
	join 
		#loanownership2 lot
		on 
		lot.loanid = lp.LoanID
		and lp.AccountEffectiveDate > '05/23/2019'
	join 
		c1..LoanPaymentRecipient (nolock) lpr
		on 
		lpr.LoanPaymentID = lp.LoanPaymentID
	left join c1..LoanGroup (nolock) lg
		on 
		lg.userid = lpr.LenderID
	where 
		1=1
		and lp.LoanGroupID = 136
		and case 
				when lg.LoanGroupID is null 
				then 3 
				else lg.loangroupid 
				end <> 136
	group by 
		LenderID, lp.LoanPaymentTypeID, LoanPaymentCategoryID
	order by 
		1,2

