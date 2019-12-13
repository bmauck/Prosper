with user_cte as (
    select
        l.LoanID Loan
        ,l.BorrowerID UserID
		,l.OriginationDate
        from
            CircleOne..Loans l
        where
            1=1
            and l.LoanID in {}
)
,version_cte as (
    select
        a.UserID
		,Loan
        ,a.CreatedDate AgreementDate
		,user_cte.OriginationDate
        from
            user_cte
        join
            CircleOne..Agreements a
            on
            a.UserID = user_cte.UserID
        where
            1=1
            and a.UserID = user_cte.UserID
            and a.AgreementTypeID = {}
        
)
select 

    v.*
    ,at.Title
    ,a.ID
    ,cast(Circleone.dbo.fn_decompress(a.AgreementBodyBinary, len(a.AgreementBodyBinary)) as varchar(max)) html
    ,a.IsCorrectedAgreement
	,a.CreatedDate
	,a.*
    from
        version_cte v

    join
        CircleOne..Agreements a
        on
        a.UserID = v.UserID
    join
        CircleOne..AgreementTypes at
        on
        at.ID = a.AgreementTypeID
    where
        1=1
        and a.AgreementTypeID = {}
        and v.AgreementDate < OriginationDate
		and v.AgreementDate >= (OriginationDate - 30)
		and a.CreatedDate < OriginationDate
		and a.CreatedDate >= (OriginationDate - 30)
    


		