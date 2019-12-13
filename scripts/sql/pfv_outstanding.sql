select
	l.ID
	,prt.RatingCode
	,b.Amount
	,l.LoanID
	,ls2.CreatedDate
	from 
		CircleOne..Bids b
	left join 
		CircleOne..ListingStatus ls 
		on 
		b.listingid = ls.listingid 
		and ls.listingstatustypeid = 8 
		and ls.versionenddate is null
	left join 
		CircleOne..loans lo 
		on 
		b.listingid = lo.listingid
	left join 
		CircleOne..listings l 
		on 
		b.listingid = l.id
	left join 
		CircleOne..ProsperRatingType prt 
		on 
		prt.ProsperRatingTypeID = l.prosperratingtypeid
	left join 
		CircleOne..ListingStatus ls2
		on 
		ls2.ListingID = b.ListingID
		and ls2.ListingStatusTypeID = 2
	
	where 
		1=1
		--and prt.RatingCode in ('AA','A','HR')
		and b.userid = 4320761		
		and ls.listingid is not null
		and lo.loanid is null
	order by
		CreatedDate desc