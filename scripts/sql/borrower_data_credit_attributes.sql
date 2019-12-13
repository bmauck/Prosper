SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH

DECLARE @PiiAndPointFico TINYINT = 1 --TODO: Change This Parameter to JUST PII

IF OBJECT_ID('tempdb..#Listings') IS NOT NULL DROP TABLE #Listings
CREATE TABLE #Listings (
	 LenderID					INT
	,LoanNumber					INT
	,ListingNumber				INT
	,ListingCreationDate		DATETIME
	,OriginationDate			DATETIME
	,PurchaseDate				DATETIME
	,OriginalAmountBorrowed		MONEY
	,OriginationFeeAmount		MONEY
	,Rating						VARCHAR(50)
	,EstimatedLossRate			DECIMAL(6,5)
	,TermMonths					SMALLINT
	,InterestRate				DECIMAL(10,7)
	,BorrowerAPR				DECIMAL(6,5)
	,NumberOfPayments			SMALLINT
	,LoanPurpose				VARCHAR(60)
	,BorrowerID					INT
	,DTIwProsperLoan			DECIMAL(15,5)
	,MonthlyIncome				MONEY
	,MonthlyDebt				MONEY
	,ExperianIsHomeowner		BIT
	,BorrowerState				VARCHAR(2)
	,TrailingFeeRate			DECIMAL(20,10)
	,OriginationSeasoningDays	INT
	,UserEmploymentDetailID		INT
	,UserID						INT
	,TermsApprovalDate			DATETIME
	)


INSERT INTO #Listings
SELECT
	 LenderID					= NULL
	,LoanNumber					= lo.LoanID
	,ListingNumber				= li.ID
	,ListingCreationDate		= li.CreationDate
	,lo.OriginationDate
	,PurchaseDate				= lo.OriginationDate
	,lo.OriginalAmountBorrowed
	,OriginationFeeAmount		= li.EndingOriginationFeeAmount
	,Rating						= prt.RatingCode
	,EstimatedLossRate			= li.EstimatedLoss
	,TermMonths					= ps.AmortizationMonths
	,InterestRate				= li.CurrentRate / 100
	,li.BorrowerAPR
	,NumberOfPayments			= ps.AmortizationMonths
	,LoanPurpose				= ISNULL(lc.Name,'')
	,lo.BorrowerID
	,DTIwProsperLoan			= li.CurrentDTI
	,li.MonthlyIncome
	,li.MonthlyDebt
	/***************** Experian Credit Attributes *****************/
	,ExperianIsHomeowner		= uh.IsHomeowner
	/***************** Experian Credit Attributes *****************/
	,li.BorrowerState
	,TrailingFeeRate			= CAST(ifs.TrailingFeeRate AS DECIMAL(20, 10))
	,lo.OriginationSeasoningDays
	,li.UserEmploymentDetailID
	,li.UserID
	,li.TermsApprovalDate
FROM C1.dbo.Loans (NOLOCK) lo
JOIN C1.dbo.Listings (NOLOCK) li
	ON li.LoanID = lo.LoanID
JOIN C1.dbo.ProsperRatingType (NOLOCK) prt
	ON prt.ProsperRatingTypeID = li.ProsperRatingTypeID
JOIN C1.dbo.InvestmentTypes	(NOLOCK) it
	ON it.InvestmentTypeID = li.InvestmentTypeID
JOIN C1.dbo.ProductSpecs (NOLOCK) ps
	ON ps.ProductSpecID = li.ProductSpecID
JOIN C1.dbo.ListingCategory (NOLOCK) lc
	ON lc.ListingCategoryID = li.ListingCategoryID
JOIN CircleOne.dbo.InvestmentFeeSpec (NOLOCK) ifs
	ON ifs.InvestmentTypeID = li.InvestmentTypeID
LEFT JOIN C1.dbo.UserHomeownership (NOLOCK) uh
	ON uh.ID = li.UserHomeownershipID
WHERE
	1=1
	and lo.LoanID in (select * from Sandbox..pmit_2019_3)
		


