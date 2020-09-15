:: 
:: Do not alter this file directly, but copy it to config.local.cmd where you can override values defined in this file
:: 

:: --------- PRODUCTION SETTINGS -----------
:: The thumbprint for your own enterprise certificate in local machine storage
set production_certificate_thumbprint=

:: Alternative to cert thumbprint; the path to a PKCS#12 file containing a certificate used to sign the request
::set production_keystore_path=

:: Password to the key store. Make sure you escape correctly.
::set production_keystore_password=

:: If authenticating with a pre-registered key, the kid used as identifier must be included in the assertion. If not supplied, falls back to thumbprint (same as x5t).
::set production_kid=

:: The client_id that you have provisioned with the scopes you want
set production_client_id=

:: The intended "aud" claim for the access_token
set production_resource=

:: The scopes you want in your access token (comma delimited, no spaces)
set production_scopes=

:: The aud claim for the bearer grant assertion. Used as issuer claim in returned token
set production_audience=https://maskinporten.no/

:: Endpoint to send bearer grant assertion
set production_token_endpoint=https://maskinporten.no/token

:: Endpoint for authorization (person mode)
set production_authorize_endpoint=https://oidc.difi.no/idporten-oidc-provider/authorize

:: --------- VER2 (for ATxx/TT02) SETTINGS -----------
set test_certificate_thumbprint=
::set test_keystore_path=
::set test_keystore_password=
::set test_kid=
set test_client_id=
set test_resource=
set test_scopes=
set test_audience=https://ver2.maskinporten.no/
set test_token_endpoint=https://ver2.maskinporten.no/token
set test_authorize_endpoint=https://oidc-ver2.difi.no/idporten-oidc-provider/authorize

:: --------- TEST1 (for DEV) SETTINGS -----------
set dev_certificate_thumbprint=
::set dev_keystore_path=
::set dev_keystore_password=
::set dev_kid=
set dev_client_id=
set dev_resource=
set dev_scopes=
set dev_audience=https://test1.maskinporten.no/
set dev_token_endpoint=https://test1.maskinporten.no/token
set dev_authorize_endpoint=https://oidc-test1.difi.no/idporten-oidc-provider/authorize
