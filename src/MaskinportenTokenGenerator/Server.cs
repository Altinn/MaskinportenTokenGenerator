using System;
using System.Net;
using System.Text;
using Newtonsoft.Json.Linq;

namespace MaskinportenTokenGenerator
{
    class Server
    {
        private HttpListener _listener;
        private int _port;
        private Token _token;
        private static string _cachedToken = null;
        private static DateTime _cachedTokenTtl = DateTime.Now;

        public Server(Token token, int port)
        {
            _token = token;
            _port = port;
        }

        public void Listen()
        {
            _listener = new HttpListener();
            _listener.Prefixes.Add("http://*:" + _port.ToString() + "/");
            _listener.Start();

            while (true)
            {
                try
                {
                    HttpListenerContext context = _listener.GetContext();
                    Process(context);
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Exception caught: " + ex.GetType() + ": " + ex.Message);
                  //  Environment.Exit(1);
                }
            }
            // ReSharper disable once FunctionNeverReturns
        }

        private void Process(HttpListenerContext context)
        {
            // To avoid fetching a token for favicon.ico requests
            if (context.Request.Url.AbsolutePath != "/") {
                context.Response.StatusCode = (int) HttpStatusCode.NotFound;
                context.Response.OutputStream.Close();
                return;
            }

            string cacheQueryString = context.Request.QueryString["cache"];
            bool useCache = cacheQueryString != null && (cacheQueryString == "1" || cacheQueryString.ToLower() == "true");
            string accessToken;
            string assertion;
            bool isError;
            bool cacheHit = false;

            if (!useCache || _cachedToken == null || _cachedTokenTtl < DateTime.Now) {
                //Console.WriteLine("Cache stale or disabled, fetching new token");
                assertion = _token.GetJwtAssertion();
                accessToken = _token.GetAccessToken(assertion, out isError, out _);
            }
            else {
                isError = false;
                accessToken = _cachedToken;
                cacheHit = true;
                //Console.WriteLine("Using cached token (expires at " + _cachedTokenTtl.ToString() + ")");
            }

            if (isError)
            {
                //Console.WriteLine("Error occured, returning 500 internal server error");
                context.Response.StatusCode = (int) HttpStatusCode.InternalServerError;
            }
            else {
                context.Response.ContentType = "application/json";
                context.Response.ContentLength64 = accessToken.Length;
                context.Response.AddHeader("Cache-Control", "no-cache");

                var bytes = Encoding.UTF8.GetBytes(accessToken);
                context.Response.OutputStream.Write(bytes, 0, bytes.Length);
                context.Response.StatusCode = (int) HttpStatusCode.OK;

                if (useCache && !cacheHit)
                {
                    dynamic response = JObject.Parse(accessToken);
                    _cachedTokenTtl = DateTime.Now.AddSeconds((double)response.expires_in);
                    _cachedToken = accessToken;
                    //Console.WriteLine("Saving token to cache (expires at " + _cachedTokenTtl.ToString() + ")");
                }
            }
            //Console.WriteLine("----- COMPLETE -----");

            context.Response.OutputStream.Close();
        }
    }
}