IF OBJECT_ID('tempdb..#CTEListings') IS NOT NULL DROP TABLE #CTEListings
SELECT
	 li.LenderID
	,li.LoanNumber
	,li.ListingNumber
	,li.ListingCreationDate
	,li.OriginationDate
	,li.PurchaseDate
	,li.OriginalAmountBorrowed
	,li.OriginationFeeAmount
	,li.Rating
	,li.EstimatedLossRate
	,li.TermMonths
	,li.InterestRate
	,li.BorrowerAPR
	,li.NumberOfPayments
	,li.LoanPurpose
	,li.BorrowerID
	,li.DTIwProsperLoan
	,li.MonthlyIncome
	,li.MonthlyDebt
	/***************** FICO Data - Vendor Agnostic *****************/
	,FICOScore					= ISNULL(tucrs.ScoreResults,ucp.Score)
	,FICODate					= ISNULL(tucr.CreditReportDate,ucp.CreditPullDate)
	,CreditBureau				= cb.CreditBureauName
	/***************** FICO Data - Vendor Agnostic *****************/
	/***************** Experian Credit Attributes *****************/
	,ExperianRealEstatePayment	= ucp.RealEstatePayment
	,li.ExperianIsHomeowner
	/***************** Experian Credit Attributes *****************/
	,li.BorrowerState
	,HardCodedServiceFeePercent = CAST(0.0107500 AS DECIMAL(20,10)) /* TECH DEBT: ServiceFeePercent is Hard-Coded */
	,li.TrailingFeeRate
	,CreditBureauID				= lcrm.CreditBureau
	,li.OriginationSeasoningDays
	,ucp.ExperianCreditProfileResponseID
	,tucr.CreditReportID
	,li.UserEmploymentDetailID
	,li.UserID
	,li.TermsApprovalDate
	,lcrm.ExternalCreditReportID
INTO #CTEListings
FROM #Listings li
LEFT JOIN CircleOne.dbo.ListingCreditReportMapping (NOLOCK) lcrm
	ON lcrm.ListingId = li.ListingNumber
	AND lcrm.IsDecisionBureau = 1
LEFT JOIN CircleOne.dbo.CreditBureau (NOLOCK) cb
	ON cb.CreditBureauID = lcrm.CreditBureau
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

IF OBJECT_ID('tempdb..#CTEPriorLoans') IS NOT NULL DROP TABLE #CTEPriorLoans
SELECT
	 LoanNumber						= lo.LoanID
	,PriorProsperLoans				= COUNT(DISTINCT lo2.LoanID)
	,ActivePriorProsperLoans		= SUM(CASE WHEN ld.LoanStatusTypesID IN (0,1) AND ld.PrinBal > 0 THEN 1 ELSE 0 END)
	,ActivePriorProsperLoansBalance	= SUM(CASE WHEN ld.LoanStatusTypesID IN (0,1) AND ld.PrinBal > 0 THEN ld.PrinBal ELSE 0 END)
INTO #CTEPriorLoans
FROM C1.dbo.Listings (NOLOCK) li
JOIN C1.dbo.InvestmentTypes (NOLOCK) it
	ON it.InvestmentTypeID = li.InvestmentTypeID
JOIN C1.dbo.Loans (NOLOCK) lo
	ON lo.LoanID = li.LoanID
JOIN C1.dbo.Listings (NOLOCK) li2
	ON li2.UserID = li.UserID
	AND li2.CreationDate < li.CreationDate
	AND li2.LoanID IS NOT NULL
	AND li2.LoanID <> li.LoanID
JOIN C1.dbo.Loans (NOLOCK) lo2
	ON lo2.LoanID = li2.LoanID
	AND lo2.OriginationDate < lo.OriginationDate
