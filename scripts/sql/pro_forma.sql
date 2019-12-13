select
	RatingCodeSortable
	,RatingCode
	,'Volume' = sum(l.Amount)
	,'Average Loan Size' = sum(l.Amount) / count(l.LoanID)
	,'Wtd Averge Cpn' = sum(l.CurrentRate * l.Amount) / sum(l.Amount)
	--,'WA Est Yield' = (sum(l.CurrentRate * l.Amount) / sum(l.Amount)) - 0.01075
	--,'WA Est Loss' = sum(l.EstimatedLoss * l.Amount) / sum(l.Amount)
	--,'WA Est Return'  = sum(l.EstimatedReturn * l.Amount) / sum(l.Amount)
	,'Wtd Avg Annual Income' = sum((l.MonthlyIncome * 12) * l.Amount) / sum(l.Amount)
	,'Wtd Avg DTIwoProsperLoan' = sum(li.DTIwoProsperLoan * l.Amount) / sum(l.Amount)
	,'Wtd Avg FICO' = sum(li.FICOScore * l.Amount) / sum(l.Amount)
		
		from 
			CircleOne..Listings l
			join 
			DW..dm_listing li
			on 
			l.ID = li.ListingID
			join 
			CircleOne..Loans lo
			on 
			lo.LoanID = l.LoanID
			join 
			DW..vloanlevelmonthly llm
			on 
			llm.LoanID = lo.LoanID
	
		where 
			1=1 
			and lo.OriginationDate < dateadd(day,1,eomonth(getdate(),-1)) 
			and lo.OriginationDate >=  dateadd(month, -1, dateadd(day,1,eomonth(getdate(),-1)))
			and l.InvestmentProductID = 1
			and l.LoanID is not null
			
		group by 
			li.Term
			,RatingCodeSortable
			,RatingCode
			
		order by 
			li.Term
			,RatingCodeSortable


