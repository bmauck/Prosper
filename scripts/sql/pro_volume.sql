begin tran

USE [Sandbox]
GO
/****** Object:  StoredProcedure [dbo].[bm_inv_volume]    Script Date: 10/29/2018 4:37:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure 
[dbo].[bm_inv_volume]
(
	@startdate datetime 
	,@enddate datetime  
	,@investorID int 
	)

as

select 
	li2.RatingCodeSortable as 'Rating'
	,li2.Term as 'Term'
	,'Rating / Term' = concat(li2.RatingCodeSortable+' ',li2.Term)
	,sum(l.OriginalAmountBorrowed) as 'Volume'
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
	and ltl.LenderID = @investorID
	and l.OriginationDate between @startdate and @enddate
	and ltl.OwnershipEndDate is null
	and li.InvestmentTypeID <> 1
	group by li2.RatingCodeSortable, li2.Term
	order by li2.RatingCodeSortable

commit