OUTER APPLY (
	SELECT TOP 1
			LoanID
		,PrinBal
		,LoanStatusTypesID
	FROM C1.dbo.LoanDetail (NOLOCK)
	WHERE LoanID = lo2.LoanID
		AND VersionValidBit = 1
		AND AccountInformationDate < lo.OriginationDate
		AND VersionStartDate < lo.OriginationDate
	ORDER BY VersionStartDate DESC
) ld
WHERE 1=1
	AND it.IsWholeLoanType = 1
	AND lo.LoanID IN (SELECT DISTINCT LoanNumber FROM #CTEListings)
GROUP BY lo.LoanID

IF OBJECT_ID('tempdb..#CTETu') IS NOT NULL DROP TABLE #CTETu
SELECT
	 CreditReportID
	,CvKey
	,CvValue
INTO #CTETu 
FROM TransUnion.dbo.CreditReportCvAttribute (NOLOCK)
WHERE CreditReportID IN (SELECT DISTINCT CreditReportID FROM #CTEListings WHERE CreditBureauID = 2)
AND CvKey IN ('at01s','at02s','at20s','at36s','bc34s','co02s','co03s','co04s','g061s','g063s','g069s','g095s','g099s','g980s','g990s','inap01','mt02s','mtap01','reap01','s071b','s207a','s207s')

IF OBJECT_ID('tempdb..#CTETuPivot') IS NOT NULL DROP TABLE #CTETuPivot
SELECT
	 CreditReportID
	,at01s	= CAST(at01s  AS INT) --TotalTradeLines
	,at02s	= CAST(at02s  AS INT) --OpenCreditLines
	,at20s	= CAST(at20s  AS INT) --CreditHistoryMonths
	,at36s  = CAST(at36s  AS INT) --MonthsSinceMostRecentDelinquency
	,bc34s	= CAST(bc34s  AS INT) --BankcardUtilization
	,co02s	= CAST(co02s  AS INT) --COLast12Months
	,co03s	= CAST(co03s  AS INT) --COLast24Months
	,co04s  = CAST(co04s  AS INT) --MonthsSinceMostRecentCOTradeReported
	,g061s	= CAST(g061s  AS INT) --Delinquencies30DaysPlus24Months
	,g063s	= CAST(g063s  AS INT) --Delinquencies60DaysPlus6Months
	,g069s	= CAST(g069s  AS INT) --Delinquencies90DaysPlus12Months
	,g095s	= CAST(g095s  AS INT) --PublicRecordsLast36Months
	,g099s	= CAST(g099s  AS INT) --BKLast24Months
	,g980s	= CAST(g980s  AS INT) 
	,g990s	= CAST(g990s  AS INT) 
	,inap01	= CAST(inap01 AS INT) --MonthlyInstallmentPayment
	,mt02s	= CAST(mt02s  AS INT) --HasOpenMortgage
	,mtap01	= CAST(mtap01 AS INT) --BureauMortgagePayment
	,reap01	= CAST(reap01 AS INT) --MonthlyRevolvingPayment
	,s071b	= CAST(s071b  AS INT) --NonMedicalCollections24Months
	,s207a 	= CAST(s207a  AS INT) --MonthsSinceBK
	,s207s	= CAST(s207s  AS INT) --MonthsSincePublicRecord
INTO #CTETuPivot
FROM (
	SELECT
		 CreditReportID
		,CvKey
		,CvValue
	FROM #CTETu
) tucv
PIVOT (
	MAX(tucv.CvValue)
	FOR tucv.CvKey IN (at01s,at02s,at20s,at36s,bc34s,co02s,co03s,co04s,g061s,g063s,g069s,g095s,g099s,g980s,g990s,inap01,mt02s,mtap01,reap01,s071b,s207a,s207s)
) piv

IF OBJECT_ID('tempdb..#CTEExp') IS NOT NULL DROP TABLE #CTEExp
SELECT
	 ExperianCreditProfileResponseID
	,AttributeID
	,AttributeValue = CAST(AttributeValue AS INT)
INTO #CTEExp
FROM C1.dbo.ExperianCreditProfileStaggData (NOLOCK)
WHERE ExperianCreditProfileResponseID IN (SELECT DISTINCT ExperianCreditProfileResponseID FROM #CTEListings WHERE CreditBureauID = 1)
AND AttributeID IN ('ALL002','ALL003','ALL022','ALL127','ALL146','ALL701','ALL724','ALL803','ALL901','BAC403','REV404')

IF OBJECT_ID('tempdb..#CTEExpPivot') IS NOT NULL DROP TABLE #CTEExpPivot
SELECT
	 ExperianCreditProfileResponseID
	,ALL002
	,ALL003
	,ALL022
	,ALL127
	,ALL146
	,ALL701
	,ALL724
	,ALL803
	,ALL901
	,BAC403
	,REV404
INTO #CTEExpPivot
FROM (
	SELECT
		 ExperianCreditProfileResponseID
		,AttributeID
		,AttributeValue = CAST(AttributeValue AS INT)
	FROM #CTEExp
) stagg
PIVOT (
	MAX(stagg.AttributeValue)
	FOR stagg.AttributeID IN (ALL002,ALL003,ALL022,ALL127,ALL146,ALL701,ALL724,ALL803,ALL901,BAC403,REV404)
) piv


SELECT DISTINCT
	li.LenderID,
	 li.LoanNumber
	,li.ListingNumber
	,li.ListingCreationDate
	,li.OriginationDate
	,li.PurchaseDate
	,li.OriginalAmountBorrowed
	,li.OriginationFeeAmount
	,DOBDec.PlainText DOB
	,GOVIDDec.PlainText SSN
	,dlv.HasPOE HasProofOFIncome
	,dlv.IsManualApprovePOE ManuallyApprovedIncome
	
	/***************** Pre-Purchase Interest *****************/
	,GrossPrePurchaseInterest	=	CAST(
											(
											li.OriginalAmountBorrowed *
											( CAST(ld.BorrowerStatedInterestRate AS DECIMAL(20,10)) / CAST(365.00 AS DECIMAL(20,10)) ) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
											--CAST(ld.IntBalDailyAccrual AS DECIMAL(20,10)) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
											)
									AS DECIMAL(20,10))
	,GrossPrePurchaseSvcFee		=	CAST(
									CAST(
											(
											li.OriginalAmountBorrowed *
											( CAST(ld.BorrowerStatedInterestRate AS DECIMAL(20,10)) / CAST(365.00 AS DECIMAL(20,10)) ) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
											--CAST(ld.IntBalDailyAccrual AS DECIMAL(20,10)) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
											)
									AS DECIMAL(20,10))
									*
									ISNULL( CAST(
												--CASE WHEN li.OriginationSeasoningDays > 1 THEN CAST(lof.ServicingFeePercent AS DECIMAL(20, 10)) + li.TrailingFeeRate ELSE CAST(lof.ServicingFeePercent AS DECIMAL(20, 10)) END
												li.HardCodedServiceFeePercent /* TECH DEBT: ServiceFeePercent is Hard-Coded */
												AS DECIMAL(20,10)) / CAST(NULLIF(ld.BorrowerStatedInterestRate,0) AS DECIMAL(20,10)) , 0)
									AS DECIMAL (20,10) )
	,NetPrePurchaseInterest			=	CAST(
										CAST(
												(
												li.OriginalAmountBorrowed *
												( CAST(ld.BorrowerStatedInterestRate AS DECIMAL(20,10)) / CAST(365.00 AS DECIMAL(20,10)) ) *DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
												--CAST(ld.IntBalDailyAccrual AS DECIMAL(20,10)) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
												)
										AS DECIMAL(20,10))
										-
										CAST(
										CAST(
												(
												li.OriginalAmountBorrowed *
												( CAST(ld.BorrowerStatedInterestRate AS DECIMAL(20,10)) / CAST(365.00 AS DECIMAL(20,10)) ) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
												--CAST(ld.IntBalDailyAccrual AS DECIMAL(20,10)) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
												)
										AS DECIMAL(20,10))
										*
										ISNULL( CAST(
													--CASE WHEN li.OriginationSeasoningDays > 1 THEN CAST(lof.ServicingFeePercent AS DECIMAL(20, 10)) + li.TrailingFeeRate ELSE CAST(lof.ServicingFeePercent AS DECIMAL(20, 10)) END
													li.HardCodedServiceFeePercent /* TECH DEBT: ServiceFeePercent is Hard-Coded */
													AS DECIMAL(20,10)) / CAST(NULLIF(ld.BorrowerStatedInterestRate,0) AS DECIMAL(20,10)) , 0)
										AS DECIMAL (20,10) )
										AS DECIMAL(10,4))
	/***************** Pre-Purchase Interest *****************/
	,li.Rating
	,li.EstimatedLossRate
	,li.TermMonths
	,li.InterestRate
	,li.BorrowerAPR
	,BorrowerState						= ISNULL(uta.StateOfResidence, CASE WHEN li.ListingCreationDate < '1/1/2009' THEN li.BorrowerState END)
	,MaturityDate						= ld.ExpectedMaturityDate
	,li.NumberOfPayments
	,MonthlyPaymentAmount				= ld.ScheduledMonthlyPaymentAmount
	,FirstPaymentDate					= ld.NextPaymentDueDate
	,li.LoanPurpose
	,pl.PriorProsperLoans
	,pl.ActivePriorProsperLoans
	,pl.ActivePriorProsperLoansBalance
	/***************** PII - Borrower Name and Address *****************/
	,li.BorrowerID						--NOTE: Not Really PII
	,FirstName							= CASE WHEN @PiiAndPointFico = 1 THEN ISNULL(und.FirstName,'') ELSE NULL END
	,MiddleName							= CASE WHEN @PiiAndPointFico = 1 THEN ISNULL(und.MiddleName,'') ELSE NULL END
	,LastName							= CASE WHEN @PiiAndPointFico = 1 THEN ISNULL(und.LastName,'') ELSE NULL END
	,Suffix								= CASE WHEN @PiiAndPointFico = 1 THEN ISNULL(und.Suffix,'') ELSE NULL END
	,BorrowerAddress					= CASE WHEN @PiiAndPointFico = 1 THEN uta.StreetAddress ELSE NULL END
	,BorrowerCity						= CASE WHEN @PiiAndPointFico = 1 THEN uta.OriginalCity ELSE NULL END
	,BorrowerZip						= uta.OriginalZip --NOTE: Not Really PII
	/***************** PII - Borrower Name and Address *****************/
	,lof.DTIwoProsperLoan
	,li.DTIwProsperLoan
	,li.MonthlyIncome
	,li.MonthlyDebt
	,EmploymentStatusDescription		= ISNULL(es.[Description],'')
	,Occupation							= o.OccupationName
	,MonthsEmployed						= DATEDIFF(M , DATEFROMPARTS(ued.StartYear,ued.StartMonth,1) , li.FICODate )
	,StatedMonthlyHousingPayment		= ular.MonthlyHousingPayment
	,StatedAnnualIncome					= ui.Income
	,IncomeVerifiable					= ui.IsVerifiable
	/***************** FICO Data - Vendor Agnostic *****************/
	,FICOScore		=	CASE WHEN @PiiAndPointFico = 1 THEN CAST(li.FICOScore AS VARCHAR(4)) ELSE
						CASE            
							WHEN CAST(li.FICOScore AS INT) < 600 THEN '< 600'
							WHEN CAST(li.FICOScore AS INT) >= 600 AND CAST(li.FICOScore AS INT) < 620 THEN '600-619'
							WHEN CAST(li.FICOScore AS INT) >= 620 AND CAST(li.FICOScore AS INT) < 640 THEN '620-639'
							WHEN CAST(li.FICOScore AS INT) >= 640 AND CAST(li.FICOScore AS INT) < 660 THEN '640-659'
							WHEN CAST(li.FICOScore AS INT) >= 660 AND CAST(li.FICOScore AS INT) < 680 THEN '660-679'
							WHEN CAST(li.FICOScore AS INT) >= 680 AND CAST(li.FICOScore AS INT) < 700 THEN '680-699'
							WHEN CAST(li.FICOScore AS INT) >= 700 AND CAST(li.FICOScore AS INT) < 720 THEN '700-719'
							WHEN CAST(li.FICOScore AS INT) >= 720 AND CAST(li.FICOScore AS INT) < 740 THEN '720-739'
							WHEN CAST(li.FICOScore AS INT) >= 740 AND CAST(li.FICOScore AS INT) < 760 THEN '740-759'
							WHEN CAST(li.FICOScore AS INT) >= 760 AND CAST(li.FICOScore AS INT) < 780 THEN '760-779'
							WHEN CAST(li.FICOScore AS INT) >= 780 AND CAST(li.FICOScore AS INT) < 800 THEN '780-799'
							WHEN CAST(li.FICOScore AS INT) >= 800 AND CAST(li.FICOScore AS INT) < 820 THEN '800-819'
							WHEN CAST(li.FICOScore AS INT) >= 820 AND CAST(li.FICOScore AS INT) <= 850 THEN '820-850'
							ELSE 'N/A' 
						END
						END
	,FICOReportDate	= li.FICODate
	,li.CreditBureau
	/***************** FICO Data - Vendor Agnostic *****************/
	/***************** Experian Credit Attributes *****************/
	,expp.ALL002
	,expp.ALL003
	,expp.ALL022
	,expp.ALL127
	,expp.ALL146
	,expp.ALL701
	,expp.ALL724
	,expp.ALL803
	,expp.ALL901
	,expp.BAC403
	,expp.REV404
	,li.ExperianRealEstatePayment
	,li.ExperianIsHomeowner
	/***************** Experian Credit Attributes *****************/
	/***************** TransUnion Credit Attributes *****************/
	,tup.at01s
	,tup.at02s
	,tup.at20s
	,tup.at36s
	,tup.bc34s
	,tup.co02s
	,tup.co03s
	,tup.co04s
	,tup.g061s
	,tup.g063s
	,tup.g069s
	,tup.g095s
	,tup.g099s
	,tup.g980s
	,tup.g990s
	,tup.inap01
	,tup.mt02s
	/* Home Ownership Type */
	--,HomeOwnershipType	=	CASE 
	--							WHEN tup.mt02s >= 1 THEN 'Mortgage: With Open Mortgage'
	--							WHEN tup.mt02s = 0 THEN 'Rental: With Mortgage but No Open Mortgage'
	--							ELSE 'Rental: No Mortgage'
	--						END
	,tup.mtap01
	,tup.reap01
	,tup.s071b
	,tup.s207a
	,tup.s207s
	/***************** TransUnion Credit Attributes *****************/
	,HousingPayment = CAST(lofsd.Value AS MONEY)

INTO #ListingCreditAttributes
FROM #CTEListings li
LEFT JOIN #CTEPriorLoans pl
	ON pl.LoanNumber = li.LoanNumber
LEFT JOIN #CTETuPivot tup
	ON tup.CreditReportID = li.CreditReportID
LEFT JOIN #CTEExpPivot expp
	ON expp.ExperianCreditProfileResponseID = li.ExperianCreditProfileResponseID
CROSS APPLY (
	SELECT 
		TOP 1 ModifiedDate
	FROM 
		C1.dbo.ListingStatus (NOLOCK)
	WHERE 
		1=1
		AND ListingID = li.ListingNumber
		AND VersionValidBit = 1
		AND VersionEndDate IS NULL
		AND ListingStatusTypeID = 6 --NOTE: Consider Changing Status Type to 1
	ORDER BY VersionStartDate DESC
) lst
OUTER APPLY (
	SELECT 
		TOP 1 LoanOfferID
	FROM 
		C1.dbo.ListingOffersSelected (NOLOCK)
	WHERE
		1=1
		AND ListingID = li.ListingNumber
		AND VersionValidBit = 1
		AND VersionEndDate IS NULL
	ORDER BY 
		VersionStartDate DESC
) los
LEFT JOIN C1.dbo.LoanOffer (NOLOCK) lof
	ON lof.LoanOfferID = los.LoanOfferID
LEFT JOIN (
	SELECT 
		ListingScoreID
		, Value
		FROM 
			CircleOne.dbo.tblLoanOfferScoreDetail (NOLOCK)
		WHERE 
			VariableID = 710
) lofsd
	ON lofsd.ListingScoreID = lof.ListingScoreID
	AND lof.ListingScoreID IS NOT NULL

LEFT JOIN 
	C1.dbo.UserEmploymentDetail (NOLOCK) ued
	ON 
	ued.UserEmploymentDetailID = li.UserEmploymentDetailID
LEFT JOIN 
	C1.dbo.EmploymentStatus (NOLOCK) es
	ON 
	es.EmploymentStatusID = ued.EmploymentStatusID
LEFT JOIN 
	C1.dbo.Occupations (NOLOCK) o
	ON 
	ued.OccupationID = o.ID
LEFT JOIN 
	CircleOne.dbo.Users u 
	ON
	u.ID = li.BorrowerID
LEFT JOIN 
	DW.dbo.dim_listing_verification dlv
	on 
	dlv.ListingID = li.ListingNumber
LEFT JOIN 
	CircleOne.DBO.GovtIssuedIdentification (NOLOCK) govid
	ON 
	u.TaxpayerIDNumberID = govid.GovtIssuedIdentificationID
OUTER APPLY
	Circleone.dbo.tfnDecrypt(enNumber) GOVIDDec
OUTER APPLY 
	Circleone.dbo.tfnDecrypt(enDateOfBirth) DOBDec
OUTER APPLY (
	SELECT TOP 1
		 StateOfResidence
		,StreetAddress = (OriginalAddress1 + ISNULL(', ' + OriginalAddress2,''))
		,OriginalCity
		,OriginalZip
	FROM 
		C1.dbo.UserToAddress (NOLOCK)
	WHERE 
		1=1
		AND UserID = li.UserID
		AND VersionValidBit = 1
		AND IsLegalAddress = 1
		AND IsVisible = 1 --NOTE: Unsure if Necessary
		AND VersionStartDate <= lst.ModifiedDate --li.TermsApprovalDate
		AND (VersionEndDate IS NULL OR VersionEndDate > lst.ModifiedDate /*li.TermsApprovalDate*/)
	ORDER BY 
		VersionStartDate DESC
) uta
OUTER APPLY (
	SELECT TOP 1
		 FirstName
		,MiddleName
		,LastName
		,Suffix
	FROM 
		C1.dbo.UserNameDetail (NOLOCK)
	WHERE 
		1=1
		AND UserID = li.UserID
		AND VersionValidBit = 1
		AND UserNameTypeID <= 3
		AND VersionStartDate <= lst.ModifiedDate --li.TermsApprovalDate
		AND (VersionEndDate IS NULL OR VersionEndDate > lst.ModifiedDate /*li.TermsApprovalDate*/)
	ORDER BY 
		UserNameTypeID DESC
		,VersionStartDate DESC
) und
OUTER APPLY (
	SELECT TOP 1
		 NextPaymentDueDate
		,ExpectedMaturityDate
		,ScheduledMonthlyPaymentAmount
		,BorrowerStatedInterestRate
		,IntBalDailyAccrual
	FROM 
		C1.dbo.LoanDetail (NOLOCK)
	WHERE 
		1=1
		AND LoanID = li.LoanNumber
		AND VersionValidBit = 1
		--AND VersionStartDate <= lo.OriginationDate 
		--AND (VersionEndDate > lo.OriginationDate OR VersionEndDate IS NULL)
		--AND IntBalDailyAccrual > 0.00
	ORDER BY 
		VersionStartDate ASC
) ld
OUTER APPLY (
	SELECT 
		TOP 1
		 Income
		,IsVerifiable
	FROM 
		C1.dbo.UserIncome (NOLOCK)
	WHERE 
		1=1
		AND UserID = li.UserID
		AND VersionValidBit = 1
		AND VersionStartDate <= li.TermsApprovalDate
		AND (
			VersionEndDate > li.TermsApprovalDate
			OR VersionEndDate IS NULL
			)
	ORDER BY 
		VersionStartDate DESC
) ui
OUTER APPLY (
	SELECT 
		TOP 1 
		MonthlyHousingPayment
	FROM 
		C1.dbo.UserLoanAmountRequests (NOLOCK)
	WHERE
		1=1  
		AND ExternalCreditReportID = li.ExternalCreditReportID
		AND UserID = li.UserID
		AND ListingID = li.ListingNumber
		AND MonthlyHousingPayment IS NOT NULL
	ORDER BY 
		CreationDate DESC
) ular


SELECT
	LoanNumber
	,OriginationDate
	,lca.bc34s Utilization
	--,inap01 + reap01 NonMortgageObligation
	--,g099s BankruptciesLast24Months
	--,g980s InquiriesLast6Months
	--,g990s InquiriesLast12Months
	--,at02s TotalOpenTrades
	--,FICOReportDate
	--,upper(FirstName) FirstName
	--,upper(LastName) LastName
	--,upper(BorrowerAddress) Address
	--,upper(BorrowerCity) City
	--,BorrowerState
	--,'"'+BorrowerZip+'"' Zip
	--,'"'+SSN+'"' SSN
	--,DOB
	,lca.PriorProsperLoans
	--,lca.ManuallyApprovedIncome
	--,lca.HasProofOfIncome
	--,lca.StatedAnnualIncome
	FROM 
		#ListingCreditAttributes lca
