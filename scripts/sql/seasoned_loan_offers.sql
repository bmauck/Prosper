use DW

DECLARE @EndPeriod	DATETIME = '08/23/2018'

IF OBJECT_ID('tempdb..#NoteLevel') IS NOT NULL DROP TABLE #NoteLevel
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* Seasoning account only, current loans only. Exclude final paymennts in-process */
IF OBJECT_ID('tempdb..#Loans') IS NOT NULL DROP TABLE #Loans
BEGIN
CREATE TABLE #Loans (LoanID INT)
INSERT INTO #Loans
	select ltl.loanid 
	from c1..loantolender ltl 	
	join c1..loandetail ld on ld.loanid = ltl.loanid
		and ld.versionenddate is null and ld.versionvalidbit = 1
	where ltl.lenderid = 4320761
	and ld.loanstatustypesid = 1
	and ltl.ownershipenddate is null
END

/* ALL LOANS + TRANSACTIONS THROUGH @EndPeriod */
IF OBJECT_ID('tempdb..#TransactionLevel') IS NOT NULL DROP TABLE #TransactionLevel
SELECT
	L.LoanID
	,PendingDate
	,CompletedDate
	,Principal
	,Interest
	,SvcFee
	,ClxFee
	,LateFee
	,NSFFee
----GROUPING-----------------------------------------------------------------------------------------------------------------
	,StatementTransactionType
	,AdjustmentFlag
	,[Status]
----TIMING-------------------------------------------------------------------------------------------------------------------
	,CompletedPeriod = CASE WHEN (CompletedDate >= @EndPeriod OR CompletedDate IS NULL) THEN 'Not Completed' ELSE 'Completed' END
INTO #TransactionLevel
FROM DW.dbo.dw_loantolender_transaction (NOLOCK) LTL
JOIN #Loans L ON L.LoanID = LTL.LoanID
WHERE 1=1
	--AND (LenderID = @LenderID)
	AND LenderID NOT IN (7,5065092)
	AND PendingDate < @EndPeriod

/* AGGREGATED BY LOANID: BEGSTATUS,ENDSTATUS,ACQUIRED,SOLD,CHARGE-OFF,BEGBAL,ENDBAL,PAYMENTS-RECEIVED,PAYMENTS-PENDING,ADJUSTMENTS */
IF OBJECT_ID('tempdb..#LoanLevelAggregates') IS NOT NULL DROP TABLE #LoanLevelAggregates
SELECT
	AsOfDate						= DATEADD(MS,-2,@EndPeriod) --AsOf IS JUST BEFORE MIDNIGHT OF THE ENDPERIOD (FILE CREATION DATE)
	,LoanID
----ACQUISITION/SALE-------------------------------------------------------------------------------------------------------
	,DateSold						= MAX(CASE WHEN StatementTransactionType IN ('Sale','DebtSale') THEN PendingDate ELSE NULL END)
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
	,EndBalance						= SUM(CASE WHEN StatementTransactionType NOT IN ('Contract Charge Off','Non Contract Charge Off') THEN Principal ELSE 0 END)
----RECEIVED---------------------------------------------------------------------------------------------------------------
	,PrincipalReceived				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
	,InterestReceived				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)
	,SvcFeePaid						= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)
	,ClxFeePaid						= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)
	,LateFeeReceived				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)
	,NSFFeeReceived					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)
	,PrincipalRecoveryReceived		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
	,InterestRecoveryReceived		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)
	,SvcFeeRecoveryPaid				= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)
	,ClxFeeRecoveryPaid				= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)
	,LateFeeRecoveryReceived		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)
	,NSFFeeRecoveryReceived			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)
----PENDING----------------------------------------------------------------------------------------------------------------
	,PrincipalPending				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
	,InterestPending				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)
	,SvcFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)
	,ClxFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)
	,LateFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)
	,NSFFeePending					= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)
	,PrincipalRecoveryPending		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
	,InterestRecoveryPending		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)
	,SvcFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)
	,ClxFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)
	,LateFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)
	,NSFFeeRecoveryPending			= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)
----ADJUSTMENTS------------------------------------------------------------------------------------------------------------
	,PrincipalAdjustment			= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Principal ELSE 0 END)
	,InterestAdjustment				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Interest ELSE 0 END)
	,OtherAdjustment				= SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN (LateFee + NSFFee) ELSE 0 END)
	,RecoveryPrincipalAdjustment	= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Principal ELSE 0 END)
	,RecoveryInterestAdjustment		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Interest ELSE 0 END)
	,RecoveryOtherAdjustment		= SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN (LateFee + NSFFee) ELSE 0 END)
INTO #LoanLevelAggregates
FROM #TransactionLevel
GROUP BY LoanID

