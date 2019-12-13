
/***
Run in Pieces
***/

/***
Define Loans to Transfer
***/

select
	l.LoanID
	into 
		#loans
	from 
		CircleOne..Loans l 
	where
		1=1 
		and l.LoanID = 1269433 --Loans Go Here

/***
Get Intent Data
***/
		
select
	 'loanNoteId' = ltl.LoanNoteID
	,'sellerUserId' = ltl.LenderID
	from 
		CircleOne..LoanToLender ltl
	where
		1=1 
		and ltl.OwnershipEndDate is null
		and ltl.LoanID in (select * from #loans)
		--and ltl.LenderID = 862024

/***
Get Transfer Data
***/

select
	 'loanNoteId' = ltl.LoanNoteID
	,'sellerUserId' = ltl.LenderID
	,'buyerUserId' = 8196710--Buyer goes here
	,'salePrice' = 0
	,'sellerFees' = 0
	,'saleYield' = 0
	,'counterParties' = ''
	from 
		CircleOne..LoanToLender ltl
	where
		1=1 
		and ltl.OwnershipEndDate is null
		and ltl.LoanID in (select * from #loans)
		--and ltl.LenderID = 862024



