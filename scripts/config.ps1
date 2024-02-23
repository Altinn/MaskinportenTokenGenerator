#### Configuration file for scopes admin scripts

$global:CONFIG = @{

# Absolute path to the tokengenerator .cmd-file
TokenGenerator = "$PSScriptRoot/../maskinporten_token_generator.ps1" 

# If set to true, will always fetch a new token from, regardless of TTL. 
AlwaysRefreshToken = $false 


}