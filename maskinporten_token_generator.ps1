# Set script directory as the current working directory
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $PSScriptRoot

$MPEXE = Join-Path $PSScriptRoot "src\MaskinportenTokenGenerator\bin\Debug\net8.0\MaskinportenTokenGenerator.exe"
if (-not (Test-Path $MPEXE)) {
    Write-Host "$MPEXE not found. Build it first."
    Pause
    exit 1
}

$server_mode_opt = $null
$only_token_opt = $null
if ($args[0] -eq "servermode") {
    $server_mode_opt = "--server_mode --server_port=17823"
}

if ($args[0] -eq "onlytoken") {
    $only_token_opt = "--only_token"
}

$local_config = $null
if ([string]::IsNullOrEmpty($args[2])) {
    $local_config = "config.local.ps1"
} else {
    if (-not (Test-Path $args[2])) {
        Write-Host "Unable to load custom config file: $($args[2])"
        Pause
        exit 1
    }
    if ([string]::IsNullOrEmpty($only_token_opt)) {
        Write-Host "Using custom config file: $($args[2])"
    }
    $local_config = $args[2]
}

. .\config.ps1
if (Test-Path $local_config) {
    . $local_config
}

$certificate_thumbprint = $null
$keystore_path = $null
$keystore_password = $null
$jwk_path = $null
$kid = $null
$client_id = $null
$resource = $null
$scopes = $null
$audience = $null
$token_endpoint = $null
$authorize_endpoint = $null
$person_mode = $null
$consumer_org = $null
$use_current_user_store_location = $null

if ($args[1] -eq "dev") {
    if ([string]::IsNullOrEmpty($dev_client_id)) {
        Write-Host "Missing configuration for DEV environment. Check the configuration, and make sure that any config.local.ps1 is up-to-date with fields defined in config.ps1"
        Pause
        exit 1
    }

    $certificate_thumbprint = $dev_certificate_thumbprint
    $keystore_path = $dev_keystore_path
    $keystore_password = $dev_keystore_password
    $jwk_path = $dev_jwk_path
    $kid = $dev_kid
    $client_id = $dev_client_id
    $resource = $dev_resource
    $scopes = $dev_scopes
    $audience = $dev_audience
    $token_endpoint = $dev_token_endpoint
    $authorize_endpoint = $dev_authorize_endpoint
    $person_mode = $dev_person_mode
    $consumer_org = $dev_consumer_org
    $use_current_user_store_location = $dev_use_current_user_store_location
}

if ($args[1] -eq "test") {
    if ([string]::IsNullOrEmpty($test_client_id)) {
        Write-Host "Missing configuration for TEST/ATxx/TT02 environment. Check the configuration, and make sure that any config.local.ps1 is up-to-date with fields defined in config.ps1"
        Pause
        exit 1
    }

    $certificate_thumbprint = $test_certificate_thumbprint
    $keystore_path = $test_keystore_path
    $keystore_password = $test_keystore_password
    $jwk_path = $test_jwk_path
    $kid = $test_kid
    $client_id = $test_client_id
    $resource = $test_resource
    $scopes = $test_scopes
    $audience = $test_audience
    $token_endpoint = $test_token_endpoint
    $authorize_endpoint = $test_authorize_endpoint
    $person_mode = $test_person_mode
    $consumer_org = $test_consumer_org
    $use_current_user_store_location = $test_use_current_user_store_location
}

if ($args[1] -eq "prod") {
    if ([string]::IsNullOrEmpty($production_client_id)) {
        Write-Host "Missing configuration for PROD environment. Check the configuration, and make sure that any config.local.ps1 is up-to-date with fields defined in config.ps1"
        Pause
        exit 1
    }

    $certificate_thumbprint = $production_certificate_thumbprint
    $keystore_path = $production_keystore_path
    $keystore_password = $production_keystore_password
    $jwk_path = $production_jwk_path
    $kid = $production_kid
    $client_id = $production_client_id
    $resource = $production_resource
    $scopes = $production_scopes
    $audience = $production_audience
    $token_endpoint = $production_token_endpoint
    $authorize_endpoint = $production_authorize_endpoint
    $person_mode = $production_person_mode
    $consumer_org = $production_consumer_org
    $use_current_user_store_location = $production_use_current_user_store_location
}

$resource_opt = if ($resource) { "--resource=$resource" } else { $null }
$certificate_thumbprint_opt = if ($certificate_thumbprint) { "--certificate_thumbprint=$certificate_thumbprint" } else { $null }
$keystore_opt = if ($keystore_path) { "--keystore_path=$keystore_path --keystore_password=$keystore_password" } else { $null }
$jwk_path_opt = if ($jwk_path) { "--jwk_path=$jwk_path" } else { $null }
$kid_opt = if ($kid) { "--kid=$kid" } else { $null }
$person_mode_opt = if ($person_mode) { "--person_mode=$person_mode" } else { $null }
$consumer_org_opt = if ($consumer_org) { "--consumer_org=$consumer_org" } else { $null }
$use_current_user_store_location_opt = if ($use_current_user_store_location) { "--use_current_user_store_location=$use_current_user_store_location" } else { $null }

$cmd = "$MPEXE --client_id=$client_id --audience=$audience --token_endpoint=$token_endpoint --authorize_endpoint=$authorize_endpoint --scopes=$scopes $only_token_opt $person_mode_opt $server_mode_opt $resource_opt $certificate_thumbprint_opt $keystore_opt $jwk_path_opt $kid_opt $consumer_org_opt $use_current_user_store_location_opt"
if (-not $only_token_opt) {
    Write-Host "-------------------------------"
    Write-Host $cmd
    Write-Host "-------------------------------"
}
Invoke-Expression $cmd
