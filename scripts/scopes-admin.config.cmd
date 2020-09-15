set maskinporten_token_generator_cmd=C:\MaskinportenTokenGenerator\maskinporten_token_generator.cmd

:: --------- VER2 SETTINGS -----------
:: The path to a PKCS#12 file containing a certificate used to sign the request
set test_keystore_path=C:\somepathto\keystore-ver2.p12

:: Password to the key store
set test_keystore_password=somepassword

:: If authenticating with a pre-registered key (private_key_jwt), a kid must be supplied
set test_kid=somekid

:: The client_id that you have provisioned with the scopes you want
set test_client_id=someclientid

:: The scopes you want in your access token
set test_scopes="idporten:scopes.write"

:: The aud claim for the bearer grant assertion. Used as issuer claim in returned token
set test_audience=https://oidc-ver2.difi.no/idporten-oidc-provider/

set test_token_endpoint=https://oidc-ver2.difi.no/idporten-oidc-provider/token