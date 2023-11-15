# Script to manage access (whitelisting) to scopes defined in ID/Maskinporten
# Author: bdl@digdir.no
# -----------------------------------------------------------------------------------------------------------------
# NOTE! Requires a "scopes-admin.config.local.cmd" file present in same directory as script.
# -----------------------------------------------------------------------------------------------------------------
#
# Examples: 
# ./scopeaccess get someprefix:somescope                -> Returns a list of organizations with access to someprefix:somescope
# ./scopeaccess getorg 912345678                        -> Returns a list of scopes granted an organization
# ./scopeaccess get someprefix:somescope 912345678      -> Returns the scope access for a given scope and organization
# ./scopeaccess remove someprefix:somescope 912345678   -> Revoke 912345678 access to someprefix:somescope
# ./scopeaccess add someprefix:somescope 912345678      -> Grant 912345678 access to someprefix:somescope
# ./scopeaccess listprefix someprefix:somescope         -> List all scopes starting with someprefix:somescope
# 
# Environment defaults to "TEST". Can be overridden by supplying a fourth positional or -env parameter containing "test" or "prod"

param (
    [Parameter(Mandatory=$true)][string]$operator,
    [Parameter()][string]$scope,
    [Parameter()][string]$org,
    [Parameter()][string]$env = "test"
)

. ($PSScriptRoot + "/config.ps1")
. ($PSScriptRoot + "/token.ps1")
. ($PSScriptRoot + "/env.ps1")

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
    if ($Scope -eq "") {
        $result = Invoke-API -Verb GET -Path "/scopes/access/?consumer_orgno=$Org"
    }
    else {
        $result = Invoke-API -Verb GET -Path "/scopes/access/?consumer_orgno=$Org&scope=$scope"
    }
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

function Get-All-Scopes-Starting-With {
    param($Prefix)
    $result = Invoke-API -Verb GET -Path "/scopes" | Where-Object { $_.name -match ("^" + $Prefix) }
    return $result
}

#####################################################

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
elseif ($operator -eq "getorg") {
    if ($org -eq "") {
        Write-Error "Organization number must be supplied"
        Exit 1
    }
    Get-Scope-Access -Org $org -Scope ""
}
elseif ($operator -eq "listprefix") {
    Get-All-Scopes-Starting-With -Prefix $scope
}
else {
    Write-Error 'Operation must be one of "add", "remove", "get", "getorg" or "listprefix"'
}
