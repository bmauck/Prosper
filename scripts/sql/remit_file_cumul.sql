

DECLARE @CutoffMin			DATETIME	= '3/4/2019'
DECLARE @CutoffMax			DATETIME	= '3/10/2019'
DECLARE @InvestorID			BIGINT		= 5513816 --3661300 (ECHELON) --3651887 (SOROS) --5513816 (BBVA) --2093353 (BLK) --2978229 (CCOLT) --5627124 (FORTRESS) --2263183 (COLCHIS)
DECLARE @LenderID			INT			= @InvestorID
DECLARE @AsOf				DATETIME	= @CutoffMax

IF OBJECT_ID('tempdb..#Remit') IS NOT NULL DROP TABLE #Remit
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* FULL XML OF PROD REPORT FOR THE PERIOD */
PRINT 'XML'
BEGIN
--DECLARE @XML TABLE (xmlData XML)
--INSERT INTO @XML
IF OBJECT_ID('tempdb..#XML') IS NOT NULL DROP TABLE #XML
SELECT CAST(xmlData AS XML) AS xmlData--, CreationDate = CAST(CreationDate AS DATE)  
INTO #XML
FROM C1.dbo.TransferMoneyHistoryOfXMLPreparedForWellsFargo
WHERE CreationDate >= @CutoffMin and CreationDate < @CutoffMax
	AND ID NOT IN (4463,4484,4741)
END

/* PARSE XML FROM PROD REPORT FOR THE PERIOD */
PRINT 'ParsedXML'
BEGIN
--DECLARE @ParsedXML TABLE (
--	OrigAcctID_Last4		VARCHAR(4)
--	,RcvAcctID_Last4		VARCHAR(4)
--	,PaymentID				VARCHAR(20)
--	,Amount					DECIMAL(38,2)
--	--,UNIQUE CLUSTERED (PaymentID,RcvAcctID_Last4)
--	)
--INSERT INTO @ParsedXML
IF OBJECT_ID('tempdb..#ParsedXML') IS NOT NULL DROP TABLE #ParsedXML
SELECT   
	--OrigAcctID_Last4	= RIGHT(b.value ('OrgnrDepAcctID[1]/DepAcctID[1]/@AcctID','varchar(max)'),4)
	--,RcvAcctID_Last4	= RIGHT(b.value ('RcvrDepAcctID[1]/DepAcctID[1]/@AcctID','varchar(max)'),4),
	PaymentID			= b.value ('PmtID[1]','Varchar(Max)')
	--,Amount				= b.value ('CurAmt[1]','Varchar(Max)')
	--,CreationDate
INTO #ParsedXML
FROM #XML
CROSS APPLY xmlData.nodes('/File/PmtRec') a(b)
END

/* STAGING ACCOUNT INFORMATION */
PRINT 'StagingFundingAccounts'
BEGIN
--DECLARE @StagingFundingAccounts TABLE (
--	AccountID			INT
--	,LenderID			INT
--	,LoanGroupID		SMALLINT
--	,HasStaging			TINYINT
--	)
--INSERT INTO @StagingFundingAccounts
IF OBJECT_ID('tempdb..#StagingFundingAccounts') IS NOT NULL DROP TABLE #StagingFundingAccounts
SELECT
	AccountID		= A.ID
	,LenderID		= A.UserID
	,LG.LoanGroupID
	,HasStaging		= CASE WHEN LG.StagingAccountCategory IS NULL THEN 0 ELSE 1 END 
INTO #StagingFundingAccounts
FROM C1.dbo.Accounts A
JOIN C1.dbo.LoanGroup LG ON A.Category = ISNULL(LG.StagingAccountCategory,LG.FundingAccountCategory)
	AND A.UserID = LG.UserID
UNION ALL
SELECT --LOANGROUP 25 AND 49 SHARE ACCOUNTS
	AccountID			= 92772544
	,LenderID			= 3637918
	,LoanGroupID		= 25
	,HasStaging			= 0
UNION ALL
SELECT --LOANGROUP 25 AND 49 SHARE ACCOUNTS
	AccountID			= 52712311
	,LenderID			= 4656385
	,LoanGroupID		= 49
	,HasStaging			= 0
END

