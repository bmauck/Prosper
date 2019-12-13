/* TESTING
DECLARE @BegPeriod	DATETIME	= '10/14/2018'
DECLARE @EndPeriod	DATETIME	= '10/15/2018'
DECLARE @LenderID	INT			= 5513816 --3661300 (ECHELON) --3651887 (SOROS) --5513816 (BBVA) --2093353 (BLK) --2978229 (CCOLT) --3233766 (CITI)
IF OBJECT_ID('tempdb..#NoteLevel') IS NOT NULL DROP TABLE #NoteLevel
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
USE DW; --*/

/* All Loans Owned Through @EndPeriod + Transactions Through @EndPeriod */
WITH CTETransactionLevel AS (
	SELECT
		LoanToLenderID
		,LoanNoteID
		,LenderID
		,PendingDate
		,CompletedDate
		,Principal
		,Interest
		,SvcFee
		,ClxFee
		,LateFee
		,NSFFee
		,CheckPaymentFee
	----GROUPING-----------------------------------------------------------------------------------------------------------------
		,StatementTransactionType
		,AdjustmentFlag
		,[Status]
	----TIMING-----------------------------------------------------------------------------------------------------------------
		,PendingPeriod =
			CASE
				WHEN PendingDate >= @BegPeriod AND PendingDate < @EndPeriod THEN 'Pending This Period'
				ELSE 'Pending Prior Period'
			END
		,CompletedPeriod =
			CASE
				WHEN CompletedDate < @BegPeriod THEN 'Completed Prior Period'
				WHEN CompletedDate >= @BegPeriod AND CompletedDate < @EndPeriod THEN 'Completed This Period'
				WHEN (CompletedDate >= @EndPeriod OR CompletedDate IS NULL) THEN 'Not Completed'
			END
	FROM dbo.dw_loantolender_transaction (NOLOCK)
	WHERE 1=1
		AND (LenderID = @LenderID)
		AND PendingDate < @EndPeriod
)

