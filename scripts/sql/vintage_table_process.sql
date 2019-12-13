use DW
if object_id('tempdb..#EndCycle') is not null 
	drop table #EndCycle
select 
	OriginationQuarter
	, min(CycleCounter) as EndCycle
	into #EndCycle
	from 
		vloanlevelmonthly
	where 
		1=1
		and ObservationMonth between '201809' and '201810'
	group by OriginationQuarter


if object_id('tempdb..#CumRecovery') is not null 
	drop table #CumRecovery
select 
	llm1.LoanID
	, llm1.CycleCounter
	, sum(llm2.RecoveryPrin) as RecoveryPrin --actual recovery prin
	, sum(case when llm2.ObservationMonth = llm2.DebtSaleMonth then llm2.NetCashToInvestorsFromDebtSale else 0 end) as DebtSale --debt sale proceeds
	, sum(case when llm2.ExplicitRoll in ('PreviouslyChargedOff','MonthOfDebtSale','PreviouslySoldDebtSale','PreviouslyDefaulted') then llm2.PrincipalPaid else 0 end) as OtherRecoveryPrin --nonexplicitprinpaid
	, sum(case when llm2.ExplicitRoll in ('NoChangeMonthOfPayoff','PreviouslyPaidOff') then llm2.PrincipalPaid else 0 end) as CumPrepayment
	into #CumRecovery
	from 
		DW..vloanlevelmonthly llm1
		inner join DW..vloanlevelmonthly llm2 
		on (llm1.LoanID = llm2.LoanID and llm1.CycleCounter >= llm2.CycleCounter)
	where 
		1=1 
		and llm1.loanproductid = 1
		and llm1.OrigMID between 201808 and 201809
	group by llm1.LoanID, llm1.CycleCounter

rollback
drop table 
Sandbox..bm_vintageCycleCounter


select 
* 
into Sandbox..bm_vintageCycleCounter
from #EndCycle

select * from Sandbox..bm_vintageCumulRecovery

begin tran
drop table Sandbox..bm_vintageCumulRecovery
select 
* 
into  Sandbox..bm_vintageCumulRecovery
from #CumRecovery

commit

if object_id('tempdb..#LoanData') is not null drop table #LoanData
select 
	llm.*
	, (case when (CumulCO > 0 or CumulBK > 0) or EOMPrin < 0 then 0
			  when (SettlementStatus = 'settlecomp') then EOMPrinAdjusted
			  else EOMPrin end) as Clean_EOM_Prin
	, (case when (ExplicitRoll in ('PreviouslyChargedOff','PreviouslySoldDebtSale','MonthOfDebtSale','PreviouslyDefaulted') or BOMPrin <= 0) then 0
			  when (SettlementStatus = 'settlecomp') then BOMPrinAdjusted
			  else BOMPrin end) as Clean_BOM_Prin
	, (case when (llm.CycleCounter = 0 or ((MargPrinBK + MargPrinCO) = 0 and (CumulCO + CumulBK) > 0) or BOMPrin <= 0) then 0
				when (year(SettlementEndDate) < left(ObservationMonth,4) or (year(SettlementEndDate) = left(ObservationMonth,4) and month(settlementenddate) < right(ObservationMonth,2))) then 0
				else ScheduledMonthlyPaymentAmount end) as Clean_ScheduledPayment
	, (case when (llm.CycleCounter = 0 or ((MargPrinBK + MargPrinCO) = 0 and (CumulCO + CumulBK) > 0) or BOMPrin <= 0) then 0
				when (year(SettlementEndDate) < left(ObservationMonth,4) or (year(SettlementEndDate) = left(ObservationMonth,4) and month(settlementenddate) < right(ObservationMonth,2))) then 0
				else (BorrowerRate / 12 * BOMPrin) end) as Clean_ScheduledInterest
	, (case when (llm.CycleCounter = 0 or ((MargPrinBK + MargPrinCO) = 0 and (CumulCO + CumulBK) > 0) or BOMPrin <= 0) then 0
				when (year(SettlementEndDate) < left(ObservationMonth,4) or (year(SettlementEndDate) = left(ObservationMonth,4) and month(settlementenddate) < right(ObservationMonth,2))) then 0
				else (CASE WHEN ((ScheduledMonthlyPaymentAmount - BorrowerRate/12 * BOMPrin) > BOMPrin) THEN BOMPrin ELSE (ScheduledMonthlyPaymentAmount - BorrowerRate/12 * BOMPrin) END) END) as Clean_SchedPrin
	, coalesce(llm.explicitroll, llm.explicitroll_EOM, summaryroll) as Clean_Roll
	, IsUnderSettlement = case when SettlementStatus = 'settlecomp' and LEFT(convert(varchar, SettlementEndDate,112),6) <= ObservationMonth then 1 else 0 end
	into 
	#LoanData
	from 
	dw..vloanlevelmonthly llm  
	where 
		1=1
		--and OriginationDate between '2018-09-01' and '2018-10-01'
		and term <> 12
		and loanproductid = 1

begin tran
drop table Sandbox..bm_vintageLoanData

select * 
into Sandbox..bm_VintageLoanData
from 
#LoanData

commit
