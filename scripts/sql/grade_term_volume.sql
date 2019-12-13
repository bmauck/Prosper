

declare @today datetime			=	getdate()
declare @startdate datetime		=	DATEADD(dd, -DAY(@today) + 1, @today)
declare @enddate datetime		=	eomonth(@today)



select 
	Investor
	, li2.RatingCode 
	, sum(l.OriginalAmountBorrowed) as 'OrigVolume'
	from 
	C1..Loans l
	join 
	C1..LoanToLender ltl
		on 
		l.LoanID = ltl.LoanID 
	join 
	Sandbox..bm_investors i 
		on 
		i.InvestorID = ltl.LenderID
	join 
	C1..Listings li
		on 
		l.ListingID = li.ID
	join 
	DW..dm_listing li2
		on 
		li2.ListingID = li.ID
	where
	1=1 
		and l.OriginationDate between @startdate and @enddate
		and ltl.OwnershipEndDate is null
		and li.InvestmentTypeID = 3
		--and Investor = @investor
	group by i.Investor, RatingCode
	order by 1, 2
	
	

