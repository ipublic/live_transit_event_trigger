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
    public static void SP_On_vehicleUpdate_clr()
    {
       
        string url = string.Empty;

       string vehicleData = string.Empty;
            SqlConnection conn = new SqlConnection("Context Connection=true");

            SqlCommand myCommand = conn.CreateCommand();
            DateTime filter = DateTime.Now.AddSeconds(-30);
            myCommand.CommandText = @"SELECT * FROM vehicle_status where (vehicle_position_date_time > @vptime) or (incident_date_time > @idt)";
            SqlParameter vptime = new SqlParameter("@vptime", SqlDbType.DateTime);
            vptime.Value = filter;
            myCommand.Parameters.Add(vptime);
            SqlParameter idt = new SqlParameter("@idt", SqlDbType.DateTime);
            idt.Value = filter;
            myCommand.Parameters.Add(idt);
            conn.Open();

            SqlDataAdapter mySqlDataAdapter = new SqlDataAdapter();
             mySqlDataAdapter.SelectCommand = myCommand;
             DataSet myDataSet = new DataSet();
             mySqlDataAdapter.Fill(myDataSet);

             if (myDataSet.Tables.Count > 0)
             {


                 //get URL from the database before closing the connection.
                 SqlCommand cmd = new SqlCommand(
                    "SELECT VALUE FROM [dbo].[CLR_Configuration] WHERE [key] = 'URL' ", conn);
                 url = (string)cmd.ExecuteScalar();

                 //Not closing connection since we are using a context connection
                 //   conn.Close();
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
                 request.Timeout = 10000;

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
     
    }

};



 