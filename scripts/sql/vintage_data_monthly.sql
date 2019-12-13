with month_id_cte as (
	
	select 
		case when 
			len(month(dateadd(month, -1, getdate()	
					)	
				)	
			) = 1
		then  
			cast(year(dateadd(month, -1, getdate()
					)
				) as varchar) 
			+ '0' 
			+ cast(month(dateadd(month, -1, getdate()
					)
				) as varchar) 
		when 
			len(month(dateadd(month, -1, getdate()
					)
				)
			) = 2
		then 
			cast(year(dateadd(month, -1, getdate()
					)
				) as varchar)
			+ ''
			+ cast(month(dateadd(month, -1, getdate()
					)
				) as varchar) 
		end obsv_month 
)
,
end_cycle_cte as (
	select 
		OrigMID
		,min(CycleCounter) as EndCycle
		from 
			DW.dbo.vloanlevelmonthly
		where 
			1=1
			and ObservationMonth = (select * from month_id_cte)
			and OrigMID >= 201806
		group by 
			OrigMID
)
,
cumul_recovery_cte as (
	select 
		llm1.LoanID
		,llm1.CycleCounter
		,sum(llm2.RecoveryPrin) RecoveryPrin
		,sum(case when llm2.ObservationMonth = llm2.DebtSaleMonth then llm2.NetCashToInvestorsFromDebtSale else 0 end) as DebtSale
		,sum(case when llm2.ExplicitRoll in ('PreviouslyChargedOff','MonthOfDebtSale','PreviouslySoldDebtSale','PreviouslyDefaulted') then llm2.PrincipalPaid else 0 end) as OtherRecoveryPrin 
		,sum(case when llm2.ExplicitRoll in ('NoChangeMonthOfPayoff','PreviouslyPaidOff') then llm2.PrincipalPaid else 0 end) as CumPrepayment
		from 
			DW.dbo.vloanlevelmonthly llm1
		inner join 
			DW.dbo.vloanlevelmonthly llm2 
			on 
			llm1.LoanID = llm2.LoanID 
			and llm1.CycleCounter >= llm2.CycleCounter
		where
			1=1 
			and llm1.LoanProductID = 1
			and llm1.OrigMID >= 201806
		group by 
			llm1.LoanID
			,llm1.CycleCounter
)
,
loan_data_cte as (
	select 
		llm.*
		,case 
			when (CumulCO > 0 or CumulBK > 0) or EOMPrin < 0 
			then 0 
			when SettlementStatus = 'settlecomp'
			then EOMPrinAdjusted 
		    else EOMPrin 
			end Clean_EOM_Prin
		,case 
			when (ExplicitRoll in ('PreviouslyChargedOff','PreviouslySoldDebtSale','MonthOfDebtSale','PreviouslyDefaulted') or BOMPrin <= 0) 
			then 0  
			when (SettlementStatus = 'settlecomp') 
			then BOMPrinAdjusted 
			else BOMPrin 
			end Clean_BOM_Prin
		,case 
			when (llm.CycleCounter = 0 or ((MargPrinBK + MargPrinCO) = 0 and (CumulCO + CumulBK) > 0) or BOMPrin <= 0) 
			then 0 
            when (year(SettlementEndDate) < left(ObservationMonth,4) or (year(SettlementEndDate) = left(ObservationMonth,4) and month(settlementenddate) < right(ObservationMonth,2))) 
			then 0
            else ScheduledMonthlyPaymentAmount 
			end Clean_ScheduledPayment
		,case 
			when (llm.CycleCounter = 0 or ((MargPrinBK + MargPrinCO) = 0 and (CumulCO + CumulBK) > 0) or BOMPrin <= 0) 
			then 0 
            when (year(SettlementEndDate) < left(ObservationMonth,4) or (year(SettlementEndDate) = left(ObservationMonth,4) and month(settlementenddate) < right(ObservationMonth,2))) 
			then 0
            else (BorrowerRate / 12 * BOMPrin) 
			end Clean_ScheduledInterest
		,case 
			when (llm.CycleCounter = 0 or ((MargPrinBK + MargPrinCO) = 0 and (CumulCO + CumulBK) > 0) or BOMPrin <= 0) 
			then 0 
            when (year(SettlementEndDate) < left(ObservationMonth,4) or (year(SettlementEndDate) = left(ObservationMonth,4) and month(settlementenddate) < right(ObservationMonth,2))) 
			then 0
            else (case 
					when((ScheduledMonthlyPaymentAmount - BorrowerRate/12 * BOMPrin) > BOMPrin) 
					then BOMPrin 
					else (ScheduledMonthlyPaymentAmount - BorrowerRate/12 * BOMPrin) end) 
			end Clean_SchedPrin
		,coalesce(llm.explicitroll, llm.explicitroll_EOM, summaryroll) Clean_Roll
		,case 
			when SettlementStatus = 'settlecomp' and LEFT(CONVERT(varchar, SettlementEndDate,112),6) <= ObservationMonth
			then 1 
			else 0 
			end IsUnderSettlement
		from 
			DW.dbo.vloanlevelmonthly llm
		where 
			1=1
			and OrigMID >= 201806
			and Term <> 12
			and LoanProductID = 1
)
select
	ld.OrigMID
	--, ld.ProsperRating
	--, ld.Term
	,ld.CycleCounter
	,sum(LoanAmount) LoanAmount
	,sum(BorrowerRate * LoanAmount)/sum(LoanAmount) AvgBorrowerRate
	,sum(Clean_BOM_Prin) prev_upb
	,sum(Clean_EOM_Prin) upb
	,sum(Clean_ScheduledPayment) ScheduledMonthlyPaymentAmount
	,sum(Clean_SchedPrin) ScheduledPeriodicPrin
	,sum(Clean_ScheduledInterest) ScheduledInterest
	,sum(case 
			when (CumulCO = 0 and CumulBK = 0 and IsUnderSettlement = 0) 
			then PrincipalPaid 
			else 0 
			end) PrincipalPaid
	,sum(case
			when (Clean_EOM_Prin = 0 
					and ld.CycleCounter < ld.Term 
	                and IsUnderSettlement = 0 
	                and (CumulCO = 0 and CumulBK = 0)
	                and PrincipalPaid > ScheduledPeriodicPrin
	                and CumulPrin > ScheduledCumulPrin) 
			then (PrincipalPaid - ScheduledPeriodicPrin) 
			else 0 
			end) FullPaydowns 
	,sum(case
			when (Clean_EOM_Prin > 0 
					and ld.CycleCounter < ld.Term 
	                and (CumulCO = 0 and CumulBK = 0)
	                and IsUnderSettlement = 0 
	                and PrincipalPaid > ScheduledPeriodicPrin 
	                and CumulPrin > ScheduledCumulPrin) 
			then (PrincipalPaid - ScheduledPeriodicPrin) 
			else 0 
			end) VoluntaryExcessPrin 
	,sum(case 
			when (ld.CycleCounter < ld.Term 
					and (CumulCO = 0 and CumulBK = 0)
	                and IsUnderSettlement = 0
	                and PrincipalPaid > ScheduledPeriodicPrin 
	                and CumulPrin > ScheduledCumulPrin) 
			then (ScheduledPeriodicPrin) 
			else 0 
			end) ExpectedPrinPaid
	,sum(case 
			when IsUnderSettlement = 1 
			then 0 
			else InterestPaid 
			end) InterestPaid
	,sum(case 
			when IsUnderSettlement = 1 
			then 0 
			else ServicingFees 
			end) SVC_Fees
	,sum(case 
			when IsUnderSettlement = 1 
			then 0 
			else ServicingFees+CollectionFees+LateFees 
			end) TotalFees
	,sum(MargPrinBK + MargPrinCO) + 
	 sum(case 
			when SettlementStatus = 'settlecomp'
				and left(convert(varchar, SettlementEndDate,112),6) <= ObservationMonth
			then PrinAdjustments 
			else 0 end) CO_Balance  
	,sum((case 
			when (CumulCO > 0 or CumulBK > 0) 
			then PrincipalPaid 
			else 0 
			end) + ld.RecoveryPrin) RecoveryPrinPaid
	,sum(case 
			when SettlementStatus = 'settlecomp'
				and left(convert(varchar, SettlementEndDate,112),6) <= ObservationMonth
			then PrinAdjustments 
			else 0 
			end) NetCO_FromSettlement
	,sum(case 
			when DebtSaleMonth = ObservationMonth
			then GrossCashFromDebtSale 
			else 0 
			end) as GrossCashFromDebtSale
	,sum(case 
			when DebtSaleMonth = ObservationMonth 
			then NetCashToInvestorsFromDebtSale 
			else 0 
			end) as NetCashToInvestorsFromDebtSale
	,sum(case 
			when (DaysPastDue_EOM > 0 and Clean_EOM_Prin > 0) 
			then Clean_BOM_Prin 
			else 0 
			end)/sum(LoanAmount) [DPD_1+]
	,sum(case 
			when (DaysPastDue_EOM > 15 and Clean_EOM_Prin > 0) 
			then (Clean_BOM_Prin) 
			else 0 
			end)/sum(LoanAmount) [DPD_16+]
	,sum(case 
			when (DaysPastDue_EOM > 30 and Clean_EOM_Prin > 0) 
			then Clean_BOM_Prin 
			else 0 
			end)/sum(LoanAmount) [DPD_31+] 
	,sum(case 
			when (DaysPastDue_EOM > 60 and Clean_EOM_Prin > 0) 
			then Clean_BOM_Prin 
			else 0 
			end)/sum(LoanAmount) [DPD_61+] 
	,sum(case 
			when (DaysPastDue_EOM > 90 and Clean_EOM_Prin > 0) 
			then Clean_BOM_Prin 
			else 0 
			end)/sum(LoanAmount) [DPD_91+] 
	,sum(CumulBK + CumulCO) + 
	 sum(case 
			when SettlementStatus = 'settlecomp' 
				and left(convert(varchar, SettlementEndDate,112),6) <= ObservationMonth
			then PrinAdjustments 
			else 0 
			end) CumulativeGrossLosses
	,(sum(cumulBK + CumulCO) + 
	 sum(case 
			when SettlementStatus = 'settlecomp' 
				and left(convert(varchar, SettlementEndDate,112),6) <= ObservationMonth
			then PrinAdjustments 
			else 0
			end))/sum(LoanAmount) CumulativeGrossLossesPct
	,sum(CumulBK + CumulCO - cr.DebtSale - cr.RecoveryPrin - cr.OtherRecoveryPrin) + 
	 sum(case 
			when SettlementStatus = 'settlecomp' 
				and left(convert(varchar, SettlementEndDate,112),6) <= ObservationMonth
			then PrinAdjustments else 0 end) CumulativeNetLosses                                                                     
	,(sum(CumulBK + CumulCO - cr.DebtSale - cr.RecoveryPrin - cr.OtherRecoveryPrin) + 
	 sum(case 
		when SettlementStatus = 'settlecomp' 
	         and left(convert(varchar, SettlementEndDate,112),6) <= ObservationMonth
		then PrinAdjustments 
		else 0 
		end))/sum(LoanAmount) CumulativeNetLossesPct
	,sum(li.DisplayedScore * ld.LoanAmount) / sum(ld.LoanAmount) FICO
	,sum(li.BorrowerStatedIncome * ld.LoanAmount) / sum(ld.LoanAmount) Income
	from 
		loan_data_cte ld
	left join 
		cumul_recovery_cte cr
		on 
		ld.LoanID = cr.LoanID 
		and 
		ld.CycleCounter = cr.CycleCounter
	left join 
		end_cycle_cte cyc
		on 
		ld.OrigMID = cyc.OrigMID
	left join 
		dw..dim_listing li 
		on 
		li.ListingID = ld.ListingNumber
	where 
		1=1
		and ld.OrigMID >= 201806
--		and ld.CycleCounter <= ld.Term
--		and ld.CycleCounter <= cyc.EndCycle 
	group by
		ld.OrigMID
		--, ld.ProsperRating
		--, ld.Term
		, ld.CycleCounter
		Order by 
		ld.OrigMID
		--, ld.ProsperRating
		--, ld.Term
		,ld.CycleCounter

