
/* !! PARAMETERS !! */
WITH CTEParameters AS (
  SELECT
     CAST('{}' AS DATETIME) BegPeriod
    ,CAST('{}' AS DATETIME) EndPeriod
    ,{} LenderID
)

/* All Loans Owned Through @EndPeriod + Transactions Through @EndPeriod */
, CTETransactionLevel AS (
  SELECT
     DATETIME_ADD(p.EndPeriod, INTERVAL -2 MILLISECOND) AsOfDate --AsOf is just before Midnight of the @EndPeriod (File Creation Date)
    ,dw.LoanToLenderID
    ,dw.LoanID
    ,dw.LoanNoteID
    ,dw.LenderID
    ,p.BegPeriod
    ,p.EndPeriod
    ,dw.PendingDate
    ,dw.CompletedDate
    ,dw.Principal
    ,dw.Interest
    ,dw.SvcFee
    ,dw.ClxFee
    ,dw.LateFee
    ,dw.NSFFee
    ,dw.CheckPaymentFee
  ----GROUPING---------------------------------------------------------------------------------------------------------------
    ,dw.StatementTransactionType
    ,dw.AdjustmentFlag
    ,dw.Status
  ----TIMING-----------------------------------------------------------------------------------------------------------------
    , CASE
        WHEN dw.PendingDate >= p.BegPeriod AND dw.PendingDate < p.EndPeriod THEN 'Pending This Period'
        ELSE 'Pending Prior Period'
      END
    PendingPeriod
    , CASE
        WHEN dw.CompletedDate < p.BegPeriod THEN 'Completed Prior Period'
        WHEN dw.CompletedDate >= p.BegPeriod AND dw.CompletedDate < p.EndPeriod THEN 'Completed This Period'
        WHEN (dw.CompletedDate >= p.EndPeriod OR dw.CompletedDate IS NULL) THEN 'Not Completed'
      END
    CompletedPeriod
  FROM DW.fact_loantolender_transaction dw
  JOIN CTEParameters p
    ON 1=1
  WHERE 1=1
    AND (dw.LenderID = p.LenderID)
    AND dw.PendingDate < p.EndPeriod
)

/* Aggregated by LoanToLenderID : Acquired,Sold,ChargeOff,BegBalance,EndBalance,Payments-Received,Payments-Pending,Adjustments */
, CTELenderNoteLevelAggregates AS (
  SELECT
     AsOfDate
    ,LoanToLenderID
    ,LoanID
    ,LoanNoteID
    ,LenderID
      ,BegPeriod
      ,EndPeriod
  ----ACQUISITION/SALE-------------------------------------------------------------------------------------------------------
    ,SUM(CASE WHEN StatementTransactionType = 'Acquisition' THEN Principal ELSE NULL END)     PrinAcquired
    ,MAX(CASE WHEN StatementTransactionType = 'Acquisition' THEN PendingDate ELSE NULL END)         DateAcquired
    ,MAX(CASE WHEN StatementTransactionType = 'Acquisition' THEN Status ELSE NULL END)              StatusAcquired
    ,SUM(CASE WHEN StatementTransactionType IN ('Sale','DebtSale') THEN Principal ELSE NULL END)    PrinSold
    ,MAX(CASE WHEN StatementTransactionType IN ('Sale','DebtSale') THEN PendingDate ELSE NULL END)  DateSold
    ,MAX(CASE WHEN StatementTransactionType IN ('Sale','DebtSale') THEN Status ELSE NULL END)       StatusSold
    ,MAX(CASE WHEN StatementTransactionType = 'DebtSale' THEN 1 ELSE 0 END)                         IsDebtSale
  ----CHARGE-OFFS------------------------------------------------------------------------------------------------------------
    ,MAX(CASE WHEN StatementTransactionType = 'Contract Charge Off' THEN 1 ELSE 0 END)                                 IsContractChargeOff
    ,MAX(CASE WHEN StatementTransactionType = 'Non Contract Charge Off' THEN 1 ELSE 0 END)                                                 IsNonContractChargeOff
    ,MAX(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN PendingDate ELSE '1900-01-01' END)   ChargeOffDate
    ,SUM(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN Principal ELSE 0 END)                ChargeOffPrincipal
    ,SUM(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN Interest ELSE 0 END)                 ChargeOffInterest
    ,SUM(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN LateFee ELSE 0 END)                  ChargeOffLateFee
    ,SUM(CASE WHEN StatementTransactionType IN ('Contract Charge Off','Non Contract Charge Off') THEN NSFFee ELSE 0 END)                   ChargeOffNSFFee
  ----BEG/END BALANCE--------------------------------------------------------------------------------------------------------
    ,SUM(CASE WHEN StatementTransactionType NOT IN ('Contract Charge Off','Non Contract Charge Off') AND PendingPeriod = 'Pending Prior Period' THEN Principal ELSE 0 END)        BegBalance
    ,SUM(CASE WHEN StatementTransactionType NOT IN ('Contract Charge Off','Non Contract Charge Off') THEN Principal ELSE 0 END)                                                   EndBalance
  ----RECEIVED---------------------------------------------------------------------------------------------------------------
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)          PrincipalReceived
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)           InterestReceived
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)             SvcFeePaid
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)             ClxFeePaid
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)            LateFeeReceived
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)             NSFFeeReceived
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN CheckPaymentFee ELSE 0 END)  CkFeeReceived

    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)            PrincipalRecoveryReceived
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)             InterestRecoveryReceived
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)               SvcFeeRecoveryPaid
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)               ClxFeeRecoveryPaid
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)              LateFeeRecoveryReceived
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)               NSFFeeRecoveryReceived
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN CheckPaymentFee ELSE 0 END)    CkFeeRecoveryReceived
  ----PENDING----------------------------------------------------------------------------------------------------------------
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)         PrincipalPending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)          InterestPending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)            SvcFeePending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)            ClxFeePending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)           LateFeePending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)            NSFFeePending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN CheckPaymentFee ELSE 0 END)   CkFeePending

    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Principal ELSE 0 END)           PrincipalRecoveryPending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN Interest ELSE 0 END)            InterestRecoveryPending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN SvcFee ELSE 0 END)              SvcFeeRecoveryPending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN ClxFee ELSE 0 END)              ClxFeeRecoveryPending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN LateFee ELSE 0 END)             LateFeeRecoveryPending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN NSFFee ELSE 0 END)              NSFFeeRecoveryPending
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod = 'Not Completed' AND AdjustmentFlag = 'Not Adjustment' THEN CheckPaymentFee ELSE 0 END)     CkFeeRecoveryPending
  ----ADJUSTMENTS------------------------------------------------------------------------------------------------------------
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Principal ELSE 0 END)                              PrincipalAdjustment
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Interest ELSE 0 END)                               InterestAdjustment
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Non Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN (LateFee + NSFFee + CheckPaymentFee) ELSE 0 END) OtherAdjustment

    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Principal ELSE 0 END)                                  RecoveryPrincipalAdjustment
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN Interest ELSE 0 END)                                   RecoveryInterestAdjustment
    ,SUM(CASE WHEN StatementTransactionType = 'Payment (Recovery)' AND CompletedPeriod <> 'Not Completed' AND AdjustmentFlag = 'Adjustment' THEN (LateFee + NSFFee + CheckPaymentFee) ELSE 0 END)   RecoveryOtherAdjustment
  FROM CTETransactionLevel tl
  GROUP BY
     AsOfDate
    ,LoanToLenderID
    ,LoanID
    ,LoanNoteID
    ,LenderID
      ,BegPeriod
      ,EndPeriod
)

