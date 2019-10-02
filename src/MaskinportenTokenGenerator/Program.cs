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
        private static string _issuer;
        private static string _audience;
        private static string _resource;
        private static string _scopes;
        private static string _tokenEndpoint;

        [STAThread]
        static void Main(string[] args)
        {
            var showHelp = false;
            var serverMode = false;
            int serverPort = 17823;

            var p = new OptionSet() {
                { "t=|certificate_thumbprint=", "Thumbprint for certificate to use, see Cert:\\LocalMachine\\My in Powershell.",
                    v => _certificateThumbPrint = v },
                { "c=|client_id=", "This is the client_id to which the access_token is requested",
                    v => _issuer = v },
                { "a=|audience=", "The audience for the grant, must be ID-porten",
                    v =>  _audience = v },
                { "r=|resource=",  "Intended audience, used as aud-claim in returned access_token",
                    v => _resource = v },
                { "s=|scopes=",  "Scopes requested, comma separated",
                    v => _scopes = v.Replace(',', ' ') },
                { "e=|token_endpoint=",  "Token endpoint to ask for access_token",
                    v => _tokenEndpoint = v },
                { "h|help",  "show this message and exit",
                    v => showHelp = v != null },
                { "m|server_mode",  "Enable server mode",
                    v => serverMode = v != null },
                { "p=|server_port=",  "Server port (default 17823)",
                    v =>
                    {
                        if (v != null && UInt16.TryParse(v, out ushort overriddenServerPort))
                        {
                            serverPort = overriddenServerPort;
                        }
                    }
                },

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

            var token = new Token(_certificateThumbPrint, _tokenEndpoint, _audience, _resource, _scopes, _issuer);

            if (!serverMode)
            {
                var assertion = token.GetJwtAssertion();
                var accessToken = token.GetAccessToken(assertion, out bool isError);

                if (isError)
                {
                    Console.WriteLine("Failed getting token: " + accessToken);
                    Console.WriteLine("Assertion used:");
                    Console.WriteLine(assertion);
                }
                else
                {
                    var accessTokenObject = JsonConvert.DeserializeObject<JObject>(accessToken);
                    Clipboard.SetText(accessTokenObject.Property("access_token").Value.ToString());
                    Console.WriteLine("Got successful response:");
                    Console.WriteLine("----------------------------------------");
                    Console.WriteLine(accessToken);
                    Console.WriteLine("----------------------------------------");
                    Console.WriteLine("Access token has been copied to clipboard.");
                }

                Console.WriteLine("Press ENTER to exit.");
                Console.ReadLine();
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

            if (_certificateThumbPrint == null)
            {
                Console.WriteLine("Requires --certificate_thumbprint");
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

            if (_resource == null)
            {
                Console.WriteLine("Requires --resource");
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
