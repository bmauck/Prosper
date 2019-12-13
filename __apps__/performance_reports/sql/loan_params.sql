select
  parse_datetime('%E4Y%m', concat(
        cast(extract(year from ltl.OwnershipStartDate) as string)
        ,cast(extract(month from ltl.OwnershipStartDate) as string)
      )) as `MonthAcquired`
  ,ltl.LoanID
from
  `Circleone.LoanToLender` ltl
where
  1=1
  and ltl.LenderID = {}
