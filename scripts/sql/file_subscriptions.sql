with 
c as 
	(
	select
		* 
		from 
			SecureTransfer..Client c
		where
			1=1
			and c.ClientName = 'dv01'
	) 
,fs as 
	(
	select
		* 
		from 
			SecureTransfer..FileSubscription fs
		where
			1=1 
			and fs.UserID = 8609673
	) 
select
	ClientName
	,c.ClientID
	,fs.*
	from 
		c
	join 
		fs 
		on 
		fs.ClientID = c.ClientID
	where
		1=1
		and c.ClientID in (select ClientID from fs)
		and fs.IsActive = 1

select
	* 
	from SecureTransfer..SubscriptionAuthorization
	where
	RequestorCompany like '%dv01%'