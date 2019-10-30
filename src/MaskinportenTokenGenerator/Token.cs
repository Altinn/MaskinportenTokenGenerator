using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Net.Http;
using System.Security.Cryptography.X509Certificates;
using Microsoft.IdentityModel.Tokens;

namespace MaskinportenTokenGenerator
{
    public class Token
    {
        private static string _certificateThumbPrint;
        private static string _issuer;
        private static string _audience;
        private static string _resource;
        private static string _scopes;
        private static string _tokenEndpoint;
        private static int _tokenTtl;

        public Token(string certificateThumbprint, string tokenEndpoint, string audience, string resource,
            string scopes, string issuer, int tokenTtl)
        {
            _certificateThumbPrint = certificateThumbprint;
            _tokenEndpoint = tokenEndpoint;
            _audience = audience;
            _resource = resource;
            _scopes = scopes;
            _issuer = issuer;
            _tokenTtl = tokenTtl;
        }

        public string GetAccessToken(string assertion, out bool isError)
        {
            var formContent = new FormUrlEncodedContent(new List<KeyValuePair<string, string>>
            {
                new KeyValuePair<string, string>("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                new KeyValuePair<string, string>("assertion", assertion),
            });

            var client = new HttpClient();
            var response = client.PostAsync(_tokenEndpoint, formContent).Result;
            isError = !response.IsSuccessStatusCode;
            return response.Content.ReadAsStringAsync().Result;
        }

        public string GetJwtAssertion()
        {
            var dateTimeOffset = new DateTimeOffset(DateTime.UtcNow);

            var cert = GetCertificateFromKeyStore(_certificateThumbPrint, StoreName.My, StoreLocation.LocalMachine);
            var securityKey = new X509SecurityKey(cert);
            var header = new JwtHeader(new SigningCredentials(securityKey, SecurityAlgorithms.RsaSha256))
            {
                {"x5c", new List<string>() {Convert.ToBase64String(cert.GetRawCertData())}}
            };
            header.Remove("typ");
            header.Remove("kid");

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

            return cert;
        }
    }
}
