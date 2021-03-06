USE [AirPuffier]
GO
/****** Object:  StoredProcedure [dbo].[p_add_OWM_json]    Script Date: 09/08/2020 09:24:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Mat Ciszkiewicz>
-- Create date: <Create Date,30/07/2020,>
-- Description:	<Description,
--The procedure consists in making a query to the openweathermap HTTP server
-- decode Json data and save to individual variables in the OWM table,>
-- =============================================
ALTER PROCEDURE [dbo].[p_add_OWM_json]

AS
BEGIN
-- Variable declaration to identifier a request 
DECLARE @CurrentDate datetime
DECLARE @EspGuid uniqueidentifier  
SET @EspGuid = NEWID()  
SET @CurrentDate = GETDATE()
-- Variable declaration related to the Object.
DECLARE @token INT;
DECLARE @ret INT;

-- Variable declaration related to the Request.
DECLARE @url NVARCHAR(MAX);
DECLARE @authHeader NVARCHAR(64);
DECLARE @contentType NVARCHAR(64);

-- Variable declaration related to the JSON string.
DECLARE @json AS TABLE(Json_Table NVARCHAR(MAX))

-- Set Authentications from "my" configuration table 
SET @authHeader = (SELECT CONFIG_KEY FROM CONFIG WHERE CONFIG_NAME ='openweathermap');

-- Set the API Key, I'm just grabbing it from another table in my Database.

-- Define the URL
SET @url = 'http://api.openweathermap.org/data/2.5/weather?q=KRAK%C3%93W,pl&units=metric&APPID='+@authHeader
-- This creates the new object.
EXEC @ret = sp_OACreate 'MSXML2.XMLHTTP', @token OUT;
IF @ret <> 0 RAISERROR('Unable to open HTTP connection.', 10, 1);

-- This calls the necessary methods.
EXEC @ret = sp_OAMethod @token, 'open', NULL, 'GET', @url, 'false';
EXEC @ret = sp_OAMethod @token, 'send'

INSERT into @json (Json_Table) EXEC sp_OAGetProperty @token, 'responseText';

--parse JSON file 

with CTE 
 as ( 
	 select * from OPENJSON((SELECT * FROM @Json  ))


	with (
			[main] nvarchar(max) as json
		)
		Parametr
		cross apply openjson (Parametr.main) 
		with  (
				[temp] float,
				[feels_like] float,
				[temp_min] float,
				[temp_max] float,
				[pressure] float,
				[humidity] float
			) as Results)
	
 -- insert value form JSON to OWM Table 

INSERT INTO OWM 
	([OWM_GUID]
	,[OWM_DATE]
	,[OWM_TEMPERATURE]
	,[OWM_TEMP_MAX]
	,[OWM_TEMP_MIN]
	,[OWM_TEMP_FL]
	,[OWM_PRESSURE]
	,[OWM_HUMIDITY]
	,[OWM_JSON_TEXT]
	)
Values 
	(@EspGuid
	,@CurrentDate
	,(select top 1 temp from CTE )
	,(select top 1 temp_max  from CTE)
	,(select top 1 temp_min  from CTE)
	,(select top 1 feels_like  from CTE)
	,(select top 1 pressure  from CTE)
	,(select top 1 humidity  from CTE)
	,(select * from @json)
	)


END

