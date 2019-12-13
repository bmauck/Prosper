select 
	l.LoanID as 'LoanID'
	,Amount
	,CurrentRate
	,MonthlyIncome
	,MonthlyDebt
	,MonthlyPayment
	,CurrentDTI
	,li.ListingCategoryID 
	,OccupationID
	,EmploymentStatusID --must be 7 or 6
	,cv.at20s as 'MonthsSinceFirstTrade'
	,cv.re02s as 'RevolvingBalance'
	,cv.g057s as 'Delinquencies'
	into #ft_filters
	from
	C1..loans l 
		join 
		C1..Listings li 
		on li.ID = l.listingID
		join 
		C1..ListingStatus lst 
		on lst.listingID = li.ID
			and lst.VersionEndDate is null 
			and lst.VersionValidBit = 1 
			and lst.ListingStatusTypeID = 6 --Need? 
		left join 
		CircleOne..ListingCreditReportMapping lcrm 
		on lcrm.listingID = li.ID
			and lcrm.CreditBureau = 2
			and lcrm.IsDecisionBureau = 1
		left join 
		CircleOne..UserModelReportMapping umrm 
		on umrm.ExternalCreditReportID = lcrm.ExternalCreditReportID
		left join 
		DW..fact_transunion_cv_attribute_eads14 cv
		on cv.ExternalCreditReportID = lcrm.ExternalCreditReportId
		--left join 
		--TransUnion..ModelReport mr 
		--on mr.ExternalModelReportID = umrm.ExternalModelReportID
		left join 
		CircleOne..UserEmploymentDetail emp
		on emp.UserID = li.UserID
			and emp.VersionEndDate is null 
			and emp.VersionValidBit = 1
	where 
	1=1
		and OriginationDate between '2018-06-01' and '2018-10-01'
		and CurrentRate between '19' and '32'

--select
	--top 10 * 
--	sum(Amount) as Volume
--	,count(LoanID) as Loans
--	into #model_3
--	from #ft_filters

--	where 
--		1=1
--		and MonthsSinceFirstTrade <> 0
--		and RevolvingBalance > 0
--		and CurrentDTI < 0.20
--		and Delinquencies < 2
--		--and ListingCategoryID in ('11', '15', '14', '16', '19', '18', '1', '2', '7', '6', '9', '20', '8')
--		--and OccupationID in ('1','2','3','4','5','8','9','10','12','14','16','17','18','19','20','21','30','31','33','35','36','37','39','40','41','42','49','57','58','61','62','64','65')
--		and (MonthlyIncome - MonthlyPayment) > 4000
--		and EmploymentStatusID in ('6', '7')


--select 
--	sum(Amount) as Volume
--	,count(LoanID) as Loans
--	from 
--	#ft_filters
--	where 
--		1=1
--		and MonthsSinceFirstTrade <> 0
--		and RevolvingBalance > 0
--		and CurrentDTI < .65
--		and Delinquencies < 2
--		and ListingCategoryID in ('11', '15', '14', '16', '19', '18', '1', '2', '7', '6', '9', '20', '8')
--		--and OccupationID in ('1','2','3','4','5','8','9','10','12','14','16','17','18','19','20','21','30','31','33','35','36','37','39','40','41','42','49','57','58','61','62','64','65')
--		--and (MonthlyIncome - MonthlyPayment) > 4000
--		and EmploymentStatusID in ('6', '7')

--select 
--	OccupationID
--	,sum(Amount)
--	from 
--	#ft_filters
--	group by OccupationID
--	order by OccupationID
	