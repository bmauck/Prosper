USE DW
/*CPR RELATED CALCS*/
/*  STAGING SEGMENT
The idea is to modify the fields to fit the formatting of this report.  There are a few data cleaning
steps taken as well as a part of this process.
observe post-settlement/extension
embed second WITH statement into LoanData?
*/
/*AgeQ is a field that approximates the minimum possible cyclecounter at the point of an observation*/
/*Cleaning Principal amounts to zero out discrepancies from Principal balance after chargeoff and any cases where Principal amounts drop below 0*/
/*Transform Chargeoff Amount into a periodic field*/
/*Remove points from scheduling after a terminal event */
declare @endmonth varchar(6)
declare @Product int
set @endmonth = '201904'      --for payment data, set to end of previous month
declare @throughdate varchar(6) = CAST(YEAR(DATEADD(MM,-1,DATEFROMPARTS(LEFT(@endmonth,4),RIGHT(@endmonth,2),1))) AS VARCHAR(4)) + RIGHT('00'+CAST(MONTH(DATEADD(MM,-1,DATEFROMPARTS(LEFT(@endmonth,4),RIGHT(@endmonth,2),1))) AS VARCHAR(2)),2)
set @Product = 1            --1 for Prime, 2 for EP, 3 for PHL

USE DW
--segment of the code for determining which months to drop off the list.  This is necessary since Cyclecounter terminal is not equal for all loans in a vintage
IF object_id('tempdb..#EndCycle') is not null drop table #EndCycle
select OriginationQuarter
, MIN(CycleCounter) as EndCycle
into #EndCycle
from vloanlevelmonthly
where ObservationMonth = '201904'
--and loanid = 866175 --TODO: Testing
group by OriginationQuarter

USE DW
--loss level information 
IF object_id('tempdb..#CumRecovery') is not null drop table #CumRecovery
(select llm1.LoanID
, llm1.CycleCounter
, SUM(llm2.RecoveryPrin) as RecoveryPrin --actual recovery prin
, SUM(case when llm2.ObservationMonth = llm2.DebtSaleMonth then llm2.NetCashToInvestorsFromDebtSale else 0 end) as DebtSale --debt sale proceeds
, SUM(case when llm2.ExplicitRoll in ('PreviouslyChargedOff','MonthOfDebtSale','PreviouslySoldDebtSale','PreviouslyDefaulted') then llm2.PrincipalPaid else 0 end) as OtherRecoveryPrin --nonexplicitprinpaid
, SUM(case when llm2.ExplicitRoll in ('NoChangeMonthOfPayoff','PreviouslyPaidOff') then llm2.PrincipalPaid else 0 end) as CumPrepayment
into #CumRecovery
from vloanlevelmonthly llm1
inner join vloanlevelmonthly llm2 on (llm1.LoanID = llm2.LoanID and llm1.CycleCounter >= llm2.CycleCounter)
where 
	1=1
	and llm1.loanproductid = 1
    and llm1.OrigMID >= 201001
	--and llm1.loanid = 866175 --TODO: Testing
group by llm1.LoanID, llm1.CycleCounter)

USE DW
--adjustments to meet market conventions
IF object_id('tempdb..#LoanData') is not null drop table #LoanData
(select llm.*
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
, COALESCE(llm.explicitroll, llm.explicitroll_EOM, summaryroll) as Clean_Roll
, IsUnderSettlement = case when SettlementStatus = 'settlecomp' and LEFT(CONVERT(varchar, SettlementEndDate,112),6) <= ObservationMonth then 1 else 0 end
into #LoanData
from vloanlevelmonthly llm  --update this table monthly (will happen with a view in the future)
where Year(OriginationDate) >= 2010
    and term <> 12 
    and LoanProductID = 1) --only consider post-2010, no 12 month loans (not currently offered) and with Prime product.
	--and loanid = 866175 --TODO: Testing
	

/*  MAIN QUERY
This transforms loan level data into vintage level information
Can be grouped either by Cyclecounter or ObservationMonth; worth discussing.
Will also want to add more cumulative fields
*/