/* Aggregated by LoanToLenderID : Acquired,Sold,ChargeOff,BegBalance,EndBalance,Payments-Received,Payments-Pending,Adjustments */
, CTELenderNoteLevelAggregates AS (
	SELECT
		AsOfDate						= DATEADD(MS,-2,@EndPeriod) --AsOf is just before Midnight of the @EndPeriod (File Creation Date)
		,LoanToLenderID
		,LoanNoteID
		,LenderID
	----ACQUISITION/SALE-------------------------------------------------------------------------------------------------------
		,PrinAcquired					= SUM(CASE WHEN StatementTransactionType = 'Acquisition' THEN Principal ELSE NULL END)
		,DateAcquired					= MAX(CASE WHEN StatementTransactionType = 'Acquisition' THEN PendingDate ELSE NULL END)
		,StatusAcquired					= MAX(CASE WHEN StatementTransactionType = 'Acquisition' THEN [Status] ELSE NULL END)
		,PrinSold						= SUM(CASE WHEN StatementTransactionType IN ('Sale','DebtSale') THEN Principal ELSE NULL END)
		,DateSold						= MAX(CASE WHEN StatementTransactionType IN ('Sale','DebtSale') THEN PendingDate ELSE NULL END)
		,StatusSold						= MAX(CASE WHEN StatementTransactionType IN ('Sale','DebtSale') THEN [Status] ELSE NULL END)
		,IsDebtSale						= MAX(CASE WHEN StatementTransactionType = 'DebtSale' THEN 1 ELSE 0 END)
	----CHARGE-OFFS------------------------------------------------------------------------------------------------------------
		,IsContractChargeOff			= MAX(CASE WHEN StatementTransactionType = 'Contract Charge Off' THEN 1 ELSE 0 END)
		,IsNonContractChargeOff			= MAX(CASE WHEN StatementTransactionType = 'Non Contract Charge Off' THEN 1 ELSE 0 END)
		,ChargeOffDate					= MAX(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN PendingDate ELSE 0 END)
		,ChargeOffPrincipal				= SUM(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN Principal ELSE 0 END)
		,ChargeOffInterest				= SUM(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN Interest ELSE 0 END)
		,ChargeOffLateFee				= SUM(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN LateFee ELSE 0 END)
		,ChargeOffNSFFee				= SUM(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN NSFFee ELSE 0 END)
	----BEG/END BALANCE--------------------------------------------------------------------------------------------------------
		,BegBalance						= SUM(CASE WHEN StatementTransactionType NOT IN ('Contract Charge Off','Non Contract Charge Off') AND PendingPeriod = 'Pending Prior Period' THEN Principal ELSE 0 END)
		,EndBalance						= SUM(CASE WHEN StatementTransactionType NOT IN ('Contract Charge Off','Non Contract Charge Off') THEN Principal ELSE 0 END)
	----RECEIVED---------------------------------------------------------------------------------------------------------------
		,PrincipalReceived				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
		,InterestReceived				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)
		,SvcFeePaid						= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)
		,ClxFeePaid						= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)
		,LateFeeReceived				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)
		,NSFFeeReceived					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)
		,CkFeeReceived					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN CheckPaymentFee ELSE 0 END)

		,PrincipalRecoveryReceived		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
		,InterestRecoveryReceived		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)
		,SvcFeeRecoveryPaid				= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)
		,ClxFeeRecoveryPaid				= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)
		,LateFeeRecoveryReceived		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)
		,NSFFeeRecoveryReceived			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)
		,CkFeeRecoveryReceived			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN CheckPaymentFee ELSE 0 END)
	----PENDING----------------------------------------------------------------------------------------------------------------
		,PrincipalPending				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
		,InterestPending				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)
		,SvcFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)
		,ClxFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)
		,LateFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)
		,NSFFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)
		,CkFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN CheckPaymentFee ELSE 0 END)

		,PrincipalRecoveryPending		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
		,InterestRecoveryPending		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)
		,SvcFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)
		,ClxFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)
		,LateFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)
		,NSFFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)
		,CkFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN CheckPaymentFee ELSE 0 END)
	----ADJUSTMENTS------------------------------------------------------------------------------------------------------------
		,PrincipalAdjustment			= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Principal ELSE 0 END)
		,InterestAdjustment				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Interest ELSE 0 END)
		,OtherAdjustment				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN (LateFee + NSFFee + CheckPaymentFee) ELSE 0 END)

		,RecoveryPrincipalAdjustment	= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Principal ELSE 0 END)
		,RecoveryInterestAdjustment		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Interest ELSE 0 END)
		,RecoveryOtherAdjustment		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN (LateFee + NSFFee + CheckPaymentFee) ELSE 0 END)
	FROM CTETransactionLevel
	GROUP BY
		LoanToLenderID
		,LoanNoteID
		,LenderID
)

/* Add Loan-Level Attributes and LoanDetail Data */
SELECT
	t.AsOfDate
	,t.LoanToLenderID
	,t.LenderID
	,u.UserAltKey
	,t.LoanNoteID
	,ln.LoanNoteDisplayName
	,ln.ProRataShare
	,ln.OwnershipShare
