drop table #loanperf
create table #loanperf (
	 LoanID						INT
	,ObservationMonth			INT
	,DefaultAmount				INT
	,ChargeoffAmount			INT
	,NetRecovery				INT
	,PrinBal					INT
	)

insert into #loanperf
	select 
	llm.LoanID
	,llm.ObservationMonth
	,llm.DefaultAmount
	,llm.ChargeoffAmount
	,llm.RecoveryPayments as NetRecovery
	,llm.EOMPrinAdjusted as PrinBal
	from DW..dw_LoanLevelMonthly llm
		inner join 
		(
			select max(llm.ObservationMonth) as LatestMonth, llm.LoanID
			from DW..dw_LoanLevelMonthly llm
			where 1=1
				and llm.OriginationDate > '2015-01-01' 
				and llm.EOMPrinAdjusted > 0
			group by llm.LoanID
		) DateDT
		on llm.ObservationMonth = DateDT.LatestMonth
		and llm.LoanID = DateDT.LoanID
	where 1=1
		and llm.OriginationDate > '2015-01-01'
		and llm.EOMPrinAdjusted > 0

select top 10 * 
from #loanperf	