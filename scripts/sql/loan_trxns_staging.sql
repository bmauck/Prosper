DECLARE @CutoffMin	DATETIME	= '{}'
DECLARE @CutoffMax	DATETIME	= '{}'
DECLARE @InvestorID	BIGINT		= {}
DECLARE @LoanID		INT			= {}

DECLARE @AsOf DATETIME = DATEADD(MS,-2,@CutoffMax) --AsOf is just before Midnight of the @EndPeriod (File Creation Date)
DECLARE @PriorBalance MONEY, @PriorRecord BIGINT

/***************************** PRIOR DAYS *****************************/
IF OBJECT_ID('tempdb..#Prior') IS NOT NULL DROP TABLE #Prior
SELECT 
	PriorBalance = SUM(CASE WHEN lc.CreditOrDebit = 'C' THEN lc.Amount ELSE -lc.Amount END)
	,PriorRecord = COUNT(*)
INTO #Prior
FROM C1.dbo.LedgerCategory32100 lc
JOIN C1.dbo.Accounts a ON a.ID = lc.AccountID
	AND a.Category = 32100
WHERE a.UserID = @InvestorID 
	AND lc.AvailableDate < @CutoffMin
GROUP BY lc.TransactionID
	,lc.AvailableDate
	,lc.EntryTypeCode

SELECT
	@PriorBalance = SUM(PriorBalance)
	,@PriorRecord = COUNT(*)
FROM #Prior

/***************************** BIDS *****************************/
IF OBJECT_ID('tempdb..#Bids') IS NOT NULL DROP TABLE #Bids
SELECT 
	b.ID
	,b.AltKey
	,ListingID = li.ID
	,li.[Status]
	,lo.LoanID
	,lc32.TransactionID
	,lc32.EntryTypeCode
	,b.UserID
INTO #Bids
FROM C1.dbo.LedgerCategory32100 lc32
JOIN C1.dbo.LedgerCategory31100 lc31 ON lc31.TransactionID = lc32.TransactionID
JOIN C1.dbo.Listings li ON li.AccountID = lc31.AccountID
JOIN C1.dbo.Bids b ON b.ListingID = li.ID
JOIN C1.dbo.Accounts a ON a.ID = lc32.AccountID
	AND a.UserID = b.UserID
	AND a.Category = 32100
LEFT JOIN C1.dbo.Loans lo ON li.LoanID = lo.LoanID
WHERE b.userID = @InvestorID
	AND lc32.EntryTypeCode IN (16,17)
	AND lc32.AvailableDate >= @CutoffMin
	AND lc32.AvailableDate < @CutoffMax

/*********************** PRE-PURCHASE INTEREST ***********************/
IF OBJECT_ID('tempdb..#PrePurchInterest') IS NOT NULL DROP TABLE #PrePurchInterest
SELECT
	lc.TransactionID
	,lc.LoanID
	,LoanNoteID = CAST(ln.LoanID AS VARCHAR) + '-' + CAST(ln.SeqNo AS VARCHAR)
INTO #PrePurchInterest
FROM C1.dbo.LedgerCategory32100 lc
JOIN C1.dbo.Accounts a ON lc.AccountID = a.ID
	AND a.Category = 32100
JOIN C1.dbo.Loantolender ltl ON ltl.LoanID  = lc.LoanID
	AND ltl.LenderID = a.UserID
	AND ltl.OwnershipEndDate IS NULL 
JOIN C1.dbo.LoanNote ln ON ln.LoanNoteID = ltl.LoanNoteID 
WHERE a.UserID = @InvestorID 
	AND lc.EntryTypeCode = 104
	AND lc.CreditOrDebit = 'D'   
	AND lc.AvailableDate >= @CutoffMin
	AND lc.AvailableDate < @CutoffMax

