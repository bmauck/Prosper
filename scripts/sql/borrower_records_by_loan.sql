/*
SET STATISTICS IO ON
SET STATISTICS TIME ON
--*/
/*
USE ReportingProgrammability
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE dbo.usp_GetBorrowerApplicationXML
(
	 @LenderID		INT
	,@MinRunDate	DATETIME
	,@MaxRunDate	DATETIME
	,@PointFICO		TINYINT		= 0
)
AS
--*/

--/* TESTING

DECLARE @MinRunDate	DATETIME	= '1/8/2018'
DECLARE @MaxRunDate	DATETIME	= '7/2/2019'
DECLARE @LenderID	INT			= 7152733
DECLARE @PointFICO	TINYINT		= 0
--SELECT * FROM C1.DBO.LoanGroup
--*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH

--DECLARE @PointFICO TINYINT = 0
DECLARE @OriginationDate DATETIME
    
SET @OriginationDate = (
	SELECT MAX(DateKey)
	FROM CircleOne.dbo.Dates (NOLOCK)
	WHERE DateKey <= @MaxRunDate
		AND FlgWeekend = 'N'	--Not a Weekend
		AND FlgUSHoliday = 'N'	--Not a Bank Holiday
)

BEGIN

;WITH CTEApplications AS (
	SELECT         
		 [@ListingID]				= l.ID
		,[@LoanID]					= l.LoanID
		,ListingCategory			= ISNULL(lc.Name,'')
		,RequestedAmount			= ISNULL(l.Amount,'')
		,SocialSecurity				= ISNULL(CircleOne.dbo.fnDecrypt(govID.enNumber),'')		--TODO: CHANGE THIS LOGIC
		,DateOfBirth				= CAST(CircleOne.dbo.fnDecrypt(u.enDateOfBirth) AS DATE) --TODO: CHANGE THIS LOGIC
		,ListingTitle				= ISNULL(l.Title,'')
		,ListingDescription			= ISNULL(l.Purpose,'')
		,l.TermsApprovalDate
		,l.FundingThreshold
		,IsPartialFundingApproved	= CASE WHEN l.IsPartialFundingApproved = 1 THEN 'TRUE' ELSE 'FALSE' END
		,CreditReport				= NULL --ed.rawXML  --Pending legal approval
		
		/* ---- User Agreements ---- */
		,UserAgreements = (
			SELECT
				 AgreementDateTime		= a.CreatedDate
				,AgreementType			= at.Title
				,AgreementBody			= CAST(circleone_dw.dbo.fn_decompress(a.AgreementBodyBinary,LEN(a.AgreementBodyBinary)) AS VARCHAR(MAX))
				,IsCorrectedAgreement	= CASE WHEN IsCorrectedAgreement = 1 THEN 'TRUE' ELSE 'FALSE' END
			FROM CircleOne.dbo.Agreements (NOLOCK) a
			JOIN CircleOne.dbo.AgreementTypes (NOLOCK) at
				ON a.AgreementTypeID = at.ID
			WHERE a.UserID = l.UserID
				AND at.ID IN (1008,6,1021,1022,1010,1014,7,10,5555572,5555574) --NOTE: 1014 added 2/25/2015; 5555572 & 5555574 (TCPA/PenFed) added 3/19/2019
			FOR XML PATH('UserAgreement'),TYPE
		)
		
		/* ---- Email Messages ---- */
		,EmailMessages = (
			SELECT
				EmailMessageBody = CASE WHEN CAST(MessageXML AS VARCHAR(MAX)) = '' THEN CAST(circleone_dw.dbo.fn_decompress(MessageXmlBinary,LEN(MessageXmlBinary)) AS VARCHAR(MAX)) ELSE MessageXML END
			FROM CircleOne.dbo.Emails (NOLOCK)
			WHERE
				MessageTypeID = 9
				AND UserID = l.UserID
				AND ABS(DATEDIFF(DD,CreationDate,lo.OriginationDate)) <= 5 --Email within 5 days of origination
			FOR XML PATH('EmailMessage'),TYPE
		)

		/* ---- Loan Agreements ---- */
		,LoanAgreements = (
			SELECT * FROM (
				SELECT
					 AgreementDateTime		= a.CreatedDate
					,AgreementType			= at.Title
					,AgreementBody			= CAST(circleone_dw.dbo.fn_decompress(a.AgreementBodyBinary,LEN(a.AgreementBodyBinary)) AS VARCHAR(MAX))
					,IsCorrectedAgreement	= CASE WHEN IsCorrectedAgreement = 1 THEN 'TRUE' ELSE 'FALSE' END
				FROM CircleOne.dbo.LoanToAgreement (NOLOCK) lta
				JOIN CircleOne.dbo.Agreements (NOLOCK) a
					ON a.ID = lta.AgreementID
				JOIN CircleOne.dbo.AgreementTypes (NOLOCK) at
					ON a.AgreementTypeID = at.ID
				WHERE lta.LoanID = l.LoanID
				
				UNION ALL
				
				SELECT
					 AgreementDateTime		= a.CreatedDate
					,AgreementType			= at.Title
					,AgreementBody			= CAST(circleone_dw.dbo.fn_decompress(a.AgreementBodyBinary,LEN(a.AgreementBodyBinary)) AS VARCHAR(MAX))
					,IsCorrectedAgreement	= CASE WHEN IsCorrectedAgreement = 1 THEN 'TRUE' ELSE 'FALSE' END
				FROM CircleOne.dbo.ListingToAgreement (NOLOCK) lta
				JOIN CircleOne.dbo.Agreements (NOLOCK) a
					ON a.ID = lta.AgreementID
				JOIN CircleOne.dbo.AgreementTypes (NOLOCK) at
					ON a.AgreementTypeID = at.ID
				WHERE lta.ListingID = l.ID
					AND at.ID = 2
			) i
			FOR XML PATH('LoanAgreement'),TYPE
		)

		/* ---- Names ---- */
		,Names = (
			SELECT
				 FirstName	= ISNULL(und.FirstName,'')
				,MiddleName	= ISNULL(und.MiddleName,'')
				,LastName	= ISNULL(und.LastName,'')
				,Suffix		= ISNULL(und.Suffix,'')
				,NameType	= ISNULL(unt.[Description],'')
			FROM CircleOne.dbo.UserNameDetail (NOLOCK) und
			JOIN CircleOne.dbo.UserNameType (NOLOCK) unt
				ON unt.UserNameTypeID = und.UserNameTypeID
			WHERE und.userid = l.userid
				AND und.VersionStartDate <= lst.ModifiedDate
				AND (und.VersionEndDate > lst.ModifiedDate OR und.VersionEndDate IS NULL)
				AND und.VersionValidBit = 1
			FOR XML PATH('Name'),TYPE
		)

		/* ---- Addresses ---- */
		,Addresses = (
			SELECT
				 AddressLine1		= ISNULL(uta.OriginalAddress1,'')
				,AddressLine2		= ISNULL(uta.OriginalAddress2,'')
				,AddressType		= ISNULL(uat.Name,'')
				,City				= ISNULL(uta.OriginalCity,'')
				,StateOfResidence	= ISNULL(uta.StateOfResidence,'')
				,ZipCode			= ISNULL(uta.OriginalZip,'')
				,IsPreferredMailing	= CASE WHEN uta.IsPreferredMailing = 1 THEN 'TRUE' ELSE 'FALSE' END
				,IsLegalAddress		= CASE WHEN uta.IsLegalAddress = 1 THEN 'TRUE' ELSE 'FALSE' END
				--,IsStateOfResidenceVerified = CASE WHEN uta.IsStateOfResidenceVerified = 1 THEN 'TRUE' ELSE 'FALSE' END
			FROM CircleOne.dbo.UserToAddress (NOLOCK) uta
			JOIN CircleOne.dbo.UserAddressType (NOLOCK) uat
				ON uat.UserAddressTypeID = uta.UserAddressTypeID
			WHERE uta.UserID = l.UserID
				AND uta.VersionStartDate <= lst.ModifiedDate
				AND (uta.VersionEndDate > lst.ModifiedDate OR uta.VersionEndDate IS NULL)
				AND uta.VersionValidBit = 1
				AND uta.IsVisible = 1
			FOR XML PATH('Address'),TYPE
		)

		/* ---- Employments ---- */
		,Employments = (
			SELECT
				 Employer				= ISNULL(ued.Employer,'')
				,EmploymentStatusMonths	= ISNULL(CAST(ued.EmploymentStatusMonths AS VARCHAR(10)),'')
				,EmploymentStartMonth	= ISNULL(CONVERT(VARCHAR, ued.StartMonth) + '-' +  CONVERT(VARCHAR, ued.StartYear) ,'')
				,EmploymentStatus		= ISNULL(es.[Description],'')
				,o.OccupationName
			FROM CircleOne.dbo.UserEmploymentDetail (NOLOCK) ued
			LEFT JOIN CircleOne.dbo.EmploymentStatus (NOLOCK) es
				ON ued.EmploymentStatusID = es.EmploymentStatusID
			LEFT JOIN CircleOne.dbo.Occupations (NOLOCK) o
				ON ued.OccupationID = o.ID
			WHERE l.UserID = ued.UserID
				AND ued.VersionStartDate <= l.TermsApprovalDate
				AND (ued.VersionEndDate > l.TermsApprovalDate OR ued.VersionEndDate IS NULL)
				AND ued.VersionValidBit = 1
			FOR XML PATH('Employment'),TYPE
		)

		/* ---- Self Employments ---- */
		,SelfEmployments = (
			SELECT
				 SelfEmployedType			= ISNULL(st.Name,'')
				,SelfEmployedEntityType		= ISNULL(seet.Name,'')
				,BusinessStateOfLicensing	= ISNULL(used.BusinessStateOfLicensing,'')
				,BusinessEIN				= ISNULL(circleone_dw.dbo.fnDecrypt(used.enBusinessEIN),'')
				,ContractorType				= ISNULL(sect.Name,'')
			FROM CircleOne.dbo.UserSelfEmploymentDetail (NOLOCK) used
			LEFT JOIN CircleOne.dbo.SelfEmployedContractorType (NOLOCK) sect
				ON sect.SelfEmployedContractorTypeID = used.ContractorTypeID
			LEFT JOIN CircleOne.dbo.SelfEmployedEntityType (NOLOCK) seet
				ON seet.SelfEmployedEntityTypeID = used.SelfEmployedEntityTypeID
			LEFT JOIN CircleOne.dbo.SelfEmployedType (NOLOCK) st
				ON st.SelfEmployedTypeID = used.SelfEmployedTypeID
			WHERE l.UserID = used.UserID
				AND used.VersionStartDate <= l.TermsApprovalDate
				AND (used.VersionEndDate > l.TermsApprovalDate OR used.VersionEndDate IS NULL)
				AND used.VersionValidBit = 1
			FOR XML PATH('SelfEmployment'),TYPE
		)

		/* ---- Emails ---- */
		,Emails = (
			SELECT EmailAddress = Email
			FROM CircleOne.dbo.UserEmails (NOLOCK)
			WHERE UserID = l.UserID
				AND VersionStartDate <= l.TermsApprovalDate
				AND (VersionEndDate > l.TermsApprovalDate OR VersionEndDate IS NULL)
				AND VersionValidBit = 1
			FOR XML PATH(''),TYPE
		)

		/* ---- Incomes ---- */
		,Incomes = (
			SELECT
				StatedAnnualIncome = Income
				--,IsVerifiable
			FROM CircleOne.dbo.UserIncome (NOLOCK)
			WHERE UserID = l.UserID
				AND VersionStartDate <= l.TermsApprovalDate
				AND (VersionEndDate > l.TermsApprovalDate OR VersionEndDate IS NULL)
				AND VersionValidBit = 1
			FOR XML PATH(''),TYPE
		)

		/* ---- Phones ---- */
		,Phones = (
			SELECT
				 p.CountryCode
				,PhoneNumber		= ISNULL(p.AreaCode + p.PhoneNumber,'')
				,PhoneNumberType	= ISNULL(pt.[Description],'')
			FROM CircleOne.dbo.UserToPhone (NOLOCK) utp
			JOIN CircleOne.dbo.PhoneTypes (NOLOCK) pt
				ON utp.UserPhoneTypeID = pt.ID
			JOIN CircleOne.dbo.Phone (NOLOCK) p
				ON utp.PhoneID =  p.PhoneID
			WHERE l.UserID = utp.UserID
				AND utp.VersionStartDate <= l.TermsApprovalDate
				AND (utp.VersionEndDate > l.TermsApprovalDate OR utp.VersionEndDate IS NULL)
				AND utp.VersionValidBit = 1
			FOR XML PATH('Phone'),TYPE
		)

		/* ---- Accounts ---- */
		,Accounts = (
			SELECT
				 BankName					= ISNULL(ba.BankName,'')
				,BankAccountType			= ISNULL(bat.Name,'')
				,FirstAccountHolderName		= ISNULL(ba.FirstAccountHolderName,'')
				,SecondAccountHolderName	= ISNULL(ba.SecondAccountHolderName,'')
				,AccountNumber				= ISNULL(CAST(circleone_dw.dbo.fnDecrypt(ba.enAccountNumber) AS VARCHAR(17)),'')
				,RoutingNumber				= ISNULL(ba.RoutingNumber,'')
				,IsDefault					= CASE WHEN a.IsDefault = 1 THEN 'TRUE' ELSE 'FALSE' END
			FROM CircleOne.dbo.Accounts (NOLOCK) a
			JOIN CircleOne.dbo.AccountCategories (NOLOCK) ac
				ON ac.ID = a.Category
			JOIN CircleOne.dbo.BankAccounts (NOLOCK) ba
				ON a.ID = ba.AccountID
			JOIN CircleOne.dbo.BankAccountType (NOLOCK) bat
				ON ba.BankAccountType = bat.BankAccountTypeID
			WHERE a.UserID = l.UserID
				AND a.CreationDate <= lo.OriginationDate
			FOR XML PATH('Account'),TYPE
		)
	
		/* ---- Credit Score ---- */
		,CreditScore		=	CASE WHEN @PointFICO = 1 THEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS VARCHAR(4)) ELSE
								CASE            
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 600 THEN '< 600'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 600 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 620 THEN '600-619'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 620 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 640 THEN '620-639'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 640 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 660 THEN '640-659'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 660 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 680 THEN '660-679'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 680 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 700 THEN '680-699'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 700 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 720 THEN '700-719'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 720 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 740 THEN '720-739'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 740 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 760 THEN '740-759'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 760 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 780 THEN '760-779'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 780 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 800 THEN '780-799'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 800 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) < 820 THEN '800-819'
									WHEN CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) >= 820 AND CAST(ISNULL(tucrs.ScoreResults,ucp.Score) AS INT) <= 850 THEN '820-850'
									ELSE 'N/A' 
								END
								END
		,CreditScoreDate	= CAST(ISNULL(tucr.CreditReportDate,ucp.CreditPullDate) AS DATETIME)
		,CreditScoreVendor	= cb.CreditBureauName
		,ProsperRating		= prt.RatingCode
		,EALR				= l.EstimatedLoss
	FROM CircleOne.dbo.Listings (NOLOCK) l
	JOIN CircleOne.dbo.ProsperRatingType (NOLOCK) prt
		ON prt.ProsperRatingTypeID = l.ProsperRatingTypeID
	JOIN CircleOne.dbo.ListingStatus (NOLOCK) lst
		ON lst.ListingID = l.ID
		AND lst.VersionEndDate IS NULL
		AND lst.VersionValidBit = 1
		AND ListingStatusTypeID  = 6
	JOIN CircleOne.dbo.Loans (NOLOCK) lo
		ON l.LoanID = lo.LoanID
	JOIN CircleOne.dbo.InvestmentTypes (NOLOCK) it
		ON it.InvestmentTypeID = l.InvestmentTypeID
	JOIN CircleOne.dbo.ListingCategory (NOLOCK) lc
		ON l.ListingCategoryID = lc.ListingCategoryID
	JOIN CircleOne.dbo.Users (NOLOCK) u
		ON u.ID = l.UserID
	--JOIN CircleOne.dbo.LoanToLender (NOLOCK) ltl
	--	ON ltl.LoanID = lo.LoanID
	--	AND ltl.LenderID = @LenderID
	--	AND lo.OriginationDate = @OriginationDate
	--JOIN TabReporting.dbo.usp_GetBorrowerApplicationXML_MultipleLoans (NOLOCK) s 
	--	ON s.LoanID = lo.LoanID
	LEFT JOIN CircleOne.dbo.GovtIssuedIdentification (NOLOCK) govID
		ON u.TaxpayerIDNumberID = govID.GovtIssuedIdentificationID
	LEFT JOIN CircleOne.dbo.ListingCreditReportMapping (NOLOCK) lcrm
		ON lcrm.ListingId = l.ID
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
		FROM CircleOne.dbo.ExperianDocuments (NOLOCK) ed
		JOIN CircleOne.dbo.UserCreditProfiles (NOLOCK) ucp
			ON ucp.ExperianDocumentID = ed.id
		JOIN CircleOne.dbo.ExperianCreditProfileResponse (NOLOCK) ecpr
			ON ecpr.ExperianDocumentID = ucp.ExperianDocumentID
		WHERE ed.ExternalCreditReportId = lcrm.ExternalCreditReportId
			AND lcrm.CreditBureau = 1	
		ORDER BY ucp.CreditPullDate DESC, ucp.CreationDate DESC, ecpr.CreatedDate DESC
	) ucp
	WHERE 1=1
		AND it.IsWholeLoanType = 1
		AND lo.LoanID IN (
			select * from #loans
			)
		--	SELECT ltl.LoanID
		--	FROM CircleOne.dbo.LoanToLender (NOLOCK) ltl
		--	JOIN CircleOne.dbo.Loans (NOLOCK) l
		--		ON l.LoanID = ltl.LoanID
		--	WHERE LenderID = @LenderID
		--		AND l.OriginationDate = @OriginationDate
		--) --TODO: Change this Logic
)

--/*
SELECT (
	SELECT
		 [@OriginationDate] = @OriginationDate
		,[@LoanCount] = (SELECT COUNT(*) FROM CTEApplications)
		,(
		   SELECT *
		   FROM CTEApplications
		   ORDER BY [@ListingID]
		   FOR XML PATH('Application'),TYPE
		)
	FOR XML PATH('Applications'),TYPE
	)
FOR XML PATH('ROOT'),TYPE --*/

/* TESTING
SELECT * FROM CTEApplications--*/

END