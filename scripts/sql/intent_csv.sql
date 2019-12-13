/***
Get Intent Data
***/

select
	 'loanNoteId' = ltl.LoanNoteID
	,'sellerUserId' = ltl.LenderID
	from
		CircleOne.LoanToLender ltl
	where
		1=1
		and ltl.OwnershipEndDate is null
		and ltl.LoanID in {}
		--and ltl.LenderID = 862024
