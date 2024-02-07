# 
# Do not alter this file directly, but copy it to config.local.cmd where you can override values defined in this file
# 

# --------- PRODUCTION SETTINGS -----------
# The thumbprint for your own enterprise certificate in local machine storage (Cert:\LocalMachine\My)
$production_certificate_thumbprint = ""

# If you want to use CurrentUser certificate store location instead (Cert:\CurrentUser\My)
$production_use_current_user_store_location = "true"

# Or alternatively; the path to a PKCS#12 file containing a certificate used to sign the request
#set production_keystore_path=

# Password to the key store. Make sure you escape correctly.
#set production_keystore_password=

# Or alternatively; the path to a JWK file containing the public/private key used to sign the request
#set production_jwk_path=

# If authenticating with a pre-registered key, the kid used as identifier must be included in the assertion. If not supplied, falls back to thumbprint (same as x5t).
#set production_kid=

# The client_id that you have provisioned with the scopes you want
$production_client_id = ""

# The intended "aud" claim for the access_token
$production_resource = ""

# The scopes you want in your access token (comma delimited, no spaces)
$production_scopes = ""

# The aud claim for the bearer grant assertion. Used as issuer claim in returned token
$production_audience = "https://maskinporten.no/"
# For ID-porten: set production_audience=https://oidc.difi.no/idporten-oidc-provider/

# Endpoint to send bearer grant assertion
# For ID-porten: set production_token_endpoint=https://oidc.difi.no/idporten-oidc-provider/token
$production_token_endpoint = "https://maskinporten.no/token"

# Endpoint for authorization (only used for person mode)
$production_authorize_endpoint = "https://login.idporten.no/authorize"

# Enables login with a person in ID-porten and authCode flow. Implies server mode, and requires a ID-porten client configured with private_jwt authentication
$production_person_mode = "false"

# Enables supplier mode for use with Maskinporten and delegation schemes. Enter the organization number that will have to delegate access to this scope in Altinn
$production_consumer_org = ""

# --------- TEST (for ATxx/TT02) SETTINGS -----------
$test_certificate_thumbprint = ""
#set test_use_current_user_store_location=true
#set test_keystore_path=
#set test_keystore_password=
#set test_jwk_path=
#set test_kid=
$test_client_id = ""
$test_resource = ""
$test_scopes = ""
$test_audience = "https://test.maskinporten.no/"
$test_token_endpoint = "https://test.maskinporten.no/token"
$test_authorize_endpoint = "https://login.test.idporten.no/authorize"
$test_person_mode = "false"
$test_consumer_org = ""

# For legacy test (VER2) environments, use:
# set test_audience=https://ver2.maskinporten.no/
# set test_token_endpoint=https://ver2.maskinporten.no/token
# set test_authorize_endpoint=https://oidc-ver2.difi.no/idporten-oidc-provider/authorize

# --------- DEV SETTINGS. This is only for internal/experimental use, you probably want TEST -----------
$dev_certificate_thumbprint = ""
#set dev_use_current_user_store_location=true
#set dev_keystore_path=
#set dev_keystore_password=
#set dev_jwk_path=
#set dev_kid=
$dev_client_id = ""
$dev_resource = ""
$dev_scopes = ""
$dev_audience = "https://maskinporten.dev/"
$dev_token_endpoint = "https://maskinporten.dev/token"
$dev_authorize_endpoint = "https://login.idporten.dev/authorize"
$dev_person_mode = "false"
$dev_consumer_org = ""
