with fico_cte 
	 as
		(
		select 
			l.EndBalance
            ,l.LoanID
			,FICOScore
			,FICO = case
				when li.FICOScore between 0 and 599 then '0 - 599'
				when li.FICOScore between 600 and 624 then '600 - 624'
				when li.FICOScore between 625 and 649 then '625 - 649'
				when li.FICOScore between 650 and 674 then '650 - 674'
				when li.FICOScore between 675 and 699 then '675 - 699' 
				when li.FICOScore between 700 and 724 then '700 - 724'
				when li.FICOScore between 725 and 749 then '725 - 749'
				when li.FICOScore between 750 and 774 then '750 - 774'
				when li.FICOScore between 775 and 799 then '775 - 799'
				when li.FICOScore between 800 and 824 then '800 - 824'
				when li.FICOScore >= 825 then '825 - 850' 
				end
			
			
			,l.LenderID
		from 
			ProsperDatamart..MonthlyStatementsDW_LoanToLenderLevelDetail l
			join 
				Circleone..loans lo
				on 
				lo.LoanID = l.LoanID
			join 
				dw..dm_listing li
				on 
				li.ListingID = lo.ListingID			
            join 
				CircleOne..LoanToLender ltl
				on 
				lo.LoanID = ltl.LoanID
		
		where 
			1=1
			and l.LenderID = {}
			and l.StatementPeriod = '{}'
			
			and l.EndLoanStatusID = 1
			
		)

select
	
	FICO
	,count(EndBalance) as Units
	,sum(EndBalance) as Principal
	,sum((EndBalance * FICOScore)) / sum(EndBalance + .00001) as WtdFico 
	from 
		fico_cte
	group by 
		FICO