----LOAN ATTRIBUTES-------------------------------------------------------------------------------------------------
	,ln.LoanID
	,ln.ListingID
	,ln.ListingCategoryID
	,ln.ListingCategoryDesc
	,ln.OriginationDate
	,ln.AmortizationMonths
	,ln.OriginalAmountBorrowed
	,ProsperRating					= ln.RatingCode
	,ln.LoanProductID
	,ln.LoanProduct
	,li.InvestmentTypeID
	,li.InvestmentProductID
	,ln.InvestmentTypeName
	,ln.ServiceFeePercent
	,ldend.PaymentDayOfMonthDue
	,ldend.DefaultReasonID
	,ldend.DefaultReasonDesc
	,ldend.NextPaymentDueAmount
	,t2.AgencyQueueName
	,t2.IsCeaseAndDesist
	,ldend.IsAutoAchOff
	-------------------------
	,ldend.ExpectedMaturityDate
	,ln.StatedMaturityDate --NOTE: Different From Above?
	-------------------------
	,ln.ClosedDate
	,ldend.DateClosed --NOTE: Different From Above?
	-------------------------
	,ln.MonthlyPaymentAmount
	,ldend.ScheduledMonthlyPaymentAmount --NOTE: Different From Above?
	-------------------------
	,ldend.NextPaymentDueDate
	,SpectrumNextPaymentDueDate		= t2.NextPaymentDueDate --NOTE: Different From Above?
	-------------------------
	,ldend.AmountPastDue
	,t2.TotalPaymentsPastDueAmount --NOTE: Different From Above?
----BORROWER ATTRIBUTES---------------------------------------------------------------------------------------------
	,BorrowerID						= ln.BorrowerUserID
	,ln.BorrowerAPR
	,ln.BorrowerState
	,IsPriorBorrower				= CASE WHEN ln.PriorLoanCount > 0 THEN 1 ELSE 0 END
	,ln.IsSCRA
	,ln.SCRABeginDate
	,ln.SCRAEndDate
	,DecisionCreditScore			= ucp.Score
	,DecisionCreditScoreRange		=
									CASE
										WHEN CAST(ucp.Score AS INT) < 600 THEN '< 600'
										WHEN CAST(ucp.Score AS INT) >= 600 AND CAST(ucp.Score AS INT) < 620 THEN '600-619'
										WHEN CAST(ucp.Score AS INT) >= 620 AND CAST(ucp.Score AS INT) < 640 THEN '620-639'
										WHEN CAST(ucp.Score AS INT) >= 640 AND CAST(ucp.Score AS INT) < 660 THEN '640-659'
										WHEN CAST(ucp.Score AS INT) >= 660 AND CAST(ucp.Score AS INT) < 680 THEN '660-679'
										WHEN CAST(ucp.Score AS INT) >= 680 AND CAST(ucp.Score AS INT) < 700 THEN '680-699'
										WHEN CAST(ucp.Score AS INT) >= 700 AND CAST(ucp.Score AS INT) < 720 THEN '700-719'
										WHEN CAST(ucp.Score AS INT) >= 720 AND CAST(ucp.Score AS INT) < 740 THEN '720-739'
										WHEN CAST(ucp.Score AS INT) >= 740 AND CAST(ucp.Score AS INT) < 760 THEN '740-759'
										WHEN CAST(ucp.Score AS INT) >= 760 AND CAST(ucp.Score AS INT) < 780 THEN '760-779'
										WHEN CAST(ucp.Score AS INT) >= 780 AND CAST(ucp.Score AS INT) < 800 THEN '780-799'
										WHEN CAST(ucp.Score AS INT) >= 800 AND CAST(ucp.Score AS INT) < 820 THEN '800-819'
										WHEN CAST(ucp.Score AS INT) >= 820 AND CAST(ucp.Score AS INT) <= 850 THEN '820-850'
										ELSE 'N/A'
									END
	,DecisionCreditScoreDate		= ucp.CreditPullDate
	,DecisionCreditScoreVendor		= ucp.CreditBureauName
	,DecisionCreditScoreVendorID	= ucp.CreditBureauID
	,DecisionExternalReportID		= ucp.ExternalCreditReportId
	,RefreshCreditScore				= NULL
	,RefreshCreditScoreRange		= NULL
	,RefreshCreditScoreDate			= NULL
	,RefreshCreditScoreVendor		= NULL
	,ucp.MonthlyDebt
	,ucp.RealEstatePayment
