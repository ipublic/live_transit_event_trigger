using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.IO;
using System.Xml;
using System.Xml.Serialization;
using System.Runtime;
using System.Net;
using System.Text;


public partial class clr_Class
{
   
    /// <summary>
    /// 
    /// </summary>
    /// <param name="vehicleID"></param>
[Microsoft.SqlServer.Server.SqlProcedure]
    public static void SP_On_vehicleUpdate_clr(SqlInt32 vehicleID)
    {
       
        string url = string.Empty;

       string vehicleData = string.Empty;
        try
        {
            SqlConnection conn = new SqlConnection("Context Connection=true");

            SqlCommand myCommand = conn.CreateCommand();

            myCommand.CommandText = @"SELECT * FROM vehicle_status WHERE vehicle_id = @vehiclID";
            myCommand.Parameters.AddWithValue("@vehiclID", vehicleID);

            conn.Open();

            SqlDataAdapter mySqlDataAdapter = new SqlDataAdapter();
             mySqlDataAdapter.SelectCommand = myCommand;
             DataSet myDataSet = new DataSet();
             mySqlDataAdapter.Fill(myDataSet);


            //get URL from the database before closing the connection.
             SqlCommand cmd = new SqlCommand(
                "SELECT VALUE FROM [dbo].[CLR_Configuration] WHERE [key] = 'URL' ", conn);
               url =  (string)cmd.ExecuteScalar();

            //Not closing connection since we are using a context connection
            //   conn.Close();

             DataTable dt = new DataTable();
            dt = (DataTable)myDataSet.Tables[0];

            vehicleData = myDataSet.GetXml(); 
       
            //Creating HTTP post and sending data.
            HttpWebRequest request = null;
            HttpWebResponse response = null;
            Stream stream = null;
            StreamReader streamReader = null;

            System.Text.ASCIIEncoding encoding = new System.Text.ASCIIEncoding();
            Byte[] bytes = encoding.GetBytes(vehicleData);


            request = (HttpWebRequest)WebRequest.Create(url);
            request.Method = "POST";
            request.ContentLength = bytes.Length;
            request.ContentType = "text/xml";
           
            Stream dataStream = request.GetRequestStream();
            dataStream.Write(bytes, 0, bytes.Length);
            dataStream.Close();

            response = (HttpWebResponse)request.GetResponse();
            stream = response.GetResponseStream();
            streamReader = new StreamReader(stream);

            response.Close();
            stream.Dispose();
            streamReader.Dispose();

        }
        catch (Exception ex)
        {
            SqlContext.Pipe.Send(ex.Message.ToString());
        }
     
    }



  

};



 