/* LoanDetail Outer Apply as CTE */
, CTELoanDetailBegin AS (
  SELECT
     ld.LoanID
    --,ld.LoanDetailID
    ,ld.LoanStatusTypesID
    ,ld.LoanStatusDesc
    ,ld.DPD
    ,ld.IntBal
    ,ld.BalDate
    ,DATE_DIFF(CAST(ld.BalDate AS DATE),CAST(t.BegPeriod AS DATE),DAY)  BegDaysforAccrual
    ,ld.IntBalDailyAccrual
    ,ld.LateFeeBal
    ,ld.NSFFeeBal
    ,ld.BorrowerStatedInterestRate
    ,ROW_NUMBER() OVER (PARTITION BY ld.LoanID ORDER BY ld.VersionStartDate DESC, ld.AccountInformationDate DESC) RN
  FROM DW.dw_loandetail ld
  JOIN CTELenderNoteLevelAggregates t
    ON t.LoanID = ld.LoanID
    AND AccountInformationDate < IFNULL(t.DateSold,t.BegPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
    AND VersionStartDate < IFNULL(t.DateSold,t.BegPeriod)   --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
)

/* LoanDetail Outer Apply as CTE */
, CTELoanDetailEnd AS (
  SELECT
     ld.LoanID
    --,ld.LoanDetailID
    ,ld.LoanStatusTypesID
    ,ld.LoanStatusDesc
    ,ld.DPD
    ,ld.BalDate
    ,ld.IntBal
    ,DATE_DIFF(CAST(ld.BalDate AS DATE),CAST(t.EndPeriod AS DATE),DAY)  EndDaysforAccrual
    ,ld.IntBalDailyAccrual
    ,ld.LateFeeBal
    ,ld.NSFFeeBal
    ,ld.BorrowerStatedInterestRate
    ,ld.PaymentDayOfMonthDue
    ,ld.DefaultReasonID
    ,ld.DefaultReasonDesc
    ,ld.NextPaymentDueAmount
    ,ld.IsAutoAchOff
    ,ld.ExpectedMaturityDate
    ,ld.DateClosed --NOTE: Different From Above?
    ,ld.ScheduledMonthlyPaymentAmount --NOTE: Different From Above?
    ,ld.NextPaymentDueDate
    ,ld.AmountPastDue
    ,ROW_NUMBER() OVER (PARTITION BY ld.LoanID ORDER BY ld.VersionStartDate DESC, ld.AccountInformationDate DESC) RN
  FROM DW.dw_loandetail ld
  JOIN CTELenderNoteLevelAggregates t
    ON t.LoanID = ld.LoanID
    AND AccountInformationDate < IFNULL(t.DateSold,t.EndPeriod) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
    AND VersionStartDate < IFNULL(t.DateSold,t.EndPeriod)   --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
)

/* Borrower State and Zip */
, CTEBorrowerStateAndZip AS (
  SELECT
     l.LoanID
    --,uta.UserToAddressID
    --,uta.StateOfResidence
    --,uta.OriginalZip
    ,BorrowerState = IFNULL(uta.StateOfResidence, CASE WHEN li.CreationDate < '2009-01-01' THEN li.BorrowerState END)
    ,uta.OriginalZip  ZipCode
    ,ROW_NUMBER() OVER (PARTITION BY l.LoanID ORDER BY uta.IsLegalAddress DESC, uta.IsVisible DESC, uta.VersionStartDate DESC) RN
  FROM Circleone.Loans l
  JOIN CTELenderNoteLevelAggregates t
    ON t.LoanID = l.LoanID
  JOIN Circleone.Listings li
    ON li.ID = l.ListingID
  JOIN Circleone.ListingStatus lst
    ON lst.ListingID = li.ID
  AND lst.VersionEndDate IS NULL
  AND lst.VersionValidBit = true
  AND lst.ListingStatusTypeID = 6 --NOTE: Consider Changing Status Type to 1
  LEFT JOIN Circleone.UserToAddress uta
  ON uta.UserID = li.UserID
  AND uta.VersionValidBit = true
  --AND uta.IsLegalAddress = 1
  --AND uta.IsVisible = 1 --NOTE: Unsure if Necessary
  AND uta.VersionStartDate <= lst.ModifiedDate --li.TermsApprovalDate
  AND (uta.VersionEndDate IS NULL OR uta.VersionEndDate > lst.ModifiedDate /*li.TermsApprovalDate*/)

)

/* Add Loan-Level Attributes and LoanDetail Data */
, CTEtfnDailyLenderPacketData_ByDateRangeAndLender AS (
  SELECT
     t.AsOfDate
    ,t.LoanToLenderID
    ,t.LenderID
    ,u.UserAltKey
    ,t.LoanNoteID
    ,ln.LoanNoteDisplayName
    ,ln.ProRataShare
    ,ln.OwnershipShare
    ,t.BegPeriod
    ,t.EndPeriod
  ----LOAN ATTRIBUTES-------------------------------------------------------------------------------------------------
    ,ln.LoanID
    ,ln.ListingID
    ,ln.ListingCategoryID
    ,ln.ListingCategoryDesc
    ,ln.OriginationDate
    ,ln.AmortizationMonths
    ,ln.OriginalAmountBorrowed
    ,ln.RatingCode ProsperRating
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
    ,t2.NextPaymentDueDate SpectrumNextPaymentDueDate --NOTE: Different From Above?
    -------------------------
    ,ldend.AmountPastDue
    ,t2.TotalPaymentsPastDueAmount --NOTE: Different From Above?
  ----BORROWER ATTRIBUTES---------------------------------------------------------------------------------------------
    ,ln.BorrowerUserID BorrowerID
    ,ln.BorrowerAPR
    ,ln.BorrowerState
    ,CASE WHEN ln.PriorLoanCount > 0 THEN 1 ELSE 0 END IsPriorBorrower
    ,ln.IsSCRA
    ,ln.SCRABeginDate
    ,ln.SCRAEndDate
    ,ucp.Score DecisionCreditScore
    ,               CASE
                      WHEN ucp.Score < 600 THEN '< 600'
                      WHEN ucp.Score >= 600 AND ucp.Score < 620 THEN '600-619'
                      WHEN ucp.Score >= 620 AND ucp.Score < 640 THEN '620-639'
                      WHEN ucp.Score >= 640 AND ucp.Score < 660 THEN '640-659'
                      WHEN ucp.Score >= 660 AND ucp.Score < 680 THEN '660-679'
                      WHEN ucp.Score >= 680 AND ucp.Score < 700 THEN '680-699'
                      WHEN ucp.Score >= 700 AND ucp.Score < 720 THEN '700-719'
                      WHEN ucp.Score >= 720 AND ucp.Score < 740 THEN '720-739'
                      WHEN ucp.Score >= 740 AND ucp.Score < 760 THEN '740-759'
                      WHEN ucp.Score >= 760 AND ucp.Score < 780 THEN '760-779'
                      WHEN ucp.Score >= 780 AND ucp.Score < 800 THEN '780-799'
                      WHEN ucp.Score >= 800 AND ucp.Score < 820 THEN '800-819'
                      WHEN ucp.Score >= 820 AND ucp.Score <= 850 THEN '820-850'
                      ELSE 'N/A'
                    END
     DecisionCreditScoreRange
    ,ucp.CreditPullDate     DecisionCreditScoreDate
    ,ucp.CreditBureauName       DecisionCreditScoreVendor
    ,ucp.CreditBureauID         DecisionCreditScoreVendorID
    ,ucp.ExternalCreditReportId DecisionExternalReportID
    ,NULL                       RefreshCreditScore
    ,NULL                       RefreshCreditScoreRange
    ,NULL                       RefreshCreditScoreDate
    ,NULL                       RefreshCreditScoreVendor
    ,ucp.MonthlyDebt
    ,ucp.RealEstatePayment
  ----LOAN DETAIL-----------------------------------------------------------------------------------------------------
    --BEGGINING VALUES--
    ,ldbeg.LoanStatusTypesID              BegLoanStatusID
    ,ldbeg.LoanStatusDesc                   BegStatus
    ,ldbeg.DPD                              BegDPD
    ,ldbeg.IntBal                           BegIntBal
    ,ldbeg.BalDate                          BegBalDate
    ,DATE_DIFF(CAST(ldbeg.BalDate AS DATE),CAST(t.BegPeriod AS DATE),DAY)  BegDaysforAccrual
    ,ldbeg.IntBalDailyAccrual               BegIntBalDailyAccrual
    ,ldbeg.LateFeeBal                       BegLateFeeBal
    ,ldbeg.NSFFeeBal                        BegNSFFeeBal
    ,ldbeg.BorrowerStatedInterestRate   BegBorrowerStatedInterestRate
    --ENDING VALUES--
    ,ldend.LoanStatusTypesID              EndLoanStatusID
    ,ldend.LoanStatusDesc                   EndStatus
    ,ldend.DPD                              EndDPD
    ,ldend.BalDate                          EndBalDate
    ,ldend.IntBal                           EndIntBal
    ,DATE_DIFF(CAST(ldend.BalDate AS DATE),CAST(t.EndPeriod AS DATE),DAY)  EndDaysforAccrual
    ,ldend.IntBalDailyAccrual               EndIntBalDailyAccrual
    ,ldend.LateFeeBal                       EndLateFeeBal
    ,ldend.NSFFeeBal                        EndNSFFeeBal
    ,ldend.BorrowerStatedInterestRate   EndBorrowerStatedInterestRate
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
    ,t.StatusAcquired
    ,t.PrinSold
    ,t.DateSold
    ,t.StatusSold
    ,t.IsDebtSale
    ,lot.SalePrice SaleGrossProceeds
    ,lot.SellerFees SaleTransactionFee
    ,(lot.SalePrice - lot.SellerFees) SaleNetProceeds
  ----CHARGE-OFFS-------------------------------------------------------------------------------------------------------------
    ,CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.IsContractChargeOff ELSE 0 END IsContractChargeOff
    ,CASE WHEN ldend.LoanStatusTypesID IN (3) OR ldbeg.LoanStatusTypesID IN (3) THEN t.IsNonContractChargeOff ELSE 0 END    IsNonContractChargeOff
    ,CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffDate END                ChargeOffDate
    ,CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffPrincipal END           ChargeOffPrincipal
    ,CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffInterest END            ChargeOffInterest
    ,CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffLateFee END             ChargeOffLateFee
    ,CASE WHEN ldend.LoanStatusTypesID IN (2,3) OR ldbeg.LoanStatusTypesID IN (2,3) THEN t.ChargeOffNSFFee END              ChargeOffNSFFee
    ,bk.DateOfFiling                                                                                                        BankruptcyFiledDate
    ,bk.BankruptcyStatusDesc                                                                                                BankruptcyStatus
    ,bk.BankruptcyTypeDesc                                                                                                  BankruptcyType
    ,IFNULL(CAST(bk.DateOfNotification AS DATETIME),bk.VersionStartDate)                                                    BankruptcyStatusDate
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
    ,SUBSTR(bsz.ZipCode,1,3)  ThreeDigitZip
    --,TuMilitaryMatch = mla.ModelReportMilitaryLendingAlertStatus
  FROM CTELenderNoteLevelAggregates t
  JOIN DW.dim_loannote ln
    ON ln.LoanNoteID = t.LoanNoteID
  JOIN DW.dim_user u
    ON u.UserID = t.LenderID
  LEFT JOIN DW.dim_listing li
    ON li.ListingID = ln.ListingID
  LEFT JOIN DW.dw_usercreditprofiles ucp
    ON ucp.ListingID = ln.ListingID
    AND ucp.IsDecisionBureau = true
  LEFT JOIN DW.dim_loan_type2 t2
    ON t2.LoanID = ln.LoanID
    AND t2.VersionStartDate <= IFNULL(CAST(t.DateSold AS DATE),CAST(t.EndPeriod AS DATE)) --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
    AND t2.VersionEndDate > IFNULL(CAST(t.DateSold AS DATE),CAST(t.EndPeriod AS DATE))    --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
    --AND t2.IsCurrentRecord = 1
  LEFT JOIN DW.fact_loannote_ownership_transfer lot
    ON lot.SellerLoanToLenderID = t.LoanToLenderID
    AND lot.SellerLoanToLenderID IS NOT NULL
  LEFT JOIN DW.fact_bankruptcy bk
    ON bk.LoanID = ln.LoanID
    AND bk.VersionStartDate < IFNULL(t.DateSold,t.EndPeriod)  --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
    AND bk.VersionEndDate >= IFNULL(t.DateSold,t.EndPeriod)   --NOTE: THIS WILL STALE UPDON THE DATE OF SALE
  LEFT JOIN CTELoanDetailBegin ldbeg
    ON ldbeg.LoanID = t.LoanID
    AND ldbeg.RN = 1
  LEFT JOIN CTELoanDetailEnd ldend
    ON ldend.LoanID = t.LoanID
    AND ldend.RN = 1
  LEFT JOIN CTEBorrowerStateAndZip bsz
    ON bsz.LoanID = t.LoanID
    AND bsz.RN = 1
--  LEFT JOIN Circleone.ListingCreditReportMapping lcrm
--  ON lcrm.ListingID = li.ListingID
--  AND lcrm.CreditBureau = 2
--  AND lcrm.IsDecisionBureau = 1
  LEFT JOIN Circleone.UserModelReportMapping umrm
    ON umrm.ExternalCreditReportId = li.ExternalCreditReportId
  LEFT JOIN TransUnion.ModelReport mr
    ON mr.ExternalModelReportId = umrm.ExternalModelReportId
--  LEFT JOIN TransUnion.ModelReportMilitaryLendingAlertAct mla
--  ON mla.modelreportid = mr.modelreportid
--  AND mla.ModelReportMilitaryLendingAlertStatus = 'MATCH'
)




SELECT
   FORMAT_DATETIME('%c',NL.AsOfDate)      AsOf
  ,NL.ListingID                                       ListingNumber
  ,FORMAT_DATETIME('%c',CAST(NL.OriginationDate AS DATETIME))   OriginationDate
  ,FORMAT_DATETIME('%c',NL.DateAcquired)    PurchaseDate      --TODO: Purchase Date is now wrong for all Loans prior to Java code change (hard-coded origination + 1)
  ,NL.UserAltKey                                      InvestorKey
  ,NL.LoanNoteDisplayName                             LoanNoteID
  ,NL.LoanID                                          LoanNumber
  ,NL.OwnershipShare                                  OriginalInvestment  --OLD: NL.PrinAcquired
  ,NL.OriginalAmountBorrowed                          LoanAmount
  ,CASE WHEN (NL.EndBalance <= 0.01 AND NL.EndLoanStatusID IN (3,4)) OR NL.PrinSold IS NOT NULL THEN 0.00 ELSE NL.EndBalance END  PrincipalBalance
----PENDING-------------------------------------------------------------------------------------------------------------
  ,-1 * (NL.PrincipalPending + NL.PrincipalRecoveryPending) InProcessPrincipalPayments
  ,-1 * (NL.InterestPending + NL.InterestRecoveryPending)     InProcessInterestPayments
  ,0.00                                 InProcessOriginationInterestPayments  --NOTE: This Field is NO LONGER Relevant
  ,-1 * (NL.LateFeePending + NL.LateFeeRecoveryPending)       InProcessLatfeePayments
  , 1 * (NL.SvcFeePending + NL.SvcFeeRecoveryPending)         InProcessSvcFeePayments
  , 1 * (NL.ClxFeePending + NL.ClxFeeRecoveryPending)         InProcessCollectionsPayments
  ,-1 * (NL.NSFFeePending + NL.NSFFeeRecoveryPending)         InProcessNSFFeePayments
  ,0.00                                 InProcessGLRewardPayments       --NOTE: This Field is NO LONGER Relevant
----PENDING-------------------------------------------------------------------------------------------------------------
----ACCRUALS------------------------------------------------------------------------------------------------------------
  ,--CAST(
    NL.ProRataShare
    *
    CASE
      WHEN NL.DateAcquired < NL.EndPeriod AND NL.EndLoanStatusID IN (0,1) AND (NL.DateSold IS NULL OR NL.DateSold >= NL.EndPeriod) AND IFNULL( NL.EndIntBal + (NL.EndIntBalDailyAccrual * NL.EndDaysforAccrual ),0.00) > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
        THEN IFNULL( NL.EndIntBal + (NL.EndIntBalDailyAccrual * NL.EndDaysforAccrual ),0.00)
      WHEN NL.DateAcquired >= NL.EndPeriod OR NL.DateSold < NL.EndPeriod /* NOTE: STOP ACCRUING ONCE SOLD */
        THEN 0.00
      ELSE NL.EndIntBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
    END
  --AS DECIMAL(20,10))
  AccruedInterest
  ,0.00 --NOTE: This Field is NO LONGER Relevant
  AccruedOriginationInterest
  ,--CAST(
    NL.ProRataShare
    *
    CASE
      WHEN NL.DateAcquired < NL.EndPeriod AND NL.EndLoanStatusID IN (0,1) AND (NL.DateSold IS NULL OR NL.DateSold >= NL.EndPeriod) AND NL.EndLateFeeBal > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
        THEN NL.EndLateFeeBal
      WHEN NL.DateAcquired >= NL.EndPeriod OR NL.DateSold < NL.EndPeriod /* NOTE: STOP ACCRUING ONCE SOLD */
        THEN 0.00
      ELSE NL.EndLateFeeBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
    END
  --AS DECIMAL(20,10))
  AccruedLatefee
  ,--CAST(
    NL.ProRataShare
    *
    CASE
      WHEN NL.DateAcquired < NL.EndPeriod AND NL.EndLoanStatusID IN (0,1) AND (NL.DateSold IS NULL OR NL.DateSold >= NL.EndPeriod) AND NL.EndNSFFeeBal > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
        THEN NL.EndNSFFeeBal
      WHEN NL.DateAcquired >= NL.EndPeriod OR NL.DateSold < NL.EndPeriod /* NOTE: STOP ACCRUING ONCE SOLD */
        THEN 0.00
      ELSE NL.EndNSFFeeBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
    END
  --AS DECIMAL(20,10))
  AccruedNSFFee
  ,--CAST(
    NL.ProRataShare
    *
    CASE
      WHEN NL.DateAcquired < NL.EndPeriod AND NL.EndLoanStatusID IN (0,1) AND (NL.DateSold IS NULL OR NL.DateSold >= NL.EndPeriod) AND IFNULL( NL.EndIntBal + (NL.EndIntBalDailyAccrual * NL.EndDaysforAccrual ),0.00) > 0 /* NOTE: ACCRUE FOR CURRENT NOTES THAT HAVEN'T BEEN SOLD YET */
        THEN IFNULL( NL.EndIntBal + (NL.EndIntBalDailyAccrual * NL.EndDaysforAccrual ),0.00)
      WHEN NL.DateAcquired >= NL.EndPeriod OR NL.DateSold < NL.EndPeriod /* NOTE: STOP ACCRUING ONCE SOLD */
        THEN 0.00
      ELSE NL.EndIntBal --OLD: 0.00 /* NOTE: CONDITION TRUE FOR NON-CURRENT STATUSES */
    END
    *
    --ISNULL( CAST(NL.ServiceFeePercent AS DECIMAL(20,10)) / CAST(NULLIF(NL.EndBorrowerStatedInterestRate,0) AS DECIMAL(20,10)) , 0.00)
    SAFE_DIVIDE(NL.ServiceFeePercent,NL.EndBorrowerStatedInterestRate)
  --AS DECIMAL(20,10))
  AccruedSvcFee
  ,0.00 --NOTE: This Field is NO LONGER Relevant
  AccruedGLReward
----ACCRUALS------------------------------------------------------------------------------------------------------------
  ,CASE WHEN (NL.DateSold IS NULL OR NL.DateSold >= NL.EndPeriod) THEN NL.EndStatus ELSE 'SOLD' END   LoanStatusDescription --OLD: NL.EndStatus
  ,NL.ProsperRating
  ,NL.AmortizationMonths                                              Term
  ,FORMAT_DATETIME('%c',NL.ExpectedMaturityDate)        MaturityDate      --OLD: NL.StatedMaturityDate
  --,CAST(NL.EndBorrowerStatedInterestRate AS DECIMAL(10,5))          BorrowerRate
  ,NL.EndBorrowerStatedInterestRate                       BorrowerRate
  ,IFNULL(CAST(NL.SpectrumNextPaymentDueDate AS DATE),CAST(NL.NextPaymentDueDate AS DATE))        NextPaymentDueDate
  ,-1 * DATE_DIFF(CAST(NL.OriginationDate AS DATE),CAST(NL.EndPeriod AS DATE),MONTH)                          AgeInMonths
  ,NL.EndDPD                                                          DaysPastDue
  ,FORMAT_DATETIME('%c',DATETIME_ADD(CAST(NL.OriginationDate AS DATETIME), INTERVAL 1 MONTH))   FirstScheduledPayment --OLD: FORMAT( DATEADD(MM,1,DATEADD(DD,-1*DAY(NL.OriginationDate),DATEADD(DD,NL.PaymentDayOfMonthDue,NL.OriginationDate))) ,'yyyy-MM-dd HH:mm:ss')
----RECEIVED------------------------------------------------------------------------------------------------------------
  ,-1 * (NL.SvcFeePaid + NL.SvcFeeRecoveryPaid)               ServiceFees
  ,-1 * (NL.PrincipalReceived + NL.PrincipalRecoveryReceived) PrincipalRepaid
  ,-1 * (NL.InterestReceived + NL.InterestRecoveryReceived) InterestPaid
  ,-1 * (NL.NSFFeeReceived + NL.NSFFeeRecoveryReceived)       ProsperFees
  ,-1 * (NL.LateFeeReceived + NL.LateFeeRecoveryReceived)     LateFees
  ,0.00                             GroupLeaderReward --NOTE: This Field is NO LONGER Relevant
----RECEIVED------------------------------------------------------------------------------------------------------------
----SALES---------------------------------------------------------------------------------------------------------------
  ,CASE WHEN NL.IsDebtSale = 1 THEN NL.SaleNetProceeds ELSE 0.00 END                  DebtSaleProceedsReceived
  ,CASE WHEN NL.DateSold IS NOT NULL THEN NL.SaleGrossProceeds ELSE 0.00 END          PlatformProceedsGrossReceived
  ,CASE WHEN NL.DateSold IS NOT NULL THEN -1 * NL.SaleTransactionFee ELSE 0.00 END  PlatformFeesPaid
----SALES---------------------------------------------------------------------------------------------------------------
  ,CASE WHEN (NL.DateSold IS NULL OR NL.DateSold >= NL.EndPeriod) THEN NL.EndLoanStatusID ELSE 86 END   NoteStatus            --OLD: NL.EndLoanStatusID
  ,NL.DefaultReasonID                                                                                 NoteDefaultReason
  ,NL.DefaultReasonDesc                                                                               NoteDefaultReasonDescription
  ,CASE WHEN NL.DateSold IS NOT NULL THEN 1 ELSE 0 END                                                IsSold
  ,NL.ScheduledMonthlyPaymentAmount                                   MonthlyPaymentAmount      --OLD: NL.MonthlyPaymentAmount
  --,CAST(NL.ProRataShare * ISNULL(NL.NextPaymentDueAmount,0.00) AS DECIMAL(20,6))                NextPaymentDueAmountNoteLevel
  --,CAST(NL.ProRataShare * ISNULL(NL.ScheduledMonthlyPaymentAmount,0.00) AS DECIMAL(20,6))       SchMonthlypaymentNoteLevel    --OLD: NL.MonthlyPaymentAmount
  ,NL.ProRataShare * IFNULL(NL.NextPaymentDueAmount,0.00)          NextPaymentDueAmountNoteLevel
  ,NL.ProRataShare * IFNULL(NL.ScheduledMonthlyPaymentAmount,0.00) SchMonthlypaymentNoteLevel
----BANKRUPTCY----------------------------------------------------------------------------------------------------------
  ,FORMAT_DATETIME('%c',CAST(NL.BankruptcyFiledDate AS DATETIME))   BankruptcyFiledDate
  ,NL.BankruptcyStatus                                    BankruptcyStatus
  ,NL.BankruptcyType                                      BankruptcyType
  ,FORMAT_DATETIME('%c',CAST(NL.BankruptcyStatusDate AS DATETIME))  BankruptcyStatusDate
----BANKRUPTCY----------------------------------------------------------------------------------------------------------
  ,FORMAT_DATETIME('%c',NL.DateClosed) LoanClosedDate --OLD: NL.ClosedDate
----CHARGE-OFFS---------------------------------------------------------------------------------------------------------
  ,FORMAT_DATETIME('%c',NL.ChargeOffDate)                                                     ChargeoffDate
  ,-1 * (NL.ChargeOffPrincipal + NL.ChargeOffInterest + NL.ChargeOffLateFee + NL.ChargeOffNSFFee)     TotalChargeoff
  ,-1 * NL.ChargeOffPrincipal                                                                         PrincipalBalanceAtChargeoff
  ,-1 * NL.ChargeOffInterest                                                                          InterestBalanceAtChargeoff
  ,-1 * NL.ChargeOffLateFee                                                                           LateFeeBalanceAtChargeoff
  ,-1 * NL.ChargeOffNSFFee                                                                            NSFFeeBalanceAtChargeoff
  ,CASE WHEN NL.ChargeOffDate IS NOT NULL THEN 0.00 END                         RewardsBalanceAtChargeoff --NOTE: This Field is NO LONGER Relevant
----CHARGE-OFFS---------------------------------------------------------------------------------------------------------
  ,IFNULL(NL.DecisionCreditScoreRange,'N/A')  FICOScore
  ,NL.InvestmentTypeID
  ,NL.LoanProductID
  ,-1 * (NL.ClxFeePaid + NL.ClxFeeRecoveryPaid) CollectionFees
  ,NL.IsPriorBorrower
  ,NL.BorrowerState
  ,NL.BorrowerAPR
  ,-1 * (NL.PrincipalAdjustment + NL.RecoveryPrincipalAdjustment) PrincipalAdjustments
--2016 BBVA ADDITIONAL FIELDS-------------------------------------------------------------------------------------------
  --,CAST(NL.ProRataShare * ISNULL(NL.AmountPastDue - NL.EndLateFeeBal - NL.EndNSFFeeBal,0.00) AS DECIMAL(20,6))  PastDueAmount --OLD: NL.TotalPaymentsPastDueAmount --NOTE: Used to be Named AmountPastDueLessFees
  ,NL.ProRataShare * IFNULL(NL.AmountPastDue - NL.EndLateFeeBal - NL.EndNSFFeeBal,0.00) PastDueAmount --OLD: NL.TotalPaymentsPastDueAmount --NOTE: Used to be Named AmountPastDueLessFees
  ,NL.ListingCategoryID
  ,IFNULL(NL.DecisionCreditScore,0) DecisionCredScore --NOTE: SECURE POSITIONS WITH FOOTER ONLY
--  ,ref.FicoScore  RefreshCredScore  --NOTE: SECURE POSITIONS WITH FOOTER ONLY
--  ,FORMAT(ref.CreatedDate,'yyyy-MM-dd HH:mm:ss')  RefreshCredScoreDate  --NOTE: SECURE POSITIONS WITH FOOTER ONLY
  ,'N/A'  RefreshCredScore
  ,'N/A'  RefreshCredScoreDate
  ,NL.IsContractChargeOff
  ,NL.IsNonContractChargeOff
  ,IFNULL(NL.DecisionCreditScoreVendor,'N/A')   DecisionCredScoreVendor --NOTE: SECURE POSITIONS WITH FOOTER ONLY
  ,'FICO 08'                    DecisionCredScoreVersion  --NOTE: SECURE POSITIONS WITH FOOTER ONLY
--  ,CASE WHEN ref.FicoScore IS NOT NULL THEN 'TransUnion' END  RefreshCredScoreVendor  --NOTE: SECURE POSITIONS WITH FOOTER ONLY
--  ,CASE WHEN ref.FicoScore IS NOT NULL THEN 'FICO 08' END   RefreshCredScoreVersion --NOTE: SECURE POSITIONS WITH FOOTER ONLY
  ,'N/A'  RefreshCredScoreVendor
  ,'N/A'  RefreshCredScoreVersion
----SETTLEMENTS---------------------------------------------------------------------------------------------------------
  ,NL.SettlementStartDate
  ,NL.SettlementEndDate
  ,NL.SettlementStatus
  --,CASE WHEN NL.SettlementBalAtEnrollment IS NOT NULL THEN CAST(NL.ProRataShare * IFULL(NL.SettlementBalAtEnrollment,0.00) AS DECIMAL(20,6)) END SettlementBalAtEnrollment
  --,CASE WHEN NL.SettlementAgreedPmtAmt IS NOT NULL THEN CAST(NL.ProRataShare * IFNULL(NL.SettlementAgreedPmtAmt,0.00) AS DECIMAL(20,6)) END   SettlementAgreedPmtAmt
  ,CASE WHEN NL.SettlementBalAtEnrollment IS NOT NULL THEN NL.ProRataShare * IFNULL(NL.SettlementBalAtEnrollment,0.00) END SettlementBalAtEnrollment
  ,CASE WHEN NL.SettlementAgreedPmtAmt IS NOT NULL THEN NL.ProRataShare * IFNULL(NL.SettlementAgreedPmtAmt,0.00) END      SettlementAgreedPmtAmt
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
  --,CASE WHEN TuMilitaryMatch = 'MATCH' THEN 1 ELSE 0 END   IsMLA
  ,0 IsMLA
----RECOVERY PAYMENT FIELDS - IN PROCESS--------------------------------------------------------------------------------
  ,-1 * (NL.PrincipalRecoveryPending) PrincipalRecoveriesInProcess
  ,-1 * (NL.InterestRecoveryPending)  InterestRecoveriesInProcess
  ,-1 * (NL.LateFeeRecoveryPending)   LateFeeRecoveriesInProcess
  ,-1 * (NL.NSFFeeRecoveryPending)    NSFFeeRecoveriesInProcess
  ,-1 * (NL.ClxFeeRecoveryPending)    ClxFeeRecoveriesInProcess
  ,-1 * (NL.SvcFeeRecoveryPending)    SvcFeeRecoveriesInProcess
----RECOVERY PAYMENT FIELDS - RECEIVED----------------------------------------------------------------------------------
  ,-1 * (NL.PrincipalRecoveryReceived)  PrincipalRecoveriesReceived
  ,-1 * (NL.InterestRecoveryReceived)     InterestRecoveriesReceived
  ,-1 * (NL.LateFeeRecoveryReceived)      LateFeeRecoveriesReceived
  ,-1 * (NL.NSFFeeRecoveryReceived)       NSFFeeRecoveriesReceived
  ,-1 * (NL.ClxFeeRecoveryPaid)           ClxFeeRecoveriesReceived
  ,-1 * (NL.SvcFeeRecoveryPaid)           SvcFeeRecoveriesReceived
----CHECK FEE FIELDS----------------------------------------------------------------------------------------------------
  ,-1 * (NL.CkFeePending + NL.CkFeeRecoveryPending) InProcessCheckFeePayments
  ,-1 * (NL.CkFeeReceived + NL.CkFeeRecoveryReceived) CheckFees
  ,-1 * (NL.CkFeeRecoveryPending)                     CheckFeeRecoveriesInProcess
  ,-1 * (NL.CkFeeRecoveryReceived)                    CheckFeeRecoveriesReceived
----2017 ADDITIONAL FIELDS----------------------------------------------------------------------------------------------
  ,ROW_NUMBER() OVER (ORDER BY NL.OriginationDate, NL.LoanID, NL.LoanToLenderID)  RecordID
  --,NL.LoanToLenderID          --NOTE: For Testing Purposes Only
  ,NL.ThreeDigitZip
  ,CASE WHEN AgencyQueueName = 'CAQ_WNR_LS' THEN 1 ELSE 0 END IsLegalStrategy
----2018 ADDITIONAL FIELDS----------------------------------------------------------------------------------------------
  ,NL.InvestmentProductID
  ,NL.PrinAcquired  PurchasePrincipal
  ,NL.PrinSold    SoldPrincipal
  ,IsCeaseAndDesist
  ,IsAutoAchOff
FROM CTEtfnDailyLenderPacketData_ByDateRangeAndLender NL
--OUTER APPLY (
--  SELECT TOP 1 LoanId,FicoScore,CreatedDate,UpdatedDate
--  FROM PortFolioMgmt.dbo.PortfolioReport
--  WHERE LoanId = NL.LoanID
--    AND CreatedDate < ISNULL(NL.DateSold,@CutoffMax) --NOTE: This will STALE Upon Date of Sale
--    AND CreatedDate > NL.DecisionCreditScoreDate --NOTE: Refresh Later than Decision Date
--  ORDER BY CreatedDate DESC, UpdatedDate DESC
--) ref
