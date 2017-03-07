<%@ WebHandler Language="C#" Class="ApiHandler" %>
using System;
using System.IO;
using System.Net;
using System.Text;
using System.Collections.Generic;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using MarvalSoftware.UI.WebUI.ServiceDesk.RFP.Plugins;
using System.Xml;

/// <summary>
///BomgarHandler
/// </summary>
public class ApiHandler : PluginHandler
{
    private string Host
    {
        get
        {
            return GlobalSettings["BomgarHost"];
        }
    }

    private string Port
    {
        get
        {
            return GlobalSettings["BomgarPort"];
        }
    }

    private string Company
    {
        get
        {
            return GlobalSettings["BomgarCompany"];
        }
    }

    private string Username
    {
        get
        {
            return GlobalSettings["BomgarUsername"];
        }
    }

    private string Password
    {
        get
        {
            return GlobalSettings["BomgarPassword"];
        }
    }

    private string APIKey
    {
        get
        {
            return GlobalSettings["MSMAPIKey"];
        }
    }

    private string MSMBaseUrl
    {
        get
        {
            return HttpContext.Current.Request.Url.Scheme+ "://127.0.0.1" + MarvalSoftware.UI.WebUI.ServiceDesk.WebHelper.ApplicationPath;
        }
    }

    private int MsmRequestNo;

    /// <summary>
    /// Process Handler Request
    /// </summary>
    public override void HandleRequest(HttpContext context)
    {
        ProcessParamaters(context.Request);

        var action = context.Request.QueryString["action"];
        RouteRequest(action, context);
    }

    /// <summary>
    /// Get Paramaters from QueryString
    /// </summary>
    private void ProcessParamaters(HttpRequest httpRequest)
    {
        int.TryParse(httpRequest.Params["requestNumber"], out MsmRequestNo);

    }

    /// <summary>
    /// Route Request via Action
    /// </summary>
    private void RouteRequest(string action, HttpContext context)
    {
        HttpWebRequest httpWebRequest;
        string json;

        switch (action)
        {
            case "PreRequisiteCheck":
                context.Response.Write(PreRequisiteCheck());
                break;
            case "StartBomgarSession":
                httpWebRequest = BuildRequest(this.Host + String.Format("api/command?username={0}&password={1}&action={2}&type={3}&queue_id={4}&session.custom.external_key={5}", this.Username, this.Password, "generate_session_key", "support", "general", MsmRequestNo));
                context.Response.Write(ProcessRequest(httpWebRequest));
                break;
            case "SessionStart":
                json = new StreamReader(context.Request.InputStream).ReadToEnd();
                AddMsmNote(Int32.Parse(context.Request.Form["external_key"]), "Bomgar session has started.");
                context.Response.StatusCode = (int)HttpStatusCode.OK;
                break;
            case "SessionEnd":
                json = new StreamReader(context.Request.InputStream).ReadToEnd();
                AddMsmNote(Int32.Parse(context.Request.Form["external_key"]), string.Format("Bomgar session has finished, see more information <a href={0}/login/sd_reporting?reportType=SupportSession&sessionId={1}><b>here.</b></a>", this.Host, context.Request.Form["lsid"]));
                context.Response.StatusCode = (int)HttpStatusCode.OK;
                break;
        }
    }

    /// <summary>
    /// Add MSM Note
    /// </summary>   
    private void AddMsmNote(int requestNumber, string note)
    {
        IDictionary<string, object> body = new Dictionary<string, object>();
        HttpWebRequest httpWebRequest;

        httpWebRequest = BuildRequest(this.MSMBaseUrl + String.Format("/api/requests?number={0}", requestNumber));
        var requestResponse = JObject.Parse(ProcessRequest(httpWebRequest, GetEncodedCredentials(this.APIKey), true));
        var requestId = (int)requestResponse["items"].First["id"];

        body.Add("id", requestId);
        body.Add("content", note);

        httpWebRequest = BuildRequest(this.MSMBaseUrl + String.Format("/api/requests/{0}/notes/", requestId), JsonHelper.ToJSON(body), "POST");
        ProcessRequest(httpWebRequest, GetEncodedCredentials(this.APIKey), true);
    }

    /// <summary>
    /// Check and return missing plugin settings
    /// </summary>
    /// <returns>Json Object containing any settings that failed the check</returns>
    private JObject PreRequisiteCheck()
    {
        var preReqs = new JObject();
        if (string.IsNullOrWhiteSpace(this.Company))
        {
            preReqs.Add("bomgarCompany", false);
        }
        if (string.IsNullOrWhiteSpace(this.Password))
        {
            preReqs.Add("bomgarPassword", false);
        }
        if (string.IsNullOrWhiteSpace(this.Username))
        {
            preReqs.Add("bomgarUsername", false);
        }
        if (string.IsNullOrWhiteSpace(this.Port))
        {
            preReqs.Add("bomgarPort", false);
        }
        if (string.IsNullOrWhiteSpace(this.Host))
        {
            preReqs.Add("bomgarHost", false);
        }

        return preReqs;
    }

    /// <summary>
    /// Builds a HttpWebRequest
    /// </summary>
    /// <param name="uri">The uri for request</param>
    /// <param name="body">The body for the request</param>
    /// <param name="method">The verb for the request</param>
    /// <returns>The HttpWebRequest ready to be processed</returns>
    private static HttpWebRequest BuildRequest(string uri = null, string body = null, string method = "GET")
    {
        var request = WebRequest.Create(new UriBuilder(uri).Uri) as HttpWebRequest;
        request.Method = method.ToUpperInvariant();
        request.ContentType = "application/json";

        if (body != null)
        {
            using (var writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(body);
            }
        }

        return request;
    }

    /// <summary>
    /// Proccess a HttpWebRequest
    /// </summary>
    /// <param name="request">The HttpWebRequest</param>
    /// <param name="credentials">The Credentails to use for the API</param>
    /// <returns>Process Response</returns>
    private static string ProcessRequest(HttpWebRequest request, string credentials = null, bool msmRequest = false)
    {
        try
        {
            if (!string.IsNullOrWhiteSpace(credentials))
            {
                request.Headers.Add("Authorization", "Basic " + credentials);
            }

           
            string result = String.Empty;
            HttpWebResponse response = request.GetResponse() as HttpWebResponse;
            using (StreamReader reader = new StreamReader(response.GetResponseStream()))
            {
                result = reader.ReadToEnd();
            }

            if (!msmRequest)
            {
                XmlDocument doc = new XmlDocument();
                doc.LoadXml(result);
                result = JsonConvert.SerializeXmlNode(doc);
            }

            return result;
        }
        catch (WebException ex)
        {
            return ex.Message;
        }

    }

    public override bool IsReusable
    {
        get
        {
            return false;
        }
    }

    /// <summary>
    /// Encodes Credentials
    /// </summary>
    /// <param name="credentials">The string to encode</param>
    /// <returns>base64 encoded string</returns>
    private string GetEncodedCredentials(string credentials)
    {
        byte[] byteCredentials = Encoding.UTF8.GetBytes(credentials);
        return Convert.ToBase64String(byteCredentials);
    }

    /// <summary>
    /// JsonHelper Functions
    /// </summary>
    internal class JsonHelper
    {
        public static string ToJSON(object obj)
        {
            return JsonConvert.SerializeObject(obj);
        }
    }
}
