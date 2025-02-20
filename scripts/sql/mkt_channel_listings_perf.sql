drop table #Listings
drop table #loanperf
CREATE TABLE #Listings (
	 LenderID					int
	,LoanNumber					int
	,ListingNumber				int
	,ListingCreationDate		datetime
	,OriginationDate			datetime
	,FICOScore					int
	,DefaultAmount				int
	,ChargeoffAmount			int
	,NetRecovery				int
	,PrinBal					int
	,MarketingChannel			varchar(50)
	)
create table #loanperf (
	 LoanID						int
	,ObservationMonth			int
	,DefaultAmount				int
	,ChargeoffAmount			int
	,NetRecovery				int
	,PrinBal					int
	)
insert into #loanperf
	select 
	llm.LoanID
	,llm.ObservationMonth
	,llm.DefaultAmount
	,llm.ChargeoffAmount
	,llm.RecoveryPayments as NetRecovery
	,llm.EOMPrinAdjusted as PrinBal
	from 
		DW..dw_LoanLevelMonthly llm
		inner join 
			(
				select 
				max(llm.ObservationMonth) as LatestMonth
				,llm.LoanID
				from 
					DW..dw_LoanLevelMonthly llm
				where 
					1=1
					and llm.OriginationDate > '2015-01-01' 
					and llm.EOMPrinAdjusted > 0
				group by llm.LoanID
			) DateDT
			on 
			llm.ObservationMonth = DateDT.LatestMonth
			and llm.LoanID = DateDT.LoanID
	where	
		1=1
		and llm.OriginationDate > '2015-01-01'
		and llm.EOMPrinAdjusted > 0

--select top 10 * from #loanperf

insert into #Listings
	select
		 LenderID					= null
		,LoanNumber					= lo.LoanID
		,ListingNumber				= li.ID
		,ListingCreationDate		= li.CreationDate
		,lo.OriginationDate
		,FICOScore					= isnull(tucrs.ScoreResults,ucp.Score)
		,lp.ChargeoffAmount
		,lp.DefaultAmount
		,lp.NetRecovery
		,lp.PrinBal
		,MarketingChannel			= fbe.MarketingLastTouchChannelName		
	from 
		C1.dbo.Loans (nolock) lo
	join 
		C1.dbo.Listings (nolock) li
			on 
			li.LoanID = lo.LoanID
	join	
		DW..dim_listing dimli
			on 
			dimli.ListingID = li.ID
	join 
		#loanperf lp
			on 
			lp.LoanID = lo.LoanID
	join 
		DW..fact_borrower_event_application fbe
			on 
			fbe.ApplicationBorrowerEventSK = dimli.TILAApplicationBorrowerEventSK
	left join 
		CircleOne.dbo.ListingCreditReportMapping (nolock) lcrm
			on 
			lcrm.ListingId = li.ID
			and lcrm.IsDecisionBureau = 1
	left join 
		TransUnion.dbo.CreditReport (nolock) tucr
			on 
			tucr.ExternalCreditReportId = lcrm.ExternalCreditReportId
			and lcrm.CreditBureau = 2
	left join 
		TransUnion.dbo.CreditReportScore (nolock) tucrs
			on 
			tucrs.CreditReportId = tucr.CreditReportId
			and tucrs.ScoreType = 'FICO_SCORE'
			and lcrm.CreditBureau = 2
	outer apply (
			select top 1
				 ucp.Score
				,ucp.CreditPullDate
				,ecpr.ExperianCreditProfileResponseID
				,ecpr.RealEstatePayment
			from 
				C1.dbo.ExperianDocuments (nolock) ed
			join 
				C1.dbo.UserCreditProfiles (nolock) ucp
					on 
					ucp.ExperianDocumentID = ed.id
			join 
				C1.dbo.ExperianCreditProfileResponse (nolock) ecpr
					on 
					ecpr.ExperianDocumentID = ucp.ExperianDocumentID
			where 
				1=1 
				and ed.ExternalCreditReportId = lcrm.ExternalCreditReportId
				and lcrm.CreditBureau = 1	
			order by 
				ucp.CreditPullDate desc
				,ucp.CreationDate desc
				,ecpr.CreatedDate desc
			) ucp
		where 
			1=1 
			and OriginationDate >= '2015-01-01'

select 
	* 
	from 
	#Listings
	where 
		1=1 
		and MarketingChannel = 'Direct Mail'
		and FICOScore > 680