IF OBJECT_ID('tempdb..#SeasonedLoanSale') IS NOT NULL DROP TABLE #SeasonedLoanSale
--/* ADD LOAN-LEVEL ATTRIBUTES
SELECT
	t.AsOfDate
	,ListingNumber = dl.listingid
	,lo.OriginationDate
	,ltl.LoanNoteID
	,LoanNumber = t.LoanID
	,LoanAmount = lo.OriginalAmountBorrowed
	,PrincipalBalance = t.EndBalance
    ,InProcessPrincipalPayments	= -1 * (t.PrincipalPending + t.PrincipalRecoveryPending)
	,InProcessInterestPayments	= -1 * (t.InterestPending + t.InterestRecoveryPending)
	,InProcessSvcFeePayments	=  1 * (t.SvcFeePending + t.SvcFeeRecoveryPending)
	,AccruedInterest			=	CAST(
											CASE
												WHEN ldend.LoanStatusTypesID IN (0,1) AND ISNULL( ldend.IntBal + (ldend.IntBalDailyAccrual * DATEDIFF(DD,ldend.BalDate,@EndPeriod) ),0.00) > 0 /* NOTE: ACCRUE FOR CURRENT NOTES */
													THEN ISNULL( ldend.IntBal + (ldend.IntBalDailyAccrual * DATEDIFF(DD,ldend.BalDate,@EndPeriod) ),0.00)
												ELSE ldend.IntBal --0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
											END
										AS DECIMAL(20,10))
	,AccruedSvcFee				=	CAST(
											CASE
												WHEN ldend.LoanStatusTypesID IN (0,1) AND ISNULL( ldend.IntBal + (ldend.IntBalDailyAccrual * DATEDIFF(DD,ldend.BalDate,@EndPeriod) ),0.00) > 0 /* NOTE: ACCRUE FOR CURRENT NOTES */
													THEN ISNULL( ldend.IntBal + (ldend.IntBalDailyAccrual * DATEDIFF(DD,ldend.BalDate,@EndPeriod) ),0.00)
												ELSE ldend.IntBal --0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
											END
											*
											ISNULL( CAST(ln.ServiceFeePercent AS DECIMAL(20,10)) / CAST(NULLIF(ldend.BorrowerStatedInterestRate,0) AS DECIMAL(20,10)) , 0.00)
										AS DECIMAL(20,10))
	,LoanStatus = ldend.LoanStatusDesc
	,dl.ratingcode
	,dl.term
	,MaturityDate				= FORMAT(ldend.ExpectedMaturityDate,'yyyy-MM-dd HH:mm:ss')
	,ldend.NextPaymentDueDate
	,FirstScheduledPayment		= FORMAT(DATEADD(MM,1,lo.OriginationDate),'yyyy-MM-dd HH:mm:ss')
	,IsSold						= CAST(CASE WHEN t.DateSold IS NOT NULL THEN 1 ELSE 0 END AS BIT)
	,MonthlyPaymentAmount = ld.ScheduledMonthlyPaymentAmount
	,FICOScore		            =	
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
	,dl.BorrowerState
	,Title = dl.listingcategoryname
	,CurrentDTI = dl.borrowerdti
	,CurrentRate = dl.borrowerinterestrate
	,dl.BorrowerAPR
	,EstimatedLoss = dl.estimatedannualizedlossrate
INTO #SeasonedLoanSale
FROM #LoanLevelAggregates t
LEFT JOIN (
	SELECT LoanID, ServiceFeePercent = MAX(ServiceFeePercent), OriginalAmountBorrowed = MAX(OriginalAmountBorrowed)
	FROM DW.dbo.dm_loannote (NOLOCK)
	GROUP BY LoanID
) ln ON ln.LoanID = t.LoanID
LEFT JOIN DW.dbo.dw_loandetail (NOLOCK) ldend ON ldend.LoanID = t.LoanID
	AND ldend.VersionStartDate IN (
		SELECT MAX(ld2.VersionStartDate)
		FROM DW.dbo.dw_loandetail (NOLOCK) ld2
		WHERE ld2.AccountInformationDate < @EndPeriod
			AND ld2.VersionStartDate < @EndPeriod
			AND ld2.LoanID = t.LoanID
	)
LEFT JOIN (
	SELECT LoanID,SalePrice = SUM(SalePrice),SellerFees = SUM(SellerFees)
	FROM DW.dbo.fact_loannote_ownership_transfer (NOLOCK)
	WHERE SellerLoanToLenderID IS NOT NULL /* to hit filtered index */
	GROUP BY LoanID
) lot on lot.LoanID = t.LoanID
LEFT JOIN dbo.dim_loan_type2 (NOLOCK) t2 ON t2.LoanID = ln.LoanID
	AND t2.VersionStartDate <= ISNULL(t.DateSold,@EndPeriod)				--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	AND t2.VersionEndDate > ISNULL(t.DateSold,@EndPeriod)					--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
LEFT JOIN dbo.fact_bankruptcy (NOLOCK) bk ON bk.LoanID = ln.LoanID
	AND bk.VersionStartDate < ISNULL(t.DateSold,@EndPeriod)					--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
	AND bk.VersionEndDate >= ISNULL(t.DateSold,@EndPeriod)					--NOTE: THIS WILL STALE UPDON THE DATE OF SALE
LEFT JOIN c1..loantolender ltl on ltl.loanid = ldend.loanid and ltl.OwnershipEndDate is null
JOIN c1..loans lo on lo.loanid = ltl.loanid
JOIN dbo.dm_listing dl ON dl.ListingID = lo.ListingID
LEFT JOIN dbo.dw_usercreditprofiles (NOLOCK) ucp ON ucp.ListingID = dl.ListingID
	AND ucp.IsDecisionBureau = 1
LEFT JOIN (
	SELECT loanid, scheduledmonthlypaymentamount
	FROM c1..loandetail
	WHERE versionenddate is null
	AND versionvalidbit = 1) ld on ld.loanid = lo.loanid

select 
*
,PurchasePrice = round((principalbalance+accruedinterest-accruedsvcfee),2)
from #SeasonedLoanSale
order by OriginationDate

select sum(PrincipalBalance) 
from 
#SeasonedLoanSale