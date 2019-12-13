with loan_params as (
  {}
)
,date_params as (
  select
  concat(
    cast(extract(
    year from current_date()
          ) as string)
   ,cast(extract(
    month from current_date()
          ) as string)
         )
)
,end_cycle as (
  select
    OriginationQuarter
    ,min(llm.ObservationMonth) as EndCycle
    from
      `DW.vloanlevelmonthly` llm
    where
      1=1
      and llm.ObservationMonth = '201909'
      and llm.LoanID in (select LoanID from loan_params)
     group by llm.OriginationQuarter
)
,cumul_recovery as (
  select
    llm1.LoanID
    ,llm1.ObservationMonth
    ,sum(llm2.RecoveryPrin) as RecoveryPrin
    ,sum(case
          when llm2.ObservationMonth = llm2.DebtSaleMonth
          then llm2.NetCashToInvestorsFromDebtSale
          else 0
          end
    ) as DebtSale
    ,sum(case
          when llm2.ExplicitRoll in ('PreviouslyChargedOff','MonthOfDebtSale','PreviouslySoldDebtSale','PreviouslyDefaulted')
          then llm2.PrincipalPaid
          else 0
          end
    ) as OtherRecoveryPrin
    ,sum(case
          when llm2.ExplicitRoll in ('NoChangeMonthOfPayoff','PreviouslyPaidOff')
          then llm2.PrincipalPaid
          else 0
          end
    ) as CumPrepayment
    from
      `DW.vloanlevelmonthly` llm1
      inner join
      `DW.vloanlevelmonthly` llm2
      on
        (
        llm1.LoanID = llm2.LoanID
        and llm1.ObservationMonth >= llm2.ObservationMonth
        )
    where
      1=1
      and llm1.LoanProductID = 1
      and llm1.OrigMID > 201001
      and llm1.LoanID in (select LoanID from loan_params)
    group by
      llm1.LoanID
      ,llm1.ObservationMonth
)
,loan_data as (
  select
    llm.*
    ,(case
      when (CumulCO > 0) or (CumulBK > 0) or (EOMPrin < 0)
      then 0
      when SettlementStatus = 'settlecomp'
      then EOMPrinAdjusted
      else EOMPrin
      end
    ) as cleanEOMPrin
    ,(case
       when (llm.ExplicitRoll in ('PreviouslyChargedOff','PreviouslySoldDebtSale','MonthOfDebtSale','PreviouslyDefaulted')) or (BOMPrin <= 0)
       then 0
       when (SettlementStatus = 'settlecomp')
       then BOMPrinAdjusted
       else BOMPrin
       end
     ) as cleanBOMPrin
    ,(case
        when (llm.CycleCounter = 0) or ((MargPrinBK + MargPrinCO) = 0 and (CumulCO + CumulBK) > 0) or (BOMPrin <= 0)
        then 0
        when extract(year from SettlementEndDate) < cast(substr(ObservationMonth,0,4) as int64) or extract(year from SettlementEndDate) = cast(substr(ObservationMonth,0,4) as int64)
          and extract(month from SettlementEndDate) < cast(substr(ObservationMonth,-2) as int64)
        then 0
        else ScheduledMonthlyPaymentAmount
        end
     ) as cleanScheduledPayment
    ,(case
        when ((llm.CycleCounter = 0) or ((MargPrinBK + MargPrinCO) = 0)) and (((CumulCO + CumulBK) > 0) or (BOMPrin <= 0))
        then 0
        when extract(year from SettlementEndDate) < cast(substr(ObservationMonth,0,4) as int64) or extract(year from SettlementEndDate) = cast(substr(ObservationMonth,0,4) as int64)
          and extract(month from settlementenddate) < cast(substr(ObservationMonth,-2) as int64)
        then 0
        else (BorrowerRate / 12 * BOMPrin)
        end
     ) as cleanScheduledInterest
     ,(case
        when (llm.CycleCounter = 0 or ((MargPrinBK + MargPrinCO) = 0 and (CumulCO + CumulBK) > 0) or BOMPrin <= 0)
        then 0
        when extract(year from SettlementEndDate) < cast(substr(ObservationMonth,0,4) as int64) or extract(year from SettlementEndDate) = cast(substr(ObservationMonth,0,4) as int64)
          and extract(month from settlementenddate) < cast(substr(ObservationMonth,-2) as int64)
        then 0
        else (case
                when ((ScheduledMonthlyPaymentAmount - BorrowerRate/12 * BOMPrin) > BOMPrin)
                then BOMPrin
                else (ScheduledMonthlyPaymentAmount - BorrowerRate/12 * BOMPrin)
                end)
        end
    ) as cleanScheduledPrin
    ,coalesce(llm.explicitroll, llm.explicitroll_EOM, summaryroll
    ) as cleanRoll
    ,(case
        when SettlementStatus = 'settlecomp' and extract(month from SettlementEndDate) <= cast(ObservationMonth as int64)
        then 1
        else 0
        end
    )as IsUnderSettlement
    from
      `DW.vloanlevelmonthly` llm
    where
      1=1
      and extract(year from llm.OriginationDate) >= 2010
      and term <> 12
      and llm.LoanProductID = 1
      and llm.LoanID in (select LoanID from loan_params)
)
select
  -- ld.OriginationQuarter
	ld.ProsperRating
	,ld.Term
	parse_datetime('%E4Y%m', ld.ObservationMonth) as ObsMonth
	,sum(LoanAmount) as LoanAmount
	,sum(BorrowerRate * LoanAmount)/sum(LoanAmount) as AvgBorrowerRate
	,sum(cleanBOMPrin) as PrevUPB
	,sum(cleanEOMPrin) as UPB
	,sum(cleanScheduledPayment) as ScheduledMonthlyPaymentAmount
	,sum(cleanScheduledPrin) as ScheduledPeriodicPrin
	,sum(cleanScheduledInterest) as ScheduledInterest
	,sum(case
        when (CumulCO = 0
          and CumulBK = 0
          and ld.IsUnderSettlement = 0)
        then PrincipalPaid
        else
        0 end
  ) as PrincipalPaid
	,sum(case
        when (CleanEOMPrin = 0
          and ld.CycleCounter < ld.Term
	        and IsUnderSettlement = 0
	        and (CumulCO = 0 and CumulBK = 0)
	        and PrincipalPaid > ScheduledPeriodicPrin
	        and CumulPrin > ScheduledCumulPrin)
        then (PrincipalPaid - ScheduledPeriodicPrin)
        else 0
        end
  ) as FullPaydowns --excluding scheduled
	,sum(case
        when (CleanEOMPrin > 0
	        and ld.CycleCounter < ld.Term
	        and (CumulCO = 0 and CumulBK = 0)
	        and IsUnderSettlement = 0
	        and PrincipalPaid > ScheduledPeriodicPrin
	        and CumulPrin > ScheduledCumulPrin)
        then (PrincipalPaid - ScheduledPeriodicPrin)
        else 0
        end
  ) as VoluntaryExcessPrin --excluding scheduled
	,sum(case
        when (ld.CycleCounter < ld.Term
	        and (CumulCO = 0 and CumulBK = 0)
	        and IsUnderSettlement = 0
	        and PrincipalPaid > ScheduledPeriodicPrin
	        and CumulPrin > ScheduledCumulPrin)
        then ScheduledPeriodicPrin
        else 0
        end
  ) as ExpectedPrinPaid
	,sum(case
        when IsUnderSettlement = 1
        then 0
        else InterestPaid
        end
  ) as InterestPaid
	,sum(case
        when IsUnderSettlement = 1
        then 0
        else ServicingFees
        end
  ) as SVC_Fees
	,sum(case
        when IsUnderSettlement = 1
        then 0
        else ServicingFees+CollectionFees+LateFees
        end
  ) as TotalFees
	,sum(MargPrinBK + MargPrinCO) + sum(case
                                       when SettlementStatus = 'settlecomp'
                                            and extract(month from SettlementEndDate) <= cast(ld.ObservationMonth as int64)
	                                          then PrinAdjustments
                                            else 0
                                            end
  ) as CO_Balance
	,sum((case
          when (CumulCO > 0 or CumulBK > 0)
          then PrincipalPaid
          else 0
          end) + ld.RecoveryPrin
  ) as RecoveryPrinPaid
	,sum(case
        when SettlementStatus = 'settlecomp'
	        and extract(month from SettlementEndDate) <= cast(ld.ObservationMonth as int64)
	      then PrinAdjustments
        else 0
        end
  ) as NetCO_FromSettlement
	,sum(case
        when debtsalemonth = ld.ObservationMonth
        then GrossCashFromDebtSale
        else 0
        end
  ) as GrossCashFromDebtSale
	,sum(case
        when debtsalemonth = ld.ObservationMonth
        then NetCashToInvestorsFromDebtSale
        else 0
        end
  ) as NetCashToInvestorsFromDebtSale
	,sum(case
        when (DaysPastDue_EOM > 0 and CleanEOMPrin > 0)
        then CleanBOMPrin
        else 0
        end
  )/sum(LoanAmount) as `DPD_1` --remove the prin paid filter when EOM DPD exists
	,sum(case
        when (DaysPastDue_EOM > 15 and CleanEOMPrin > 0)
        then CleanBOMPrin
        else 0
        end
  )/sum(LoanAmount) as `DPD_16` --remove the prin paid filter when EOM DPD exists
	,sum(case
        when (DaysPastDue_EOM > 30 and CleanEOMPrin > 0)
        then CleanBOMPrin
        else 0
        end
  )/sum(LoanAmount) as `DPD_31` --remove the prin paid filter when EOM DPD exists
	,sum(case
        when (DaysPastDue_EOM > 60 and CleanEOMPrin > 0)
        then CleanBOMPrin
        else 0
        end
  )/sum(LoanAmount) as `DPD_61` --remove the prin paid filter when EOM DPD exists
	,sum(case
        when (DaysPastDue_EOM > 90 and CleanEOMPrin > 0)
        then CleanBOMPrin
        else 0
        end
  )/sum(LoanAmount) as `DPD_91` --remove the prin paid filter when EOM DPD exists
	,sum(CumulBK + CumulCO) + sum(case
                                  when SettlementStatus = 'settlecomp'
	                                 and extract(month from SettlementEndDate) <= cast(ld.ObservationMonth as int64)
	                                then PrinAdjustments
                                  else 0
                                  end
  ) as CumulativeGrossLosses
	,(sum(CumulBK + CumulCO) + sum(case
                                  when SettlementStatus = 'settlecomp'
	                                  and extract(month from SettlementEndDate) <= cast(ld.ObservationMonth as int64)
	                                then PrinAdjustments
                                  else 0
                                  end)
  )/sum(LoanAmount) as CumulativeGrossLossesPct
	,sum(CumulBK + CumulCO - cr.DebtSale - cr.RecoveryPrin - cr.OtherRecoveryPrin) + sum(case
                                                                                        when SettlementStatus = 'settlecomp'
                                                                                         and extract(month from SettlementEndDate) <= cast(ld.ObservationMonth as int64)
                                                                                        then PrinAdjustments
                                                                                        else 0
                                                                                        end
  ) as CumulativeNetLosses
	,(sum(CumulBK + CumulCO - cr.DebtSale - cr.RecoveryPrin - cr.OtherRecoveryPrin) + sum(case
                                                                                          when SettlementStatus = 'settlecomp'
                                                                                            and extract(month from SettlementEndDate) <= cast(ld.ObservationMonth as int64)
                                                                                          then PrinAdjustments
                                                                                          else 0
                                                                                          end)
  )/sum(LoanAmount) as CumulativeNetLossesPct
	,cast(sum(li.DisplayedScore * ld.LoanAmount) / sum(ld.LoanAmount) as int64) as FICO
	,cast(sum(li.BorrowerStatedIncome * ld.LoanAmount) / sum(ld.LoanAmount) as int64) as Income
	from
    loan_data ld
	left join
    cumul_recovery cr
		on
		ld.LoanID = cr.LoanID
		and
		ld.ObservationMonth = cr.ObservationMonth
	left join
		end_cycle cyc
		on
		ld.OriginationQuarter = cyc.OriginationQuarter
	left join
		`DW.dim_listing` li
		on
		li.ListingID = ld.ListingNumber
	where
		1=1
    and ld.CycleCounter <= ld.Term
		and ld.ObservationMonth <= cyc.EndCycle
    and ld.LoanID in (select LoanID from loan_params)
    and parse_datetime('%E4Y%m', ld.ObservationMonth) > (select min(MonthAcquired) from loan_params)
	group by
    ObsMonth
  	,ld.ProsperRating
	  ,ld.Term
	  -- ,ld.CycleCounter
  order by
	  ObsMonth
	  ,ld.ProsperRating
	  ,ld.Term
	  -- ,ld.CycleCounter
