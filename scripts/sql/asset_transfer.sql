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

/***
Get Transfer Data
***/

select
	 'loanNoteId' = ltl.LoanNoteID
	,'sellerUserId' = ltl.LenderID
	,'buyerUserId' = {}--Buyer goes here
	,'salePrice' = 0
	,'sellerFees' = 0
	,'saleYield' = 0
	,'counterParties' = ''
	from
		CircleOne.LoanToLender ltl
	where
		1=1
		and ltl.OwnershipEndDate is null
		and ltl.LoanID in {}
		--and ltl.LenderID = 862024
