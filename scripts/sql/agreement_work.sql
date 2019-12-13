with agreement_cte as (
	select 
		ID
		from 
			CircleOne..AgreementTypes at
		where
			1=1 
			and at.Title like '%Price%'
)
,loans_cte as (
	select
		ltl.LoanID
		from 
			CircleOne..LoanToLender ltl
		where
			1=1
			and ltl.LenderID = 8116364
			and ltl.OwnershipEndDate is null
)
,user_cte as (
	select 
		l.LoanID Loan
		,l.BorrowerID UserID
		
		from 
			CircleOne..Loans l
		where
			1=1 
			and l.LoanID in (select *  from loans_cte)
)
,version_cte as (
	select 
		a.UserID
		,Loan
		,max(a.CreatedDate) MostRecentAgreementDate
		from 
			user_cte
		join
			CircleOne..Agreements a
			on 
			a.UserID = user_cte.UserID
		where
			1=1 
			and a.UserID = user_cte.UserID
			and a.AgreementTypeID in (select ID from agreement_cte)
		group by 
			a.UserID
			,Loan
)
select
	top 10
	v.* 
	,at.Title
	,a.ID
	,a.AgreementBodyBinary
	,cast(Circleone.dbo.fn_decompress(a.AgreementBodyBinary, len(a.AgreementBodyBinary)) as varchar(max)) html
	,a.IsCorrectedAgreement
	from 
	version_cte v

	join 
		CircleOne..Agreements a
		on 
		a.UserID = v.UserID
	join 
		CircleOne..AgreementTypes at
		on 
		at.ID = a.AgreementTypeID
	where
		1=1
		and a.AgreementTypeID in (select ID from agreement_cte)
		and a.CreatedDate = MostRecentAgreementDate
		--and a.UserID = 58627