----LOAN DETAIL-----------------------------------------------------------------------------------------------------
	--BEGGINING VALUES--
	,BegLoanStatusID				= ldbeg.LoanStatusTypesID
	,BegStatus						= ldbeg.LoanStatusDesc
	,BegDPD							= ldbeg.DPD
	,BegIntBal						= ldbeg.IntBal
	,BegBalDate						= ldbeg.BalDate
	,BegDaysforAccrual				= DATEDIFF(DD,ldbeg.BalDate,@BegPeriod)
	,BegIntBalDailyAccrual			= ldbeg.IntBalDailyAccrual
	,BegLateFeeBal					= ldbeg.LateFeeBal
	,BegNSFFeeBal					= ldbeg.NSFFeeBal
	,BegBorrowerStatedInterestRate	= ldbeg.BorrowerStatedInterestRate
	--ENDING VALUES--
	,EndLoanStatusID				= ldend.LoanStatusTypesID
	,EndStatus						= ldend.LoanStatusDesc
	,EndDPD							= ldend.DPD
	,EndBalDate						= ldend.BalDate
	,EndIntBal						= ldend.IntBal
	,EndDaysforAccrual				= DATEDIFF(DD,ldend.BalDate,@EndPeriod)
	,EndIntBalDailyAccrual			= ldend.IntBalDailyAccrual
	,EndLateFeeBal					= ldend.LateFeeBal
	,EndNSFFeeBal					= ldend.NSFFeeBal
	,EndBorrowerStatedInterestRate	= ldend.BorrowerStatedInterestRate
----SETTLEMENTS------------------------------------------------------------------------------------------------------------
	,t2.SettlementStartDate
	,t2.SettlementEndDate
	,t2.SettlementStatus
	,t2.SettlementBalAtEnrollment
	,t2.SettlementAgreedPmtAmt
	,t2.SettlementPmtCount
	,t2.SettlementFirstPmtDueDate
----EXTENSIONS------------------------------------------------------------------------------------------------------------
	,t2.ExtensionStatus
	,t2.ExtensionTerm
	,t2.ExtensionOfferDate
	,t2.ExtensionExecutionDate
----ACQUISITION/SALE-------------------------------------------------------------------------------------------------------------
	,t.PrinAcquired
	,t.DateAcquired
	,StatusAcquired				= CAST(t.StatusAcquired as TINYINT)
	,t.PrinSold
	,t.DateSold
	,StatusSold					= CAST(t.StatusSold AS TINYINT)
	,t.IsDebtSale
	,SaleGrossProceeds			= lot.SalePrice
	,SaleTransactionFee			= lot.SellerFees
	,SaleNetProceeds			= (lot.SalePrice - lot.SellerFees)
----CHARGE-OFFS-------------------------------------------------------------------------------------------------------------
	,IsContractChargeOff		= CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.IsContractChargeOff ELSE 0 END
	,IsNonContractChargeOff		= CASE WHEN ldend.LoanStatusTypesID IN (3) OR ldbeg.LoanStatusTypesID IN (3) THEN t.IsNonContractChargeOff ELSE 0 END
	,ChargeOffDate				= CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffDate END
	,ChargeOffPrincipal			= CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffPrincipal END
	,ChargeOffInterest			= CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffInterest END
	,ChargeOffLateFee			= CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffLateFee END
	,ChargeOffNSFFee			= CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffNSFFee END
	,BankruptcyFiledDate		= bk.DateOfFiling
	,BankruptcyStatus			= bk.BankruptcyStatusDesc
	,BankruptcyType				= bk.BankruptcyTypeDesc
	,BankruptcyStatusDate		= ISNULL(bk.DateOfNotification,bk.VersionStartDate)
----BEG/END BALANCE-------------------------------------------------------------------------------------------------------------
	,t.BegBalance
	,t.EndBalance
