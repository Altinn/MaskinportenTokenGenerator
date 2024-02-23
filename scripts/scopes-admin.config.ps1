# --------- PROD SETTINGS -----------
# The path to a PKCS#12 file containing a certificate used to sign the request
$production_keystore_path = "somepathto/keystore-prod.p12"

# Password to the key store
$production_keystore_password = "somepassword"

# If authenticating with a pre-registered key (private_key_jwt), a kid must be supplied
$production_kid = "somekid"

# The client_id that you have provisioned with the scopes you want
$production_client_id = "someclientid"

# The scopes you want in your access token
$production_scopes = "idporten:scopes.write"

# --------- TETS SETTINGS -----------
# The path to a PKCS#12 file containing a certificate used to sign the request
$test_keystore_path = "somepathto/keystore-test.p12"
$test_keystore_password = "somepassword"
$test_kid = "somekid"
$test_client_id = "someclientid"
$test_scopes = "idporten:scopes.write"
