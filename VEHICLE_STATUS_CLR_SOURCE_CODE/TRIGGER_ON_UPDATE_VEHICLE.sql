USE [DOT]
GO

/****** Object:  Trigger [on_update_vehicle]    Script Date: 10/12/2011 14:20:21 ******/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[on_update_vehicle]'))
DROP TRIGGER [dbo].[on_update_vehicle]
GO

USE [DOT]
GO

/****** Object:  Trigger [dbo].[on_update_vehicle]    Script Date: 10/12/2011 14:20:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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

