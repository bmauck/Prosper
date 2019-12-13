select
	li.ID
	,li.LoanID
	,li.Amount
	,pe.IncentiveAmount
	
	from 
		Offer..PenfedEligibility pe
	join 
		CircleOne..ListingOffersSelected liof
		on 
			liof.LoanOfferID = pe.LoanOfferID
			and liof.VersionEndDate is null
			and liof.VersionValidBit = 1
	join 
		CircleOne..Listings li 
		on 
			liof.ListingID = li.ID
			and liof.VersionEndDate is null
			and liof.VersionValidBit = 1
	join 
		CircleOne..Loans lo
		on 
			lo.LoanID = li.LoanID
	where
		1=1
		and pe.IsPenFedOfferAccepted = 1
		and lo.OriginationDate between 
			dateadd(month, datediff(month, 0, getdate())-1, 0)
			and dateadd(month, datediff(month, -1, getdate())-1, -1)
		
