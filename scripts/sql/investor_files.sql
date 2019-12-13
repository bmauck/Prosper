use ReportingProgrammability

declare @UserID INT        =		8804736
declare @start date		   =	  '2019-09-01'
declare @end Date          =      '2019-09-01'

exec ReportingProgrammability..Report_DailyLenderPacket_Positions			 @UserID,     @Start, @end
--exec Report_DailyLenderPacket_Payments			  @UserID,     @Start, @end
--exec Report_DailyLenderPacket_Transactions       @UserID,     @Start, @end
--exec Report_DailyLenderPacket_Remit @userid, @end
--exec Report_DailyLenderPacket_PositionsPending   @UserID,     @Start, @end
--exec [dbo].[Report_DailyLenderPacket_Borrower] @Start, @end, @userid, 0
--exec [dbo].[Report_DailyLenderPacket_ListingCreditAttributes] @Start, @end, @userid
--exec [dbo].[Report_DailyLenderPacket_FixedWidthGLFile]  @Start, @end, @userid

--exec [dbo].[Report_WholeLoans_FundingNotice_Details] @userid, @end
--exec [dbo].[usp_GetBorrowerApplicationXML] @userID, @start, @end, 0

--EXEC ReportingProgrammability.dbo.Report_ECI_Holdings 2093353, '4/1/2017'

-- To Re-run Borrower CSV File


--USE [ReportingProgrammability]
--GO
--
--DECLARE	@return_value int
--
--EXEC	@return_value = [dbo].[Report_DailyLenderPacket_Borrower]
--		@BegPeriod = '4/11/2017',
--		@EndPeriod = '4/12/2017',
--		@LenderID = 5513816,
--		@ScrubPII = 0
--

