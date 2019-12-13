declare @cutoffmin		datetime	= '2019-04-01'
declare @cutoffmax		datetime	= '2019-04-23'
declare @InvestorID		int			=  8273547


select

	AsOf									
	,ld.ListingID
	,OriginationDate						
	,PurchaseDate								= ld.DateAcquired
	,InvestorKey								= ld.UserAltKey
	,LoanNoteID									= ld.LoanNoteDisplayName
	,LoanNumber									= ld.LoanID
	,OriginalInvestment							= ld.OwnershipShare 
	,LoanAmount									= ld.OriginalAmountBorrowed
	,PrincipalBalance							= case when (ld.EndBalance <= 0.01 and ld.EndLoanStatusID in (3,4)) or ld.PrinSold is not null then 0.00 else ld.EndBalance end
----PENDING-------------------------------------------------------------------------------------------------------------
    ,InProcessPrincipalPayments					= -1 * (ld.PrincipalPending + ld.PrincipalRecoveryPending)
	,InProcessInterestPayments					= -1 * (ld.InterestPending + ld.InterestRecoveryPending)
	,InProcessOriginationInterestPayments		= 0.00	--NOTE: This Field is NO LONGER Relevant
	,InProcessLatfeePayments					= -1 * (ld.LateFeePending + ld.LateFeeRecoveryPending)
	,InProcessSvcFeePayments					=  1 * (ld.SvcFeePending + ld.SvcFeeRecoveryPending)
	,InProcessCollectionsPayments				=  1 * (ld.ClxFeePending + ld.ClxFeeRecoveryPending)
	,InProcessNSFFeePayments					= -1 * (ld.NSFFeePending + ld.NSFFeeRecoveryPending)
	,InProcessGLRewardPayments					= 0.00	--NOTE: This Field is NO LONGER Relevant
----ACCRUALS------------------------------------------------------------------------------------------------------------
	,AccruedInterest						=	CAST(
													ld.ProRataShare
													*
													CASE 
														WHEN ld.DateAcquired < @CutoffMax AND ld.EndLoanStatusID IN (0,1) AND (ld.DateSold IS NULL OR ld.DateSold >= @CutoffMax) AND ISNULL( ld.EndIntBal + (ld.EndIntBalDailyAccrual * ld.EndDaysforAccrual ),0.00) > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
															THEN ISNULL( ld.EndIntBal + (ld.EndIntBalDailyAccrual * ld.EndDaysforAccrual ),0.00)
														WHEN ld.DateAcquired >= @CutoffMax OR ld.DateSold < @CutoffMax /* NOTE: STOP ACCRUING ONCE SOLD */
															THEN 0.00
														ELSE ld.EndIntBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
													END 
												AS DECIMAL(20,10))
	,AccruedOriginationInterest				= 0.00 --NOTE: This Field is NO LONGER Relevant
	,AccruedLatefee							= CAST(
													ld.ProRataShare
													*
													CASE 
														WHEN ld.DateAcquired < @CutoffMax AND ld.EndLoanStatusID IN (0,1) AND (ld.DateSold IS NULL OR ld.DateSold >= @CutoffMax) AND ld.EndLateFeeBal > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
															THEN ld.EndLateFeeBal
														WHEN ld.DateAcquired >= @CutoffMax OR ld.DateSold < @CutoffMax /* NOTE: STOP ACCRUING ONCE SOLD */
															THEN 0.00
														ELSE ld.EndLateFeeBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
													END 
												AS DECIMAL(20,10))
	,AccruedNSFFee							= CAST(
													ld.ProRataShare
													*
													CASE 
														WHEN ld.DateAcquired < @CutoffMax AND ld.EndLoanStatusID IN (0,1) AND (ld.DateSold IS NULL OR ld.DateSold >= @CutoffMax) AND ld.EndNSFFeeBal > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
															THEN ld.EndNSFFeeBal
														WHEN ld.DateAcquired >= @CutoffMax OR ld.DateSold < @CutoffMax /* NOTE: STOP ACCRUING ONCE SOLD */
															THEN 0.00
														ELSE ld.EndNSFFeeBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
													END 
												AS DECIMAL(20,10))
	,AccruedSvcFee							=	CAST(
													ld.ProRataShare
													*
													CASE
														WHEN ld.DateAcquired < @CutoffMax AND ld.EndLoanStatusID IN (0,1) AND (ld.DateSold IS NULL OR ld.DateSold >= @CutoffMax) AND ISNULL( ld.EndIntBal + (ld.EndIntBalDailyAccrual * ld.EndDaysforAccrual ),0.00) > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
															THEN ISNULL( ld.EndIntBal + (ld.EndIntBalDailyAccrual * ld.EndDaysforAccrual ),0.00)
														WHEN ld.DateAcquired >= @CutoffMax OR ld.DateSold < @CutoffMax /* NOTE: STOP ACCRUING ONCE SOLD */
															THEN 0.00
														ELSE ld.EndIntBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
													END
													*
													ISNULL( CAST(ld.ServiceFeePercent AS DECIMAL(20,10)) / CAST(NULLIF(ld.EndBorrowerStatedInterestRate,0) AS DECIMAL(20,10)) , 0.00)
												AS DECIMAL(20,10))
	,AccruedGLReward						= 0.00 --NOTE: This Field is NO LONGER Relevant