USE [tempdb]
GO
CREATE NONCLUSTERED INDEX [vintage_ix]
ON [dbo].[#LoanData] ([OrigMID])
INCLUDE ([LoanID],[ListingNumber],[LoanAmount],[ProsperRating],[Term],[BorrowerRate],[OriginationQuarter],[DebtSaleMonth],[GrossCashFromDebtSale],[NetCashToInvestorsFromDebtSale],[SettlementEndDate],[SettlementStatus],[ObservationMonth],[CycleCounter],[DaysPastDue_EOM],[CollectionFees],[PrincipalPaid],[InterestPaid],[LateFees],[ServicingFees],[RecoveryPrin],[PrinAdjustments],[CumulPrin],[CumulCO],[CumulBK],[MargPrinCO],[MargPrinBK],[ScheduledCumulPrin],[ScheduledPeriodicPrin],[Clean_EOM_Prin],[Clean_BOM_Prin],[Clean_ScheduledPayment],[Clean_ScheduledInterest],[Clean_SchedPrin],[IsUnderSettlement])
GO

CREATE NONCLUSTERED INDEX [vintage_ix2]
ON [dbo].[#LoanData] ([OriginationQuarter],[OrigMID],[CycleCounter])
INCLUDE ([LoanID],[ListingNumber],[LoanAmount],[ProsperRating],[Term],[BorrowerRate],[DebtSaleMonth],[GrossCashFromDebtSale],[NetCashToInvestorsFromDebtSale],[SettlementEndDate],[SettlementStatus],[ObservationMonth],[DaysPastDue_EOM],[CollectionFees],[PrincipalPaid],[InterestPaid],[LateFees],[ServicingFees],[RecoveryPrin],[PrinAdjustments],[CumulPrin],[CumulCO],[CumulBK],[MargPrinCO],[MargPrinBK],[ScheduledCumulPrin],[ScheduledPeriodicPrin],[Clean_EOM_Prin],[Clean_BOM_Prin],[Clean_ScheduledPayment],[Clean_ScheduledInterest],[Clean_SchedPrin],[IsUnderSettlement])
GO

SELECT 
	ld.OriginationQuarter
	, ld.ProsperRating
	, ld.Term
	, ld.CycleCounter
	, SUM(LoanAmount) as LoanAmount
	, sum(BorrowerRate * LoanAmount)/sum(LoanAmount) as AvgBorrowerRate
	, SUM(Clean_BOM_Prin) as PrevUPB
	, SUM(Clean_EOM_Prin) as UPB
	, SUM(Clean_ScheduledPayment) as ScheduledMonthlyPaymentAmount
	, SUM(Clean_SchedPrin) as ScheduledPeriodicPrin
	, SUM(Clean_ScheduledInterest) as ScheduledInterest
	, sum(case when (CumulCO = 0 and CumulBK = 0 and IsUnderSettlement = 0) then PrincipalPaid else 0 end) as PrincipalPaid
	, SUM(case 
	            when (Clean_EOM_Prin = 0 
	                    and ld.CycleCounter < ld.Term 
	                    and IsUnderSettlement = 0 
	                    and (CumulCO = 0 and CumulBK = 0)
	                    and PrincipalPaid > ScheduledPeriodicPrin
	                    and CumulPrin > ScheduledCumulPrin) then (PrincipalPaid - ScheduledPeriodicPrin) else 0 end) as FullPaydowns --excluding scheduled
	, SUM(case
	            when (Clean_EOM_Prin > 0 
	                    and ld.CycleCounter < ld.Term 
	                    and (CumulCO = 0 and CumulBK = 0)
	                    and IsUnderSettlement = 0 
	                    and PrincipalPaid > ScheduledPeriodicPrin 
	                    and CumulPrin > ScheduledCumulPrin) then (PrincipalPaid - ScheduledPeriodicPrin) else 0 end) as VoluntaryExcessPrin --excluding scheduled
	,ExpectedPrinPaid = SUM(case when (ld.CycleCounter < ld.Term 
	                    and (CumulCO = 0 and CumulBK = 0)
	                    and IsUnderSettlement = 0
	                    and PrincipalPaid > ScheduledPeriodicPrin 
	                    and CumulPrin > ScheduledCumulPrin) then (ScheduledPeriodicPrin) else 0 end)
	, sum(case when IsUnderSettlement = 1 then 0 else InterestPaid end) as InterestPaid
	, SUM(case when IsUnderSettlement = 1 then 0 else ServicingFees end) as SVC_Fees
	, SUM(case when IsUnderSettlement = 1 then 0 else ServicingFees+CollectionFees+LateFees end) as TotalFees
	, CO_Balance = SUM(MargPrinBK + MargPrinCO) + sum(case when SettlementStatus = 'settlecomp' 
	                            and LEFT(CONVERT(varchar, SettlementEndDate,112),6) <= ObservationMonth
	                            then PrinAdjustments else 0 end)  
	, sum((case when (CumulCO > 0 or CumulBK > 0) then PrincipalPaid else 0 end) + ld.RecoveryPrin) as RecoveryPrinPaid
	, NetCO_FromSettlement = sum(case when SettlementStatus = 'settlecomp' 
	                            and LEFT(CONVERT(varchar, SettlementEndDate,112),6) <= ObservationMonth
	                            then PrinAdjustments else 0 end)
	, sum(case when debtsalemonth = observationmonth then GrossCashFromDebtSale else 0 end) as GrossCashFromDebtSale
	, sum(case when debtsalemonth = observationmonth then NetCashToInvestorsFromDebtSale else 0 end) as NetCashToInvestorsFromDebtSale
	, sum(case when (DaysPastDue_EOM > 0 and Clean_EOM_Prin > 0) then Clean_BOM_Prin else 0 end)/sum(LoanAmount) as [DPD_1+] --remove the prin paid filter when EOM DPD exists
	,[DPD_16+] = cast(sum(case when (DaysPastDue_EOM > 15 and Clean_EOM_Prin > 0) then cast(Clean_BOM_Prin as decimal(19,10)) else 0.00 end)/sum(cast(LoanAmount as decimal(19,10))) as decimal(19,10)) --remove the prin paid filter when EOM DPD exists
	, sum(case when (DaysPastDue_EOM > 30 and Clean_EOM_Prin > 0) then Clean_BOM_Prin else 0 end)/sum(LoanAmount) as [DPD_31+] --remove the prin paid filter when EOM DPD exists
	, sum(case when (DaysPastDue_EOM > 60 and Clean_EOM_Prin > 0) then Clean_BOM_Prin else 0 end)/sum(LoanAmount) as [DPD_61+] --remove the prin paid filter when EOM DPD exists
	, sum(case when (DaysPastDue_EOM > 90 and Clean_EOM_Prin > 0) then Clean_BOM_Prin else 0 end)/sum(LoanAmount) as [DPD_91+] --remove the prin paid filter when EOM DPD exists
	, sum(CumulBK + CumulCO) + sum(case when SettlementStatus = 'settlecomp' 
	                            and LEFT(CONVERT(varchar, SettlementEndDate,112),6) <= ObservationMonth
	                            then PrinAdjustments else 0 end) as CumulativeGrossLosses
	,CumulativeGrossLossesPct = cast( (sum(cast(CumulBK as decimal(19,10)) + cast(CumulCO as decimal(19,10))) + sum(case when SettlementStatus = 'settlecomp' 
	                            and LEFT(CONVERT(varchar, SettlementEndDate,112),6) <= ObservationMonth
	                            then cast(PrinAdjustments as decimal(19,10)) else 0.00 end))/sum(cast(LoanAmount as decimal(19,10))) as decimal(19,10))
	, sum(CumulBK + CumulCO - cr.DebtSale - cr.RecoveryPrin - cr.OtherRecoveryPrin) + sum(case when SettlementStatus = 'settlecomp' 
	                            and LEFT(CONVERT(varchar, SettlementEndDate,112),6) <= ObservationMonth
	                            then PrinAdjustments else 0 end) as CumulativeNetLosses                                                                     
	, (sum(CumulBK + CumulCO - cr.DebtSale - cr.RecoveryPrin - cr.OtherRecoveryPrin) + sum(case when SettlementStatus = 'settlecomp' 
	                            and LEFT(CONVERT(varchar, SettlementEndDate,112),6) <= ObservationMonth
	                            then PrinAdjustments else 0 end))/sum(LoanAmount) as CumulativeNetLossesPct
	, cast(sum(li.DisplayedScore * ld.LoanAmount) / SUM(ld.LoanAmount) as int) as FICO
	, cast(sum(li.BorrowerStatedIncome * ld.LoanAmount) / SUM(ld.LoanAmount) as int) as Income
	FROM 
		#LoanData ld
	left join 
		#CumRecovery cr 
		on 
		ld.LoanID = cr.LoanID 
		and 
		ld.CycleCounter = cr.CycleCounter
	left join 
		#EndCycle cyc 
		on 
		ld.OriginationQuarter = cyc.OriginationQuarter
	left join 
		dw..dim_listing li 
		on 
		li.ListingID = ld.ListingNumber
	where 
		1=1
		and ld.OrigMID <= 201903 --set for 1 month lag from @endmonth
		and ld.CycleCounter <= ld.Term  --want to discuss; if we do monthly vintages, this isn't needed.
		and ld.CycleCounter <= cyc.EndCycle 
	GROUP BY 
	ld.OriginationQuarter
	, ld.ProsperRating
	, ld.Term
	, ld.CycleCounter
	Order by 
	ld.OriginationQuarter
	, ld.ProsperRating
	, ld.Term
	, ld.CycleCounter
	-- remove the last two MOB obs for each vintage if quarterly


"""
in a given month of all the loans that made a prepayment in the same given month, the aggregate sum of principal that was not prepaid
"""