/* ALL TR / TMQ RECORDS AGGREGATED FOR THE PERIOD */
PRINT 'TrTmq'
BEGIN
--;WITH CTETrTmq AS (
IF OBJECT_ID('tempdb..#TrTmq') IS NOT NULL DROP TABLE #TrTmq
SELECT
	TR.TransactionID
	,TMQ.PaymentID
	,TR.FromAccountID
	,TMQ.fromAccount
	,TR.ToAccountID
	,TMQ.toAccount
	,TMQ.amount
	,TMQ.CreationDate
	,TMQ.ProcessOnDate
	,TR.LoanID
INTO #TrTmq
FROM C1.dbo.TransferRequests TR
JOIN C1.dbo.TransferMoneyQueue TMQ ON CAST(TMQ.ID AS VARCHAR(20)) = TR.ConfirmationCode
JOIN #ParsedXML XM ON XM.PaymentID = TMQ.PaymentID
--WHERE @IsBankingDayToday = 1
--AND TMQ.PaymentID IN (SELECT DISTINCT PaymentID FROM #ParsedXML)
--AND (
--	TR.ToAccountID IN (SELECT AccountID FROM #StagingFundingAccounts WHERE LenderID = @LenderID)
--	OR 
--	TR.FromAccountID IN (SELECT AccountID FROM #StagingFundingAccounts WHERE LenderID = @LenderID)
--	)
--)
END




/* ALL REMIT TRANSACTION BUCKETS */
PRINT 'Remit'
BEGIN

/* REMIT FOR PAYMENTS */
SELECT
	PAY_ID						= LP.LoanPaymentID
	,LOAN_ID					= LP.LoanID --NL.LoanID
	,EXLOAN_ID					= CAST(LP.LoanID AS VARCHAR) + '-1' --NL.LoanNoteDisplayName
	,TRANSACTION_EFFECTIVE_DT	= CONVERT(VARCHAR,LP.TransactionEffectiveDate,101)
	,ACCOUNT_EFFECTIVE_DT		= CONVERT(VARCHAR,LP.AccountEffectiveDate,101)
	,PMT_TRANS_CODE				= LPT.code
	,PMT_STATUS					= LPOT.Code
	,MATCH_ID					= HASHBYTES('sha1','a$23nf' + CAST(LP.OntarioSPlitID AS VARCHAR(10)))
	,PRIOR_MATCH_ID				= HASHBYTES('sha1','a$23nf' + CAST(LP.OntarioPreviousSplitID AS VARCHAR(10)))
	,CASH_FLOW_TYPE				= LPCFT.Name
	,AmountSentToSTG			= TMQ.amount --CAST(TMQ.amount AS DECIMAL(38,2))
	,FirstDayINtValue			=	CASE WHEN LP.LoanPaymentCategoryID IN (1,4,6) --NOTE: All Categories for Payments (Non-Failures)
										THEN TMQ.amount - (
											CAST(	ISNULL(LPCF.LenderPrincipal,LP.Principal)							AS DECIMAL(8,2))
											+CAST(	ISNULL(LPCF.LenderInterest,LP.Interest)								AS DECIMAL(8,2))
											+CAST(	ISNULL(LPCF.LenderLateFee,LP.LateFees)								AS DECIMAL(8,2))
											-CAST(	ISNULL(-1*LPCF.LenderServiceFee,LP.LenderServicingFee)				AS DECIMAL(8,2))
											-CAST(	ISNULL(-1*LPCF.LenderCollectionFee,LP.CollectionFeesChargedLenders)	AS DECIMAL(8,2))
											)
										ELSE TMQ.amount + (
											CAST(	ISNULL(LPCF.LenderPrincipal,LP.Principal)							AS DECIMAL(8,2))
											+CAST(	ISNULL(LPCF.LenderInterest,LP.Interest)								AS DECIMAL(8,2))
											+CAST(	ISNULL(LPCF.LenderLateFee,LP.LateFees)								AS DECIMAL(8,2))
											-CAST(	ISNULL(-1*LPCF.LenderServiceFee,LP.LenderServicingFee)				AS DECIMAL(8,2))
											-CAST(	ISNULL(-1*LPCF.LenderCollectionFee,LP.CollectionFeesChargedLenders) AS DECIMAL(8,2))
											) 
									END
	,PMT_AMT					= LP.Amount
	,PRIN_AMT					= CAST(ISNULL(LPCF.LenderPrincipal,LP.Principal) AS DECIMAL (16,2))
	,INT_AMT					= CAST(ISNULL(LPCF.LenderInterest,LP.Interest) AS DECIMAL (16,2))
	,LATE_FEE_AMT				= CAST(ISNULL(LPCF.LenderLateFee,LP.LateFees) AS DECIMAL (16,2))
	,SVC_FEE_AMT				= CAST(ISNULL(-1*LPCF.LenderServiceFee,LP.LenderServicingFee) AS DECIMAL (16,2))
	,CLX_FEE_AMT				= CAST(ISNULL(-1*LPCF.LenderCollectionFee,LP.CollectionFeesChargedLenders) AS DECIMAL (16,2))
	,NSF_FEE_AMT				= CAST(ISNULL(LPCF.CompanyNSFFee,LP.NSFFees) AS DECIMAL (16,2))
	,RESULT_PRIN_BAL			= CAST(LP.ResultingPrinBal AS DECIMAL (16,2))
	,LOAN_PAYMENT_CATEGORY		= LPC.Code
	,INT_RATE					= LD.BorrowerStatedInterestRate
	,MNTHLY_PMT_AMT				= LD.ScheduledMonthlyPaymentAmount
	,AsOf						= FORMAT(DATEADD(MS,-2,@AsOf),'yyyy-MM-dd HH:mm:ss')
	,CHECK_FEE_AMT				= CAST(ISNULL(LPCF.CheckPaymentFee,LP.CheckPaymentFee) AS DECIMAL (16,2))
FROM C1.dbo.LoanPaymentRecipient LPR
JOIN C1.dbo.LoanPayment LP ON LP.LoanPaymentID = LPR.LoanPaymentID 
	AND LPR.LenderID = @LenderID
JOIN C1.dbo.LoanDetail LD ON LD.LoanID = LP.LoanID
	AND LD.VersionValidBit = 1
	AND LD.VersionEndDate IS NULL
JOIN C1.dbo.LoanPaymentType LPT ON LPT.LoanPaymentTypeID = LP.LoanPaymentTypeID
JOIN C1.dbo.LoanPaymentOutcomeType LPOT ON LPOT.LoanpaymentOutcomeTypeID = LP.LoanPaymentOutcometypeID  
JOIN C1.dbo.LoanPaymentCategory LPC ON LPC.LoanPaymentCategoryID = LP.LoanPaymentCategoryID
JOIN C1.dbo.LoanPaymentCashflow LPCF ON LPCF.LoanPaymentCashflowID = LPR.LoanPaymentCashflowID
JOIN C1.dbo.LoanPaymentCashflowType LPCFT ON LPCFT.LoanPaymentCashflowTypeID = LPCF.LoanPaymentCashflowTypeID
JOIN #TrTmq TMQ ON TMQ.TransactionID = LPCF.LedgerTransactionID
--JOIN #NoteLevel NL ON NL.LoanToLenderID = LPR.LoanToLenderID
--WHERE @IsBankingDayToday = 1
	/* Filter Transactions for @LenderID Staging Accounts */
	WHERE (
		TMQ.ToAccountID IN (SELECT AccountID FROM #StagingFundingAccounts WHERE LenderID = @LenderID)
		OR 
		TMQ.FromAccountID IN (SELECT AccountID FROM #StagingFundingAccounts WHERE LenderID = @LenderID)
		)

--/*
UNION --ALL

/* REMIT FOR NON-PAYMENTS */
SELECT
	PAY_ID						= NULL
	,LOAN_ID					= LC.LoanID --NL.LoanID
	,EXLOAN_ID					= CAST(LC.LoanID AS VARCHAR) + '-1' --NL.LoanNoteDisplayName
	,TRANSACTION_EFFECTIVE_DT	= CONVERT(VARCHAR,LC.AvailableDate,101)
	,ACCOUNT_EFFECTIVE_DT		= CONVERT(VARCHAR,LC.AvailableDate,101)
	,PMT_TRANS_CODE				= CASE LC.EntryTypeCode 
		WHEN 104 THEN 'Net Pre-Purchase Interest'
		WHEN 132 THEN 'Origination Fee Rebate'
		WHEN 118 THEN 'Debt Sale Net Proceeds'
		END
	,PMT_STATUS					= 'Success'
	,MATCH_ID					= NULL
	,PRIOR_MATCH_ID				= NULL
	,CASH_FLOW_TYPE				= CASE LC.EntryTypeCode 
		WHEN 104 THEN 'ChargeBack'
		WHEN 132 THEN 'Money'
		WHEN 118 THEN 'Debt Sale'
		END
	,AmountSentToSTG			= TMQ.amount --CAST(TMQ.amount AS DECIMAL(38,2))
	,FirstDayINtValue			= 0 --CASE WHEN LC.EntryTypeCode IN (104,132) THEN NL.IntBalDailyAccrual ELSE 0 END
	,PMT_AMT					= 0
	,PRIN_AMT					= 0
	,INT_AMT					= 0
	,LATE_FEE_AMT				= 0
	,SVC_FEE_AMT				= 0
	,CLX_FEE_AMT				= 0
	,NSF_FEE_AMT				= 0
	,RESULT_PRIN_BAL			= 0
	,LOAN_PAYMENT_CATEGORY		= CASE LC.EntryTypeCode 
		WHEN 104 THEN 'Reversal'
		WHEN 132 THEN 'Reversal'
		WHEN 118 THEN 'Debt Sale'
		END
	,INT_RATE					= LD.BorrowerStatedInterestRate
	,MNTHLY_PMT_AMT				= LD.ScheduledMonthlyPaymentAmount
	,AsOf						= FORMAT(DATEADD(MS,-2,@AsOf),'yyyy-MM-dd HH:mm:ss')
	,CHECK_FEE_AMT				= 0
FROM C1.dbo.LedgerCategory32100 LC
JOIN C1.dbo.Accounts A ON A.ID = LC.AccountID
JOIN #TrTmq TMQ ON TMQ.TransactionID = LC.TransactionID
JOIN C1.dbo.LoanDetail LD ON LD.LoanID = LC.LoanID
	AND LD.VersionValidBit = 1
	AND LD.VersionEndDate IS NULL
--JOIN #NoteLevel NL ON NL.LoanID = LC.LoanID --NOTE: JOIN ON LOANTOLENDERID WILL NOT WORK FOR THESE TXNS
	--AND NL.LenderID = A.UserID
WHERE A.UserID = @LenderID
		/* Filter Transactions for @LenderID Staging Accounts */
	AND (
		TMQ.ToAccountID IN (SELECT AccountID FROM #StagingFundingAccounts WHERE LenderID = @LenderID)
		OR 
		TMQ.FromAccountID IN (SELECT AccountID FROM #StagingFundingAccounts WHERE LenderID = @LenderID)
		)
    AND (
		/*Net Pre-Purchase Interest*/
		(LC.EntryTypeCode = 104 AND LC.CreditOrDebit = 'D'  --NOTE: THIS SHOULD ONLY EVER RETURN ONE VALUE PER LOAN
			AND TMQ.toAccount = 'OrigIntFeeAccount'
			AND TMQ.fromAccount <> 'PflOneDayInterestFeeZBA'
		) 		
		/*Origination Fee Rebate*/
		OR (LC.EntryTypeCode = 132 AND LC.CreditOrDebit = 'C'  --NOTE: THIS SHOULD ONLY EVER RETURN ONE VALUE PER LOAN
			AND TMQ.fromAccount = 'PlatformFeesAccount'
		)
		/*Debt Sale Net Proceeds*/
		OR (LC.EntryTypeCode = 118 AND LC.CreditOrDebit = 'C'  --NOTE: THIS SHOULD ONLY EVER RETURN ONE VALUE PER LOAN
			AND TMQ.LoanID IS NOT NULL
			AND TMQ.ToAccountID <> 11
			AND TMQ.toAccount <> 'LenderServiceFeeAccount'
			AND TMQ.toAccount <> 'OrigIntFeeAccount' --NOTE: THIS ACCOUNT REQUIRES ONE MORE BUSINESS DAY UNTIL THE FUNDS MOVE
		)
	) --*/

END