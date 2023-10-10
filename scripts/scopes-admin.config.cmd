:: --------- PROD SETTINGS -----------
:: The path to a PKCS#12 file containing a certificate used to sign the request
set production_keystore_path=C:\somepathto\keystore-prod.p12

:: Password to the key store
set production_keystore_password=somepassword

:: If authenticating with a pre-registered key (private_key_jwt), a kid must be supplied
set production_kid=somekid

:: The client_id that you have provisioned with the scopes you want
set production_client_id=someclientid

:: The scopes you want in your access token
set production_scopes="idporten:scopes.write"

:: --------- TETS SETTINGS -----------
:: The path to a PKCS#12 file containing a certificate used to sign the request
set test_keystore_path=C:\somepathto\keystore-test.p12
set test_keystore_password=somepassword
set test_kid=somekid
set test_client_id=someclientid
set test_scopes="idporten:scopes.write"
