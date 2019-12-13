DECLARE @CutoffMin	DATETIME	= dateadd(month, -1, dateadd(day,1,eomonth(getdate(),-1)))
DECLARE @CutoffMax	DATETIME	= dateadd(day,1,eomonth(getdate(),-1))
DECLARE @EndPeriod  DATETIME	= dateadd(day,1,eomonth(getdate(),-1))
DECLARE @ScrubPII   INT			= 0

DECLARE @InvestorID	INT			=  8441820
DECLARE @LenderID   INT			=  8441820

IF OBJECT_ID('tempdb..#Positions') IS NOT NULL DROP TABLE #Positions

DECLARE @Query1 NVARCHAR(MAX) =		
'SELECT
	AsOfDate
	,LoanToLenderID
	,LenderID
	,UserAltKey
	,LoanNoteID
	,LoanNoteDisplayName
	,ProRataShare
	,OwnershipShare
	,LoanID
	,ListingID
	,ListingCategoryID
	,ListingCategoryDesc
	,OriginationDate
	,AmortizationMonths
	,OriginalAmountBorrowed
	,ProsperRating
	,LoanProductID
	,LoanProduct
	,InvestmentTypeID
	,InvestmentTypeName
	,InvestmentProductID
	,ServiceFeePercent
	,PaymentDayOfMonthDue
	,DefaultReasonID
	,DefaultReasonDesc
	,NextPaymentDueAmount
	,AgencyQueueName
	,IsCeaseAndDesist
	,IsAutoAchOff
	,ExpectedMaturityDate
	,StatedMaturityDate
	,ClosedDate
	,DateClosed
	,MonthlyPaymentAmount
	,ScheduledMonthlyPaymentAmount
	,NextPaymentDueDate
	,SpectrumNextPaymentDueDate
	,AmountPastDue
	,TotalPaymentsPastDueAmount
	,BorrowerID
	,BorrowerAPR
	,BorrowerState
	,IsPriorBorrower
	,IsSCRA
	,SCRABeginDate
	,SCRAEndDate
	,DecisionCreditScore
	,DecisionCreditScoreRange
	,DecisionCreditScoreDate
	,DecisionCreditScoreVendor
	,DecisionCreditScoreVendorID
	,DecisionExternalReportID
	,RefreshCreditScore
	,RefreshCreditScoreRange
	,RefreshCreditScoreDate
	,RefreshCreditScoreVendor
	,MonthlyDebt
	,RealEstatePayment
	,BegLoanStatusID
	,BegStatus
	,BegDPD
	,BegIntBal
	,BegBalDate
	,BegDaysforAccrual
	,BegIntBalDailyAccrual
	,BegLateFeeBal
	,BegNSFFeeBal
	,BegBorrowerStatedInterestRate
	,EndLoanStatusID
	,EndStatus
	,EndDPD
	,EndBalDate
	,EndIntBal
	,EndDaysforAccrual
	,EndIntBalDailyAccrual
	,EndLateFeeBal
	,EndNSFFeeBal
	,EndBorrowerStatedInterestRate
	,SettlementStartDate
	,SettlementEndDate
	,SettlementStatus
	,SettlementBalAtEnrollment
	,SettlementAgreedPmtAmt
	,SettlementPmtCount
	,SettlementFirstPmtDueDate
	,ExtensionStatus
	,ExtensionTerm
	,ExtensionOfferDate
	,ExtensionExecutionDate
	,PrinAcquired
	,DateAcquired
	,StatusAcquired
	,PrinSold
	,DateSold
	,StatusSold
	,IsDebtSale
	,SaleGrossProceeds
	,SaleTransactionFee
	,SaleNetProceeds
	,IsContractChargeOff
	,IsNonContractChargeOff
	,ChargeOffDate
	,ChargeOffPrincipal
	,ChargeOffInterest
	,ChargeOffLateFee
	,ChargeOffNSFFee
	,BankruptcyFiledDate
	,BankruptcyStatus
	,BankruptcyType
	,BankruptcyStatusDate
	,BegBalance
	,EndBalance
	,PrincipalReceived
	,InterestReceived
	,SvcFeePaid
	,ClxFeePaid
	,LateFeeReceived
	,NSFFeeReceived
	,CkFeeReceived
	,PrincipalRecoveryReceived
	,InterestRecoveryReceived
	,SvcFeeRecoveryPaid
	,ClxFeeRecoveryPaid
	,LateFeeRecoveryReceived
	,NSFFeeRecoveryReceived
	,CkFeeRecoveryReceived
	,PrincipalPending
	,InterestPending
	,SvcFeePending
	,ClxFeePending
	,LateFeePending
	,NSFFeePending
	,CkFeePending
	,PrincipalRecoveryPending
	,InterestRecoveryPending
	,SvcFeeRecoveryPending
	,ClxFeeRecoveryPending
	,LateFeeRecoveryPending
	,NSFFeeRecoveryPending
	,CkFeeRecoveryPending
	,PrincipalAdjustment
	,InterestAdjustment
	,OtherAdjustment
	,RecoveryPrincipalAdjustment
	,RecoveryInterestAdjustment
	,RecoveryOtherAdjustment
