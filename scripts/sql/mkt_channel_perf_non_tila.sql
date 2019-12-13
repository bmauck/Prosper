select distinct 
li.ListingID as 'Listing ID'
, fbe.MarketingLastTouchChannelName as 'Marketing Channel'
, l.LoanID as 'Loan ID'
, l.OriginationDate
, prt.RatingCode
, li.Term
, lpd.Status
, lpd.PrincipalBalance 
, lpd.InterestBalance
, lpd.DPD
, lpd.GrossDefaults
, lpd.NetDefaults
, ucp.Score
from 
DW..dim_listing li
inner join C1..Listings listing on 
li.ListingID = listing.ID
inner join DW..fact_borrower_event_application fbe on 
fbe.ApplicationBorrowerEventSK = li.CreatedApplicationBorrowerEventSK
inner join c1..Loans l on 
listing.ID = l.ListingID
inner join c1..MarketplaceLoanPerformanceData lpd on 
l.LoanID = lpd.LoanID
inner join C1..UserCreditProfiles ucp on 
listing.UserCreditProfileID = ucp.UserCreditProfileID
inner join C1..ProsperRatingType prt on 
listing.ProsperRatingTypeID = prt.ProsperRatingTypeID
where
fbe.MarketingLastTouchChannelName = 'Direct Mail'
and ucp.Score > 680

