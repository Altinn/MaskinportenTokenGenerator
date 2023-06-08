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
        private string _codeVerifier;
        private TokenHandler _tokenHandler;
        private static string _cachedToken = null;
        private static DateTime _cachedTokenTtl = DateTime.Now;
        private string _authCode = null;
        private string _clientId = null;
        private string _redirectUri = null;

        public Server(TokenHandler token, int port, string clientId = null, string redirectUri = null, string codeVerifier = null)
        {
            _tokenHandler = token;
            _port = port;
            _codeVerifier = codeVerifier;
            _clientId = clientId;
            _redirectUri = redirectUri;
        }

        public void Listen()
        {
            _listener = new HttpListener();
            _listener.Prefixes.Add("http://localhost:" + _port.ToString() + "/");
            _listener.Start();

            while (true)
            {
                try
                {
                    if (_listener.IsListening) {
                        HttpListenerContext context = _listener.GetContext();
                        Route(context);
                    }
                    else
                    {
                        break;
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Exception caught: " + ex.GetType() + ": " + ex.Message);
                  //  Environment.Exit(1);
                }
            }
            // ReSharper disable once FunctionNeverReturns
        }

        private void Route(HttpListenerContext context)
        {

            switch (context.Request.Url.AbsolutePath)
            {
                case "/":
                    ProcessTokenRequest(context);
                    break;

                case "/response":
                    ProcessAuthorizeResponse(context);
                    break;

                default:
                    context.Response.StatusCode = (int) HttpStatusCode.NotFound;
                    context.Response.OutputStream.Close();
                    break;
            }
        }

        private void ProcessTokenRequest(HttpListenerContext context)
        {
            string cacheQueryString = context.Request.QueryString["cache"];
            bool useCache = cacheQueryString != null && (cacheQueryString == "1" || cacheQueryString.ToLower() == "true");
            string accessToken;
            string assertion;
            bool isError;
            bool cacheHit = false;

            if (!useCache || _cachedToken == null || _cachedTokenTtl < DateTime.Now) {
                //Console.WriteLine("Cache stale or disabled, fetching new token");
                assertion = _tokenHandler.GetJwtAssertion();
                if (_authCode != null)
                {
                    accessToken = _tokenHandler.GetTokenFromAuthCodeGrant(assertion, _authCode, _clientId, _redirectUri, _codeVerifier, out isError);
                }
                else
                {
                    accessToken = _tokenHandler.GetTokenFromJwtBearerGrant(assertion, out isError);
                }
            }
            else {
                isError = false;
                accessToken = _cachedToken;
                cacheHit = true;
                //Console.WriteLine("Using cached token (expires at " + _cachedTokenTtl.ToString() + ")");
            }

            if (isError)
            {
                context.Response.StatusCode = (int) HttpStatusCode.InternalServerError;
                Console.WriteLine("################");
                Console.WriteLine("500 Internal Server error: Failed getting token");
                Console.WriteLine("Response from token endpoint was:");
                Console.WriteLine("---------------");
                Console.WriteLine(accessToken);
                Console.WriteLine("---------------");
                Console.WriteLine("Call made (formatted as curl command):");
                Console.WriteLine(_tokenHandler.CurlDebugCommand);
                if (_tokenHandler.LastException != null) TokenHandler.PrettyPrintException(_tokenHandler.LastException);
                if (_tokenHandler.LastTokenRequest != null) {
                    Console.WriteLine("Token Request:");
                    Console.WriteLine("---------------");
                    Console.WriteLine(_tokenHandler.LastTokenRequest.Replace('&','\n'));
                    Console.WriteLine("---------------");
                }
            }
            else {
                context.Response.ContentType = "application/json";
                context.Response.ContentLength64 = accessToken.Length;
                context.Response.AddHeader("Cache-Control", "no-cache");
                context.Response.AddHeader("X-TokenRequest", _tokenHandler.LastTokenRequest);

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

        private void ProcessAuthorizeResponse(HttpListenerContext context)
        {
            string code = context.Request.QueryString["code"];

            if (code == null)
            {
                context.Response.StatusCode = (int) HttpStatusCode.BadRequest;
            }
            else
            {
                _authCode = code;
                context.Response.AddHeader("Cache-Control", "no-cache");
                context.Response.StatusCode = (int) HttpStatusCode.Redirect;
                context.Response.AddHeader("Location", "/?cache=true");
            }

            context.Response.OutputStream.Close();
        }
    }
}
