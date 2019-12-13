begin tran 
--rollback / commit

select 
	li.id
	,li.Amount 'listing_amount'
	,li2.Term 'listing_term'
	,li.CurrentRate 'borrower_rate'
	,OccupationID 'occupation_id'
	,uemp.EmploymentStatusID 'employment_status'
	,uemp.EmploymentStatusMonths 'employment_length'
	,li.ProsperRatingTypeID 'prosper_rating_type'
	,li.MonthlyIncome 'monthly_income'
	,li.MonthlyDebt 'monthly_debt'
	,li2.DTIwoProsperLoan 'dti_without_loan'
	,li.ListingCategoryID 'listing_category_id'
	,li.MonthlyPayment 'monthly_payment_amt'
	,li2.FICOScore 'fico_score'
	,li2.RatingCode 'prosper_rating'
	,tu.AT01S 'total_trade_items'
	,tu.AT02S 'open_credit_lines'
	,tu.RE33S 'revolving_balance'
	,tu.AT20S 'time_passed_first_credit_line'
	,tu.G980S 'inquiries_last_six_months'
	,tu.G093S 'public_records_last_ten_years'
	,tu.RE02S 'total_open_revolving_trades'
	,tu.G218B 'currently_dq'
	,tu.RE34S 'for_revolving_avail'
	,tu.MTAP01 'mortgage_trades'
	


	--,tu.G099S as 'Bankruptcies in the past 24 months'
	--,tu.AT28B as 'Total Non-Mortgage Credit'
	--,tu.G238S as  'Inquiries in the past 12 months'
	--,(case when uemp.EmploymentStatusMonths is null then 108.29
	--		else uemp.EmploymentStatusMonths end)
	into
		--begin tran
		
		Sandbox..bm_franklin_modeling
	from 
		CircleOne.dbo.listings li
	left join  
		(select *
			, (row_number()
			over(
				partition by UserID 
				order by CreditPullDate desc,
			CreatedDate desc)) as id1 
		from 
			CircleOne.dbo.UserCreditReportMapping) ucp 
		on 
		li.userid=ucp.UserID  
		and id1=1
	left join  
		(select *
			, (row_number()	
			over(
				partition by UserID 
				order by CreationDate desc
			,CreationDate desc)) as uempid1 
		from 
		CircleOne.dbo.UserEmploymentDetail) uemp 
		on 
		li.userid = uemp.UserID  
		and uempid1 = 1
	left join 
		c1..loans l 
		on 
		li.loanid = l.loanid
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
	where 
		1=1
		and li.TermsApprovalDate is not null
		and li.CreationDate between '2019-01-01' and '2019-06-30'
		and li.ProsperRatingTypeID <> 1
		and li.Status <> 0