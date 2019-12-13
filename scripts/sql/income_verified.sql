-- drop table #tmp
select 
	pmit.loanid
	,lo.originationdate
	,coalesce(c.incomeverifyflag, b.IncomeVerifyFlag) IncomeVerifyFlag
	,coalesce(c.IncomeV_value,  b.Incomevertreatmentcode) IncomeVerTreatmentCode
	into 
		#tmp
	from 
		Sandbox.dbo.pmit_2019_3 pmit
	left join 
		CircleOne..loans lo 
		on 
		lo.LoanID = pmit.LoanID 
	left join 
		RiskAnalytics..listings_ad_Listsverf_TU_Append b 
		on 
		b.LoanID = pmit.LoanID
	left join 
		TabReporting..kpiincome c 
		on 
		c.LoanID = pmit.LoanID

/*
select 
	eomonth(originationdate)
	,count(*) loans
	,avg(case when IncomeVerifyFlag is null or Incomevertreatmentcode is null then 1.0 else 0 end) missings
	from #tmp
	group by 
		eomonth(originationdate)
	order by 1

select 
	* 
	from 
	#tmp 
	where 
		IncomeVerifyFlag is null or Incomevertreatmentcode is null
*/

-- drop table sandbox.dbo.as_income_verification_pmit_2019_02
select 
	loanid
	,case
		when IncomeVerifyFlag is null 
			or Incomevertreatmentcode is null 
		then null
		when IncomeVerifyFlag = 'Y' 
			or IncomeVerTreatmentCode = 'Binary Do Not Verify Prior POI Mod and No Income Change' 
		then 1
		else 0 
		end income_verified
	
	from #tmp