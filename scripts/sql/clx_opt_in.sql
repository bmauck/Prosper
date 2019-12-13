use TabReporting

select * from investoreligibility_master

where lenderid in (6030916, 6078093)
order by LoanGroup desc