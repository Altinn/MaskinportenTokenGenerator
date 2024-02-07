using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Security.Cryptography.X509Certificates;
using Microsoft.IdentityModel.Tokens;

namespace MaskinportenTokenGenerator
{
    public class TokenHandler
    {

        private readonly string _issuer;
        private readonly string _audience;
        private readonly string _resource;
        private readonly string _scopes;
        private readonly string _tokenEndpoint;
        private readonly int _tokenTtl;
        private readonly X509Certificate2 _signingCertificate;
        private readonly SecurityKey _signingKey;
        private readonly string _kidClaim;
        private readonly string _consumerOrg;

        public string LastTokenRequest { get; private set; }
        public Exception LastException { get; private set; }
        public string CurlDebugCommand { get; private set; }

        public TokenHandler(string certificateThumbprint, StoreLocation certificateStoreLocation, string kidClaim, string tokenEndpoint, string audience, string resource,
            string scopes, string issuer, int tokenTtl, string consumerOrg)
        {
            _signingCertificate = GetCertificateFromKeyStore(certificateThumbprint, StoreName.My, certificateStoreLocation);

            _kidClaim = kidClaim;
            _tokenEndpoint = tokenEndpoint;
            _audience = audience;
            _resource = resource;
            _scopes = scopes;
            _issuer = issuer;
            _tokenTtl = tokenTtl;
            _consumerOrg = consumerOrg;
        }

        public TokenHandler(string p12KeyStoreFile, string p12KeyStorePassword, string kidClaim, string tokenEndpoint, string audience, string resource,
            string scopes, string issuer, int tokenTtl, string consumerOrg)
        {
            _signingCertificate = new X509Certificate2(
                File.ReadAllBytes(p12KeyStoreFile),
                p12KeyStorePassword,
                X509KeyStorageFlags.MachineKeySet | X509KeyStorageFlags.PersistKeySet | X509KeyStorageFlags.Exportable);

            _kidClaim = kidClaim;
            _tokenEndpoint = tokenEndpoint;
            _audience = audience;
            _resource = resource;
            _scopes = scopes;
            _issuer = issuer;
            _tokenTtl = tokenTtl;
            _consumerOrg = consumerOrg;
        }

        public TokenHandler(string jwkJsonFile, bool isKeySetFormat, string kidClaim, string tokenEndpoint, string audience, string resource,
            string scopes, string issuer, int tokenTtl, string consumerOrg)
        {
            if (isKeySetFormat)
            {
                throw new NotImplementedException();
            }
            else
            {
                _signingKey = new JsonWebKey(File.ReadAllText(jwkJsonFile));
            }

            _kidClaim = kidClaim;
            _tokenEndpoint = tokenEndpoint;
            _audience = audience;
            _resource = resource;
            _scopes = scopes;
            _issuer = issuer;
            _tokenTtl = tokenTtl;
            _consumerOrg = consumerOrg;
        }

        public string GetTokenFromAuthCodeGrant(string assertion, string code, string clientId, string redirectUri, string codeVerifier, out bool isError)
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

            var formContent = new FormUrlEncodedContent(new List<KeyValuePair<string, string>>
            {
                new KeyValuePair<string, string>("client_id", clientId),
                new KeyValuePair<string, string>("grant_type", "authorization_code"),
                new KeyValuePair<string, string>("code", code),
                new KeyValuePair<string, string>("redirect_uri", redirectUri),
                new KeyValuePair<string, string>("code_verifier", codeVerifier),
                new KeyValuePair<string, string>("client_assertion_type", "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"),
                new KeyValuePair<string, string>("client_assertion", assertion)
            });

            LastTokenRequest = formContent.ReadAsStringAsync().Result;
            return SendTokenRequest(formContent, out isError);     
        }

        public string GetTokenFromJwtBearerGrant(string assertion, out bool isError)
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

            var formContent = new FormUrlEncodedContent(new List<KeyValuePair<string, string>>
            {
                new KeyValuePair<string, string>("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                new KeyValuePair<string, string>("assertion", assertion),
            });

            LastTokenRequest = formContent.ReadAsStringAsync().Result;
            return SendTokenRequest(formContent, out isError);            
        }

        public static void PrettyPrintException(Exception e)
        {
            Console.WriteLine("############");
            Console.WriteLine("Failed request to token endpoint, Exception thrown: " + e.GetType().FullName);
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
        }

        public string GetJwtAssertion()
        {
            var dateTimeOffset = new DateTimeOffset(DateTime.UtcNow);
            JwtHeader header;
            if (_signingCertificate != null)
            {
                var securityKey = new X509SecurityKey(_signingCertificate);
                header = new JwtHeader(new SigningCredentials(securityKey, SecurityAlgorithms.RsaSha256))
                {
                    { "x5c", new List<string>() { Convert.ToBase64String(_signingCertificate.GetRawCertData()) } }
                };
                header.Remove("typ");
            }
            else if (_signingKey != null)
            {
                // TODO! We always assume RS256
                header = new JwtHeader(new SigningCredentials(_signingKey, SecurityAlgorithms.RsaSha256));
                header.Remove("typ");
            }
            else
            {
                throw new ArgumentException(
                    "Internal error: expected either _signingCertificate or _signingKey to be non-null");
            }
 
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
                { "scope", _scopes },
                { "sub", _issuer }, // See https://docs.digdir.no/docs/idporten/oidc/oidc_protocol_token.html#client-authentication-using-jwt-token
                { "iss", _issuer },
                { "exp", dateTimeOffset.ToUnixTimeSeconds() + _tokenTtl },
                { "iat", dateTimeOffset.ToUnixTimeSeconds() },
                { "jti", Guid.NewGuid().ToString() },
            };

            if (_resource != null)
            {
                payload.Add("resource", _resource);
            }

            if (_consumerOrg != null) {
                payload.Add("consumer_org", _consumerOrg);
            }

            var securityToken = new JwtSecurityToken(header, payload);
            var handler = new JwtSecurityTokenHandler();

            return handler.WriteToken(securityToken);
        }

        private string SendTokenRequest(FormUrlEncodedContent formContent, out bool isError)
        {
            var client = new HttpClient();

            CurlDebugCommand = "curl -v -X POST -d '" + formContent.ReadAsStringAsync().Result + "' " + _tokenEndpoint;
            try {
                var response = client.PostAsync(_tokenEndpoint, formContent).Result;
                isError = !response.IsSuccessStatusCode;
                return response.Content.ReadAsStringAsync().Result;
            }
            catch (Exception e)
            {
                LastException = e;
                isError = true;
                PrettyPrintException(e);
                return null;
            }
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
