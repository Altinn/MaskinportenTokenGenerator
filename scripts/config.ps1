#### Configuration file for scopes admin scripts

$global:CONFIG = @{

# Absolute path to the tokengenerator .cmd-file
TokenGenerator = "C:\Repos\MaskinportenTokenGenerator\maskinporten_token_generator.cmd" 

# If set to true, will always fetch a new token from, regardless of TTL. 
AlwaysRefreshToken = $false 


}