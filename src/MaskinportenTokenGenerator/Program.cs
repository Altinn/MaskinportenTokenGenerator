using System;
using System.Net;
using System.Threading.Tasks;
using System.Windows.Forms;
using Mono.Options;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;


namespace MaskinportenTokenGenerator
{
    internal class Program
    {
        private static string _certificateThumbPrint;
        private static string _p12KeyStoreFile;
        private static string _p12KeyStorePassword;
        private static string _kidClaim;
        private static string _issuer;
        private static string _audience;
        private static string _resource = null;
        private static string _scopes;
        private static string _tokenEndpoint;
        private static string _authorizeEndpoint;
        private static int _tokenTtl = 120;
        private static string _consumerOrg;

        [STAThread]
        static void Main(string[] args)
        {
            var showHelp = false;
            var serverMode = false;
            var onlyToken = false;
            var onlyGrant = false;
            int serverPort = 17823;
            bool personMode = false;

            var p = new OptionSet() {
                { "t=|certificate_thumbprint=", "Thumbprint for certificate to use, see Cert:\\LocalMachine\\My in Powershell.",
                    v => _certificateThumbPrint = v },
                { "k=|keystore_path=", "Path to PKCS12 file containing certificate to use.",
                    v => _p12KeyStoreFile = v },
                { "p=|keystore_password=", "Path to PKCS12 file containing certificate to use.",
                    v => _p12KeyStorePassword = v },
                { "K=|kid=", "Set kid-claim in bearer grant assertion header. Used for pre-registered JWK clients.",
                    v => _kidClaim = v },
                { "c=|client_id=", "This is the client_id to which the access_token is requested",
                    v => _issuer = v },
                { "a=|audience=", "The audience for the grant, must be ID-porten",
                    v =>  _audience = v },
                { "r=|resource=",  "Intended audience, used as aud-claim in returned access_token",
                    v => _resource = v },
                { "l=|token_ttl=",  "Token lifetime in seconds (default: 120)",
                    v =>
                    {
                        if (v != null && Int32.TryParse(v, out int overriddenTokenTtl))
                        {
                            _tokenTtl = overriddenTokenTtl;
                        }
                    }
                },
                { "s=|scopes=",  "Scopes requested, comma separated",
                    v => _scopes = v.Replace(',', ' ') },
                { "e=|token_endpoint=",  "Token endpoint to ask for access_token",
                    v => _tokenEndpoint = v },
                { "A=|authorize_endpoint=",  "Authorize endpoint to redirect user for consent",
                    v => _authorizeEndpoint = v },
                { "C|consumer_org=", "Enable supplier mode for given consumer organization number",
                    v => _consumerOrg = v },
                { "m|server_mode",  "Enable server mode",
                    v => serverMode = v != null  },
                { "P=|server_port=",  "Server port (default 17823)",
                    v =>
                    {
                        if (v != null && UInt16.TryParse(v, out ushort overriddenServerPort))
                        {
                            serverPort = overriddenServerPort;
                        }
                    }
                },
                { "i|person_mode=",  "Enable person mode (ID-porten)",
                    v => personMode = v != null && v == "true" },
                { "o|only_token", "Only return token to stdout", 
                    v => onlyToken = v != null },
                { "g|only_grant", "Only return bearer grant to stdout", 
                    v => onlyGrant = v != null },
                { "h|help",  "show this message and exit",
                    v => showHelp = v != null },

            };

            try
            {
                p.Parse(args);
            }
            catch (OptionException e)
            {
                Console.Write("MaskinportenTokenGenerator: ");
                Console.WriteLine(e.Message);
                Console.WriteLine("Try `MaskinportenTokenGenerator --help' for more information.");
                return;
            }

            if (showHelp)
            {
                ShowHelp(p);
                return;
            }

            CheckParameters(p);
            
            TokenHandler tokenHandler;
            try {
                if (_certificateThumbPrint != null) {
                    tokenHandler = new TokenHandler(_certificateThumbPrint, _kidClaim, _tokenEndpoint, _audience, _resource, _scopes, _issuer, _tokenTtl, _consumerOrg);
                }
                else
                {
                    tokenHandler = new TokenHandler(_p12KeyStoreFile, _p12KeyStorePassword, _kidClaim, _tokenEndpoint, _audience, _resource, _scopes, _issuer, _tokenTtl, _consumerOrg);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("Caught exception " + e.GetType().FullName + ": " + e.Message);
                Console.WriteLine();
                if (!onlyToken) {
                    Console.WriteLine("Press ENTER to exit.");
                    Console.ReadLine();
                }
                Environment.Exit(1);
                return; // To please code inspector complaining about token being undefined below
            }

            if (!serverMode && !personMode)
            {
                var assertion = tokenHandler.GetJwtAssertion();
                if (onlyGrant)
                {
                    Console.WriteLine(assertion);
                    Environment.Exit(0);
                }

                var token = tokenHandler.GetTokenFromJwtBearerGrant(assertion, out bool isError);

                if (isError)
                {
                    Console.WriteLine("Failed getting token: " + token);
                    Console.WriteLine("Call made (formatted as curl command, also placed in clipboard):");
                    Console.WriteLine(tokenHandler.CurlDebugCommand);
                    Clipboard.SetText(tokenHandler.CurlDebugCommand);
                }
                else
                {
                    var tokenObject = JsonConvert.DeserializeObject<JObject>(token);
                    if (onlyToken)
                    {
                        Console.WriteLine(tokenObject.GetValue("access_token"));
                        Environment.Exit(0);
                    }

                    Clipboard.SetText(tokenObject.Property("access_token").Value.ToString());
                    Console.WriteLine("Got successful response:");
                    Console.WriteLine("----------------------------------------");
                    Console.WriteLine(token);
                    Console.WriteLine("----------------------------------------");
                    Console.WriteLine("Access token has been copied to clipboard.");
                }

                if (!onlyToken) {
                    Console.WriteLine("Press ENTER to exit.");
                    Console.ReadLine();
                }
                Environment.Exit(isError ? 1 : 0);
            }


            Server server; 

            if (personMode)
            {
                string url = GetAuthorizeUrl(serverPort);
                Console.WriteLine("Person login mode, opening browser to: " + url);
                System.Diagnostics.Process.Start(url);
                server = new Server(tokenHandler, serverPort, _issuer, GetRedirectUri(serverPort));
            }
            else
            {
                 server = new Server(tokenHandler, serverPort);
            }

            Console.WriteLine("Server started, serving tokens at http://localhost:" + serverPort.ToString() + "/");            
            Task.Run(() => server.Listen());
            Console.WriteLine("Press ESCAPE or CTRL-C to exit");

            while (true)
            {
                if (Console.KeyAvailable)
                {
                    ConsoleKeyInfo info = Console.ReadKey(true);
                    if (info.Key == ConsoleKey.Escape || info.Modifiers == ConsoleModifiers.Control && info.Key == ConsoleKey.C)
                    {
                        Console.WriteLine("Bye!");
                        Environment.Exit(0);
                    }
                }
            }
        }

        static void ShowHelp(OptionSet p)
        {
            Console.WriteLine("Usage: MaskinportenTokenGenerator.exe [OPTIONS]");
            Console.WriteLine("Generates as JWT Bearer Grant and uses it against Maskinporten/ID-porten to get tokens.");
            Console.WriteLine();
            Console.WriteLine("Options:");
            p.WriteOptionDescriptions(Console.Out);
        }

        static void CheckParameters(OptionSet p)
        {
            var hasErrors = false;

            if (_certificateThumbPrint == null && _p12KeyStoreFile == null || _certificateThumbPrint != null && _p12KeyStoreFile != null)
            {
                Console.WriteLine("Requires either --certificate_thumbprint or --keystore_path");
                hasErrors = true;
            }

            if (_issuer == null)
            {
                Console.WriteLine("Requires --client_id");
                hasErrors = true;
            }

            if (_audience == null)
            {
                Console.WriteLine("Requires --audience");
                hasErrors = true;
            }

            if (_scopes == null)
            {
                Console.WriteLine("Requires --scopes");
                hasErrors = true;
            }

            if (_tokenEndpoint == null)
            {
                Console.WriteLine("Requires --token_endpoint");
                hasErrors = true;
            }

            if (!hasErrors) return;
            ShowHelp(p);
            Environment.Exit(1);
        }

        static string GetAuthorizeUrl(int serverPort)
        {
            return string.Format("{0}?scope={1}&acr_values=Level3&client_id={2}&redirect_uri={3}&response_type=code&ui_locales=nb", _authorizeEndpoint, WebUtility.UrlEncode(_scopes), _issuer, GetRedirectUri(serverPort));
        }

        static string GetRedirectUri(int serverPort)
        {
            return WebUtility.UrlEncode("http://localhost:" + serverPort.ToString() + "/response");
        }
    }
}
