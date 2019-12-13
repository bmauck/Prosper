set nocount on;

with phl_cte as (

	select distinct
		listingID
		,InstitutionID 
		from 
			CircleOne.dbo.tblLoanofferscore
		where 
			1=1
			and InstitutionID is NOT NuLL
			and InstitutionID <> 0
)
select 
	l.LoanID
	,l.OriginationDate
	,dlv.ListingID
	,HasIDV
	,IsManualApproveIDV
	,HasPOI
	,IsManualApprovePOI
	,HasPOE
	,IsManualApprovePOE
	,HasFS
	,IsManualApproveFS
	,'isPHL' = case when 
				ltl.LenderID in (
					select 
					listingID 
					from phl_cte)
				then 1
				else 0 
				end
	from 
		DW..dim_listing_verification dlv

	left join 
		C1..Loans l 
		on 
		l.ListingID = dlv.ListingID
	left join 
		C1..LoanToLender ltl 
		on 
		ltl.LoanID = l.LoanID
	where 
		1=1
		and ltl.LenderID = 5513816
		and OriginationDate < dateadd(day,1,eomonth(getdate(),-1))
		and OriginationDate >= dateadd(month, -1, dateadd(day,1,eomonth(getdate(),-1)))
		and ltl.OwnershipEndDate is null
