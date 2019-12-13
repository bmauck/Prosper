--Select * from c1..tblscorevariables where VariableName like '%G2%'

--select * from sandbox..bm_investors

--First Name und.FirstName
--Last Name und.LastName
--Address uta.OriginalAddress
--City uta.OriginalCity
--State Zip uta.OriginalZip
--Dob u.edDateOfBirth
--SSN 
--Credit report date 
--Income u.Income
--Bankruptcies in the last 12 months g099s
--Number of credit inquiries in the last 6 months g237s *
--Total Non-mortgage debts at28b *
--total number of open trades at02s
--Disbursement date
--Payment Frequency
--Number of credit inquiries in the last 12 months g238s *


declare @endperiod datetime = '2018-10-16'

SELECT
	 --,PurchaseDate				= lot.EffectiveDate
	--,SoldDate					= ltl.OwnershipEndDate
	ltl.LoanID
	--,CustomerID				= lo.BorrowerID
	--,OriginationFeeAmount		= li.EndingOriginationFeeAmount
	--,ue.Email
	,LastName					= und.LastName + ISNULL(' ' + NULLIF(und.Suffix,''),'')
	,FirstName					= und.FirstName 
	,MiddleInitial				= und.MiddleName
	,u.enDateOfBirth
	,govid.enNumber				as 'enSSN'
	,uta.OriginalAddress1
	--,uta.OriginalAddress2
	,uta.OriginalCity
	,uta.StateOfResidence
	,uta.OriginalZip
	--,HomeAreaCode				= ph.AreaCode
	--,HomeLineNumber				= ph.PhoneNumber
	--,HomeExtension				= CAST( NULL AS VARCHAR(6) )
	--,WorkAreaCode				= pw.AreaCode
	--,WorkLineNumber				= pw.PhoneNumber
	--,WorkExtension				= CAST( NULL AS VARCHAR(6) )
	--,ued.Employer
	--,ued.EmploymentStatus
	--,ued.OccupationDescription
	--,ued.EmploymentStartYear
	--,ued.EmploymentStartMonth
	,ui.Income
	FROM CircleOne.dbo.LoanToLender (NOLOCK) ltl
	JOIN CircleOne.dbo.LoanOwnershipTransfer (NOLOCK) lot
		ON lot.LoanOwnershipTransferID = ltl.PurchaseLoanOwnershipTransferID
		AND lot.RecipientID = ltl.LenderID
		AND lot.LoanNoteID = ltl.LoanNoteID
		AND lot.LoanID = ltl.LoanID
	JOIN CircleOne.dbo.Loans (NOLOCK) lo
		ON lo.LoanID = ltl.LoanID
	JOIN CircleOne.dbo.Listings (NOLOCK) li
		ON li.LoanID = lo.LoanID
	JOIN CircleOne.dbo.Users (NOLOCK) u
		ON u.ID = lo.BorrowerID
	
	LEFT JOIN CircleOne.DBO.GovtIssuedIdentification (NOLOCK) govid
		ON u.TaxpayerIDNumberID = govid.GovtIssuedIdentificationID
	OUTER APPLY (
		SELECT TOP 1 
			 OriginalAddress1
			,OriginalAddress2
			,OriginalCity
			,StateOfResidence
			,OriginalZip
			,IsLegalAddress
			,IsStateOfResidenceVerified = ISNULL(IsStateOfResidenceVerified,0)
			,IsPreferredMailing
			--,IsVisible
		FROM CircleOne.dbo.UserToAddress (NOLOCK)
		WHERE UserID = lo.BorrowerID
			AND VersionStartDate < ISNULL(ltl.OwnershipEndDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
			AND (VersionEndDate IS NULL OR VersionEndDate >= ISNULL(ltl.OwnershipEndDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
			AND VersionValidBit = 1			
		ORDER BY
			 --VersionStartDate DESC,
			 IsLegalAddress DESC
			,IsPreferredMailing DESC
			,VersionStartDate DESC
	) uta --*/
	OUTER APPLY (
		SELECT TOP 1
			 FirstName	= LTRIM(RTRIM(FirstName))
			,MiddleName	= LTRIM(RTRIM(MiddleName))
			,LastName	= LTRIM(RTRIM(LastName))
			,Suffix		= LTRIM(RTRIM(Suffix))
			,IsVerified			
		FROM Circleone.dbo.UserNameDetail (NOLOCK)
		WHERE UserID = lo.BorrowerID
			AND VersionStartDate < ISNULL(ltl.OwnershipEndDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
			AND (VersionEndDate IS NULL OR VersionEndDate >= ISNULL(ltl.OwnershipEndDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
			AND VersionValidBit = 1
		ORDER BY
			 --VersionStartDate DESC,
			 CASE 
			 	WHEN UserNameTypeID = 3 THEN 1
			 	WHEN UserNameTypeID = 2 THEN 2
			 	ELSE 3
			 END 
			,VersionStartDate DESC
	) und --*/
	OUTER APPLY (
		SELECT TOP 1
			 ued.Employer
			,EmploymentStatus			= es.[Description]
			,OccupationDescription		= o.OccupationName
			,EmploymentStartYear		= ued.StartYear
			,EmploymentStartMonth		= ued.StartMonth
		FROM CircleOne.dbo.UserEmploymentDetail (NOLOCK) ued
		LEFT JOIN CircleOne.dbo.EmploymentStatus (NOLOCK) es
			ON es.EmploymentStatusID = ued.EmploymentStatusID
		LEFT JOIN CircleOne.dbo.Occupations (NOLOCK) o
			ON o.ID = ued.OccupationID
		WHERE ued.UserID = lo.BorrowerID
			AND ued.VersionStartDate < ISNULL(ltl.OwnershipEndDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
			AND (ued.VersionEndDate IS NULL OR ued.VersionEndDate >= ISNULL(ltl.OwnershipEndDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
			AND ued.VersionValidBit = 1
		ORDER BY ued.VersionStartDate DESC
	) ued --*/
	OUTER APPLY (
		SELECT TOP 1
			 Income
			,IsVerifiable
		FROM CircleOne.dbo.UserIncome (NOLOCK)
		WHERE UserID = lo.BorrowerID
			AND VersionStartDate < ISNULL(ltl.OwnershipEndDate,'2018-10-16') --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
			AND (VersionEndDate IS NULL OR VersionEndDate >= ISNULL(ltl.OwnershipEndDate,'2018-10-16')) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
			AND VersionValidBit = 1
		ORDER BY
			 --VersionStartDate DESC,
			 IsVerifiable DESC
			,VersionStartDate DESC
	) ui --*/
	
	WHERE 1=1
		AND	ltl.LoanID in ( 974451
							, 987140
							,1019374
							,1027154
							,1034498
							,1107052
							,1124934
							,1004855
							)
		AND lot.EffectiveDate < @EndPeriod