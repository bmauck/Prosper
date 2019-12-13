SELECT
	lca.LenderID
	,p.*
	,lca.MonthlyIncome
	,lca.MonthlyDebt
	,lca.DTIwProsperLoan
	,lca.FICOScore as 'FICOScorePt'
	FROM
		#Positions p
	JOIN 
		#listingcreditattributes lca
		ON 
		lca.LoanNumber = p.LoanNumber
	WHERE
		1=1 

