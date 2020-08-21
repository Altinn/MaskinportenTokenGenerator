using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Security.Cryptography.X509Certificates;
using System.Windows.Forms;
using Microsoft.IdentityModel.Tokens;

namespace MaskinportenTokenGenerator
{
    public class Token
    {

        private static string _issuer;
        private static string _audience;
        private static string _resource;
        private static string _scopes;
        private static string _tokenEndpoint;
        private static int _tokenTtl;
        private static X509Certificate2 _signingCertificate;
        private static string _kidClaim;

        public Token(string certificateThumbprint, string kidClaim, string tokenEndpoint, string audience, string resource,
            string scopes, string issuer, int tokenTtl)
        {
            _signingCertificate = GetCertificateFromKeyStore(certificateThumbprint, StoreName.My, StoreLocation.LocalMachine);

            _kidClaim = kidClaim;
            _tokenEndpoint = tokenEndpoint;
            _audience = audience;
            _resource = resource;
            _scopes = scopes;
            _issuer = issuer;
            _tokenTtl = tokenTtl;
        }

        public Token(string p12KeyStoreFile, string p12KeyStorePassword, string kidClaim, string tokenEndpoint, string audience, string resource,
            string scopes, string issuer, int tokenTtl)
        {
            _signingCertificate = new X509Certificate2();
            _signingCertificate.Import(File.ReadAllBytes(p12KeyStoreFile), p12KeyStorePassword, X509KeyStorageFlags.MachineKeySet | X509KeyStorageFlags.PersistKeySet | X509KeyStorageFlags.Exportable);

            _kidClaim = kidClaim;
            _tokenEndpoint = tokenEndpoint;
            _audience = audience;
            _resource = resource;
            _scopes = scopes;
            _issuer = issuer;
            _tokenTtl = tokenTtl;
        }

        public string GetAccessToken(string assertion, out bool isError, out string curlDebugCommand)
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

            var formContent = new FormUrlEncodedContent(new List<KeyValuePair<string, string>>
            {
                new KeyValuePair<string, string>("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                new KeyValuePair<string, string>("assertion", assertion),
            });

            var client = new HttpClient();

            curlDebugCommand = "curl -v -X POST -d '" + formContent.ReadAsStringAsync().Result + "' " + _tokenEndpoint;
            try {
                var response = client.PostAsync(_tokenEndpoint, formContent).Result;
                isError = !response.IsSuccessStatusCode;
                return response.Content.ReadAsStringAsync().Result;
            }
            catch (Exception e)
            {
                isError = true;
                Console.WriteLine("############");
                Console.WriteLine("Failed request to " + _tokenEndpoint + ", Exception thrown: " + e.GetType().FullName);
                Console.WriteLine("Message:" + e.Message);
                Console.WriteLine("Stack trace:");
                Console.WriteLine(e.StackTrace);
                while (e.InnerException != null)
                {
                    Console.WriteLine("Inner Exception:" + e.InnerException.GetType().FullName);
                    Console.WriteLine("Message:" + e.InnerException.Message);
                    Console.WriteLine("Stack trace:");
                    Console.WriteLine(e.InnerException.StackTrace);
                    e = e.InnerException;
                }

                Console.WriteLine("############");
                return null;
            }
        }

        public string GetJwtAssertion()
        {
            var dateTimeOffset = new DateTimeOffset(DateTime.UtcNow);

            var securityKey = new X509SecurityKey(_signingCertificate);
            var header = new JwtHeader(new SigningCredentials(securityKey, SecurityAlgorithms.RsaSha256))
            {
                {"x5c", new List<string>() {Convert.ToBase64String(_signingCertificate.GetRawCertData())}}
            };
            header.Remove("typ");

            // kid claim by default is set to x5t (certificate thumbprint). This can only be supplied if 
            // the client is configured with a custom public key, and must be removed if signing the assertion 
            // with a enterprise certificate. For convenience, the magic value "thumbprint" allows the 
            // kid to stay the same as certificate thumbprint
            if (_kidClaim != null && _kidClaim != "thumbprint")
            {
                header.Remove("kid");
                header.Add("kid", _kidClaim);
            }
            else if (_kidClaim == null)
            {
                header.Remove("kid");
            }

            var payload = new JwtPayload
            {
                { "aud", _audience },
                { "resource", _resource },
                { "scope", _scopes },
                { "iss", _issuer },
                { "exp", dateTimeOffset.ToUnixTimeSeconds() + _tokenTtl },
                { "iat", dateTimeOffset.ToUnixTimeSeconds() },
                { "jti", Guid.NewGuid().ToString() },
            };

            var securityToken = new JwtSecurityToken(header, payload);
            var handler = new JwtSecurityTokenHandler();

            return handler.WriteToken(securityToken);
        }

        private static X509Certificate2 GetCertificateFromKeyStore(string thumbprint, StoreName storeName, StoreLocation storeLocation, bool onlyValid = false)
        {
            var store = new X509Store(storeName, storeLocation);
            store.Open(OpenFlags.ReadOnly);
            var certCollection = store.Certificates.Find(X509FindType.FindByThumbprint, thumbprint, onlyValid);
            var enumerator = certCollection.GetEnumerator();
            X509Certificate2 cert = null;
            while (enumerator.MoveNext())
            {
                cert = enumerator.Current;
            }

            if (cert == null)
            {
                throw new ArgumentException("Unable to find certificate in store with thumbprint: " + thumbprint + ". Check your config, and make sure the certificate is installed in the \"LocalMachine\\My\" store.");
            }

            return cert;
        }
    }
}
