# Script to manage access (whitelisting) to scopes defined in ID/Maskinporten
# Author: bdl@digdir.no
# -----------------------------------------------------------------------------------------------------------------
# NOTE! Requires MaskinportenTokenGenerator to be running in server mode on port 17823 configured to return a token 
# with "idporten:scopes.write" scope for the requested environment
# -----------------------------------------------------------------------------------------------------------------
#
# Examples: 
# ./scopeaccess.ps1 get someprefix:somescope                -> Returns a list of organizations with access to someprefix:somescope
# ./scopeaccess.ps1 get someprefix:somescope 912345678      -> Returns the scope access for a given scope and organization
# ./scopeaccess.ps1 remove someprefix:somescope 912345678   -> Revoke 912345678 access to someprefix:somescope
# ./scopeaccess.ps1 add someprefix:somescope 912345678      -> Grant 912345678 access to someprefix:somescope
# 
# Environment defaults to "VER2". Can be overridden by supplying a fourth positional or -env parameter containing "test1", "ver1", ver2" or "prod"

param (
    [Parameter(Mandatory=$true)][string]$operator,
    [Parameter(Mandatory=$true)][string]$scope,
    [Parameter()][string]$org,
    [Parameter()][string]$env = "ver2"
)

function Add-Scope-Access {
    param($Scope, $Org)
    $result = Invoke-API -Verb PUT -Path ("/scopes/access/" + $Org + "?scope=" + $scope)
    $result
}

function Remove-Scope-Access {
    param($Scope, $Org)
    $result = Invoke-API -Verb DELETE -Path ("/scopes/access/" + $Org + "?scope=" + $scope)
    $result
}

function Get-Scope-Access {
    param($Scope, $Org)
    $result = Invoke-API -Verb GET -Path "/scopes/access/?consumer_orgno=$Org&scope=$scope"
    if ($null -eq $result) {
        Write-Output "No scope or org found"
    }
    else {
        $result
    }
}

function Get-Scope-Access-All {
    param($Scope)
    $result = Invoke-API -Verb GET -Path "/scopes/access/?scope=$scope"
    if ($null -eq $result) {
        Write-Output "No scope found"
    }
    else {
        $result
    }
}

function Get-Token {
    $result = Invoke-RestMethod -Uri http://localhost:17823/?cache=true
    if ($null -eq $result.access_token) {
        Write-Error "Did not get token"
        Exit 1
    }

    return $result.access_token
}

function Get-All-Scopes-Starting-With {
    param($Prefix)
    $result = Invoke-API -Verb GET -Path "/scopes" | where { $_.name -match ("^" + $Prefix) }
    return $result
}

function Invoke-API {
    param($Verb, $Path)
    $access_token = Get-Token
    $url = $envUrl + $Path
    try {
        $result = Invoke-RestMethod -Uri $url -Method $Verb -Headers @{
            Accept = "application/json"
            Authorization = "Bearer $access_token"
        }
    }
    catch {
        Write-Warning "Request $verb $url failed"
        Write-Warning ("Server gave status code: " + $_.Exception.Response.StatusCode)
        Exit 1
    }

    return $result
}

#####################################################

$validenv = "test1", "ver1", "ver2", "prod"

if ($validenv -notcontains $env) {
    Write-Error ("Invalid env supplied. Valid environments: " + $validenv) 
    Exit 1
}

if ($env -eq "prod") {
    $envurl = "https://integrasjon.difi.no"
}
else {
    $envurl = "https://integrasjon-$env.difi.no"

}

if ($operator -eq "add") {
    if ($org -eq "") {
        Write-Error "Organization number must be supplied"
        Exit 1
    }
    Add-Scope-Access -Scope $scope -Org $org
}
elseif ($operator -eq "remove") {
    if ($org -eq "") {
        Write-Error "Organization number must be supplied"
        Exit 1
    }
    Remove-Scope-Access -Scope $scope -Org $org
}
elseif ($operator -eq "get") {
    if ($org -eq "") {
        Get-Scope-Access-All -Scope $scope
    }
    else {
        Get-Scope-Access -Scope $scope -Org $org
    }
}
elseif ($operator -eq "listprefix") {
    Get-All-Scopes-Starting-With -Prefix $scope
}
else {
    Write-Error 'Operation must be one of "add", "remove", "get" or listprefix'
}