----ACCRUALS------------------------------------------------------------------------------------------------------------
	,LoanStatusDescription					= CASE WHEN (ld.DateSold IS NULL OR ld.DateSold >= @CutoffMax) THEN ld.EndStatus ELSE 'SOLD' END --OLD: ld.EndStatus
	,ld.ProsperRating
	,Term									= ld.AmortizationMonths
	,MaturityDate							= FORMAT(ld.ExpectedMaturityDate,'yyyy-MM-dd HH:mm:ss') --OLD: ld.StatedMaturityDate
	,BorrowerRate							= CAST(ld.EndBorrowerStatedInterestRate AS DECIMAL(10,5))
	,NextPaymentDueDate						= ISNULL(ld.SpectrumNextPaymentDueDate,ld.NextPaymentDueDate)
	,AgeInMonths							= DATEDIFF(M,ld.OriginationDate,@CutoffMax)
	,DaysPastDue							= ld.EndDPD
	,FirstScheduledPayment					= FORMAT(DATEADD(MM,1,ld.OriginationDate),'yyyy-MM-dd HH:mm:ss') --OLD: FORMAT( DATEADD(MM,1,DATEADD(DD,-1*DAY(ld.OriginationDate),DATEADD(DD,ld.PaymentDayOfMonthDue,ld.OriginationDate))) ,'yyyy-MM-dd HH:mm:ss')
----RECEIVED------------------------------------------------------------------------------------------------------------
	,ServiceFees							= -1 * (ld.SvcFeePaid + ld.SvcFeeRecoveryPaid)
	,PrincipalRepaid						= -1 * (ld.PrincipalReceived + ld.PrincipalRecoveryReceived)
	,InterestPaid							= -1 * (ld.InterestReceived + ld.InterestRecoveryReceived)	
	,ProsperFees							= -1 * (ld.NSFFeeReceived + ld.NSFFeeRecoveryReceived)
	,LateFees								= -1 * (ld.LateFeeReceived + ld.LateFeeRecoveryReceived)
	,GroupLeaderReward						= 0.00 --NOTE: This Field is NO LONGER Relevant
----SALES---------------------------------------------------------------------------------------------------------------
	,DebtSaleProceedsReceived				= CASE WHEN ld.IsDebtSale = 1 THEN ld.SaleNetProceeds ELSE 0.00 END
	,PlatformProceedsGrossReceived			= CASE WHEN ld.DateSold IS NOT NULL THEN ld.SaleGrossProceeds ELSE 0.00 END
	,PlatformFeesPaid						= CASE WHEN ld.DateSold IS NOT NULL THEN -1 * ld.SaleTransactionFee ELSE 0.00 END
----SALES---------------------------------------------------------------------------------------------------------------
	,NoteStatus								= CASE WHEN (ld.DateSold IS NULL OR ld.DateSold >= @CutoffMax) THEN ld.EndLoanStatusID ELSE 86 END --OLD: ld.EndLoanStatusID
	,NoteDefaultReason						= ld.DefaultReasonID
	,NoteDefaultReasonDescription			= ld.DefaultReasonDesc
	,IsSold									= CAST(CASE WHEN ld.DateSold IS NOT NULL THEN 1 ELSE 0 END AS BIT)
	,MonthlyPaymentAmount					= ld.ScheduledMonthlyPaymentAmount --OLD: ld.MonthlyPaymentAmount
	,NextPaymentDueAmountNoteLevel			= CAST(ld.ProRataShare * ISNULL(ld.NextPaymentDueAmount,0.00) AS DECIMAL(20,6))
	,SchMonthlypaymentNoteLevel				= CAST(ld.ProRataShare * ISNULL(ld.ScheduledMonthlyPaymentAmount,0.00) AS DECIMAL(20,6)) --OLD: ld.MonthlyPaymentAmount
