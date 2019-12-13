select
	RatingCodeSortable
	,RatingCode
	,sum(l.Amount) `Volume`
	,sum(l.Amount) / count(l.LoanID) `AverageLoanSize`
	,sum(l.CurrentRate * l.Amount) / sum(l.Amount) `WtdAvgCpn`
	--,(sum(l.CurrentRate * l.Amount) / sum(l.Amount)) - 0.01075 `Wtd Avg Est Yield`
	--,sum(l.EstimatedLoss * l.Amount) / sum(l.Amount) `Wtd Avg Est Loss`
	--,sum(l.EstimatedReturn * l.Amount) / sum(l.Amount) `Wtd Avg Est Return`
	,sum((l.MonthlyIncome * 12) * l.Amount) / sum(l.Amount) `WtdAvgAnnualIncome`
	,sum(li.DTIwoProsperLoan * l.Amount) / sum(l.Amount) `WtdAvgDTIwoProsperLoan`
	,sum(li.FICOScore * l.Amount) / sum(l.Amount) `WtdAvgFICO`

		from
			Circleone.Listings l
			join
			DW.dim_listing li
			on
			l.ID = li.ListingID
			join
			Circleone.Loans lo
			on
			lo.LoanID = l.LoanID

		where
			1=1
			and lo.OriginationDate < '{}' --dateadd(day,1,eomonth(getdate(),-1))
		and lo.OriginationDate >=  '{}' --dateadd(month, -1, dateadd(day,1,eomonth(getdate(),-1)))
			and l.InvestmentProductID = 1
			and l.LoanID is not null

		group by
			li.Term
			,RatingCodeSortable
			,RatingCode

		order by
			li.Term
			,RatingCodeSortable
