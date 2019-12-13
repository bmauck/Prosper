/***
Get Intent Data
***/

select
	 ltl.LoanNoteID loanNoteId
	,ltl.LenderID sellerUserId
	from
		Circleone.LoanToLender ltl
	where
		1=1
		and ltl.OwnershipEndDate is null
		and ltl.LoanID in {}
		--and ltl.LenderID = 862024
