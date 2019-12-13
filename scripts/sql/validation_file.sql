declare @begin			datetime	= '{}'
declare @end			datetime	= '{}'
declare @InvestorID		int			=  {}

select
	DateAcquired
	,'Obligor Name' = upper(br.FirstName) + ' ' + upper(br.LastName)
	,'Obligor State' = ld.BorrowerState
	,'Loan Number' = ld.LoanID
	,'Borrower APR' = BorrowerAPR
	,'Interest Rate' = EndBorrowerStatedInterestRate
	,'Maturity Date' = StatedMaturityDate
	,'Monthly Payment Amount' = MonthlyPaymentAmount
	,'Origination Date' = OriginationDate
	,'Original Amount Borrowed' = OriginalAmountBorrowed
	,'Origination Fee Amount' = OriginationFeeAmount
	,'Term Months' = AmortizationMonths
	,ld.PrincipalReceived

	from 
		DW.dbo.tfnDailyLenderPacketBorrowerData_ByDateRangeAndLender 
			(
			@begin
			,@end
			,@InvestorID
			) br
	join 
		DW.dbo.tfnDailyLenderPacketData_ByDateRangeAndLender 
			(
			@begin
			,@end
			,@InvestorID
			) ld
		on 
		br.LoanID = ld.LoanID
	--join 
	--	CircleOne.dbo.GovtIssuedIdentification (nolock) govid
	--	on 
	--	br.BorrowerUserID = govid.GovtIssuedIdentificationID 
	--outer apply 
	--	Circleone.dbo.tfnDecrypt(enNumber) GOVIDDec
	where
		1=1 
	
