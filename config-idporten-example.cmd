:: --------- TEST SETTINGS -----------

:: Whether or not personal login is request (ID-porten mode)
set test_person_mode=true

:: The client_id that you have provisioned with the scopes you want
set test_client_id=yourclientidhere

:: The thumbprint for your own enterprise certificate in local machine storage (Cert:\LocalMachine\My). This must match the orgno for the owner of the client.
set test_certificate_thumbprint=yourcertificatethumprinthere 

:: If you want to use CurrentUser certificate store location instead (Cert:\CurrentUser\My)
set test_use_current_user_store_location=true

:: The scopes you want in your access token
set test_scopes="yourscopehere"

:: The aud claim for the bearer grant assertion. Used as issuer claim in returned token
set test_audience=https://test.idporten.no

:: Endpoint for token
set test_token_endpoint=https://test.idporten.no/token

:: Endpoint for authorization (person mode)
set test_authorize_endpoint=https://login.test.idporten.no/authorize