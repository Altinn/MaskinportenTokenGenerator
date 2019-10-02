using System;
using System.Net;
using System.Text;

namespace MaskinportenTokenGenerator
{
    class Server
    {
        private HttpListener _listener;
        private int _port;
        private Token _token;

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
                    Environment.Exit(1);
                }
            }
            // ReSharper disable once FunctionNeverReturns
        }

        private void Process(HttpListenerContext context)
        {
            var assertion = _token.GetJwtAssertion();
            var accessToken = _token.GetAccessToken(assertion, out bool isError);

            context.Response.ContentType = "application/json";
            context.Response.ContentLength64 = accessToken.Length;
            context.Response.AddHeader("Cache-Contraol", "no-cache");

            var bytes = Encoding.UTF8.GetBytes(accessToken);
            context.Response.OutputStream.Write(bytes, 0, bytes.Length);
            context.Response.StatusCode = isError ? (int) HttpStatusCode.InternalServerError : (int) HttpStatusCode.OK;
            context.Response.OutputStream.Close();
        }
    }
}
