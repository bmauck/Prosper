/*********************** OUTPUT ***********************/
SELECT
	[Row]						= CAST(l.[Row] + @PriorRecord AS INT)
	,InvestorKey				= u.AltKey
	,l.TransactionID
	,AvailableDate				= CONVERT(VARCHAR(19),l.AvailableDate,121)
	,l.TransactionType
	,l.TransactionDescription
	,LoanNoteID					= ISNULL(l.LoanNoteID,pre.LoanNoteID)
	,l.NetAmount
	,l.PrincipalAmount
	,l.InterestAmount
	,b.ListingID
	,CashBalance				= a.RunningCash + @PriorBalance
	,AsOf						= FORMAT(@AsOf,'yyyy-MM-dd HH:mm:ss')
--INTO #Transactions
--INTO TabReporting.[!!!].Transactions
FROM #AggregateLedger l
JOIN #Aggregated a ON a.[Row] = l.[Row]
JOIN C1.dbo.Users u ON u.ID = l.UniqueInvestorID
LEFT JOIN #Bids b ON b.TransactionID = l.TransactionID
	AND b.EntryTypeCode = l.TransactionType
LEFT JOIN #PrePurchInterest pre ON pre.TransactionID = l.TransactionID
ORDER BY 1