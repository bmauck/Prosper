select
	 ltl.LoanNoteID loanNoteId
	,ltl.LenderID sellerUserId
	,{} buyerUserId
	,0 salePrice
	,0 sellerFees
	,0 saleYield
	,'' counterParties
	from
		Circleone.LoanToLender ltl
	where
		1=1
		and ltl.OwnershipEndDate is null
		and ltl.LoanID in {}
		--and ltl.LenderID = 862024
