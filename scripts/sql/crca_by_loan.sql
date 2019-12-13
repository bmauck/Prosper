Select 
	lo.LoanId
	,li.ID as 'ListingId'
	,crca.*
	,tlosd.*
	from 
	CircleOne.dbo.Loans lo
	left join 
		CircleOne.dbo.listings li 
		on 
		li.Id = lo.ListingId
	left join 
		CircleOne.dbo.ListingOffersSelected los 
		on 
		los.ListingId = li.Id 
		and los.VersionEndDate is null 
		and los.VersionValidBit = 1
	left join 
		CircleOne.dbo.LoanOffer lof 
		on 
		lof.LoanOfferId = los.LoanOfferId
	left join 
		CircleOne.dbo.tblLOanOfferScore tlos 
		on 
		tlos.ListingScoreId = lof.ListingScoreId
	left join 
		Transunion.dbo.CreditReport cr 
		on 
		cr.ExternalCreditreportid = tlos.Externalcreditreportid
	left join 
		Transunion.dbo.creditreportcvattribute crca 
		on 
		crca.creditreportid = cr.creditreportid 
		
	left join 
		CircleOne.dbo.tblLoanOfferscoredetail tlosd 
		on 
		tlosd.ListingScoreId = tlos.ListingScoreId 
		and tlosd.variableid = 658

	where lo.LoanID in (
		1134432,
		728922,
		767337,
		847452,
		925320,
		962971,
		968361,
		976980
	)

