select
	top 100
	a.UserID
	,upper(und.FirstName) FirstName
	,upper(und.MiddleName) MiddleName
	,upper(und.LastName) LastName
	,upper(und.Suffix) Suffix
	,upper(DOBDec.PlainText) DOB
	,upper(GOVIDDec.PlainText) SSN
	,upper(uta.StreetAddress) StreetAddress
	,upper(OriginalCity) City
	,upper(uta.StateOfResidence) State
	,upper(OriginalZip) Zip
	,req.AmountRequested
	,fe.MonthlyIncome
	,a.EventType
	,a.EventSubType
	,a.EventDetails
	,fe.ExternalCreditReportID

	from
		Sandbox..bm_lendingpoint_pop a
	left join 
		CircleOne.dbo.users u 
		on 
		a.UserID = u.ID
	left join 
		CircleOne.DBO.GovtIssuedIdentification (nolock) govid
		on 
		u.TaxpayerIDNumberID = govid.GovtIssuedIdentificationID
	outer apply
		Circleone.dbo.tfnDecrypt(enNumber) GOVIDDec
	outer apply
		Circleone.dbo.tfnDecrypt(enDateOfBirth) DOBDec
	outer apply (
		select top 1
			StateOfResidence
			,StreetAddress = (OriginalAddress1 + ISNULL(', ' + OriginalAddress2,''))
			,OriginalCity
			,OriginalZip
		from  
			CircleOne.dbo.UserToAddress (nolock)
		where
			1=1
			and UserID = a.UserID
			and VersionValidBit = 1
			and IsLegalAddress = 1
			and IsVisible = 1 --NOTE: Unsure if Necessary
			and VersionEndDate is null 
		order by
			VersionStartDate desc
	) uta
	outer apply (
		select 
			top 1
			UserID
			,FirstName
			,MiddleName
			,LastName
			,Suffix
			from 
				CircleOne..UserNameDetail
			where
				1=1 
				and VersionEndDate is null
				and VersionValidBit = 1
				and a.UserID = UserNameDetail.UserID
			order by 
				CreationDate desc
	) und
	left join (
      SELECT 
		dfe.ApplicationBorrowerEventSK
		,max(dfe.ExternalCreditReportID) as ExternalCreditReportID
        ,max(LoanProductID) as LoanProductID
        ,max(Underwriter) as Underwriter
        ,max(EmploymentStatus) as EmploymentStatus
		,avg(PMIScore) as PMIScore
		,avg(VantageScore) as VantageScore
		,avg(InitialLoanAmount) as InitialLoanAmount
		,avg(MonthlyIncome) as MonthlyIncome
		,max(BusinessRuleVersion) as BusinessRuleVersion
      from 
		DW..fact_eligibility dfe 
      where
		1=1 
		and CAST(IsDupe as INT) = 0
      group by 
		ApplicationBorrowerEventSK
     ) fe
		on 
		a.ApplicationBorrowerEventSK = fe.ApplicationBorrowerEventSK
	outer apply (
		select 
			top 1
			AmountRequested 
			from 
				CircleOne..UserLoanAmountRequests ular
			where 
				1=1 
				and ular.ExternalCreditReportId = fe.ExternalCreditReportID
			order by 
				ExternalCreditReportID desc
			) req