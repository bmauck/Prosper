drop table #loandata

select 
	l.LoanID
	,li2.Term
	,l.OriginalAmountBorrowed
	,li2.RatingCode
	,l.originationDate
	,li2.FICOScore
	into 
	#loandata 
	from 
		CircleOne..Loans l 
	join 
		dw..dm_listing li2
		on 
		li2.ListingID = l.ListingID
	where 
		1=1
		--and l.LoanID in ()
		and l.OriginationDate between '2017-10-01' and '2018-09-30'
		--and li2.ratingCode in ('A', 'B', 'C')
		--and li2.InvestmentProductID = 1


select * from #loandata

select 
	RatingCode
	,Term
	,count(FICOScore) as 'Number'
	,sum(OriginalAmountBorrowed) as 'Volume'
	,sum(FICOScore) as 'Sum FICO'
	,sum(OriginalAmountBorrowed) / count(OriginalAmountBorrowed) as 'Average Loan Size' 
	from 
		#loandata
	group by 
		RatingCode,Term
	order by 
		Term

select
	#loandata.ListingID
	, #loandata.OriginalAmountBorrowed
	, #loandata.RatingCode
	, NumMonthlyPayments
	, #loanData.OriginationDate
	, #loandata.FICOScore
	, lofsd.Value as 'DTI Fully Loaded'
	, DTIwoProsperLoan as 'DTI Unloaded'
	from 
	#loandata
		outer apply (
				select top 1 
					LoanOfferID
					from 
					CircleOne..ListingOffersSelected 
					where 
					1=1
						and ListingID = #loandata.ListingID
						and VersionValidBit = 1
						and VersionEndDate IS NULL
						order by VersionStartDate desc
					) los
		left join CircleOne..LoanOffer lof
			on lof.LoanOfferID = los.LoanOfferID
		join 
			CircleOne..tblLoanOfferScoreDetail lofsd
			on 
			lofsd.ListingScoreID = lof.ListingScoreID
			and lofsd.VariableID = 709
	where
		1=1
		and lofsd.VariableID = 709
		--and lofsd.Value >= .45
		--and li2.FICOScore >=680
	--group by li2.RatingCode


