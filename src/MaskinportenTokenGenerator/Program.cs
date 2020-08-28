using System;
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
        private static int _tokenTtl = 120;

        [STAThread]
        static void Main(string[] args)
        {
            var showHelp = false;
            var serverMode = false;
            var onlyToken = false;
            var onlyGrant = false;
            int serverPort = 17823;

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
            
            Token token;
            try {
                if (_certificateThumbPrint != null) {
                    token = new Token(_certificateThumbPrint, _kidClaim, _tokenEndpoint, _audience, _resource, _scopes, _issuer, _tokenTtl);
                }
                else
                {
                    token = new Token(_p12KeyStoreFile, _p12KeyStorePassword, _kidClaim, _tokenEndpoint, _audience, _resource, _scopes, _issuer, _tokenTtl);
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

            if (!serverMode)
            {
                var assertion = token.GetJwtAssertion();
                if (onlyGrant)
                {
                    Console.WriteLine(assertion);
                    Environment.Exit(0);
                }

                var accessToken = token.GetAccessToken(assertion, out bool isError, out string curlDebugCommand);

                if (isError)
                {
                    Console.WriteLine("Failed getting token: " + accessToken);
                    Console.WriteLine("Call made (formatted as curl command, also placed in clipboard):");
                    Console.WriteLine(curlDebugCommand);
                    Clipboard.SetText(curlDebugCommand);
                }
                else
                {
                    var accessTokenObject = JsonConvert.DeserializeObject<JObject>(accessToken);
                    if (onlyToken)
                    {
                        Console.WriteLine(accessTokenObject.GetValue("access_token"));
                        Environment.Exit(0);
                    }

                    Clipboard.SetText(accessTokenObject.Property("access_token").Value.ToString());
                    Console.WriteLine("Got successful response:");
                    Console.WriteLine("----------------------------------------");
                    Console.WriteLine(accessToken);
                    Console.WriteLine("----------------------------------------");
                    Console.WriteLine("Access token has been copied to clipboard.");
                }

                if (!onlyToken) {
                    Console.WriteLine("Press ENTER to exit.");
                    Console.ReadLine();
                }
                Environment.Exit(isError ? 1 : 0);
            }

            var server = new Server(token, serverPort);
            Console.WriteLine("Enabling server mode, serving tokens at http://localhost:" + serverPort.ToString() + "/");
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
            Console.WriteLine("Generates as JWT Bearer Grant and uses it against Maskinporten to get an access_token.");
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
    }
}
