SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH

Declare 
@InvestorID		INT			= {}
,@CutoffMin		DATETIME	= '{}'
,@CutoffMax		DATETIME	= '{}'
,@LoanID		INT			= {}

DECLARE @AsOf				DATETIME	= DATEADD(MS,-2,@CutoffMax) --AsOf IS JUST BEFORE MIDNIGHT OF THE ENDPERIOD (FILE CREATION DATE)

BEGIN

/* CREATE A TEMP LEDGER, AGGREGATE AMOUNTS FOR EACH TRANSACTIONID */
;WITH CTETransactions (TransactionID, FundsAvailableDate, LedgerDeposit, LedgerWithdrawal)
AS
(
	SELECT 
		LC.TransactionID
		,FundsAvailableDate = LC.AvailableDate
		,LedgerDeposit		= SUM(CASE WHEN LC.CreditorDebit = 'C' THEN LC.Amount END)
		,LedgerWithdrawal	= SUM(CASE WHEN LC.CreditorDebit = 'D' THEN LC.Amount END)
	FROM C1.dbo.LedgerCategory32100 LC
	JOIN C1.dbo.Accounts A ON A.ID = LC.AccountID
		AND A.UserID = @InvestorID
	GROUP BY LC.TransactionID, LC.AvailableDate
)

SELECT
	LC.TransactionID
	--,LP.LoanPaymentID
	,LoanNumber					= LTL.LoanID
	,LoanNoteID					= CAST(LO.LoanID AS VARCHAR) + '-' + CAST(LN.SeqNo AS VARCHAR)
	,FundsAvailableDate			= FORMAT(LC.FundsAvailableDate,'yyyy-MM-dd HH:mm:ss')
	,InvestorDisbursement		= FORMAT(LPC.DisbursementDate,'yyyy-MM-dd HH:mm:ss')
	,TransactionEffectiveDate	= FORMAT(LP.TransactionEffectiveDate,'yyyy-MM-dd HH:mm:ss')
	,AccountEffectiveDate		= FORMAT(LP.AccountEffectiveDate,'yyyy-MM-dd HH:mm:ss')
	,PaymentTransactionCode		= LPT.Code
	,PaymentStatus				= LPOT.Code
	,MatchBackID				= HASHBYTES('sha1','a$23nf' + CAST(LP.OntarioSplitID AS VARCHAR(10)))
	,PriorMatchBackID			= HASHBYTES('sha1','a$23nf' + CAST(LP.OntarioPreviousSplitID AS VARCHAR(10)))
	,LoanPaymentCashflowType	= LPCT.Name
	,LC.LedgerDeposit
	,LC.LedgerWithdrawal
	,PaymentAmount				= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(LP.Amount AS FLOAT)															AS MONEY)
	,PrincipalAmount			= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(ISNULL(LPC.LenderPrincipal,LP.Principal) AS FLOAT)								AS MONEY)
	,InterestAmount				= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(ISNULL(LPC.LenderInterest,LP.Interest) AS FLOAT)								AS MONEY)
	,OriginationInterestAmount	= 0
	,LateFeeAmount				= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(ISNULL(LPC.LenderLatefee,LP.LateFees) AS FLOAT)								AS MONEY)
	,ServiceFeeAmount			= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(ISNULL(LPC.CompanyServiceFee,LP.LenderServicingFee) AS FLOAT)					AS MONEY)
	,CollectionFeeAmount		= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(ISNULL(LPC.LenderCollectionFee,LP.CollectionFeesChargedLenders) AS FLOAT)		AS MONEY)
	,GLRewardAmount				= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(ISNULL(LPC.GLReward,LP.GLRewardLenders) AS FLOAT)								AS MONEY)
	,NSFFeeAmount				= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(ISNULL(LPC.CompanyNSFFee,LP.NSFFees) AS FLOAT)									AS MONEY)
	,PreDaysPastDue				= LP.PreDPD
	,PostDaysPasDue				= LP.PostDPD --NOTE: USED TO BE PostDaysPasDue
	,ResultingPrincipalBalance	= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(LP.ResultingPrinBal AS FLOAT)													AS MONEY)
	,LP.IsChargeoffRecovery
	,AsOf						= FORMAT(@AsOf,'yyyy-MM-dd HH:mm:ss')
	,PurchaseDate				= FORMAT(LTL.OwnershipStartDate,'yyyy-MM-dd HH:mm:ss')
	,CheckFeeAmount				= CAST(		(CAST(LTL.Amount AS FLOAT) / CAST(LO.OriginalAmountBorrowed AS FLOAT))	*	CAST(ISNULL(LPC.CheckPaymentFee,LP.CheckPaymentFee) AS FLOAT)						AS MONEY)
	--,LP.CreatedDate
	--,LP.ModifiedDate
--INTO #Payments
--INTO Sandbox.[!!!].Payments_20160330
--DROP TABLE Sandbox.[!!!].Payments_20160330
FROM C1.dbo.LoanPayment LP 
JOIN C1.dbo.LoanPaymentOutcomeType LPOT ON LPOT.LoanpaymentOutcomeTypeID = LP.LoanPaymentOutcometypeID
JOIN C1.dbo.Loans LO ON LO.LoanID = LP.LoanID
JOIN C1.dbo.LoanToLender LTL ON LTL.LoanID = LP.LoanID
	--AND LP.AccountEffectiveDate >= LTL.OwnershipStartDate --TODO: THIS WILL NEED TO BE ADDED ONCE WE ROLL BACK THE LTL/LOT DATA --NOTE: THIS ALLOWS FOR GENERATING HISTORICAL FILES ACCURATELY
	AND (LP.AccountEffectiveDate < LTL.OwnershipEndDate OR LTL.OwnershipEndDate IS NULL)
JOIN C1.dbo.LoanNote LN ON LN.LoanNoteID = LTL.LoanNoteID
JOIN C1.dbo.LoanPaymentType LPT ON LPT.LoanPaymentTypeID = LP.LoanPaymentTypeID
LEFT JOIN C1.dbo.LoanPaymentCashflow LPC ON LPC.LoanPaymentID = LP.LoanPaymentID
LEFT JOIN C1.dbo.LoanPaymentCashflowType LPCT ON LPCT.LoanPaymentCashflowTypeID = LPC.LoanPaymentCashflowTypeID
LEFT JOIN CTETransactions LC ON LC.TransactionID = LPC.LedgerTransactionID
WHERE 1=1
	AND LTL.LenderID = @InvestorID
	AND LP.AccountEffectiveDate < @CutoffMax
	AND LP.CreatedDate < @CutoffMax --NOTE: Keep Late-Synching Payments from Historical Day(s)
/* FIRST WE WANT PAYMENTS POSTED (EFFECTIVE) ON THIS SYSTEM DATE BUT POSSIBLY MODIFIED THE NIGHT BEFORE (EOD PAYMENTS POSTED FOR NEXT DAY) */
	AND (	(LP.AccountEffectiveDate >= @CutoffMin)
/* SECOND WE WANT PAYMENTS MODIFIED ON THIS CALENDAR DATE BUT REMOVE PAYMENTS MEANT FOR THE NEXT SYSTEM DATE (EOD PAYMENTS POSTED FOR NEXT DAY) */
			OR 
			(LP.ModifiedDate >= @CutoffMin AND LP.ModifiedDate < @CutoffMax)
		)
	AND lp.LoanID = @LoanID
ORDER BY 6 DESC, 7 DESC

END