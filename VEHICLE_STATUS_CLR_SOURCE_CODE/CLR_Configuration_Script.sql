USE [DOT_TRN_SmartTraveler]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- Clean up all our old stuff
IF  EXISTS (SELECT * FROM msdb.dbo.sysschedules WHERE name = N'Send Vehicle Info Schedule')
BEGIN
EXEC msdb.dbo.sp_detach_schedule
  @job_name = N'Send Vehicle Info to Live Transit API',
  @schedule_name = N'Send Vehicle Info Schedule'
;
EXEC msdb.dbo.sp_delete_schedule
  @schedule_name = N'Send Vehicle Info Schedule' ;
END
GO

IF  EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'Send Vehicle Info to Live Transit API')
BEGIN
EXEC msdb.dbo.sp_delete_jobstep
    @job_name = N'Send Vehicle Info to Live Transit API',
	@step_id = 1
	;

EXEC msdb.dbo.sp_delete_job
    @job_name = N'Send Vehicle Info to Live Transit API' ;
END
GO

IF  EXISTS (SELECT * FROM sys.triggers WHERE name = N'on_update_vehicle')
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

-- production value: http://172.30.12.210:80/vehicle_positions.xml

INSERT INTO [dbo].CLR_Configuration ([key],value) VALUES('URL', 'http://172.20.4.142:3000/vehicle_positions.xml')
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
		cps.incident_date_time AS 'incident_date_time',		
		LEFT(t.trip_id_external, LEN(t.trip_id_external) - 3) as "trip_id",
		cps.deviation as "last_stop_deviation",
		v.predicted_deviation,
		ctp.global_seq_num AS "previous_sequence",
		cps.sched_time as "last_scheduled_time"
	FROM 
		dbo.current_performance_status cps
	JOIN dbo.trip t
	    ON
			cps.trip_id = t.trip_id and cps.sched_version = t.sched_version		
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
	WHERE cps.next_tp_id <> 0 and cps.tp_id <> 0
	and cps.vehicle_id <> 0 and v.logon_state = 1
	AND
	  RIGHT(t.trip_id_external, 3) = '000'
	)
UNION
(SELECT  
		v.vehicle_id,
		v.loc_x AS 'latitude',
		v.loc_y AS 'longitude',
		v.average_speed AS 'speed',
		v.heading AS 'heading',
		v.vehicle_position_date_time,
		cps.incident_date_time,
		LEFT(t.trip_id_external, LEN(t.trip_id_external) - 3) as "trip_id",
		cps.deviation,
		v.predicted_deviation,
		null,
		cps.sched_time as "last_scheduled_time"
	FROM 
		dbo.current_performance_status cps
	JOIN dbo.trip t
	    ON
			cps.trip_id = t.trip_id and cps.sched_version = t.sched_version		
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
	WHERE cps.next_tp_id <> 0 and cps.tp_id = 0 
	and cps.vehicle_id <> 0 and v.logon_state = 1
	AND
	  RIGHT(t.trip_id_external, 3) = '000'
	)
UNION
(SELECT  
		v.vehicle_id,
		v.loc_x AS 'latitude',
		v.loc_y AS 'longitude',
		v.average_speed AS 'speed',
		v.heading AS 'heading',
		v.vehicle_position_date_time,
		cps.incident_date_time,
		LEFT(t.trip_id_external, LEN(t.trip_id_external) - 3) as "trip_id",
		cps.deviation,
		v.predicted_deviation,
	    ctp.global_seq_num AS "previous_sequence",
		cps.sched_time as "last_scheduled_time"
	FROM 
		dbo.current_performance_status cps
	JOIN dbo.trip t
	    ON
			cps.trip_id = t.trip_id and cps.sched_version = t.sched_version
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
	WHERE cps.next_tp_id = 0 and cps.tp_id <> 0
	and cps.vehicle_id <> 0 and v.logon_state = 1
		AND
	  RIGHT(t.trip_id_external, 3) = '000'
)
)
GO

------ENABLE CLR INTEGRATION IN YOUR SQL ENVIRONMENT
EXEC sp_configure 'clr enabled', '1'
GO

RECONFIGURE WITH OVERRIDE
GO

------OTHER SETTINGS THAT MAY BE NEEDED

ALTER DATABASE DOT_TRN_SmartTraveler SET TRUSTWORTHY ON
GO


CREATE ASSEMBLY VEHICLE_UPDATE_CLR
FROM 'c:\ON_VEHICLE_UPDATE_CLR_LIB.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS
GO


CREATE PROCEDURE SP_On_vehicleUpdate_clr
AS
EXTERNAL NAME VEHICLE_UPDATE_CLR.[clr_Class].SP_On_vehicleUpdate_clr

GO

EXEC msdb.dbo.sp_add_job 
	@job_name = N'Send Vehicle Info to Live Transit API',
	@enabled = 1,
	@start_step_id = 1,
	@notify_level_eventlog = 3
;
GO

EXEC msdb.dbo.sp_add_jobstep
	@job_name = N'Send Vehicle Info to Live Transit API',
	@step_name = N'Post Vehicle Data',
	@step_id = 1,
	@subsystem = 'TSQL',
	@database_name = 'DOT_TRN_SmartTraveler',
	@command = 'EXEC SP_On_vehicleUpdate_clr',
	@flags = 32
	;
GO
  

EXEC msdb.dbo.sp_add_schedule
  @schedule_name = N'Send Vehicle Info Schedule',
  @freq_type = 4,
  @freq_interval = 1,
  @freq_subday_type = 2,
  @freq_subday_interval = 10
;
GO

EXEC msdb.dbo.sp_attach_schedule
  @job_name = N'Send Vehicle Info to Live Transit API',
  @schedule_name = N'Send Vehicle Info Schedule'
;
GO

EXEC msdb.dbo.sp_add_jobserver
  @job_name = N'Send Vehicle Info to Live Transit API'
  ;
GO

/*
CREATE TRIGGER [dbo].[on_update_vehicle]
    ON [dbo].[vehicle]
    FOR  UPDATE
AS
 DECLARE
   @vehicle_id as int
 BEGIN	  
   DECLARE vehicle_cursor CURSOR
   FOR select vehicle_id from inserted;
   OPEN vehicle_cursor;
   FETCH NEXT FROM vehicle_cursor
   INTO @vehicle_id;
   
   WHILE @@FETCH_STATUS = 0
   BEGIN
		  EXEC SP_On_vehicleUpdate_clr @vehicle_id;
		     FETCH NEXT FROM vehicle_cursor
             INTO @vehicle_id;
   END
   CLOSE vehicle_cursor;
   DEALLOCATE vehicle_cursor;
END

GO
*/