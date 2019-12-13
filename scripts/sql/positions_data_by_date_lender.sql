select 
	a.AsOfDate
	,a.LoanID
	,a.LenderID
	,DateAcquired
	,BorrowerState
	,ProsperRating
	,AmortizationMonths
	,OriginalAmountBorrowed
	,BegBorrowerStatedInterestRate
	,BorrowerAPR
	,OriginationDate
	,DecisionCreditScore
	,EndDPD
	,ChargeOffDate
	,ChargeOffPrincipal
	,IsContractChargeOff
	,IsNonContractChargeOff
	,EndStatus
	,EndBalance
	,PrincipalPending
	,InterestReceived
	,BankruptcyStatus
	,SettlementStatus
	,ExtensionStatus

	from
		DW.dbo.tfnDailyLenderPacketData_ByDateRangeAndLender (
			'2019-07-08', '2019-07-08', 7221731
			) a
	join 
		CircleOne.dbo.LoanToLender ltl
		on 
		1=1
		and ltl.LoanID = a.LoanID
		and ltl.LenderID = a.LenderID
		and ltl.OwnershipEndDate is null
	where
		1=1
		
		
