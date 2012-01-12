USE [DOT]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- Clean up all our old stuff
IF  EXISTS (SELECT * FROM sys.triggers WHERE name = N'[dbo].[on_update_vehicle]')
DROP TRIGGER [dbo].[on_update_vehicle]
GO

IF OBJECT_ID('dbo.SP_On_vehicleUpdate_clr') IS NOT NULL
DROP PROCEDURE SP_On_vehicleUpdate_clr
GO

IF OBJECT_ID('dbo.vehicle_status', 'V') IS NOT NULL
DROP VIEW [dbo].[vehicle_status]
GO

IF OBJECT_ID('dbo.CLR_Configuration','U') IS NOT NULL
DROP TABLE  [dbo].[CLR_Configuration]
GO

IF EXISTS (SELECT * FROM sys.assemblies WHERE name = N'VEHICLE_UPDATE_CLR')
DROP ASSEMBLY VEHICLE_UPDATE_CLR
GO

--CREATES CONFIGURATION TABLE WHICH WILL HOLD A SET OF CONFIGURATION.

CREATE TABLE [dbo].[CLR_Configuration](
	[key] [varchar](50) NOT NULL,
	[value] [varchar](50) NOT NULL,
	
) ON [PRIMARY]

GO

INSERT INTO [dbo].CLR_Configuration ([key],value) VALUES('URL', 'http://localhost:1945/Home/Index')
GO

SET ANSI_PADDING OFF
GO

