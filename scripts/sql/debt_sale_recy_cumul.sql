use c1

DECLARE @LenderID INT = 3651887
DECLARE @AsOf DATETIME = '2018-08-15'
--SELECT * FROM C1.dbo.LoanGroup


--/* RECOVERIES SINCE INCEPTION THROUGH @AsOf DATE
--SELECT
--       LoanToLenderID
--       ,LenderID
--       ,LoanID
----------------------
--       ,StatementTransactionType
--       ,AdjustmentFlag
--       ,[Type]
--       ,TypeDetail
--       ,ReferenceKey
----------------------
--       ,PendingDate
--       ,CompletedDate
--       ,Principal
--       ,Interest
--       ,SvcFee
--       ,ClxFee
--       ,LateFee
--       ,NSFFee
--FROM DW.dbo.dw_loantolender_transaction
--WHERE 1=1
--       AND StatementTransactionType = 'Payment (Recovery)'
--       AND LenderID = @LenderID
--       AND PendingDate < @AsOf 
--ORDER BY PendingDate --*/


--/* DEBT SALES SINCE INCEPTION THROUGH @AsOf DATE
SELECT
       LoanToLenderID
       ,LenderID
       ,LoanID
----------------------
       ,[Source]
       ,[Type]
       ,ReferenceKey
       ,[Status]
----------------------
       ,PendingDate
       ,CompletedDate
       ,Principal
       ,Interest
       ,SvcFee
       ,ClxFee
       ,LateFee
       ,NSFFee
------------------------
       ,GrossSaleProceeds   = LOT.SalePrice
       ,GrossSaleFees             = LOT.SellerFees
       ,NetSaleProceeds     = LOT.SalePrice - lot.SellerFees
FROM DW.dbo.dw_loantolender_transaction LTL
JOIN (
       SELECT SellerLoanToLenderID,SalePrice,SellerFees
       FROM DW.DBO.fact_loannote_ownership_transfer
       WHERE SellerLoanToLenderID IS NOT NULL /* to hit filtered index */
       ) LOT on LOT.SellerLoanToLenderID = LTL.LoanToLenderID
WHERE 1=1
       AND StatementTransactionType = 'DebtSale'
       AND LenderID = @LenderID
       AND PendingDate < @AsOf 
ORDER BY PendingDate --*/
