select 
	l.LoanID
	,li.ID
	,l.OriginationDate
	--,li.Amount
	--,li.MonthlyIncome
	--,tu.AT02S as 'Time Since First Credit'
	--,'Prior Borrower' = case when li2.PriorLoanCount > 0 then 1
	--	else 0 end
	--,app.dti_woprosploan_allemp as 'DTI w/o Prosper Loan'
	--,l.loanid 
	--,uemp.EmploymentStatusMonths as 'Months Employed'
	--,tu.BC34S as 'Utilitization'
	--,tu.ATAP01 - tu.MTAP01 as 'Non Mortgage Monthly Obligation'
	--,tu.G099S as 'Bankruptcies in the past 24 months'
	--,tu.G237S as 'Inquiries in the past 6 months'
	--,tu.AT28B as 'Total Non-Mortgage Credit'
	--,tu.AT02S as 'Total Number of Open Trades'
	--,tu.G980S as  'Deduped Inquiries in the past 12 months'
	--,li2.CreditReportDate 
	,tlosd.value as 'DTI'
	,crca.CvValue as 'Inquiries'
	from 
	c1..listings li
	left join  
		(select *, (row_number()
		over(partition by UserID order by CreditPullDate desc,
		CreatedDate desc)) as id1 
		from CircleOne..UserCreditReportMapping) ucp 
		on 
		li.userid=ucp.UserID  
		and id1=1
	left join  
		(select *, (row_number()
		over(partition by UserID order by CreationDate desc,
		CreationDate desc)) as uempid1 
		from CircleOne..UserEmploymentDetail) uemp 
		on 
		li.userid=uemp.UserID  
		and uempid1=1
	left join 
		dw..dw_application app
		on 
		li.ID = app.listing_id
	left join 
		c1..loans l 
		on 
		li.loanid=l.loanid
	left join
		dw..dm_listing li2
		on 
		li2.ListingID = li.ID
	left join
		TransUnion..CreditReport cr 
		on 
		ucp.ExternalCreditReportid = cr.ExternalCreditReportId
	left join 
		dw..fact_transunion_cv_attribute_eads14 tu 
		on 
		tu.CreditReportrequestId = CR.CreditReportrequestId
	left join 
		CircleOne..ListingOffersSelected los 
		on 
		los.ListingId = li.Id 
		and los.VersionEndDate is null 
		and los.VersionValidBit = 1
	left join 
		CircleOne..LoanOffer lof 
		on 
		lof.LoanOfferId = los.LoanOfferId
	left join 
		CircleOne.dbo.tblLOanOfferScore tlos 
		on 
		tlos.ListingScoreId = lof.ListingScoreId
	left join 
		CircleOne.dbo.tblLOanOfferscoredetail tlosd 
		on 
		tlosd.ListingScoreId = tlos.ListingScoreId 
		and tlosd.variableid = 658
	left join 
		Transunion..creditreportcvattribute crca 
		on 
		crca.creditreportid = cr.creditreportid 
		and crca.cvkey = 'G980S' 
	where 
	1=1 
	and li.ID in (
	7858358
,8066365
,8066365
,5917034
,5917034
,8272831
,8272831
,8272831
,8272831
	)
	order by tu.G980S desc

select 
	* 
	from 
	Circleone..tblScoreVariables


	tblosd on tblosd 
	where value =1

	tblosd1 on tblosd1 
	where value = 2

	...

	...