CREATE VIEW [dbo].[vehicle_status] as (
(SELECT  
		v.vehicle_id,
		v.loc_x AS 'latitude',
		v.loc_y AS 'longitude',
		v.average_speed AS 'speed',
		v.heading AS 'heading',
		v.vehicle_position_date_time,
		cps.direction_code_id as "route_direction",
		cps.route_id,
		cps.trip_id,
		its.incident_desc,
		cps.deviation as "last_stop_deviation",
		v.predicted_deviation,
		ctp.bs_id as 'previous_stop_id',
		ntp.bs_id as 'next_stop_id',
		(CAST((
		  CONVERT(VARCHAR(19), cps.incident_date_time, 102) + ' ' +
		  CONVERT(VARCHAR(19), ntp.eta,108)
		  ) AS DATETIME)
		) as "next_scheduled_stop_time",
		cps.incident_date_time,
		(CAST((
		  CONVERT(VARCHAR(19), cps.incident_date_time, 102) + ' ' +
		  CONVERT(VARCHAR(19), ctp.eta,108)
		  ) AS DATETIME)
		) as "last_scheduled_time",
		cps.sched_time as "status_scheduled_time",
		ctp.global_seq_num AS "previous_sequence",
		ntp.global_seq_num as "next_sequence"
	FROM 
		dbo.current_performance_status cps
	JOIN dbo.vehicle v
		ON
			cps.vehicle_id = v.vehicle_id
    JOIN dbo.trip_timepoint ctp
      ON
        cps.trip_id = ctp.trip_id
      AND
        cps.tp_id = ctp.tp_id
      AND
		cps.sched_version = ctp.sched_version
    JOIN dbo.trip_timepoint ntp
          ON
        cps.trip_id = ntp.trip_id
      AND
        cps.next_tp_id = ntp.tp_id
      AND
		cps.sched_version = ntp.sched_version
	  AND
	    --Need the next point, choosing the lowest in case we pass through the same
	    --Timepoint more than once
        ntp.global_seq_num = (
	      select MIN(global_seq_num)
	      from trip_timepoint
	      where
	        trip_timepoint.tp_id = cps.next_tp_id
	        and
	        trip_timepoint.trip_id = cps.trip_id
	        and
	        trip_timepoint.sched_version = cps.sched_version
	        and
	        trip_timepoint.global_seq_num >= ctp.global_seq_num
	    )
	JOIN incident_types its
	  ON
	    cps.incident_type = its.incident_type    	    
	WHERE cps.next_tp_id <> 0 and cps.tp_id <> 0
	and cps.vehicle_id <> 0 and v.logon_state = 1)
UNION
(SELECT  
		v.vehicle_id,
		v.loc_x AS 'latitude',
		v.loc_y AS 'longitude',
		v.average_speed AS 'speed',
		v.heading AS 'heading',
		v.vehicle_position_date_time,
		cps.direction_code_id as "route_direction",
		cps.route_id,
		cps.trip_id,
		its.incident_desc,
		cps.deviation,
		v.predicted_deviation,
		null,
		ntp.bs_id as "next_stop_id",
		(CAST((
		  CONVERT(VARCHAR(19), cps.incident_date_time, 102) + ' ' +
		  CONVERT(VARCHAR(19), ntp.eta,108)
		  ) AS DATETIME)
		) as "next_scheduled_stop_time",
		cps.incident_date_time,
		null,
		cps.sched_time,
		null,
		ntp.global_seq_num as "next_sequence"
	FROM 
		dbo.current_performance_status cps
	JOIN dbo.vehicle v
		ON
			cps.vehicle_id = v.vehicle_id
    JOIN dbo.trip_timepoint ntp
      ON
        cps.trip_id = ntp.trip_id
      AND
        cps.next_tp_id = ntp.tp_id
      AND
		cps.sched_version = ntp.sched_version
	  AND
	  -- The first Time Point might not be sequence 1
	    ntp.global_seq_num = (
	      select MIN(global_seq_num)
	      from trip_timepoint
	      where
	        trip_timepoint.tp_id = cps.next_tp_id
	        and
	        trip_timepoint.trip_id = cps.trip_id
	        and
	        trip_timepoint.sched_version = cps.sched_version
	    )
	JOIN incident_types its
	  ON
	    cps.incident_type = its.incident_type	  
	WHERE cps.next_tp_id <> 0 and cps.tp_id = 0 
	and cps.vehicle_id <> 0 and v.logon_state = 1)
UNION
(SELECT  
		v.vehicle_id,
		v.loc_x AS 'latitude',
		v.loc_y AS 'longitude',
		v.average_speed AS 'speed',
		v.heading AS 'heading',
		v.vehicle_position_date_time,
		cps.direction_code_id as "route_direction",
		cps.route_id,
		cps.trip_id,
		its.incident_desc,
		cps.deviation,
		v.predicted_deviation,
		ctp.bs_id,
		null as "next_stop_id",
		null as "next_scheduled_stop_time",
		cps.incident_date_time,
		(CAST((
		  CONVERT(VARCHAR(19), cps.incident_date_time, 102) + ' ' +
		  CONVERT(VARCHAR(19), ctp.eta,108)
		  ) AS DATETIME)
		) AS "last_scheduled_time",
		cps.sched_time,
	    ctp.global_seq_num AS "previous_sequence",
		null
	FROM 
		dbo.current_performance_status cps
	JOIN dbo.vehicle v
		ON
			cps.vehicle_id = v.vehicle_id
    JOIN dbo.trip_timepoint ctp
      ON
        cps.trip_id = ctp.trip_id
      AND
        cps.tp_id = ctp.tp_id
      AND
		cps.sched_version = ctp.sched_version
	JOIN incident_types its
	  ON
	    cps.incident_type = its.incident_type
	WHERE cps.next_tp_id = 0 and cps.tp_id <> 0
	and cps.vehicle_id <> 0 and v.logon_state = 1
)
)
GO

------ENABLE CLR INTEGRATION IN YOUR SQL ENVIRONMENT
EXEC sp_configure 'clr enabled', '1'

reconfigure

------OTHER SETTINGS THAT MAY BE NEEDED

ALTER DATABASE DOT SET TRUSTWORTHY ON


CREATE ASSEMBLY VEHICLE_UPDATE_CLR
FROM 'c:\ON_VEHICLE_UPDATE_CLR_LIB.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS
GO


CREATE PROCEDURE SP_On_vehicleUpdate_clr(@vehicle_id integer)
AS
EXTERNAL NAME VEHICLE_UPDATE_CLR.[clr_Class].SP_On_vehicleUpdate_clr

GO

CREATE TRIGGER [dbo].[on_update_vehicle]
    ON [dbo].[vehicle]
    FOR  UPDATE
 AS
 DECLARE @vehicle_id int

SET @vehicle_id = (SELECT vehicle_id FROM DELETED)
 BEGIN
	IF @vehicle_id IS NOT NULL
	    BEGIN
	        --may decide to get the data on the fly and returning the data row to the CLR ; depends on performance analysis. 
		    -- SELECT * FROM vehicle_status V WHERE V.vehicle_id = @vehicle_id
		  
		  EXEC SP_On_vehicleUpdate_clr @vehicle_id
	  END 
END

GO