FROM dbo.tfnDailyLenderPacketData_ByDateRangeAndLender('''''+CONVERT(VARCHAR(10),@CutoffMin,121)+''''','''''+CONVERT(VARCHAR(10),@CutoffMax,121)+''''','+CAST(@InvestorID AS VARCHAR(10)) +')'
DECLARE @Query2 NVARCHAR(MAX) = 'SELECT * FROM OPENQUERY(DW,'''+@Query1+''')'

PRINT '#NoteLevel'
/* ALL NOTE-LEVEL DATA FROM OPEN QUERY */
IF OBJECT_ID('tempdb..#NoteLevel') IS NOT NULL DROP TABLE #NoteLevel
CREATE TABLE #NoteLevel (
	[AsOfDate]							DATETIME			NULL
	,[LoanToLenderID]					INT					NOT NULL
	,[LenderID]							INT					NOT NULL
	,[UserAltKey]						VARCHAR(30)			NOT NULL
	,[LoanNoteID]						INT					NOT NULL
	,[LoanNoteDisplayName]				VARCHAR(21)			NULL
	,[ProRataShare]						DECIMAL(20,19)		NULL
	,[OwnershipShare]					MONEY				NOT NULL
	,[LoanID]							INT					NOT NULL
	,[ListingID]						INT					NOT NULL
	,[ListingCategoryID]				INT					NOT NULL
	,[ListingCategoryDesc]				VARCHAR(60)			NOT NULL
	,[OriginationDate]					DATE				NOT NULL
	,[AmortizationMonths]				SMALLINT			NOT NULL
	,[OriginalAmountBorrowed]			MONEY				NOT NULL
	,[ProsperRating]					VARCHAR(10)			NOT NULL
	,[LoanProductID]					SMALLINT			NOT NULL
	,[LoanProduct]						VARCHAR(30)			NOT NULL
	,[InvestmentTypeID]					INT					NULL
	,[InvestmentTypeName]				VARCHAR(30)			NOT NULL
	,[InvestmentProductID]				INT					NULL
	,[ServiceFeePercent]				DECIMAL(8,7)		NULL
	,[PaymentDayOfMonthDue]				TINYINT				NULL
	,[DefaultReasonID]					INT					NULL
	,[DefaultReasonDesc]				VARCHAR(30)			NULL
	,[NextPaymentDueAmount]				SMALLMONEY			NULL
	,[AgencyQueueName]					VARCHAR(100)		NULL
	,[IsCeaseAndDesist]					BIT					NULL
	,[IsAutoAchOff]						BIT					NULL
	,[ExpectedMaturityDate]				DATETIME			NULL
	,[StatedMaturityDate]				DATE				NOT NULL
	,[ClosedDate]						DATE				NULL
	,[DateClosed]						DATETIME			NULL
	,[MonthlyPaymentAmount]				MONEY				NOT NULL
	,[ScheduledMonthlyPaymentAmount]	SMALLMONEY			NULL
	,[NextPaymentDueDate]				DATETIME			NULL
	,[SpectrumNextPaymentDueDate]		DATE				NULL
	,[AmountPastDue]					SMALLMONEY			NULL
	,[TotalPaymentsPastDueAmount]		NUMERIC(15,2)		NULL
	,[BorrowerID]						INT					NOT NULL
	,[BorrowerAPR]						DECIMAL(6,5)		NULL
	,[BorrowerState]					VARCHAR(2)			NOT NULL
	,[IsPriorBorrower]					INT					NOT NULL
	,[IsSCRA]							BIT					NULL
	,[SCRABeginDate]					DATE				NULL
	,[SCRAEndDate]						DATE				NULL
	,[DecisionCreditScore]				SMALLINT			NULL
	,[DecisionCreditScoreRange]			VARCHAR(7)			NOT NULL
	,[DecisionCreditScoreDate]			DATETIME			NULL
	,[DecisionCreditScoreVendor]		VARCHAR(100)		NULL
	,[DecisionCreditScoreVendorID]		INT					NULL
	,[DecisionExternalReportID]			UNIQUEIDENTIFIER	NULL
	,[RefreshCreditScore]				SMALLINT			NULL
	,[RefreshCreditScoreRange]			VARCHAR(7)			NULL
	,[RefreshCreditScoreDate]			DATETIME			NULL
	,[RefreshCreditScoreVendor]			VARCHAR(100)		NULL
	,[MonthlyDebt]						MONEY				NULL
	,[RealEstatePayment]				MONEY				NULL
	,[BegLoanStatusID]					TINYINT				NULL
	,[BegStatus]						VARCHAR(32)			NULL
	,[BegDPD]							SMALLINT			NULL
	,[BegIntBal]						MONEY				NULL
	,[BegBalDate]						DATETIME			NULL
	,[BegDaysforAccrual]				INT					NULL
	,[BegIntBalDailyAccrual]			DECIMAL(20,10)		NULL
	,[BegLateFeeBal]					MONEY				NULL
	,[BegNSFFeeBal]						MONEY				NULL
	,[BegBorrowerStatedInterestRate]	DECIMAL(6,5)		NULL
	,[EndLoanStatusID]					TINYINT				NULL
	,[EndStatus]						VARCHAR(32)			NULL
	,[EndDPD]							SMALLINT			NULL
	,[EndBalDate]						DATETIME			NULL
	,[EndIntBal]						MONEY				NULL
	,[EndDaysforAccrual]				INT					NULL
	,[EndIntBalDailyAccrual]			DECIMAL(20,10)		NULL
	,[EndLateFeeBal]					MONEY				NULL
	,[EndNSFFeeBal]						MONEY				NULL
	,[EndBorrowerStatedInterestRate]	DECIMAL(6,5)		NULL
	,[SettlementStartDate]				DATE				NULL
	,[SettlementEndDate]				DATE				NULL
	,[SettlementStatus]					VARCHAR(25)			NULL
	,[SettlementBalAtEnrollment]		DECIMAL(15,2)		NULL
	,[SettlementAgreedPmtAmt]			DECIMAL(15,2)		NULL
	,[SettlementPmtCount]				INT					NULL
	,[SettlementFirstPmtDueDate]		DATE				NULL
	,[ExtensionStatus]					VARCHAR(25)			NULL
	,[ExtensionTerm]					INT					NULL
	,[ExtensionOfferDate]				DATE				NULL
	,[ExtensionExecutionDate]			DATE				NULL
	,[PrinAcquired]						DECIMAL(38,10)		NULL
	,[DateAcquired]						DATETIME			NULL
	,[StatusAcquired]					TINYINT				NULL
	,[PrinSold]							DECIMAL(38,10)		NULL
	,[DateSold]							DATETIME			NULL
	,[StatusSold]						TINYINT				NULL
	,[IsDebtSale]						INT					NULL
	,[SaleGrossProceeds]				DECIMAL(19,4)		NULL
	,[SaleTransactionFee]				DECIMAL(9,2)		NULL
	,[SaleNetProceeds]					DECIMAL(20,4)		NULL
	,[IsContractChargeOff]				INT					NULL
	,[IsNonContractChargeOff]			INT					NULL
	,[ChargeOffDate]					DATETIME			NULL
	,[ChargeOffPrincipal]				DECIMAL(38,10)		NULL
	,[ChargeOffInterest]				DECIMAL(38,10)		NULL
	,[ChargeOffLateFee]					DECIMAL(38,10)		NULL
	,[ChargeOffNSFFee]					DECIMAL(38,10)		NULL
	,[BankruptcyFiledDate]				DATE				NULL
	,[BankruptcyStatus]					VARCHAR(50)			NULL
	,[BankruptcyType]					VARCHAR(50)			NULL
	,[BankruptcyStatusDate]				DATE				NULL
	,[BegBalance]						DECIMAL(38,10)		NULL
	,[EndBalance]						DECIMAL(38,10)		NULL
	,[PrincipalReceived]				DECIMAL(38,10)		NULL
	,[InterestReceived]					DECIMAL(38,10)		NULL
	,[SvcFeePaid]						DECIMAL(38,10)		NULL
	,[ClxFeePaid]						DECIMAL(38,10)		NULL
	,[LateFeeReceived]					DECIMAL(38,10)		NULL
	,[NSFFeeReceived]					DECIMAL(38,10)		NULL
	,[CkFeeReceived]					DECIMAL(38,10)		NULL
	,[PrincipalRecoveryReceived]		DECIMAL(38,10)		NULL
	,[InterestRecoveryReceived]			DECIMAL(38,10)		NULL
	,[SvcFeeRecoveryPaid]				DECIMAL(38,10)		NULL
	,[ClxFeeRecoveryPaid]				DECIMAL(38,10)		NULL
	,[LateFeeRecoveryReceived]			DECIMAL(38,10)		NULL
	,[NSFFeeRecoveryReceived]			DECIMAL(38,10)		NULL
	,[CkFeeRecoveryReceived]			DECIMAL(38,10)		NULL
	,[PrincipalPending]					DECIMAL(38,10)		NULL
	,[InterestPending]					DECIMAL(38,10)		NULL
	,[SvcFeePending]					DECIMAL(38,10)		NULL
	,[ClxFeePending]					DECIMAL(38,10)		NULL
	,[LateFeePending]					DECIMAL(38,10)		NULL
	,[NSFFeePending]					DECIMAL(38,10)		NULL
	,[CkFeePending]						DECIMAL(38,10)		NULL
	,[PrincipalRecoveryPending]			DECIMAL(38,10)		NULL
	,[InterestRecoveryPending]			DECIMAL(38,10)		NULL
	,[SvcFeeRecoveryPending]			DECIMAL(38,10)		NULL
	,[ClxFeeRecoveryPending]			DECIMAL(38,10)		NULL
	,[LateFeeRecoveryPending]			DECIMAL(38,10)		NULL
	,[NSFFeeRecoveryPending]			DECIMAL(38,10)		NULL
	,[CkFeeRecoveryPending]				DECIMAL(38,10)		NULL
	,[PrincipalAdjustment]				DECIMAL(38,10)		NULL
	,[InterestAdjustment]				DECIMAL(38,10)		NULL
	,[OtherAdjustment]					DECIMAL(38,10)		NULL
	,[RecoveryPrincipalAdjustment]		DECIMAL(38,10)		NULL
	,[RecoveryInterestAdjustment]		DECIMAL(38,10)		NULL
	,[RecoveryOtherAdjustment]			DECIMAL(38,10)		NULL
)

INSERT INTO #NoteLevel
EXEC (@Query2)

CREATE INDEX NC_LoanToLenderID ON #NoteLevel (LoanToLenderID)
CREATE INDEX NC_LenderID_LoanID ON #NoteLevel (LenderID,LoanID)
/************************************************************ NOTE LEVEL DETAILS ************************************************************/

/************************************************************ BORROWER STATE AND ZIP ************************************************************/
IF OBJECT_ID('tempdb..#BorrowerStateAndZip') IS NOT NULL DROP TABLE #BorrowerStateAndZip
SELECT DISTINCT
	l.LoanID
	,BorrowerState = ISNULL(uta.StateOfResidence, CASE WHEN li.CreationDate < '1/1/2009' THEN li.BorrowerState END)
	,ZipCode = uta.OriginalZip
	,TuMilitaryMatch = mla.ModelReportMilitaryLendingAlertStatus
INTO #BorrowerStateAndZip
FROM CircleOne.dbo.Loans l
JOIN CircleOne.dbo.Listings li ON li.ID = l.ListingID
JOIN CircleOne.dbo.ListingStatus lst ON lst.ListingID = li.ID
	AND lst.VersionEndDate IS NULL
	AND lst.VersionValidBit = 1
	AND lst.ListingStatusTypeID = 6 --NOTE: Consider Changing Status Type to 1
LEFT JOIN CircleOne.dbo.ListingCreditReportMapping lcrm (NOLOCK) ON lcrm.ListingID = li.ID
	AND lcrm.CreditBureau = 2
	AND lcrm.IsDecisionBureau = 1
LEFT JOIN CircleOne.dbo.UserModelReportMapping umrm (NOLOCK) ON umrm.ExternalCreditReportId = lcrm.ExternalCreditReportId
LEFT JOIN TransUnion.dbo.ModelReport mr (NOLOCK) ON mr.ExternalModelReportId = umrm.ExternalModelReportId
LEFT JOIN TransUnion.dbo.ModelReportMilitaryLendingAlertAct mla (NOLOCK) ON mla.modelreportid = mr.modelreportid
	AND mla.ModelReportMilitaryLendingAlertStatus = 'MATCH'
OUTER APPLY (
	SELECT TOP 1 StateOfResidence, OriginalZip
	FROM CircleOne.dbo.UserToAddress
	WHERE UserID = li.UserID
		AND VersionValidBit = 1
		--AND IsLegalAddress = 1
		--AND IsVisible = 1 --NOTE: Unsure if Necessary
		AND VersionStartDate <= lst.ModifiedDate --li.TermsApprovalDate
		AND (VersionEndDate IS NULL OR VersionEndDate > lst.ModifiedDate /*li.TermsApprovalDate*/)
	ORDER BY IsLegalAddress DESC, IsVisible DESC, VersionStartDate DESC
) uta
WHERE l.LoanID IN (SELECT LoanID FROM CircleOne.dbo.LoanToLender WHERE LenderID = @InvestorID)
/************************************************************ BORROWER STATE AND ZIP ************************************************************/

SELECT
	AsOf									= FORMAT(NL.AsOfDate,'yyyy-MM-dd HH:mm:ss')
	,ListingNumber							= NL.ListingID
	,OriginationDate						= FORMAT(NL.OriginationDate,'yyyy-MM-dd HH:mm:ss')
	,PurchaseDate							= FORMAT(NL.DateAcquired,'yyyy-MM-dd HH:mm:ss') --TODO: Purchase Date is now wrong for all Loans prior to Java code change (hard-coded origination + 1)
	,InvestorKey							= NL.UserAltKey
	,LoanNoteID								= NL.LoanNoteDisplayName
	,LoanNumber								= NL.LoanID
	,OriginalInvestment						= NL.OwnershipShare --OLD: NL.PrinAcquired
	,LoanAmount								= NL.OriginalAmountBorrowed
	,PrincipalBalance						= CASE WHEN (NL.EndBalance <= 0.01 AND NL.EndLoanStatusID IN (3,4)) OR NL.PrinSold IS NOT NULL THEN 0.00 ELSE NL.EndBalance END
----PENDING-------------------------------------------------------------------------------------------------------------
    ,InProcessPrincipalPayments				= -1 * (NL.PrincipalPending + NL.PrincipalRecoveryPending)
	,InProcessInterestPayments				= -1 * (NL.InterestPending + NL.InterestRecoveryPending)
	,InProcessOriginationInterestPayments	= 0.00	--NOTE: This Field is NO LONGER Relevant
	,InProcessLatfeePayments				= -1 * (NL.LateFeePending + NL.LateFeeRecoveryPending)
	,InProcessSvcFeePayments				=  1 * (NL.SvcFeePending + NL.SvcFeeRecoveryPending)
	,InProcessCollectionsPayments			=  1 * (NL.ClxFeePending + NL.ClxFeeRecoveryPending)
	,InProcessNSFFeePayments				= -1 * (NL.NSFFeePending + NL.NSFFeeRecoveryPending)
	,InProcessGLRewardPayments				= 0.00	--NOTE: This Field is NO LONGER Relevant
----PENDING-------------------------------------------------------------------------------------------------------------
----ACCRUALS------------------------------------------------------------------------------------------------------------
	,AccruedInterest						=	CAST(
													NL.ProRataShare
													*
													CASE 
														WHEN NL.DateAcquired < @CutoffMax AND NL.EndLoanStatusID IN (0,1) AND (NL.DateSold IS NULL OR NL.DateSold >= @CutoffMax) AND ISNULL( NL.EndIntBal + (NL.EndIntBalDailyAccrual * NL.EndDaysforAccrual ),0.00) > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
															THEN ISNULL( NL.EndIntBal + (NL.EndIntBalDailyAccrual * NL.EndDaysforAccrual ),0.00)
														WHEN NL.DateAcquired >= @CutoffMax OR NL.DateSold < @CutoffMax /* NOTE: STOP ACCRUING ONCE SOLD */
															THEN 0.00
														ELSE NL.EndIntBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
													END 
												AS DECIMAL(20,10))
	,AccruedOriginationInterest				= 0.00 --NOTE: This Field is NO LONGER Relevant
	,AccruedLatefee							= CAST(
													NL.ProRataShare
													*
													CASE 
														WHEN NL.DateAcquired < @CutoffMax AND NL.EndLoanStatusID IN (0,1) AND (NL.DateSold IS NULL OR NL.DateSold >= @CutoffMax) AND NL.EndLateFeeBal > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
															THEN NL.EndLateFeeBal
														WHEN NL.DateAcquired >= @CutoffMax OR NL.DateSold < @CutoffMax /* NOTE: STOP ACCRUING ONCE SOLD */
															THEN 0.00
														ELSE NL.EndLateFeeBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
													END 
												AS DECIMAL(20,10))
	,AccruedNSFFee							= CAST(
													NL.ProRataShare
													*
													CASE 
														WHEN NL.DateAcquired < @CutoffMax AND NL.EndLoanStatusID IN (0,1) AND (NL.DateSold IS NULL OR NL.DateSold >= @CutoffMax) AND NL.EndNSFFeeBal > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
															THEN NL.EndNSFFeeBal
														WHEN NL.DateAcquired >= @CutoffMax OR NL.DateSold < @CutoffMax /* NOTE: STOP ACCRUING ONCE SOLD */
															THEN 0.00
														ELSE NL.EndNSFFeeBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
													END 
												AS DECIMAL(20,10))
	,AccruedSvcFee							=	CAST(
													NL.ProRataShare
													*
													CASE
														WHEN NL.DateAcquired < @CutoffMax AND NL.EndLoanStatusID IN (0,1) AND (NL.DateSold IS NULL OR NL.DateSold >= @CutoffMax) AND ISNULL( NL.EndIntBal + (NL.EndIntBalDailyAccrual * NL.EndDaysforAccrual ),0.00) > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
															THEN ISNULL( NL.EndIntBal + (NL.EndIntBalDailyAccrual * NL.EndDaysforAccrual ),0.00)
														WHEN NL.DateAcquired >= @CutoffMax OR NL.DateSold < @CutoffMax /* NOTE: STOP ACCRUING ONCE SOLD */
															THEN 0.00
														ELSE NL.EndIntBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
													END
													*
													ISNULL( CAST(NL.ServiceFeePercent AS DECIMAL(20,10)) / CAST(NULLIF(NL.EndBorrowerStatedInterestRate,0) AS DECIMAL(20,10)) , 0.00)
												AS DECIMAL(20,10))
	,AccruedGLReward						= 0.00 --NOTE: This Field is NO LONGER Relevant
----ACCRUALS------------------------------------------------------------------------------------------------------------
	,LoanStatusDescription					= CASE WHEN (NL.DateSold IS NULL OR NL.DateSold >= @CutoffMax) THEN NL.EndStatus ELSE 'SOLD' END --OLD: NL.EndStatus
	,NL.ProsperRating
	,Term									= NL.AmortizationMonths
	,MaturityDate							= FORMAT(NL.ExpectedMaturityDate,'yyyy-MM-dd HH:mm:ss') --OLD: NL.StatedMaturityDate
	,BorrowerRate							= CAST(NL.EndBorrowerStatedInterestRate AS DECIMAL(10,5))
	,NextPaymentDueDate						= ISNULL(NL.SpectrumNextPaymentDueDate,NL.NextPaymentDueDate)
	,AgeInMonths							= DATEDIFF(M,NL.OriginationDate,@CutoffMax)
	,DaysPastDue							= NL.EndDPD
	,FirstScheduledPayment					= FORMAT(DATEADD(MM,1,NL.OriginationDate),'yyyy-MM-dd HH:mm:ss') --OLD: FORMAT( DATEADD(MM,1,DATEADD(DD,-1*DAY(NL.OriginationDate),DATEADD(DD,NL.PaymentDayOfMonthDue,NL.OriginationDate))) ,'yyyy-MM-dd HH:mm:ss')
----RECEIVED------------------------------------------------------------------------------------------------------------
	,ServiceFees							= -1 * (NL.SvcFeePaid + NL.SvcFeeRecoveryPaid)
	,PrincipalRepaid						= -1 * (NL.PrincipalReceived + NL.PrincipalRecoveryReceived)
	,InterestPaid							= -1 * (NL.InterestReceived + NL.InterestRecoveryReceived)	
	,ProsperFees							= -1 * (NL.NSFFeeReceived + NL.NSFFeeRecoveryReceived)
	,LateFees								= -1 * (NL.LateFeeReceived + NL.LateFeeRecoveryReceived)
	,GroupLeaderReward						= 0.00 --NOTE: This Field is NO LONGER Relevant
----RECEIVED------------------------------------------------------------------------------------------------------------
----SALES---------------------------------------------------------------------------------------------------------------
	,DebtSaleProceedsReceived				= CASE WHEN NL.IsDebtSale = 1 THEN NL.SaleNetProceeds ELSE 0.00 END
	,PlatformProceedsGrossReceived			= CASE WHEN NL.DateSold IS NOT NULL THEN NL.SaleGrossProceeds ELSE 0.00 END
	,PlatformFeesPaid						= CASE WHEN NL.DateSold IS NOT NULL THEN -1 * NL.SaleTransactionFee ELSE 0.00 END
----SALES---------------------------------------------------------------------------------------------------------------
	,NoteStatus								= CASE WHEN (NL.DateSold IS NULL OR NL.DateSold >= @CutoffMax) THEN NL.EndLoanStatusID ELSE 86 END --OLD: NL.EndLoanStatusID
	,NoteDefaultReason						= NL.DefaultReasonID
	,NoteDefaultReasonDescription			= NL.DefaultReasonDesc
	,IsSold									= CAST(CASE WHEN NL.DateSold IS NOT NULL THEN 1 ELSE 0 END AS BIT)
	,MonthlyPaymentAmount					= NL.ScheduledMonthlyPaymentAmount --OLD: NL.MonthlyPaymentAmount
	,NextPaymentDueAmountNoteLevel			= CAST(NL.ProRataShare * ISNULL(NL.NextPaymentDueAmount,0.00) AS DECIMAL(20,6))
	,SchMonthlypaymentNoteLevel				= CAST(NL.ProRataShare * ISNULL(NL.ScheduledMonthlyPaymentAmount,0.00) AS DECIMAL(20,6)) --OLD: NL.MonthlyPaymentAmount
----BANKRUPTCY----------------------------------------------------------------------------------------------------------
	,BankruptcyFiledDate					= FORMAT(NL.BankruptcyFiledDate,'yyyy-MM-dd HH:mm:ss')
	,BankruptcyStatus						= NL.BankruptcyStatus
	,BankruptcyType							= NL.BankruptcyType
	,BankruptcyStatusDate					= FORMAT(NL.BankruptcyStatusDate,'yyyy-MM-dd HH:mm:ss')
----BANKRUPTCY----------------------------------------------------------------------------------------------------------
	,LoanClosedDate							= FORMAT(NL.DateClosed,'yyyy-MM-dd HH:mm:ss') --OLD: NL.ClosedDate
----CHARGE-OFFS---------------------------------------------------------------------------------------------------------
	,ChargeoffDate							= FORMAT(NL.ChargeOffDate,'yyyy-MM-dd HH:mm:ss')
	,TotalChargeoff							= -1 * (NL.ChargeOffPrincipal + NL.ChargeOffInterest + NL.ChargeOffLateFee + NL.ChargeOffNSFFee)
	,PrincipalBalanceAtChargeoff			= -1 * NL.ChargeOffPrincipal
	,InterestBalanceAtChargeoff				= -1 * NL.ChargeOffInterest
	,LateFeeBalanceAtChargeoff				= -1 * NL.ChargeOffLateFee
	,NSFFeeBalanceAtChargeoff				= -1 * NL.ChargeOffNSFFee
	,RewardsBalanceAtChargeoff				= CASE WHEN NL.ChargeOffDate IS NOT NULL THEN 0.00 END --NOTE: This Field is NO LONGER Relevant
----CHARGE-OFFS---------------------------------------------------------------------------------------------------------
	,FICOScore								= ISNULL(NL.DecisionCreditScoreRange,'N/A')
	,NL.InvestmentTypeID
	,NL.LoanProductID
	,CollectionFees							= -1 * (NL.ClxFeePaid + NL.ClxFeeRecoveryPaid)
	,NL.IsPriorBorrower
	,NL.BorrowerState
	,NL.BorrowerAPR
	,PrincipalAdjustments					= -1 * (NL.PrincipalAdjustment + NL.RecoveryPrincipalAdjustment)
--2016 BBVA ADDITIONAL FIELDS-------------------------------------------------------------------------------------------
	,PastDueAmount							= CAST(NL.ProRataShare * ISNULL(NL.AmountPastDue - NL.EndLateFeeBal - NL.EndNSFFeeBal,0.00) AS DECIMAL(20,6)) --OLD: NL.TotalPaymentsPastDueAmount --NOTE: Used to be Named AmountPastDueLessFees
	,NL.ListingCategoryID
	,DecisionCredScore						= ISNULL(NL.DecisionCreditScore,0) --NOTE: SECURE POSITIONS WITH FOOTER ONLY
	,RefreshCredScore						= ref.FicoScore --NOTE: SECURE POSITIONS WITH FOOTER ONLY
	,RefreshCredScoreDate					= FORMAT(ref.CreatedDate,'yyyy-MM-dd HH:mm:ss') --NOTE: SECURE POSITIONS WITH FOOTER ONLY
	,NL.IsContractChargeOff
	,NL.IsNonContractChargeOff
	,DecisionCredScoreVendor				= ISNULL(NL.DecisionCreditScoreVendor,'N/A') --NOTE: SECURE POSITIONS WITH FOOTER ONLY
	,DecisionCredScoreVersion				= 'FICO 08' --NOTE: SECURE POSITIONS WITH FOOTER ONLY
	,RefreshCredScoreVendor					= CASE WHEN ref.FicoScore IS NOT NULL THEN 'TransUnion' END --NOTE: SECURE POSITIONS WITH FOOTER ONLY
	,RefreshCredScoreVersion				= CASE WHEN ref.FicoScore IS NOT NULL THEN 'FICO 08' END --NOTE: SECURE POSITIONS WITH FOOTER ONLY
----SETTLEMENTS---------------------------------------------------------------------------------------------------------
	,NL.SettlementStartDate
	,NL.SettlementEndDate
	,NL.SettlementStatus
	,SettlementBalAtEnrollment				= CASE WHEN NL.SettlementBalAtEnrollment IS NOT NULL THEN CAST(NL.ProRataShare * ISNULL(NL.SettlementBalAtEnrollment,0.00) AS DECIMAL(20,6)) END
	,SettlementAgreedPmtAmt					= CASE WHEN NL.SettlementAgreedPmtAmt IS NOT NULL THEN CAST(NL.ProRataShare * ISNULL(NL.SettlementAgreedPmtAmt,0.00) AS DECIMAL(20,6)) END
	,NL.SettlementPmtCount
	,NL.SettlementFirstPmtDueDate
----EXTENSIONS----------------------------------------------------------------------------------------------------------
	,NL.ExtensionStatus
	,NL.ExtensionTerm
	,NL.ExtensionOfferDate
	,NL.ExtensionExecutionDate
--2017 ADDITIONAL FIELDS------------------------------------------------------------------------------------------------
	,NL.ServiceFeePercent
	,NL.DateSold
	,NL.IsSCRA
	,NL.SCRABeginDate
	,NL.SCRAEndDate
	,IsMLA									= CAST(CASE WHEN TuMilitaryMatch = 'MATCH' THEN 1 ELSE 0 END AS BIT)
----RECOVERY PAYMENT FIELDS - IN PROCESS--------------------------------------------------------------------------------
    ,PrincipalRecoveriesInProcess			= -1 * (NL.PrincipalRecoveryPending)
	,InterestRecoveriesInProcess			= -1 * (NL.InterestRecoveryPending)
	,LateFeeRecoveriesInProcess				= -1 * (NL.LateFeeRecoveryPending)
	,NSFFeeRecoveriesInProcess				= -1 * (NL.NSFFeeRecoveryPending)
	,ClxFeeRecoveriesInProcess				= -1 * (NL.ClxFeeRecoveryPending)
	,SvcFeeRecoveriesInProcess				= -1 * (NL.SvcFeeRecoveryPending)
----RECOVERY PAYMENT FIELDS - RECEIVED----------------------------------------------------------------------------------
	,PrincipalRecoveriesReceived			= -1 * (NL.PrincipalRecoveryReceived)
	,InterestRecoveriesReceived				= -1 * (NL.InterestRecoveryReceived)
	,LateFeeRecoveriesReceived				= -1 * (NL.LateFeeRecoveryReceived)
	,NSFFeeRecoveriesReceived				= -1 * (NL.NSFFeeRecoveryReceived)
	,ClxFeeRecoveriesReceived				= -1 * (NL.ClxFeeRecoveryPaid)
	,SvcFeeRecoveriesReceived				= -1 * (NL.SvcFeeRecoveryPaid)
----CHECK FEE FIELDS----------------------------------------------------------------------------------------------------
	,InProcessCheckFeePayments				= -1 * (NL.CkFeePending + NL.CkFeeRecoveryPending)
	,CheckFees								= -1 * (NL.CkFeeReceived + NL.CkFeeRecoveryReceived)
	,CheckFeeRecoveriesInProcess			= -1 * (NL.CkFeeRecoveryPending)
	,CheckFeeRecoveriesReceived				= -1 * (NL.CkFeeRecoveryReceived)
----2017 ADDITIONAL FIELDS----------------------------------------------------------------------------------------------
	,RecordID								= ROW_NUMBER() OVER (ORDER BY NL.OriginationDate, NL.LoanID, NL.LoanToLenderID)
	--,NL.LoanToLenderID					--NOTE: For Testing Purposes Only
	,ThreeDigitZip							= CAST(LEFT(bsz.ZipCode,3) AS VARCHAR(3))
	,IsLegalStrategy						= CAST(CASE WHEN AgencyQueueName = 'CAQ_WNR_LS' THEN 1 ELSE 0 END AS BIT)
----2018 ADDITIONAL FIELDS----------------------------------------------------------------------------------------------
	,NL.InvestmentProductID
	,PurchasePrincipal						= NL.PrinAcquired
	,SoldPrincipal							= NL.PrinSold
	,IsCeaseAndDesist
	,IsAutoAchOff
INTO #Positions
--INTO Sandbox.[!!!].Positions
FROM #NoteLevel NL
LEFT JOIN #BorrowerStateAndZip bsz ON bsz.LoanID = NL.LoanID
OUTER APPLY (
	SELECT TOP 1 LoanId,FicoScore,CreatedDate,UpdatedDate
	FROM PortFolioMgmt.dbo.PortfolioReport
	WHERE LoanId = NL.LoanID
		AND CreatedDate < ISNULL(NL.DateSold,@CutoffMax) --NOTE: This will STALE Upon Date of Sale
		AND CreatedDate > NL.DecisionCreditScoreDate --NOTE: Refresh Later than Decision Date
	ORDER BY CreatedDate DESC, UpdatedDate DESC
) ref




IF OBJECT_ID('tempdb..#ListingCreditAttributes') IS NOT NULL DROP TABLE #ListingCreditAttributes
----*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH

DECLARE @PiiAndPointFico TINYINT = 1 --TODO: Change This Parameter to JUST PII
DECLARE @BackFillTable TINYINT = 1 --NOTE: If you want a BackFill of a Given Set of Loans

IF OBJECT_ID('tempdb..#Listings') IS NOT NULL DROP TABLE #Listings
CREATE TABLE #Listings (
	 LenderID					INT
	,LoanNumber					INT
	,ListingNumber				INT
	,ListingCreationDate		DATETIME
	,OriginationDate			DATETIME
	,PurchaseDate				DATETIME
	,OriginalAmountBorrowed		MONEY
	,OriginationFeeAmount		MONEY
	,Rating						VARCHAR(50)
	,EstimatedLossRate			DECIMAL(6,5)
	,TermMonths					SMALLINT
	,InterestRate				DECIMAL(10,7)
	,BorrowerAPR				DECIMAL(6,5)
	,NumberOfPayments			SMALLINT
	,LoanPurpose				VARCHAR(60)
	,BorrowerID					INT
	,DTIwProsperLoan			DECIMAL(15,5)
	,MonthlyIncome				MONEY
	,MonthlyDebt				MONEY
	,ExperianIsHomeowner		BIT
	,BorrowerState				VARCHAR(2)
	,TrailingFeeRate			DECIMAL(20,10)
	,OriginationSeasoningDays	INT
	,UserEmploymentDetailID		INT
	,UserID						INT
	,TermsApprovalDate			DATETIME
	)

IF @BackFillTable = 1
	INSERT INTO #Listings
	SELECT
		 LenderID					= ltl.LenderID
		,LoanNumber					= lo.LoanID
		,ListingNumber				= li.ID
		,ListingCreationDate		= li.CreationDate
		,lo.OriginationDate
		,PurchaseDate				= lo.OriginationDate
		,lo.OriginalAmountBorrowed
		--,li.OriginationFeeAmount
		,OriginationFeeAmount		= li.EndingOriginationFeeAmount
		,Rating						= prt.RatingCode
		,EstimatedLossRate			= li.EstimatedLoss
		--,li.EstimatedReturn
		,TermMonths					= ps.AmortizationMonths
		,InterestRate				= li.CurrentRate / 100
		,li.BorrowerAPR
		,NumberOfPayments			= ps.AmortizationMonths
		,LoanPurpose				= ISNULL(lc.Name,'')
		,lo.BorrowerID
		,DTIwProsperLoan			= li.CurrentDTI
		,li.MonthlyIncome
		,li.MonthlyDebt
		/***************** Experian Credit Attributes *****************/
		,ExperianIsHomeowner		= uh.IsHomeowner
		/***************** Experian Credit Attributes *****************/
		,li.BorrowerState
		,TrailingFeeRate			= CAST(ifs.TrailingFeeRate AS DECIMAL(20, 10))
		,lo.OriginationSeasoningDays
		,li.UserEmploymentDetailID
		,li.UserID
		,li.TermsApprovalDate
	FROM C1.dbo.Loans (NOLOCK) lo
	JOIN C1.dbo.Listings (NOLOCK) li
		ON li.LoanID = lo.LoanID
	JOIN C1.dbo.ProsperRatingType (NOLOCK) prt
		ON prt.ProsperRatingTypeID = li.ProsperRatingTypeID
	JOIN C1.dbo.InvestmentTypes	(NOLOCK) it
		ON it.InvestmentTypeID = li.InvestmentTypeID
	JOIN C1.dbo.ProductSpecs (NOLOCK) ps
		ON ps.ProductSpecID = li.ProductSpecID
	JOIN C1.dbo.ListingCategory (NOLOCK) lc
		ON lc.ListingCategoryID = li.ListingCategoryID
	JOIN CircleOne.dbo.InvestmentFeeSpec (NOLOCK) ifs
		ON ifs.InvestmentTypeID = li.InvestmentTypeID
	JOIN C1.dbo.LoanToLender (NOLOCK) ltl
		ON ltl.LoanID = lo.LoanID
	LEFT JOIN C1.dbo.UserHomeownership (NOLOCK) uh
		ON uh.ID = li.UserHomeownershipID
	WHERE 
		1=1
		and ltl.OwnershipEndDate is null
		/** Insert Loans Here **/
		and lo.loanID in (select 
							LoanNumber
							from 
								#Positions
							where
								1=1 
														
							)
	ELSE
	INSERT INTO #Listings
	SELECT
		 ltl.LenderID
		,LoanNumber					= lo.LoanID
		,ListingNumber				= li.ID
		,ListingCreationDate		= li.CreationDate
		,lo.OriginationDate
		,PurchaseDate				= lot.EffectiveDate
		--,OwnershipCreationDate		= ltl.creationDate
		--,ltl.OwnershipStartDate
		--,ltl.OwnershipEndDate
		,lo.OriginalAmountBorrowed
		--,li.OriginationFeeAmount
		,OriginationFeeAmount		= li.EndingOriginationFeeAmount
		,Rating						= prt.RatingCode
		,EstimatedLossRate			= li.EstimatedLoss
		--,li.EstimatedReturn
		,TermMonths					= ps.AmortizationMonths
		,InterestRate				= li.CurrentRate / 100
		,li.BorrowerAPR
		,NumberOfPayments			= ps.AmortizationMonths
		,LoanPurpose				= ISNULL(lc.Name,'')
		,lo.BorrowerID
		,DTIwProsperLoan			= li.CurrentDTI
		,li.MonthlyIncome
		,li.MonthlyDebt
		/***************** Experian Credit Attributes *****************/
		,ExperianIsHomeowner		= uh.IsHomeowner
		/***************** Experian Credit Attributes *****************/
		,li.BorrowerState
		,TrailingFeeRate			= CAST(ifs.TrailingFeeRate AS DECIMAL(20, 10))
		,lo.OriginationSeasoningDays
		,li.UserEmploymentDetailID
		,li.UserID
		,li.TermsApprovalDate
	FROM C1.dbo.Loans (NOLOCK) lo
	JOIN C1.dbo.Listings (NOLOCK) li
		ON li.LoanID = lo.LoanID
	JOIN C1.dbo.ProsperRatingType (NOLOCK) prt
		ON prt.ProsperRatingTypeID = li.ProsperRatingTypeID
	JOIN C1.dbo.InvestmentTypes	(NOLOCK) it
		ON it.InvestmentTypeID = li.InvestmentTypeID
	JOIN C1.dbo.ProductSpecs (NOLOCK) ps
		ON ps.ProductSpecID = li.ProductSpecID
	JOIN C1.dbo.ListingCategory (NOLOCK) lc
		ON lc.ListingCategoryID = li.ListingCategoryID
	JOIN CircleOne.dbo.InvestmentFeeSpec (NOLOCK) ifs
		ON ifs.InvestmentTypeID = li.InvestmentTypeID
	JOIN C1.dbo.LoanToLender (NOLOCK) ltl
		ON ltl.LoanID = lo.LoanID
	JOIN C1.dbo.LoanOwnershipTransfer (NOLOCK) lot
		ON lot.LoanOwnershipTransferID = ltl.PurchaseLoanOwnershipTransferID
	LEFT JOIN C1.dbo.UserHomeownership (NOLOCK) uh
		ON uh.ID = li.UserHomeownershipID
	WHERE 1=1
		AND it.IsWholeLoanType = 1 --Whole Loans Only
		AND lot.LoanOwnershipTransferTypeID = 5 --Origination Transfer
		
IF OBJECT_ID('tempdb..#CTEListings') IS NOT NULL DROP TABLE #CTEListings
SELECT
	 li.LenderID
	,li.LoanNumber
	,li.ListingNumber
	,li.ListingCreationDate
	,li.OriginationDate
	,li.PurchaseDate
	,li.OriginalAmountBorrowed
	,li.OriginationFeeAmount
	,li.Rating
	,li.EstimatedLossRate
	--,li.EstimatedReturn
	,li.TermMonths
	,li.InterestRate
	,li.BorrowerAPR
	,li.NumberOfPayments
	,li.LoanPurpose
	,li.BorrowerID
	,li.DTIwProsperLoan
	,li.MonthlyIncome
	,li.MonthlyDebt
	/***************** FICO Data - Vendor Agnostic *****************/
	,FICOScore					= ISNULL(tucrs.ScoreResults,ucp.Score)
	,FICODate					= ISNULL(tucr.CreditReportDate,ucp.CreditPullDate)
	,CreditBureau				= cb.CreditBureauName
	/***************** FICO Data - Vendor Agnostic *****************/
	/***************** Experian Credit Attributes *****************/
	,ExperianRealEstatePayment	= ucp.RealEstatePayment
	,li.ExperianIsHomeowner
	/***************** Experian Credit Attributes *****************/
	,li.BorrowerState
	,HardCodedServiceFeePercent = CAST(0.0107500 AS DECIMAL(20,10)) /* TECH DEBT: ServiceFeePercent is Hard-Coded */
	,li.TrailingFeeRate
	,CreditBureauID				= lcrm.CreditBureau
	,li.OriginationSeasoningDays
	,ucp.ExperianCreditProfileResponseID
	,tucr.CreditReportID
	,li.UserEmploymentDetailID
	,li.UserID
	,li.TermsApprovalDate
	,lcrm.ExternalCreditReportID
INTO #CTEListings
FROM #Listings li
LEFT JOIN CircleOne.dbo.ListingCreditReportMapping (NOLOCK) lcrm
	ON lcrm.ListingId = li.ListingNumber
	AND lcrm.IsDecisionBureau = 1
LEFT JOIN CircleOne.dbo.CreditBureau (NOLOCK) cb
	ON cb.CreditBureauID = lcrm.CreditBureau
LEFT JOIN TransUnion.dbo.CreditReport (NOLOCK) tucr
	ON tucr.ExternalCreditReportId = lcrm.ExternalCreditReportId
	AND lcrm.CreditBureau = 2
LEFT JOIN TransUnion.dbo.CreditReportScore (NOLOCK) tucrs
	ON tucrs.CreditReportId = tucr.CreditReportId
	AND tucrs.ScoreType = 'FICO_SCORE'
	AND lcrm.CreditBureau = 2
OUTER APPLY (
	SELECT TOP 1
		 ucp.Score
		,ucp.CreditPullDate
		,ecpr.ExperianCreditProfileResponseID
		,ecpr.RealEstatePayment
	FROM C1.dbo.ExperianDocuments (NOLOCK) ed
	JOIN C1.dbo.UserCreditProfiles (NOLOCK) ucp
		ON ucp.ExperianDocumentID = ed.id
	JOIN C1.dbo.ExperianCreditProfileResponse (NOLOCK) ecpr
		ON ecpr.ExperianDocumentID = ucp.ExperianDocumentID
	WHERE ed.ExternalCreditReportId = lcrm.ExternalCreditReportId
		AND lcrm.CreditBureau = 1	
	ORDER BY ucp.CreditPullDate DESC, ucp.CreationDate DESC, ecpr.CreatedDate DESC
) ucp
WHERE 1=1

IF OBJECT_ID('tempdb..#CTEPriorLoans') IS NOT NULL DROP TABLE #CTEPriorLoans
SELECT
	 LoanNumber						= lo.LoanID
	,PriorProsperLoans				= COUNT(DISTINCT lo2.LoanID)
	,ActivePriorProsperLoans		= SUM(CASE WHEN ld.LoanStatusTypesID IN (0,1) AND ld.PrinBal > 0 THEN 1 ELSE 0 END)
	,ActivePriorProsperLoansBalance	= SUM(CASE WHEN ld.LoanStatusTypesID IN (0,1) AND ld.PrinBal > 0 THEN ld.PrinBal ELSE 0 END)
INTO #CTEPriorLoans
FROM C1.dbo.Listings (NOLOCK) li
JOIN C1.dbo.InvestmentTypes (NOLOCK) it
	ON it.InvestmentTypeID = li.InvestmentTypeID
JOIN C1.dbo.Loans (NOLOCK) lo
	ON lo.LoanID = li.LoanID
JOIN C1.dbo.Listings (NOLOCK) li2
	ON li2.UserID = li.UserID
	AND li2.CreationDate < li.CreationDate
	AND li2.LoanID IS NOT NULL
	AND li2.LoanID <> li.LoanID
JOIN C1.dbo.Loans (NOLOCK) lo2
	ON lo2.LoanID = li2.LoanID
	AND lo2.OriginationDate < lo.OriginationDate
OUTER APPLY (
	SELECT TOP 1
			LoanID
		,PrinBal
		,LoanStatusTypesID
	FROM C1.dbo.LoanDetail (NOLOCK)
	WHERE LoanID = lo2.LoanID
		AND VersionValidBit = 1
		AND AccountInformationDate < lo.OriginationDate
		AND VersionStartDate < lo.OriginationDate
	ORDER BY VersionStartDate DESC
) ld
WHERE 1=1
	AND it.IsWholeLoanType = 1
	AND lo.LoanID IN (SELECT DISTINCT LoanNumber FROM #CTEListings)
GROUP BY lo.LoanID

IF OBJECT_ID('tempdb..#CTETu') IS NOT NULL DROP TABLE #CTETu
SELECT
	 CreditReportID
	,CvKey
	,CvValue
INTO #CTETu
FROM TransUnion.dbo.CreditReportCvAttribute (NOLOCK)
WHERE CreditReportID IN (SELECT DISTINCT CreditReportID FROM #CTEListings WHERE CreditBureauID = 2)
AND CvKey IN ('at01s','at02s','at20s','at36s','bc34s','co02s','co03s','co04s','g061s','g063s','g069s','g095s','g099s','g980s','inap01','mt02s','mtap01','reap01','s071b','s207a','s207s')

IF OBJECT_ID('tempdb..#CTETuPivot') IS NOT NULL DROP TABLE #CTETuPivot
SELECT
	 CreditReportID
	,at01s	= CAST(at01s  AS INT) --TotalTradeLines
	,at02s	= CAST(at02s  AS INT) --OpenCreditLines
	,at20s	= CAST(at20s  AS INT) --CreditHistoryMonths
	,at36s  = CAST(at36s  AS INT) --MonthsSinceMostRecentDelinquency
	,bc34s	= CAST(bc34s  AS INT) --BankcardUtilization
	,co02s	= CAST(co02s  AS INT) --COLast12Months
	,co03s	= CAST(co03s  AS INT) --COLast24Months
	,co04s  = CAST(co04s  AS INT) --MonthsSinceMostRecentCOTradeReported
	,g061s	= CAST(g061s  AS INT) --Delinquencies30DaysPlus24Months
	,g063s	= CAST(g063s  AS INT) --Delinquencies60DaysPlus6Months
	,g069s	= CAST(g069s  AS INT) --Delinquencies90DaysPlus12Months
	,g095s	= CAST(g095s  AS INT) --PublicRecordsLast36Months
	,g099s	= CAST(g099s  AS INT) --BKLast24Months
	,g980s	= CAST(g980s  AS INT) --Inquiries6Months
	,inap01	= CAST(inap01 AS INT) --MonthlyInstallmentPayment
	,mt02s	= CAST(mt02s  AS INT) --HasOpenMortgage
	,mtap01	= CAST(mtap01 AS INT) --BureauMortgagePayment
	,reap01	= CAST(reap01 AS INT) --MonthlyRevolvingPayment
	,s071b	= CAST(s071b  AS INT) --NonMedicalCollections24Months
	,s207a 	= CAST(s207a  AS INT) --MonthsSinceBK
	,s207s	= CAST(s207s  AS INT) --MonthsSincePublicRecord
INTO #CTETuPivot
FROM (
	SELECT
		 CreditReportID
		,CvKey
		,CvValue
	FROM #CTETu
) tucv
PIVOT (
	MAX(tucv.CvValue)
	FOR tucv.CvKey IN (at01s,at02s,at20s,at36s,bc34s,co02s,co03s,co04s,g061s,g063s,g069s,g095s,g099s,g980s,inap01,mt02s,mtap01,reap01,s071b,s207a,s207s)
) piv

IF OBJECT_ID('tempdb..#CTEExp') IS NOT NULL DROP TABLE #CTEExp
SELECT
	 ExperianCreditProfileResponseID
	,AttributeID
	,AttributeValue = CAST(AttributeValue AS INT)
INTO #CTEExp
FROM C1.dbo.ExperianCreditProfileStaggData (NOLOCK)
WHERE ExperianCreditProfileResponseID IN (SELECT DISTINCT ExperianCreditProfileResponseID FROM #CTEListings WHERE CreditBureauID = 1)
AND AttributeID IN ('ALL002','ALL003','ALL022','ALL127','ALL146','ALL701','ALL724','ALL803','ALL901','BAC403','REV404')

IF OBJECT_ID('tempdb..#CTEExpPivot') IS NOT NULL DROP TABLE #CTEExpPivot
SELECT
	 ExperianCreditProfileResponseID
	,ALL002
	,ALL003
	,ALL022
	,ALL127
	,ALL146
	,ALL701
	,ALL724
	,ALL803
	,ALL901
	,BAC403
	,REV404
INTO #CTEExpPivot
FROM (
	SELECT
		 ExperianCreditProfileResponseID
		,AttributeID
		,AttributeValue = CAST(AttributeValue AS INT)
	FROM #CTEExp
) stagg
PIVOT (
	MAX(stagg.AttributeValue)
	FOR stagg.AttributeID IN (ALL002,ALL003,ALL022,ALL127,ALL146,ALL701,ALL724,ALL803,ALL901,BAC403,REV404)
) piv


SELECT DISTINCT
	 li.LenderID,
	 li.LoanNumber
	,li.ListingNumber
	,li.ListingCreationDate
	,li.OriginationDate
	,li.PurchaseDate
	,li.OriginalAmountBorrowed
	,li.OriginationFeeAmount
	/***************** Pre-Purchase Interest *****************/
	,GrossPrePurchaseInterest	=	CAST(
											(
											li.OriginalAmountBorrowed *
											( CAST(ld.BorrowerStatedInterestRate AS DECIMAL(20,10)) / CAST(365.00 AS DECIMAL(20,10)) ) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
											--CAST(ld.IntBalDailyAccrual AS DECIMAL(20,10)) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
											)
									AS DECIMAL(20,10))
	,GrossPrePurchaseSvcFee		=	CAST(
									CAST(
											(
											li.OriginalAmountBorrowed *
											( CAST(ld.BorrowerStatedInterestRate AS DECIMAL(20,10)) / CAST(365.00 AS DECIMAL(20,10)) ) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
											--CAST(ld.IntBalDailyAccrual AS DECIMAL(20,10)) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
											)
									AS DECIMAL(20,10))
									*
									ISNULL( CAST(
												--CASE WHEN li.OriginationSeasoningDays > 1 THEN CAST(lof.ServicingFeePercent AS DECIMAL(20, 10)) + li.TrailingFeeRate ELSE CAST(lof.ServicingFeePercent AS DECIMAL(20, 10)) END
												li.HardCodedServiceFeePercent /* TECH DEBT: ServiceFeePercent is Hard-Coded */
												AS DECIMAL(20,10)) / CAST(NULLIF(ld.BorrowerStatedInterestRate,0) AS DECIMAL(20,10)) , 0)
									AS DECIMAL (20,10) )
	,NetPrePurchaseInterest			=	CAST(
										CAST(
												(
												li.OriginalAmountBorrowed *
												( CAST(ld.BorrowerStatedInterestRate AS DECIMAL(20,10)) / CAST(365.00 AS DECIMAL(20,10)) ) *DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
												--CAST(ld.IntBalDailyAccrual AS DECIMAL(20,10)) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
												)
										AS DECIMAL(20,10))
										-
										CAST(
										CAST(
												(
												li.OriginalAmountBorrowed *
												( CAST(ld.BorrowerStatedInterestRate AS DECIMAL(20,10)) / CAST(365.00 AS DECIMAL(20,10)) ) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
												--CAST(ld.IntBalDailyAccrual AS DECIMAL(20,10)) * DATEDIFF(DD,li.OriginationDate,li.PurchaseDate)
												)
										AS DECIMAL(20,10))
										*
										ISNULL( CAST(
													--CASE WHEN li.OriginationSeasoningDays > 1 THEN CAST(lof.ServicingFeePercent AS DECIMAL(20, 10)) + li.TrailingFeeRate ELSE CAST(lof.ServicingFeePercent AS DECIMAL(20, 10)) END
													li.HardCodedServiceFeePercent /* TECH DEBT: ServiceFeePercent is Hard-Coded */
													AS DECIMAL(20,10)) / CAST(NULLIF(ld.BorrowerStatedInterestRate,0) AS DECIMAL(20,10)) , 0)
										AS DECIMAL (20,10) )
										AS DECIMAL(10,4))
	/***************** Pre-Purchase Interest *****************/
	,li.Rating
	,li.EstimatedLossRate
	--,li.EstimatedReturn				--TODO: Notify DV01 this was Deprecated Everywhere
	,li.TermMonths
	,li.InterestRate
	,li.BorrowerAPR
	,BorrowerState						= ISNULL(uta.StateOfResidence, CASE WHEN li.ListingCreationDate < '1/1/2009' THEN li.BorrowerState END)
	,MaturityDate						= ld.ExpectedMaturityDate
	,li.NumberOfPayments
	,MonthlyPaymentAmount				= ld.ScheduledMonthlyPaymentAmount
	,FirstPaymentDate					= ld.NextPaymentDueDate
	,li.LoanPurpose
	,pl.PriorProsperLoans
	,pl.ActivePriorProsperLoans
	,pl.ActivePriorProsperLoansBalance
	/***************** PII - Borrower Name and Address *****************/
	,li.BorrowerID						--NOTE: Not Really PII
	,FirstName							= CASE WHEN @PiiAndPointFico = 1 THEN ISNULL(und.FirstName,'') ELSE NULL END
	,MiddleName							= CASE WHEN @PiiAndPointFico = 1 THEN ISNULL(und.MiddleName,'') ELSE NULL END
	,LastName							= CASE WHEN @PiiAndPointFico = 1 THEN ISNULL(und.LastName,'') ELSE NULL END
	,Suffix								= CASE WHEN @PiiAndPointFico = 1 THEN ISNULL(und.Suffix,'') ELSE NULL END
	,BorrowerAddress					= CASE WHEN @PiiAndPointFico = 1 THEN uta.StreetAddress ELSE NULL END
	,BorrowerCity						= CASE WHEN @PiiAndPointFico = 1 THEN uta.OriginalCity ELSE NULL END
	,BorrowerZip						= uta.OriginalZip --NOTE: Not Really PII
	/***************** PII - Borrower Name and Address *****************/
	,lof.DTIwoProsperLoan
	,li.DTIwProsperLoan
	,li.MonthlyIncome
	,li.MonthlyDebt
	,EmploymentStatusDescription		= ISNULL(es.[Description],'')
	,Occupation							= o.OccupationName
	,MonthsEmployed						= DATEDIFF(M , DATEFROMPARTS(ued.StartYear,ued.StartMonth,1) , li.FICODate )
	,StatedMonthlyHousingPayment		= ular.MonthlyHousingPayment
	,StatedAnnualIncome					= ui.Income
	,IncomeVerifiable					= ui.IsVerifiable
	/***************** FICO Data - Vendor Agnostic *****************/
	,FICOScore		=	CASE WHEN @PiiAndPointFico = 1 THEN CAST(li.FICOScore AS VARCHAR(4)) ELSE
						CASE            
							WHEN CAST(li.FICOScore AS INT) < 600 THEN '< 600'
							WHEN CAST(li.FICOScore AS INT) >= 600 AND CAST(li.FICOScore AS INT) < 620 THEN '600-619'
							WHEN CAST(li.FICOScore AS INT) >= 620 AND CAST(li.FICOScore AS INT) < 640 THEN '620-639'
							WHEN CAST(li.FICOScore AS INT) >= 640 AND CAST(li.FICOScore AS INT) < 660 THEN '640-659'
							WHEN CAST(li.FICOScore AS INT) >= 660 AND CAST(li.FICOScore AS INT) < 680 THEN '660-679'
							WHEN CAST(li.FICOScore AS INT) >= 680 AND CAST(li.FICOScore AS INT) < 700 THEN '680-699'
							WHEN CAST(li.FICOScore AS INT) >= 700 AND CAST(li.FICOScore AS INT) < 720 THEN '700-719'
							WHEN CAST(li.FICOScore AS INT) >= 720 AND CAST(li.FICOScore AS INT) < 740 THEN '720-739'
							WHEN CAST(li.FICOScore AS INT) >= 740 AND CAST(li.FICOScore AS INT) < 760 THEN '740-759'
							WHEN CAST(li.FICOScore AS INT) >= 760 AND CAST(li.FICOScore AS INT) < 780 THEN '760-779'
							WHEN CAST(li.FICOScore AS INT) >= 780 AND CAST(li.FICOScore AS INT) < 800 THEN '780-799'
							WHEN CAST(li.FICOScore AS INT) >= 800 AND CAST(li.FICOScore AS INT) < 820 THEN '800-819'
							WHEN CAST(li.FICOScore AS INT) >= 820 AND CAST(li.FICOScore AS INT) <= 850 THEN '820-850'
							ELSE 'N/A' 
						END
						END
	,FICOReportDate	= li.FICODate
	,li.CreditBureau
	/***************** FICO Data - Vendor Agnostic *****************/
	/***************** Experian Credit Attributes *****************/
	,expp.ALL002
	,expp.ALL003
	,expp.ALL022
	,expp.ALL127
	,expp.ALL146
	,expp.ALL701
	,expp.ALL724
	,expp.ALL803
	,expp.ALL901
	,expp.BAC403
	,expp.REV404
	,li.ExperianRealEstatePayment
	,li.ExperianIsHomeowner
	/***************** Experian Credit Attributes *****************/
	/***************** TransUnion Credit Attributes *****************/
	,tup.at01s
	,tup.at02s
	,tup.at20s
	,tup.at36s
	,tup.bc34s
	,tup.co02s
	,tup.co03s
	,tup.co04s
	,tup.g061s
	,tup.g063s
	,tup.g069s
	,tup.g095s
	,tup.g099s
	,tup.g980s
	,tup.inap01
	,tup.mt02s
	/* Home Ownership Type */
	,HomeOwnershipType	=	CASE 
								WHEN tup.mt02s >= 1 THEN 'Mortgage: With Open Mortgage'
								WHEN tup.mt02s = 0 THEN 'Rental: With Mortgage but No Open Mortgage'
								ELSE 'Rental: No Mortgage'
							END
	,tup.mtap01
	,tup.reap01
	,tup.s071b
	,tup.s207a
	,tup.s207s
	/***************** TransUnion Credit Attributes *****************/
	,HousingPayment = CAST(lofsd.Value AS MONEY)
--INTO TabReporting.[!!!].ListingCreditAttributes
INTO #ListingCreditAttributes
FROM #CTEListings li
LEFT JOIN #CTEPriorLoans pl
	ON pl.LoanNumber = li.LoanNumber
LEFT JOIN #CTETuPivot tup
	ON tup.CreditReportID = li.CreditReportID
LEFT JOIN #CTEExpPivot expp
	ON expp.ExperianCreditProfileResponseID = li.ExperianCreditProfileResponseID
CROSS APPLY (
	SELECT TOP 1 ModifiedDate
	FROM C1.dbo.ListingStatus (NOLOCK)
	WHERE ListingID = li.ListingNumber
		AND VersionValidBit = 1
		AND VersionEndDate IS NULL
		AND ListingStatusTypeID = 6 --NOTE: Consider Changing Status Type to 1
	ORDER BY VersionStartDate DESC
) lst
OUTER APPLY (
	SELECT TOP 1 LoanOfferID
	FROM C1.dbo.ListingOffersSelected (NOLOCK)
	WHERE ListingID = li.ListingNumber
		AND VersionValidBit = 1
		AND VersionEndDate IS NULL
	ORDER BY VersionStartDate DESC
) los
LEFT JOIN C1.dbo.LoanOffer (NOLOCK) lof
	ON lof.LoanOfferID = los.LoanOfferID

--/* Additional Table(s) Added for Housing Payment Variable NOTE: Use CircleOne Instead of C1 for Performance Improvement
--LEFT JOIN CircleOne.dbo.tblLoanofferScore (NOLOCK) lofs
--	ON lofs.ListingScoreID = lof.ListingScoreID
--	AND li.ListingNumber = lofs.ListingID
--LEFT JOIN CircleOne.dbo.tblLoanOfferScoreDetail (NOLOCK) lofsd
--	ON lofsd.ListingScoreID = lofs.ListingScoreID
--	AND lofs.ListingScoreID IS NOT NULL
--	AND lofsd.VariableID = 710 --710 = Housing Payment Variable, 709 = New DTI Inclusive of Rental Payments
LEFT JOIN (
	SELECT ListingScoreID, Value
	FROM CircleOne.dbo.tblLoanOfferScoreDetail (NOLOCK)
	WHERE VariableID = 710
) lofsd
	ON lofsd.ListingScoreID = lof.ListingScoreID
	AND lof.ListingScoreID IS NOT NULL
-- Additional Table(s) Added for Housing Payment Variable */

LEFT JOIN C1.dbo.UserEmploymentDetail (NOLOCK) ued
	ON ued.UserEmploymentDetailID = li.UserEmploymentDetailID
LEFT JOIN C1.dbo.EmploymentStatus (NOLOCK) es
	ON es.EmploymentStatusID = ued.EmploymentStatusID
LEFT JOIN C1.dbo.Occupations (NOLOCK) o
	ON ued.OccupationID = o.ID
OUTER APPLY (
	SELECT TOP 1
		 StateOfResidence
		,StreetAddress = (OriginalAddress1 + ISNULL(', ' + OriginalAddress2,''))
		,OriginalCity
		,OriginalZip
	FROM C1.dbo.UserToAddress (NOLOCK)
	WHERE UserID = li.UserID
		AND VersionValidBit = 1
		AND IsLegalAddress = 1
		AND IsVisible = 1 --NOTE: Unsure if Necessary
		AND VersionStartDate <= lst.ModifiedDate --li.TermsApprovalDate
		AND (VersionEndDate IS NULL OR VersionEndDate > lst.ModifiedDate /*li.TermsApprovalDate*/)
	ORDER BY VersionStartDate DESC
) uta
OUTER APPLY (
	SELECT TOP 1
		 FirstName
		,MiddleName
		,LastName
		,Suffix
	FROM C1.dbo.UserNameDetail (NOLOCK)
	WHERE UserID = li.UserID
		AND VersionValidBit = 1
		AND UserNameTypeID <= 3
		AND VersionStartDate <= lst.ModifiedDate --li.TermsApprovalDate
		AND (VersionEndDate IS NULL OR VersionEndDate > lst.ModifiedDate /*li.TermsApprovalDate*/)
	ORDER BY UserNameTypeID DESC, VersionStartDate DESC
) und
OUTER APPLY (
	SELECT TOP 1
		 NextPaymentDueDate
		,ExpectedMaturityDate
		,ScheduledMonthlyPaymentAmount
		,BorrowerStatedInterestRate
		,IntBalDailyAccrual
	FROM C1.dbo.LoanDetail (NOLOCK)
	WHERE LoanID = li.LoanNumber
		AND VersionValidBit = 1
		--AND VersionStartDate <= lo.OriginationDate 
		--AND (VersionEndDate > lo.OriginationDate OR VersionEndDate IS NULL)
		--AND IntBalDailyAccrual > 0.00
	ORDER BY VersionStartDate ASC
) ld
OUTER APPLY (
	SELECT TOP 1
		 Income
		,IsVerifiable
	FROM C1.dbo.UserIncome (NOLOCK)
	WHERE UserID = li.UserID
		AND VersionValidBit = 1
		AND VersionStartDate <= li.TermsApprovalDate
		AND (
			VersionEndDate > li.TermsApprovalDate
			OR VersionEndDate IS NULL
			)
	ORDER BY VersionStartDate DESC
) ui
OUTER APPLY (
	SELECT TOP 1 MonthlyHousingPayment
	FROM C1.dbo.UserLoanAmountRequests (NOLOCK)
	WHERE ExternalCreditReportID = li.ExternalCreditReportID
		AND UserID = li.UserID
		AND ListingID = li.ListingNumber
		AND MonthlyHousingPayment IS NOT NULL
	ORDER BY CreationDate DESC
) ular

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH

IF OBJECT_ID('tempdb..#BorrowerData') IS NOT NULL DROP TABLE #BorrowerData
SELECT
	 LoanToLenderID				= ltl.ID
	,AsOf						= FORMAT(DATEADD(MS,-2,@EndPeriod),'yyyy-MM-dd HH:mm:ss')
	,PurchaseDate				= lot.EffectiveDate
	,SoldDate					= ltl.OwnershipEndDate
	,ltl.LoanID
	,CustomerID					= lo.BorrowerID
	,OriginationFeeAmount		= li.EndingOriginationFeeAmount
	,govid.enNumber
	,u.enDateOfBirth
	--,ui.Income
	--,ue.Email
	,LastName					= CASE WHEN @ScrubPII = 1 THEN 'Smith' ELSE und.LastName + ISNULL(' ' + NULLIF(und.Suffix,''),'') END
	,FirstName					= CASE WHEN @ScrubPII = 1 THEN 'John' ELSE und.FirstName END
	,MiddleInitial				= CAST( CASE WHEN @ScrubPII = 1 THEN 'K' ELSE und.MiddleName END AS VARCHAR(1) )
	,uta.OriginalAddress1
	,uta.OriginalAddress2
	,uta.OriginalCity
	,uta.StateOfResidence
	,uta.OriginalZip
	,HomeAreaCode				= ph.AreaCode
	,HomeLineNumber				= ph.PhoneNumber
	,HomeExtension				= CAST( NULL AS VARCHAR(6) )
	,WorkAreaCode				= pw.AreaCode
	,WorkLineNumber				= pw.PhoneNumber
	,WorkExtension				= CAST( NULL AS VARCHAR(6) )
	,ued.Employer
	,ued.EmploymentStatus
	,ued.OccupationDescription
	,ued.EmploymentStartYear
	,ued.EmploymentStartMonth
	--,bank.BankName
	--,bank.BankAccountType
	--,bank.BankAccountStatus
	--,bank.BankRoutingNumber
	--,bank.enAccountNumber
	--,bank.FirstAccountHolderName
	--,bank.SecondAccountHolderName
INTO #BorrowerData
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
/************** ------- NEED SSN ------- **************/
LEFT JOIN CircleOne.DBO.GovtIssuedIdentification (NOLOCK) govid
	ON u.TaxpayerIDNumberID = govid.GovtIssuedIdentificationID
/************** NEED BANK ACCOUNT INFO **************
OUTER APPLY (
	SELECT TOP 1
		 BankName					= ISNULL(ba.BankName,'')
		,BankAccountType			= ISNULL(bat.Name,'')
		,BankAccountStatus			= CASE WHEN acct.[Status] = 2 THEN 'Active' ELSE 'Pending' END
		,BankRoutingNumber			= ISNULL(ba.RoutingNumber,'')
		,ba.enAccountNumber
		,FirstAccountHolderName		= ISNULL(ba.FirstAccountHolderName,'')
		,SecondAccountHolderName	= ISNULL(ba.SecondAccountHolderName,'')
		,IsPrimaryAccount			= acct.ISDefault
	FROM CircleOne.dbo.Accounts (NOLOCK) acct
	JOIN CircleOne.dbo.BankAccounts (NOLOCK) ba
		ON ba.[AccountID] = acct.ID
	JOIN CircleOne.dbo.BankAccountType (NOLOCK) bat
		ON bat.BankAccountTypeID = ba.BankAccountType
	WHERE 1=1
		AND acct.UserID = lo.BorrowerID
		AND acct.AccountTypeCode = 'Bank'
		AND acct.[Status] IN (0,2)
		AND acct.CreationDate < ISNULL(ltl.OwnershipEndDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	ORDER BY
		 acct.IsDefault DESC
		,acct.[Status] DESC
		,acct.CreationDate DESC --CASE WHEN acct.[Status] = 2 AND acct.IsDefault = 1 THEN 1 WHEN acct.[Status] = 0 THEN 3 END
) bank --*/
--/************** --- NEED ADDRESS DETAIL --- **************
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
--/************** --- NEED NAME DETAIL --- **************
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
--/************** NEED HOME PHONE NUMBER **************
OUTER APPLY (
	SELECT TOP 1 
		 p.AreaCode
		,p.PhoneNumber				
	FROM CircleOne.dbo.UserToPhone (NOLOCK) utp
	JOIN CircleOne.dbo.Phone (NOLOCK) p
		ON p.PhoneID = utp.PhoneID
	WHERE utp.UserID = lo.BorrowerID
		AND utp.UserPhoneTypeID NOT IN (2,4) /* DONT WANT EMPLOYER OR WORK PHONE */
		AND utp.VersionStartDate < ISNULL(ltl.OwnershipEndDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND (utp.VersionEndDate IS NULL OR utp.VersionEndDate >= ISNULL(ltl.OwnershipEndDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND utp.VersionValidBit = 1
	ORDER BY 	
		 --utp.VersionStartDate DESC,
		 utp.IsPreferredContact DESC
		,utp.IsVisible DESC
		,utp.VersionStartDate DESC
		,CASE
			WHEN utp.UserPhoneTypeID = 1 THEN 1
			WHEN utp.UserPhoneTypeID = 3 THEN 2
			ELSE 3
		 END
) ph  --*/
--/************** NEED WORK PHONE NUMBER **************
OUTER APPLY (
	SELECT TOP 1 
		 p.AreaCode
		,p.PhoneNumber				
	FROM CircleOne.dbo.UserToPhone (NOLOCK) utp
	JOIN CircleOne.dbo.Phone (NOLOCK) p
		ON p.PhoneID = utp.PhoneID
	WHERE utp.UserID = lo.BorrowerID
		AND utp.UserPhoneTypeID IN (2,4) /* WANT EMPLOYER OR WORK PHONE */
		AND utp.VersionStartDate < ISNULL(ltl.OwnershipEndDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND (utp.VersionEndDate IS NULL OR utp.VersionEndDate >= ISNULL(ltl.OwnershipEndDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND utp.VersionValidBit = 1
	ORDER BY 	
		 --utp.VersionStartDate DESC,
		 utp.IsPreferredContact DESC
		,utp.IsVisible DESC
		,utp.VersionStartDate DESC
) pw --*/
--/************** NEED EMPLOYMENT INFO **************
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
/************** NEED INCOME INFO **************
OUTER APPLY (
	SELECT TOP 1
		 Income
		,IsVerifiable
	FROM CircleOne.dbo.UserIncome (NOLOCK)
	WHERE UserID = lo.BorrowerID
		AND VersionStartDate < ISNULL(ltl.OwnershipEndDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND (VersionEndDate IS NULL OR VersionEndDate >= ISNULL(ltl.OwnershipEndDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND VersionValidBit = 1
	ORDER BY
		 --VersionStartDate DESC,
		 IsVerifiable DESC
		,VersionStartDate DESC
) ui --*/
/************** NEED EMAIL INFO ***************
OUTER APPLY (
	SELECT TOP 1
		 Email
		,IsSignInEmail = IsSignIn
		,UserEmailStatusID
	FROM CircleOne.dbo.UserEmails (NOLOCK)
	WHERE UserID = lo.BorrowerID
		AND VersionStartDate < ISNULL(ltl.OwnershipEndDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND (VersionEndDate IS NULL OR VersionEndDate >= ISNULL(ltl.OwnershipEndDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND VersionValidBit = 1
	ORDER BY
		 --VersionStartDate DESC,
		 CASE
		 	WHEN IsSignIn = 1 AND UserEmailStatusID = 1  THEN 1
		 	WHEN IsSignIn = 1 AND UserEmailStatusID = 0  THEN 2
		 	WHEN IsSignIn = 0 AND UserEmailStatusID <> 2 THEN 3
		 	WHEN IsSignIn = 1 AND UserEmailStatusID = 2  THEN 4
		 	ELSE 5
		 END 
		,VersionStartDate DESC 
) ue --*/
WHERE 1=1
	AND ltl.LenderID = @LenderID
	AND lot.EffectiveDate < @EndPeriod



IF OBJECT_ID('tempdb..#Incomes') IS NOT NULL DROP TABLE #Incomes
SELECT
	 UserIncomeID
	,UserID
	,Income
	,IsVerifiable
	,VersionStartDate
	,VersionEndDate
INTO #Incomes
FROM CircleOne.dbo.UserIncome (NOLOCK)
WHERE UserID IN (SELECT DISTINCT CustomerID FROM #BorrowerData)
	AND VersionValidBit = 1

IF OBJECT_ID('tempdb..#Emails') IS NOT NULL DROP TABLE #Emails
SELECT
	 UserEmailID
	,UserID
	,Email
	,IsSignInEmail = IsSignIn
	,UserEmailStatusID
	,VersionStartDate
	,VersionEndDate
INTO #Emails
FROM CircleOne.dbo.UserEmails (NOLOCK)
WHERE UserID IN (SELECT DISTINCT CustomerID FROM #BorrowerData)
	AND VersionValidBit = 1

IF OBJECT_ID('tempdb..#Accounts') IS NOT NULL DROP TABLE #Accounts
SELECT
	 AccountID					= acct.ID
	,acct.UserID
	,IsPrimaryAccount			= acct.ISDefault
	,acct.[Status]
	,acct.CreationDate
	,acct.AccountTypeCode
	--,BankName					= ISNULL(ba.BankName,'')
	--,BankAccountType			= ISNULL(bat.Name,'')
	,BankAccountStatus			= CASE WHEN acct.[Status] = 2 THEN 'Active' ELSE 'Pending' END
	--,BankRoutingNumber			= ISNULL(ba.RoutingNumber,'')
	--,ba.enAccountNumber
	--,FirstAccountHolderName		= ISNULL(ba.FirstAccountHolderName,'')
	--,SecondAccountHolderName	= ISNULL(ba.SecondAccountHolderName,'')
INTO #Accounts
FROM CircleOne.dbo.Accounts (NOLOCK) acct
--JOIN CircleOne.dbo.BankAccounts (NOLOCK) ba
--	ON ba.AccountID = acct.ID
--JOIN CircleOne.dbo.BankAccountType (NOLOCK) bat
--	ON bat.BankAccountTypeID = ba.BankAccountType
WHERE 1=1
	AND acct.UserID IN (SELECT DISTINCT CustomerID FROM #BorrowerData)
	--AND acct.AccountTypeCode = 'Bank'
	AND acct.[Status] IN (0,2)

IF OBJECT_ID('tempdb..#BankAccounts') IS NOT NULL DROP TABLE #BankAccounts
SELECT
	 a.AccountID
	,a.UserID
	,a.IsPrimaryAccount
	,a.[Status]
	,a.CreationDate
	,BankName					= ISNULL(ba.BankName,'')
	,BankAccountType			= ISNULL(bat.Name,'')
	,BankAccountStatus			= CASE WHEN a.[Status] = 2 THEN 'Active' ELSE 'Pending' END
	,BankRoutingNumber			= ISNULL(ba.RoutingNumber,'')
	,ba.enAccountNumber
	,FirstAccountHolderName		= ISNULL(ba.FirstAccountHolderName,'')
	,SecondAccountHolderName	= ISNULL(ba.SecondAccountHolderName,'')
INTO #BankAccounts
FROM #Accounts a
JOIN CircleOne.dbo.BankAccounts (NOLOCK) ba
	ON ba.AccountID = a.AccountID
JOIN CircleOne.dbo.BankAccountType (NOLOCK) bat
	ON bat.BankAccountTypeID = ba.BankAccountType
WHERE a.AccountTypeCode = 'Bank'



IF OBJECT_ID('tempdb..#BorrowerDataSecondPass') IS NOT NULL DROP TABLE #BorrowerDataSecondPass
SELECT
	 bd.LoanToLenderID
	,bd.AsOf
	,bd.PurchaseDate
	,bd.SoldDate
	,bd.LoanID
	,bd.CustomerID
	,bd.OriginationFeeAmount
	,bd.enNumber
	,bd.enDateOfBirth
	,ui.Income
	,ue.Email
	,bd.LastName
	,bd.FirstName
	,bd.MiddleInitial
	,bd.OriginalAddress1
	,bd.OriginalAddress2
	,bd.OriginalCity
	,bd.StateOfResidence
	,bd.OriginalZip
	,bd.HomeAreaCode
	,bd.HomeLineNumber
	,bd.HomeExtension
	,bd.WorkAreaCode
	,bd.WorkLineNumber
	,bd.WorkExtension
	,bd.Employer
	,bd.EmploymentStatus
	,bd.OccupationDescription
	,bd.EmploymentStartYear
	,bd.EmploymentStartMonth
	,bank.BankName
	,bank.BankAccountType
	,bank.BankAccountStatus
	,bank.BankRoutingNumber
	,bank.enAccountNumber
	,bank.FirstAccountHolderName
	,bank.SecondAccountHolderName
INTO #BorrowerDataSecondPass
FROM #BorrowerData bd
--/************** NEED BANK ACCOUNT INFO **************
OUTER APPLY (
	SELECT TOP 1
		 BankName
		,BankAccountType
		,BankAccountStatus
		,BankRoutingNumber
		,enAccountNumber
		,FirstAccountHolderName
		,SecondAccountHolderName
		,IsPrimaryAccount
	FROM #BankAccounts ba
	WHERE 1=1
		AND UserID = bd.CustomerID
		AND CreationDate < ISNULL(bd.SoldDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	ORDER BY
		 IsPrimaryAccount DESC
		,[Status] DESC
		,CreationDate DESC --CASE WHEN acct.[Status] = 2 AND acct.IsDefault = 1 THEN 1 WHEN acct.[Status] = 0 THEN 3 END
) bank --*/
--/************** NEED INCOME INFO **************
OUTER APPLY (
	SELECT TOP 1
		 Income
		,IsVerifiable
	FROM #Incomes
	WHERE UserID = bd.CustomerID
		AND VersionStartDate < ISNULL(bd.SoldDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND (VersionEndDate IS NULL OR VersionEndDate >= ISNULL(bd.SoldDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	ORDER BY
		 --VersionStartDate DESC,
		 IsVerifiable DESC
		,VersionStartDate DESC
) ui --*/
--/************** NEED EMAIL INFO ***************
OUTER APPLY (
	SELECT TOP 1
		 Email
		,IsSignInEmail
		,UserEmailStatusID
	FROM #Emails
	WHERE UserID = bd.CustomerID
		AND VersionStartDate < ISNULL(bd.SoldDate,@EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND (VersionEndDate IS NULL OR VersionEndDate >= ISNULL(bd.SoldDate,@EndPeriod)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	ORDER BY
		 --VersionStartDate DESC,
		 CASE
		 	WHEN IsSignInEmail = 1 AND UserEmailStatusID = 1  THEN 1
		 	WHEN IsSignInEmail = 1 AND UserEmailStatusID = 0  THEN 2
		 	WHEN IsSignInEmail = 0 AND UserEmailStatusID <> 2 THEN 3
		 	WHEN IsSignInEmail = 1 AND UserEmailStatusID = 2  THEN 4
		 	ELSE 5
		 END 
		,VersionStartDate DESC 
) ue --*/
WHERE 1=1



--/*
IF OBJECT_ID('tempdb..#BorrowerDataFinal') IS NOT NULL DROP TABLE #BorrowerDataFinal
SELECT			
	 AsOf
	,LoanID
	,CustomerID
	,LastName
	,FirstName
	,MiddleInitial
	,SocialSecurityNumber				= CASE WHEN @ScrubPII = 1 THEN '123456789' ELSE GOVIDDec.PlainText END
	,DateOfBirth						= TRY_CAST( CASE WHEN @ScrubPII = 1 THEN '12/30/1986' ELSE DOBDec.PlainText END AS DATE )
	,AddressLine1						= CASE WHEN @ScrubPII = 1 THEN '221 Main Street' ELSE OriginalAddress1 END
	,AddressLine2						= CASE WHEN @ScrubPII = 1 THEN 'Suite 300' ELSE OriginalAddress2 END
	,City								= CASE WHEN @ScrubPII = 1 THEN 'San Francisco' ELSE OriginalCity END
	,StateCode							= CASE WHEN @ScrubPII = 1 THEN 'CA' ELSE StateOfResidence END
	,ZipCode							= CAST( CASE WHEN @ScrubPII = 1 THEN '94105' ELSE OriginalZip END AS VARCHAR(5) )
	,HomeAreaCode						= CAST( CASE WHEN @ScrubPII = 1 THEN '415'  ELSE (CASE WHEN LEN(HomeAreaCode) = 3 AND LEN(HomeLineNumber) = 7 AND ISNUMERIC(HomeAreaCode) = 1 AND ISNUMERIC(HomeLineNumber) = 1 THEN HomeAreaCode END) END AS VARCHAR(3) )
	,HomePrefix							= CAST( CASE WHEN @ScrubPII = 1 THEN '867'  ELSE (CASE WHEN LEN(HomeAreaCode) = 3 AND LEN(HomeLineNumber) = 7 AND ISNUMERIC(HomeAreaCode) = 1 AND ISNUMERIC(HomeLineNumber) = 1  THEN LEFT(HomeLineNumber,3) END) END AS VARCHAR(3) )
	,HomeLineNumber						= CAST( CASE WHEN @ScrubPII = 1 THEN '5309' ELSE (CASE WHEN LEN(HomeAreaCode) = 3 AND LEN(HomeLineNumber) = 7 AND ISNUMERIC(HomeAreaCode) = 1 AND ISNUMERIC(HomeLineNumber) = 1  THEN RIGHT(HomeLineNumber,4) END) END AS VARCHAR(4) )
	,HomeExtension
	,WorkAreaCode						= CAST( CASE WHEN @ScrubPII = 1 THEN '415'  ELSE (CASE WHEN LEN(WorkAreaCode) = 3 AND LEN(WorkLineNumber) = 7 AND ISNUMERIC(WorkAreaCode) = 1 AND ISNUMERIC(WorkLineNumber) = 1 THEN WorkAreaCode END) END AS VARCHAR(3) )
	,WorkPrefix							= CAST( CASE WHEN @ScrubPII = 1 THEN '555'  ELSE (CASE WHEN LEN(WorkAreaCode) = 3 AND LEN(WorkLineNumber) = 7 AND ISNUMERIC(WorkAreaCode) = 1 AND ISNUMERIC(WorkLineNumber) = 1  THEN LEFT(WorkLineNumber,3) END) END AS VARCHAR(3) )
	,WorkLineNumber						= CAST( CASE WHEN @ScrubPII = 1 THEN '1212' ELSE (CASE WHEN LEN(WorkAreaCode) = 3 AND LEN(WorkLineNumber) = 7 AND ISNUMERIC(WorkAreaCode) = 1 AND ISNUMERIC(WorkLineNumber) = 1  THEN RIGHT(WorkLineNumber,4) END) END AS VARCHAR(4) )
	,WorkExtension
	,EmailAddress						= CASE WHEN @ScrubPII = 1 THEN 'investors@prosper.com' ELSE Email END
	,EmployerName						= CAST( Employer AS VARCHAR(50) ) --NOTE: THIS WILL TRUNCATE FOR LONG EMPLOYER NAMES!
	,EmploymentStatus
	,OccupationDescription
	,ApplicantMonthsAtCurrentJob		= CAST( CASE WHEN LEN(DATEDIFF(M,DATEFROMPARTS(EmploymentStartYear,EmploymentStartMonth,1),AsOf)) > 3 THEN NULL ELSE DATEDIFF(M,DATEFROMPARTS(EmploymentStartYear,EmploymentStartMonth,1),AsOf) END AS INT)
	,ApplicantGrossAnnualIncomeAmount	= CAST( ISNULL(Income,0) AS DECIMAL(11,2) ) --TODO: SHOULD THIS REALLY BE ISNULL(,0)?
	,OriginationFeeAmount
	,BankName
	,BankAccountType
	,BankAccountStatus
	,BankRoutingNumber
	,BankAccountNumber					= CASE WHEN @ScrubPII = 1 THEN '123456789' ELSE CAST( LTRIM( RTRIM( AcctNum.PlainText ) ) AS VARCHAR(20) ) END
	,FirstAccountHolderName				= CASE WHEN @ScrubPII = 1 THEN 'First Name' ELSE FirstAccountHolderName END
	,SecondAccountHolderName			= CASE WHEN @ScrubPII = 1 THEN 'Second Name' ELSE SecondAccountHolderName END
INTO #BorrowerDataFinal
--INTO Sandbox.[!!!].BorrowerFile
FROM #BorrowerDataSecondPass
OUTER APPLY Circleone.dbo.tfnDecrypt(enNumber) GOVIDDec
OUTER APPLY Circleone.dbo.tfnDecrypt(enDateOfBirth) DOBDec
OUTER APPLY CircleOne.dbo.tfnDecrypt(enAccountNumber) AcctNum




SELECT
	  'Loan #'								= p.LoanNumber
	, 'CB LOAN NUMBER'						= ''
	, 'BORROWER FIRST'						= upper(lca.FirstName)
	, 'BORROWER LAST'						= upper(lca.LastName)
	, 'BORROWER TAX ID'						= br.SocialSecurityNumber
	, 'BORROWER PHONE NBR'					= br.HomeAreaCode + '-' + br.HomePrefix + '-' + br.HomeLineNumber
	, 'PROPERTY CO-OWNER FIRST'				= ''
	, 'PROPERTY CO-OWNER LAST'				= ''
	, 'PROPERTY CO-OWNER TAX-ID'			= ''
	, 'PURCHASE CONTRACT DATE'				= ''
	, 'PURCHASE PRICE'						= ''
	, 'PURPOSE CODE'						= ''
	, 'LIEN TYPE'							= ''
	, 'LOAN START DATE'						= p.OriginationDate
	, 'ORIGINAL LOAN TERM IN MONTHS'		= p.Term
	, 'ORIGINAL PRINCIPAL BALANCE'			= p.LoanAmount
	, 'CURRENT PRINCIPAL BALANCE'			= p.PrincipalBalance
	, 'ACCRUED INTEREST'					= p.AccruedInterest
	, 'ORIGINAL LTV'						= ''
	, 'CURRENT BALANCE LTV'					= ''
	, 'NOTE INITIAL RATE'					= p.BorrowerRate
	, 'NOTE RATE TYPE'						= 'Fixed'
	, 'NOTE MARGIN FIXED'					= 'Yes'
	, 'NOTE MARGIN PERCENTAGE'				= ''
	, 'NOTE INTEREST INDEX'					= '' 
	, 'MAX RATE INCREASE'					= ''
	, 'MINIMUM RATE INCREASE'				= ''
	, 'NOTE MINIMUM INTEREST RATE'			= ''
	, 'NOTE MAXIMUM INTEREST RATE'			= ''
	, 'INTEREST RATE RESET INTERVAL'		= ''
	, 'NEGATIVE AMORT  ALLOWED'				= ''
	, 'MONTHS TO 1st ADJUSTMENT'			= ''
	, 'MONTHS TO NEXT ADJUSTMENT'			= ''
	, 'INITIAL REPRICING FREQUENCY'			= ''
	, 'NEXT ADJUSTMENT DATE'				= ''
	, 'ARM INITIAL INTEREST RATE'			= ''
	, 'ARM INITIAL P&I'						= ''
	, 'ESCROW BAL'							= ''
	, 'P & I'								= ''
	, 'T & I'								= ''
	, 'TOTAL SCHEDULED PMT'					= p.MonthlyPaymentAmount
	, 'REMAINING TERM (IN MONTHS)'			= p.Term - p.AgeInMonths
	, 'MATURITY DATE'						= p.MaturityDate
	, 'INTEREST PAID TO DATE'				= p.InterestPaid
	, 'FIRST PAYMENT DUE DATE'				= p.FirstScheduledPayment
	, 'NEXT DUE DATE'						= p.NextPaymentDueDate
	, 'MTG IS CURRENT (Yes or No)'			= ''
	, 'PENDING PAYMENT EFFECTIVE DATE'		= ''
	, 'PENDING P&I'							= ''
	, 'PENDING T&I'							= ''
	, 'PENDING TOTAL'						= ''
	, 'ACH PAYMENT'							= case when p.IsAutoAchOff = 0 then 'TRUE' else 'FALSE' end
	, 'GRACE DAYS'							= 0
	, 'LATE CHARGE FACTOR'					= 0.05
	, 'DTI RATIO'							= lca.DTIwoProsperLoan
	, 'CREDIT SCORE'						= lca.FICOScore
	, 'CREDIT SCORE DATE'					= lca.FICOReportDate
	, 'SSN_VERIFY_DATE'						= lca.FICOReportDate 
	, 'SSN CERTIFY DATE'					= ''
	, 'Lending Division'					= ''
	, 'Lending Officer'						= ''
	, 'Branch ID'							= ''
	, 'PRIMARY /Mailing STREET NUMBER'		= upper(br.AddressLine1)
	, 'STREET DIRECTIONAL'					= ''
	, 'PRIMARY /Mailing STREET NAME'		= ''
	, 'STREET SUFFIX'						= ''
	, 'STREET DIRECTIONAL SUFFIX'			= ''
	, 'UNIT DESIGNATION'					= ''
	, 'UNIT #'								= ''
	, 'PRIMARY / Mailing CITY'				= upper(br.City)
	, 'PRIMARY ADDRESS STATE'				= upper(br.StateCode)
	, 'PRIMARY ADDRESS ZIP'					= upper(br.ZipCode)
	, 'Collateral Code'						= ''
	, 'PROPERTY TYPE DESCRIP (per apprsl)'	= ''
	, 'PURPOSE DESCRIPTION'					= ''
	, 'OWNERSHIP TYPE'						= ''
	, 'COLLATERAL STREET NBR'				= ''
	, 'STREET DIRECTIONAL'					= ''
	, 'COLLATERAL STREET NAME'				= ''
	, 'STREET SUFFIX'						= ''
	, 'STREET DIRECTIONAL SUFFIX'			= ''
	, 'UNIT DESIGNATION'					= ''
	, 'UNIT NUMBER'							= ''
	, 'COLLATERAL CITY'						= ''
	, 'COLLATERAL COUNTY'					= ''
	, 'COLLATERAL STATE'					= ''
	, 'COLLATERAL ZIP CODE'					= ''
	, 'COLLATERAL PROPERTY VALUE'			= ''
	, 'COLLATERAL APPRAISAL DATE'			= ''
	, 'YEAR BUILT'							= ''
	, 'PROP CENSUS TRACT'					= ''
	, 'NUMBER OF UNITS'						= ''
	, 'DEVELOPMENT TYPE'					= ''
	, 'FLOOD_ZONE'							= ''
	, 'FLOOD INS REQ'						= ''
	, 'MERS'								= ''
	, 'MERS ORIG ORG ID'					= ''
	, 'MERS ORIG NOTE HOLDER NAME'			= ''
	, 'PRIMARY BORROWER NAME FIRST'			= ''
	, 'PRIMARY BORROWER NAME MIDDLE'		= ''
	, 'PRIMARY BORROWER NAME LAST'			= ''
	, 'PRIMARY TELEPHONE NUMBER'			= ''
	, 'SECOND PHONE NUMBER'					= ''
	, 'EMAIL ADDRESS'						= ''
	, 'BORROWER SHORT NAME'					= ''
	, 'DOB PRIMARY BORROWER'				= ''
	, 'BORROWER IS CB EMPLOYEE'				= ''
	, 'COBORROWER # 1 NAME FIRST'			= ''
	, 'COBORROWER # 1  NAME MIDDLE'			= ''
	, 'COBORROWER # 1  NAME LAST'			= ''
	, 'COBORROWER # 1 TELEPHONE NUMBER'		= ''
	, 'SECOND TELEPHONE NUMBER'				= ''
	, 'CO BORROWER EMAIL ADDRESS'			= ''
	, 'DOB COBORROWER # 1'					= ''
	, 'PROP MSA CODE'						= ''
	, 'STATE CODE'							= ''
	, 'COUNTY CODE'							= ''
	, 'FIPS COUNTY CODE'					= ''
	, 'ADDITIONAL COBORROWER # 2 FULL NAME' = ''
	, 'ADDITIONAL COBORROWER # 3 FULL NAME' = ''
	, 'ECLOSE (Yes or No)'					= ''
	, 'CEMA LOAN (Yes or No)'				= ''
	, 'ORIGINAL COMPANY NAME'				= ''
	, 'ORIG CO. TEL Number'					= ''
	, 'Business Type'						= ''
	, 'Relationship Name'					= ''
	, 'Relationship ID'						= ''
	, 'Stock Symbol'						= ''
	, 'Commitment Availability'				= ''
	, 'Last Renewal Date'					= ''
	, 'Last Extension Date'					= ''
	, 'Number of Renewals'					= ''
	, 'Number of Extensions'				= ''
	, 'Interest Earned Not Collected'		= ''
	, 'Borrower Internal Rating'			= ''
	, 'Borrower Rating Date'				= ''
	, 'Note Risk Rating'					= ''
	, 'Balance Rated Pass'					= ''
	, 'Balance Rated Special Mention'		= ''
	, 'Balance  Rated Sub-standard'			= ''
	, 'Balance Rated Doubtful'				= '' 
	, 'Charge-Off Amount'					= isnull(p.PrincipalBalanceAtChargeoff, 0)
	, 'Specific Reserve'					= ''
	, 'Shared National Credit'				= ''
	, 'Guarantor'							= ''
	, 'Days Past Due'						= p.DaysPastDue
	, 'Non-Accrual'							= ''
	, 'Times Past Due 30-59'				= ''
	, 'Times Past Due 60-89'				= ''
	, 'Times Past Due 90+'					= ''
	, 'Type'								= ''
	, 'FFEIC Call Code Default'				= ''
	, 'Collateral Description'				= ''
	, 'Payment Frequency'					= 'Monthly'
	, 'Variable Rate'						= 'N'
	, 'Troubled Debt Restructure'			= '' 
	, 'Amoritizing=Y / Non-Amoritizing=N'	= 'Y'
	, 'Last Payment Date'					= ''
	, 'Capitalized Interest'				= ''
	, 'Dealer Code'							= ''
	, 'Dealer Reserve Balance'				= ''
	, 'Late Charges Due & Unpaid'			= p.AccruedLatefee
	, 'Servicing Fee'						= 0.01075
	, 'Accrual Method'						= 'Actual days / 365 days'
	, 'Last Repricing Date'					= ''
	, 'Amortization Code Default'			= ''
	, 'Balloon Indicator Default'			= ''
	, 'Interest Payment Frequency'			= 1
	, 'Principal Payment Frequency'			= 1
	
	FROM
		#Positions p
	JOIN 
		#listingcreditattributes lca
		ON 
		lca.LoanNumber = p.LoanNumber
	JOIN
		#BorrowerDataFinal br
		ON
		br.LoanID = p.LoanNumber
	WHERE
		1=1 
		and p.OriginationDate < dateadd(day,1,eomonth(getdate(),-1))
		and p.OriginationDate >= dateadd(month, -1, dateadd(day,1,eomonth(getdate(),-1)))
		
	