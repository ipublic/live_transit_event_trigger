CLR Stored procedure installation steps
1. Unzip folder and copy the "ON_VEHICLE_UPDATE_CLR_LIB.dll" in "stored procedure dll" to a prefered location. e.g c:\ON_VEHICLE_UPDATE_CLR_LIB
2. Open "CLR_Configuration_Script" and modify the path in the CREATE assembly syntax to where the dll in step 1 above is located.
3. Run the CLR_Configuration_Script" which will create; 1.) configuration table 2.)one Assembly "VEHICLE_UPDATE_CLR" 3.) one store procedure "dbo.Sp_On_vehicleUpdate_clr
4. Run Script to create Trigger "TRIGGER_ON_UPDATE_VEHICLE" 
5. Run Script to create View    "VIEW_VEHICLE_STATUS" 


For testing purposes:
1. G&O will need to suppy a valid Restful URL which will be put into the configuration table as a value for the end point URL