/*********************** LEDGER TRANSACTIONS ***********************/
IF OBJECT_ID('tempdb..#Ledger') IS NOT NULL DROP TABLE #Ledger
SELECT
	a.UserID
	,lc.TransactionID
	,lc.EntryTypeCode
	,et.Memo
	,lc.CreditOrDebit
	,lc.Amount
	,lc.AvailableDate
	,LoanNoteID					= CAST(ln.LoanID AS VARCHAR) + '-' + CAST(ln.SeqNo AS VARCHAR)
	,ProRataShare				= CAST(ltl.Amount AS DECIMAL(20,10))	/	CAST(lo.OriginalAmountBorrowed AS DECIMAL(20,10))
	,lpcf.LenderPrincipal
	,lpcf.LenderInterest
INTO #Ledger
FROM C1.dbo.LedgerCategory32100 lc
JOIN C1.dbo.Accounts a ON a.ID = lc.AccountID
	AND a.Category = 32100
JOIN C1.dbo.EntryTypes et ON et.Code = lc.EntryTypeCode
LEFT JOIN C1.dbo.LoanToLender ltl ON ltl.ID = lc.LoantolenderID --NOTE: This has to be left join since pending bids will not show up on Loan to Lender
LEFT JOIN C1.dbo.Loans lo ON lo.LoanID = ltl.LoanID 
LEFT JOIN C1.dbo.LoanPaymentCashflow lpcf ON lpcf.LedgerTransactionID = lc.TransactionID 
LEFT JOIN C1.dbo.LoanNote ln ON ln.LoanNoteID = ltl.LoanNoteID  --NOTE: This has to be Left join for those bids that are pending and cash that moves not associated with a Loan
WHERE 
	1=1 
	AND lc.LoanID = @LoanID
	AND a.UserID = @InvestorID
	AND lc.AvailableDate >= @CutoffMin
	AND lc.AvailableDate < @CutoffMax

IF OBJECT_ID('tempdb..#AggregateLedger') IS NOT NULL DROP TABLE #AggregateLedger
SELECT
	[Row]						= ROW_NUMBER() OVER (PARTITION BY UserID ORDER BY AvailableDate, EntryTypeCode)
	,UniqueInvestorID			= UserID
	,TransactionID
	,AvailableDate
	,TransactionType			= EntryTypeCode
    ,TransactionDescription		= CASE WHEN EntryTypeCode <> 104 THEN Memo ELSE 'Net Pre-Purchase Interest' END
	,LoanNoteID
    ,NetAmount					= SUM(CASE WHEN CreditOrDebit = 'C' THEN Amount ELSE -Amount END)
								  /* Principal/Interest for Note payment, Note payment chargeback, Payment recovery, Payment recovery dispute, Promotional credit, Customer relations credit */
    ,PrincipalAmount			= SUM(ISNULL(CASE WHEN EntryTypeCode IN (73,74,60,61,81,82) THEN ProRataShare * CAST(LenderPrincipal AS DECIMAL(20,10)) ELSE 0 END,0))
	,InterestAmount				= SUM(ISNULL(CASE WHEN EntryTypeCode IN (73,74,60,61,81,82) THEN ProRataShare * CAST(LenderInterest AS DECIMAL(20,10)) ELSE 0 END,0))
INTO #AggregateLedger
FROM #Ledger
GROUP BY
	UserID
	,TransactionID
	,AvailableDate
	,EntryTypeCode
    ,Memo 
	,LoanNoteID
ORDER BY 1 DESC

IF OBJECT_ID('tempdb..#Aggregated') IS NOT NULL DROP TABLE #Aggregated
CREATE TABLE #Aggregated (
	[Row]			INT PRIMARY KEY
	,NetAmount		MONEY
	,RunningCash	MONEY
)

DECLARE @Row INT, @NetAmount MONEY, @RunningCash MONEY = 0

DECLARE rt_cursor CURSOR
FOR
	SELECT [Row], NetAmount
	FROM #AggregateLedger
	ORDER BY [Row]

OPEN rt_cursor

FETCH NEXT FROM rt_cursor INTO @Row, @NetAmount

WHILE @@FETCH_STATUS = 0 
BEGIN
	SET @RunningCash = @RunningCash + @NetAmount
	INSERT #Aggregated VALUES(@Row, @NetAmount, @RunningCash)
	FETCH NEXT FROM rt_cursor INTO @Row, @NetAmount
END

CLOSE rt_cursor
DEALLOCATE rt_cursor
