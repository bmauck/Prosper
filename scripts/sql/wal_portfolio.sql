DECLARE @BegPeriod   DATETIME      = dateadd(DD,-1,getdate())
DECLARE @EndPeriod   DATETIME      = getdate()
DECLARE @LenderID    INT           =  5513816

IF OBJECT_ID('tempdb..#WALLevel1') IS NOT NULL DROP TABLE #WALLevel1
SELECT
LoanToLenderID
,LoanNoteID
,LenderID
,PendingDate
,CompletedDate
,Principal
,StatementTransactionType
,AdjustmentFlag
,[Status]
,PendingPeriod = CASE WHEN PendingDate >= @BegPeriod AND PendingDate < @EndPeriod THEN 'Pending This Period' ELSE 'Pending Prior Period' END  
,CompletedPeriod = CASE WHEN CompletedDate < @BegPeriod THEN 'Completed Prior Period' WHEN CompletedDate >= @BegPeriod AND CompletedDate < @EndPeriod THEN 'Completed This Period' WHEN (CompletedDate >= @EndPeriod OR CompletedDate IS NULL) THEN 'Not Completed' end
INTO #WALLevel1
FROM dw.dbo.dw_loantolender_transaction (NOLOCK)
WHERE 1=1
AND (LenderID = @LenderID)
AND PendingDate < @EndPeriod

IF OBJECT_ID('tempdb..#WALLevel2') IS NOT NULL DROP TABLE #WALLevel2

SELECT loannoteid
,LoanToLenderID
,PrincipalRecoveryReceived = SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)       
,PrincipalReceived = SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)
INTO #WALLevel2
FROM #WALLevel1
GROUP BY LoanToLenderID, LoanNoteID

IF OBJECT_ID('tempdb..#WALLevel3') IS NOT NULL DROP TABLE #WALLevel3
SELECT
ltl.loannoteid
,ltl.loanid
,ltl.lenderid
,PrincipalRepaid = -1 * (WAL2.PrincipalReceived + WAL2.PrincipalRecoveryReceived) 
,AgeinMonths = DATEDIFF(M,lo.OriginationDate,@EndPeriod)
INTO #WALLevel3
FROM c1..loandetail ld
JOIN c1..loans lo on lo.loanid = ld.loanid
JOIN c1..loantolender ltl on ltl.loanid = ld.loanid
JOIN #WALLevel2 WAL2 on WAL2.LoanNoteID = ltl.LoanNoteID
WHERE 1 = 1
AND ld.versionenddate is null
AND ld.versionvalidbit = 1
AND ltl.ownershipenddate is null
AND ld.LoanStatusTypesID in (1,2,3,5)

SELECT 
WAL = (SUM(AgeinMonths * PrincipalRepaid)/SUM(PrincipalRepaid))
FROM #WALLevel3
WHERE LenderID = @LenderID
