SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH

DECLARE @start		DATETIME			= '2019-04-21'
DECLARE @end		DATETIME			= '2019-06-01'
DECLARE @InvestorID	INT					= 8534717
DECLARE @LoanID		INT					= 1228001

if object_id('tempdb..#Positions') is not null drop table #Positions

Create table #positions (
AsOf	DATETIME
,ListingNumber	INT
,OriginationDate	DATETIME
,PurchaseDate	DATETIME
,InvestorKey	VARCHAR(30)
,LoanNoteID	VARCHAR(30)
,LoanNumber	INT
,OriginalInvestment	MONEY
,LoanAmount	MONEY
,PrincipalBalance	MONEY
,InProcessPrincipalPayments	MONEY
,InProcessInterestPayments	MONEY
,InProcessOriginationInterestPayments	MONEY
,InProcessLatfeePayments	MONEY
,InProcessSvcFeePayments	MONEY
,InProcessCollectionsPayments	MONEY
,InProcessNSFFeePayments	MONEY
,InProcessGLRewardPayments	MONEY
,AccruedInterest	MONEY
,AccruedOriginationInterest	MONEY
,AccruedLatefee	MONEY
,AccruedNSFFee	MONEY
,AccruedSvcFee	MONEY
,AccruedGLReward	MONEY
,LoanStatusDescription	VARCHAR(30)
,ProsperRating	VARCHAR(30)
,Term	INT
,MaturityDate	DATETIME
,BorrowerRate	DECIMAL(8,7)
,NextPaymentDueDate	DATETIME
,AgeInMonths	INT
,DaysPastDue	INT
,FirstScheduledPayment	DATETIME
,ServiceFees	MONEY
,PrincipalRepaid	MONEY
,InterestPaid	MONEY
,ProsperFees	MONEY
,LateFees	MONEY
,GroupLeaderReward	MONEY
,DebtSaleProceedsReceived	MONEY
,PlatformProceedsGrossReceived	MONEY
,PlatformFeesPaid	MONEY
,NoteStatus	INT
,NoteDefaultReason	INT
,NoteDefaultReasonDescription	VARCHAR(30)
,IsSold	BIT
,MonthlyPaymentAmount	MONEY
,NextPaymentDueAmountNoteLevel	MONEY
,SchMonthlypaymentNoteLevel	MONEY
,BankruptcyFiledDate	DATETIME
,BankruptcyStatus	VARCHAR(30)
,BankruptcyType	VARCHAR(30)
,BankruptcyStatusDate	DATETIME
,LoanClosedDate	DATETIME
,ChargeoffDate	DATETIME
,TotalChargeoff	MONEY
,PrincipalBalanceAtChargeoff	MONEY
,InterestBalanceAtChargeoff	MONEY
,LateFeeBalanceAtChargeoff	MONEY
,NSFFeeBalanceAtChargeoff	MONEY
,RewardsBalanceAtChargeoff	MONEY
,FICOScore	VARCHAR(30)
,InvestmentTypeID	INT
,LoanProductID	INT
,CollectionFees	MONEY
,IsPriorBorrower	BIT
,BorrowerState	VARCHAR(30)
,BorrowerAPR	DECIMAL(8,7)
,PrincipalAdjustments	MONEY
,PastDueAmount	MONEY
,ListingCategoryID	INT
,DecisionCredScore	INT
,RefreshCredScore	INT
,RefreshCredScoreDate	DATETIME
,IsContractChargeOff	BIT
,IsNonContractChargeOff	BIT
,DecisionCredScoreVendor	VARCHAR(30)
,DecisionCredScoreVersion	VARCHAR(30)
,RefreshCredScoreVendor	VARCHAR(30)
,RefreshCredScoreVersion	VARCHAR(30)
,SettlementStartDate	DATETIME
,SettlementEndDate	DATETIME
,SettlementStatus	VARCHAR(30)
,SettlementBalAtEnrollment	MONEY
,SettlementAgreedPmtAmt	MONEY
,SettlementPmtCount	INT
,SettlementFirstPmtDueDate	DATETIME
,ExtensionStatus	VARCHAR(30)
,ExtensionTerm	INT
,ExtensionOfferDate	DATETIME
,ExtensionExecutionDate	DATETIME
,ServiceFeePercent	DECIMAL(8,7)
,DateSold	DATETIME
,IsSCRA	BIT
,SCRABeginDate	DATETIME
,SCRAEndDate	DATETIME
,IsMLA	BIT
,PrincipalRecoveriesInProcess	MONEY
,InterestRecoveriesInProcess	MONEY
,LateFeeRecoveriesInProcess	MONEY
,NSFFeeRecoveriesInProcess	MONEY
,ClxFeeRecoveriesInProcess	MONEY
,SvcFeeRecoveriesInProcess	MONEY
,PrincipalRecoveriesReceived	MONEY
,InterestRecoveriesReceived	MONEY
,LateFeeRecoveriesReceived	MONEY
,NSFFeeRecoveriesReceived	MONEY
,ClxFeeRecoveriesReceived	MONEY
,SvcFeeRecoveriesReceived	MONEY
,InProcessCheckFeePayments	MONEY
,CheckFees	MONEY
,CheckFeeRecoveriesInProcess	MONEY
,CheckFeeRecoveriesReceived	MONEY
,RecordID	INT
,ThreeDigitZip	INT
,IsLegalStrategy	BIT
,InvestmentProductID	INT
,PurchasePrincipal	MONEY
,SoldPrincipal	MONEY
,IsCeaseAndDesist	BIT
,IsAutoAchOff	BIT
)


while @start <= @end
begin

DECLARE @CutoffMin	DATETIME	= @start
DECLARE @CutoffMax	DATETIME	= @CutoffMin



/***************************************************************************************/

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

--CREATE INDEX NC_LoanToLenderID ON #NoteLevel (LoanToLenderID)
--CREATE INDEX NC_LenderID_LoanID ON #NoteLevel (LenderID,LoanID)
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
WHERE l.LoanID = @LoanID
/************************************************************ BORROWER STATE AND ZIP ************************************************************/
insert into #Positions

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
--INTO #Positions
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
WHERE 
	1=1
	and NL.LoanID = @LoanID

/***************************************************************************************************************/
	set @start = @start + 1
	
end

--select everything in the table


SELECT
	* 
	FROM 
		#Positions
	ORDER BY 
		AsOf ASC