----BANKRUPTCY----------------------------------------------------------------------------------------------------------
	,BankruptcyFiledDate					= FORMAT(ld.BankruptcyFiledDate,'yyyy-MM-dd HH:mm:ss')
	,BankruptcyStatus						= ld.BankruptcyStatus
	,BankruptcyType							= ld.BankruptcyType
	,BankruptcyStatusDate					= FORMAT(ld.BankruptcyStatusDate,'yyyy-MM-dd HH:mm:ss')
----BANKRUPTCY----------------------------------------------------------------------------------------------------------
	,LoanClosedDate							= FORMAT(ld.DateClosed,'yyyy-MM-dd HH:mm:ss') --OLD: ld.ClosedDate
----CHARGE-OFFS---------------------------------------------------------------------------------------------------------
	,ChargeoffDate							= FORMAT(ld.ChargeOffDate,'yyyy-MM-dd HH:mm:ss')
	,TotalChargeoff							= -1 * (ld.ChargeOffPrincipal + ld.ChargeOffInterest + ld.ChargeOffLateFee + ld.ChargeOffNSFFee)
	,PrincipalBalanceAtChargeoff			= -1 * ld.ChargeOffPrincipal
	,InterestBalanceAtChargeoff				= -1 * ld.ChargeOffInterest
	,LateFeeBalanceAtChargeoff				= -1 * ld.ChargeOffLateFee
	,NSFFeeBalanceAtChargeoff				= -1 * ld.ChargeOffNSFFee
	,RewardsBalanceAtChargeoff				= CASE WHEN ld.ChargeOffDate IS NOT NULL THEN 0.00 END --NOTE: This Field is NO LONGER Relevant
----CHARGE-OFFS---------------------------------------------------------------------------------------------------------
	,FICOScore								= ISNULL(ld.DecisionCreditScoreRange,'N/A')
	,ld.InvestmentTypeID
	,ld.LoanProductID
	,CollectionFees							= -1 * (ld.ClxFeePaid + ld.ClxFeeRecoveryPaid)
	,ld.IsPriorBorrower
	,ld.BorrowerState
	,ld.BorrowerAPR
	,PrincipalAdjustments					= -1 * (ld.PrincipalAdjustment + ld.RecoveryPrincipalAdjustment)
--2016 BBVA ADDITIONAL FIELDS-------------------------------------------------------------------------------------------
	,PastDueAmount							= CAST(ld.ProRataShare * ISNULL(ld.AmountPastDue - ld.EndLateFeeBal - ld.EndNSFFeeBal,0.00) AS DECIMAL(20,6)) --OLD: ld.TotalPaymentsPastDueAmount --NOTE: Used to be Named AmountPastDueLessFees
	,ld.ListingCategoryID
	,DecisionCredScore						= ISNULL(ld.DecisionCreditScore,0) --NOTE: SECURE POSITIONS WITH FOOTER OldY
	,RefreshCredScore						= ref.FicoScore --NOTE: SECURE POSITIONS WITH FOOTER OldY
	,RefreshCredScoreDate					= FORMAT(ref.CreatedDate,'yyyy-MM-dd HH:mm:ss') --NOTE: SECURE POSITIONS WITH FOOTER OldY
	,ld.IsContractChargeOff
	,ld.IsNonContractChargeOff
	,DecisionCredScoreVendor				= ISNULL(ld.DecisionCreditScoreVendor,'N/A') --NOTE: SECURE POSITIONS WITH FOOTER OldY
	,DecisionCredScoreVersion				= 'FICO 08' --NOTE: SECURE POSITIONS WITH FOOTER OldY
	,RefreshCredScoreVendor					= CASE WHEN ref.FicoScore IS NOT NULL THEN 'TransUnion' END --NOTE: SECURE POSITIONS WITH FOOTER OldY
	,RefreshCredScoreVersion				= CASE WHEN ref.FicoScore IS NOT NULL THEN 'FICO 08' END --NOTE: SECURE POSITIONS WITH FOOTER OldY
----SETTLEMENTS---------------------------------------------------------------------------------------------------------
	,ld.SettlementStartDate
	,ld.SettlementEndDate
	,ld.SettlementStatus
	,SettlementBalAtEnrollment				= CASE WHEN ld.SettlementBalAtEnrollment IS NOT NULL THEN CAST(ld.ProRataShare * ISNULL(ld.SettlementBalAtEnrollment,0.00) AS DECIMAL(20,6)) END
	,SettlementAgreedPmtAmt					= CASE WHEN ld.SettlementAgreedPmtAmt IS NOT NULL THEN CAST(ld.ProRataShare * ISNULL(ld.SettlementAgreedPmtAmt,0.00) AS DECIMAL(20,6)) END
	,ld.SettlementPmtCount
	,ld.SettlementFirstPmtDueDate