----RECEIVED-------------------------------------------------------------------------------------------------------------
	,t.PrincipalReceived
	,t.InterestReceived
	,t.SvcFeePaid
	,t.ClxFeePaid
	,t.LateFeeReceived
	,t.NSFFeeReceived
	,t.CkFeeReceived
	,t.PrincipalRecoveryReceived
	,t.InterestRecoveryReceived
	,t.SvcFeeRecoveryPaid
	,t.ClxFeeRecoveryPaid
	,t.LateFeeRecoveryReceived
	,t.NSFFeeRecoveryReceived
	,t.CkFeeRecoveryReceived
----PENDING-------------------------------------------------------------------------------------------------------------
	,t.PrincipalPending
	,t.InterestPending
	,t.SvcFeePending
	,t.ClxFeePending
	,t.LateFeePending
	,t.NSFFeePending
	,t.CkFeePending
	,t.PrincipalRecoveryPending
	,t.InterestRecoveryPending
	,t.SvcFeeRecoveryPending
	,t.ClxFeeRecoveryPending
	,t.LateFeeRecoveryPending
	,t.NSFFeeRecoveryPending
	,t.CkFeeRecoveryPending
----ADJUSTMENTS-------------------------------------------------------------------------------------------------------------
	,t.PrincipalAdjustment
	,t.InterestAdjustment
	,t.OtherAdjustment
	,t.RecoveryPrincipalAdjustment
	,t.RecoveryInterestAdjustment
	,t.RecoveryOtherAdjustment
--INTO #NoteLevel
--INTO Sandbox.[!!!].LenderPacketFunction
FROM CTELenderNoteLevelAggregates t
JOIN dbo.dm_loannote (NOLOCK) ln ON ln.LoanNoteID = t.LoanNoteID
JOIN dbo.dm_user (NOLOCK) u ON u.UserID = t.LenderID
LEFT JOIN dbo.dm_listing (NOLOCK) li ON li.ListingID = ln.ListingID
LEFT JOIN dbo.dw_usercreditprofiles (NOLOCK) ucp ON ucp.ListingID = ln.ListingID
	AND ucp.IsDecisionBureau = 1
LEFT JOIN dbo.dim_loan_type2 (NOLOCK) t2 ON t2.LoanID = ln.LoanID
	AND t2.VersionStartDate <= ISNULL(t.DateSold,@EndPeriod)				--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	AND t2.VersionEndDate > ISNULL(t.DateSold,@EndPeriod)					--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	--AND t2.IsCurrentRecord = 1
LEFT JOIN dbo.fact_loannote_ownership_transfer (NOLOCK) lot on lot.SellerLoanToLenderID = t.LoanToLenderID
	AND lot.SellerLoanToLenderID IS NOT NULL /* to hit filtered index */
LEFT JOIN dbo.fact_bankruptcy (NOLOCK) bk ON bk.LoanID = ln.LoanID
	AND bk.VersionStartDate < ISNULL(t.DateSold,@EndPeriod)					--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	AND bk.VersionEndDate >= ISNULL(t.DateSold,@EndPeriod)					--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
OUTER APPLY (
	SELECT TOP 1 *
	FROM dbo.dw_loandetail (NOLOCK) ldb
	WHERE ldb.LoanID = ln.LoanID
		AND ldb.AccountInformationDate < ISNULL(t.DateSold,@BegPeriod)		--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND ldb.VersionStartDate < ISNULL(t.DateSold,@BegPeriod)			--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	ORDER BY ldb.VersionStartDate DESC
) ldbeg
OUTER APPLY (
	SELECT TOP 1 *
	FROM dbo.dw_loandetail (NOLOCK) lde
	WHERE lde.LoanID = ln.LoanID
		AND lde.AccountInformationDate < ISNULL(t.DateSold,@EndPeriod)		--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
		AND lde.VersionStartDate < ISNULL(t.DateSold,@EndPeriod)			--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	ORDER BY lde.VersionStartDate DESC
) ldend

--/*
