/****** Object:  View [dbo].[vehicle_status]    Script Date: 10/12/2011 14:34:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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