----EXTENSIONS----------------------------------------------------------------------------------------------------------
	,ld.ExtensionStatus
	,ld.ExtensionTerm
	,ld.ExtensionOfferDate
	,ld.ExtensionExecutionDate
--2017 ADDITIONAL FIELDS------------------------------------------------------------------------------------------------
	,ld.ServiceFeePercent
	,ld.DateSold
	,ld.IsSCRA
	,ld.SCRABeginDate
	,ld.SCRAEndDate
	,IsMLA									= null
----RECOVERY PAYMENT FIELDS - IN PROCESS--------------------------------------------------------------------------------
    ,PrincipalRecoveriesInProcess			= -1 * (ld.PrincipalRecoveryPending)
	,InterestRecoveriesInProcess			= -1 * (ld.InterestRecoveryPending)
	,LateFeeRecoveriesInProcess				= -1 * (ld.LateFeeRecoveryPending)
	,NSFFeeRecoveriesInProcess				= -1 * (ld.NSFFeeRecoveryPending)
	,ClxFeeRecoveriesInProcess				= -1 * (ld.ClxFeeRecoveryPending)
	,SvcFeeRecoveriesInProcess				= -1 * (ld.SvcFeeRecoveryPending)
----RECOVERY PAYMENT FIELDS - RECEIVED----------------------------------------------------------------------------------
	,PrincipalRecoveriesReceived			= -1 * (ld.PrincipalRecoveryReceived)
	,InterestRecoveriesReceived				= -1 * (ld.InterestRecoveryReceived)
	,LateFeeRecoveriesReceived				= -1 * (ld.LateFeeRecoveryReceived)
	,NSFFeeRecoveriesReceived				= -1 * (ld.NSFFeeRecoveryReceived)
	,ClxFeeRecoveriesReceived				= -1 * (ld.ClxFeeRecoveryPaid)
	,SvcFeeRecoveriesReceived				= -1 * (ld.SvcFeeRecoveryPaid)
----CHECK FEE FIELDS----------------------------------------------------------------------------------------------------
	,InProcessCheckFeePayments				= -1 * (ld.CkFeePending + ld.CkFeeRecoveryPending)
	,CheckFees								= -1 * (ld.CkFeeReceived + ld.CkFeeRecoveryReceived)
	,CheckFeeRecoveriesInProcess			= -1 * (ld.CkFeeRecoveryPending)
	,CheckFeeRecoveriesReceived				= -1 * (ld.CkFeeRecoveryReceived)
----2017 ADDITIONAL FIELDS----------------------------------------------------------------------------------------------
	,RecordID								= ROW_NUMBER() OVER (ORDER BY ld.OriginationDate, ld.LoanID, ld.LoanToLenderID)
	--,ld.LoanToLenderID					--NOTE: For Testing Purposes Oldy
	,ThreeDigitZip							= null
	,IsLegalStrategy						= CAST(CASE WHEN AgencyQueueName = 'CAQ_WNR_LS' THEN 1 ELSE 0 END AS BIT)
----2018 ADDITIONAL FIELDS----------------------------------------------------------------------------------------------
	,ld.InvestmentProductID
	,PurchasePrincipal						= ld.PrinAcquired
	,SoldPrincipal							= ld.PrinSold
	,IsCeaseAndDesist
	,IsAutoAchOff
	,ld.DecisionCreditScore


	from 
		DW.dbo.tfnDailyLenderPacketBorrowerData_ByDateRangeAndLender 
			(
			 @cutoffmin
			,@cutoffmax
			,@InvestorID
			) br
	join 
		DW.dbo.tfnDailyLenderPacketData_ByDateRangeAndLender 
			(
			 @cutoffmin
			,@cutoffmax
			,@InvestorID
			) ld
		on 
		br.LoanID = ld.LoanID
	outer apply (
		select 
			top 1 
			LoanId
			,FicoScore
			,CreatedDate
			,UpdatedDate
		from PortFolioMgmt.dbo.PortfolioReport
		where LoanId = ld.LoanID
			and CreatedDate < isnull(ld.DateSold,@CutoffMax) --NOTE: This will STALE Upon Date of Sale
			and CreatedDate > ld.DecisionCreditScoreDate --NOTE: Refresh Later than Decision Date
		order by CreatedDate desc, UpdatedDate desc
		) ref
	where
		1=1
		and DateAcquired > '2019-04-20'

