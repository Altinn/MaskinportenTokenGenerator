:: --------- VER2 SETTINGS -----------

:: Whether or not personal login is request (ID-porten mode)
set test_person_mode=true

:: The client_id that you have provisioned with the scopes you want
set test_client_id=yourclientidhere

:: The thumbprint for your own enterprise certificate in local machine storage. This must match the orgno for the owner of the client.
set test_certificate_thumbprint=yourcertificatethumprinthere 

:: The scopes you want in your access token
set test_scopes="difitest:altinneus"

:: The aud claim for the bearer grant assertion. Used as issuer claim in returned token
set test_audience=https://oidc-ver2.difi.no/idporten-oidc-provider/

:: Endpoint for token
set test_token_endpoint=https://oidc-ver2.difi.no/idporten-oidc-provider/token

:: Endpoint for authorization (person mode)
set test_authorize_endpoint=https://oidc-ver2.difi.no/idporten-oidc-provider/authorize