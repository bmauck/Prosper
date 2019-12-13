select 
	li.ID 'ListingID' 
	,li.LoanID 
	,li.TermsApprovalDate 
	,lcrm.ExternalCreditReportID 
	,mla.modelreportmilitarylendingalertstatus 'TU_Military_Match'
	,case 
		when mil.workflowid is not null 
		then 'Yes' 
		else 'No' 
		end as 'GDS_MIL_Hold'
	from 
		circleone.dbo.listings li
	left join 
		circleone.dbo.workflow mil (nolock) 
		on 
		mil.listingid = li.id 
		and mil.workflowtypeid = 3801
	left join 
		circleone.dbo.listingcreditreportmapping lcrm (nolock)	
		on 
		lcrm.listingid = li.id 
		and lcrm.creditbureau = 2 
		and lcrm.IsDecisionBureau = 1
	left join 
		circleone.dbo.usermodelreportmapping umrm (nolock) 
		on 
		umrm.ExternalCreditReportId = lcrm.ExternalCreditReportId
	left join 
		TransUnion.dbo.ModelReport mr (nolock) 
		on 
		mr.ExternalModelReportID = umrm.ExternalModelReportId
	left join 
		TransUnion.dbo.ModelReportMilitaryLendingAlertAct mla (nolock) 
		on 
		mla.modelreportid = mr.modelreportid
	where 
		1=1
		and (modelreportmilitarylendingalertstatus = 'MATCH' or mil.WorkflowID is not null)
		and li.LoanID in (
			773456	
			,786435	
			,906324	
			,922238	
			,935812	
			,1006886	
			,1029731	
			,1046337	
			,1057586	
			)