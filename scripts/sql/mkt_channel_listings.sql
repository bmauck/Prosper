DROP TABLE #Listings
CREATE TABLE #Listings (
	 LenderID					INT
	,LoanNumber					INT
	,ListingNumber				INT
	,ListingCreationDate		DATETIME
	,OriginationDate			DATETIME
	,FICOScore					INT
	,MarketingChannel			VARCHAR(50)
	)

INSERT INTO #Listings
	SELECT
		 LenderID					= NULL
		,LoanNumber					= lo.LoanID
		,ListingNumber				= li.ID
		,ListingCreationDate		= li.CreationDate
		,lo.OriginationDate
		,FICOScore					= ISNULL(tucrs.ScoreResults,ucp.Score)
		,MarketingChannel			= fbe.MarketingLastTouchChannelName		
	FROM C1.dbo.Loans (NOLOCK) lo
	JOIN C1.dbo.Listings (NOLOCK) li
		ON li.LoanID = lo.LoanID
	JOIN DW..dim_listing dimli
		ON dimli.ListingID = li.ID
	JOIN DW..fact_borrower_event_application fbe
		ON fbe.ApplicationBorrowerEventSK = dimli.TILAApplicationBorrowerEventSK
	LEFT JOIN CircleOne.dbo.ListingCreditReportMapping (NOLOCK) lcrm
		ON lcrm.ListingId = li.ID
		AND lcrm.IsDecisionBureau = 1
	LEFT JOIN TransUnion.dbo.CreditReport (NOLOCK) tucr
		ON tucr.ExternalCreditReportId = lcrm.ExternalCreditReportId
		AND lcrm.CreditBureau = 2
	LEFT JOIN TransUnion.dbo.CreditReportScore (NOLOCK) tucrs
		ON tucrs.CreditReportId = tucr.CreditReportId
		AND tucrs.ScoreType = 'FICO_SCORE'
		AND lcrm.CreditBureau = 2
	OUTER APPLY (
		SELECT TOP 1
			 ucp.Score
			,ucp.CreditPullDate
			,ecpr.ExperianCreditProfileResponseID
			,ecpr.RealEstatePayment
		FROM C1.dbo.ExperianDocuments (NOLOCK) ed
		JOIN C1.dbo.UserCreditProfiles (NOLOCK) ucp
			ON ucp.ExperianDocumentID = ed.id
		JOIN C1.dbo.ExperianCreditProfileResponse (NOLOCK) ecpr
			ON ecpr.ExperianDocumentID = ucp.ExperianDocumentID
		WHERE ed.ExternalCreditReportId = lcrm.ExternalCreditReportId
			AND lcrm.CreditBureau = 1	
		ORDER BY ucp.CreditPullDate DESC, ucp.CreationDate DESC, ecpr.CreatedDate DESC
	) ucp
	WHERE 1=1 
		AND OriginationDate >= '2015-01-01'


select top 10 *
from 
#Listings
where 
--#Listings.OriginationDate > '2015-01-01' and 
#Listings.FICOScore > 680
order by 5 asc

--CREATE TABLE #perf (
--	LoanID		INT
--	,PrinBal	INT
--	,COAmt		INT
--	,RecAmt		INT
--)

--INSERT INTO #perf
--	SELECT
--		LoanID						= lds.LoanID
--		,PrinBal					= lds.PrincipalBalance
--		,COAmt						= ltlco.ChargeOffAmount
--		,RecAmt						= ldsi.Price
--	FROM
--		c1..LoanDetailSnapshot lds
--		JOIN c1..LoanDefaultSaleItem ldsi 
--		ON lds.LoanID = ldsi.LoanID 
--		JOIN C1..LoanToLenderChargeOffDetail ltlco 
--		ON lds.LoanID = ltlco.LoanID
--	WHERE 1=1

--select distinct top 10 * 
--from #perf