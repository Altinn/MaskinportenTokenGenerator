# Script to patch which scopes a service owner has access to based on the scopes defined in the scopes file.
# Author: teh@digdir.no
# -----------------------------------------------------------------------------------------------------------------
# NOTE! Requires a "scopes-admin.config.local.cmd" file present in same directory as script.
# -----------------------------------------------------------------------------------------------------------------
#
# Examples: 
# .\so-patch report -env test -org 991825827                  --> Generates a report showing expected and actual access to scopes for one org
# .\so-patch patch -env test -org 991825827                   --> Gives org access to all scopes defined in scopes.local.json
# .\so-patch patch_all -env test -scope someprefix:somescope  --> Perfect if introducing a new scope you want all application owners to have access to
#

[cmdletbinding()]
param (
    [Parameter(Mandatory=$true)][string]$Operator,
    [Parameter(Mandatory=$true)][string]$Env,
    [Parameter(Mandatory=$false)][string]$Org,
    [Parameter(Mandatory=$false)][string]$Scope
)

$ScopeAccess = ($PSScriptRoot + "\scopeaccess.ps1")

function Get-Scopes {
    $scopesfile = "$PSScriptRoot\scopes.local.json"
    if (!(Test-Path $scopesfile)) {
        Write-Warning "$scopesfile not found. Copy it from scopes.json"
        Exit 1
    }
    $scopes = Get-Content -Raw -Path $scopesfile | ConvertFrom-Json 
    $scopes.scopes
}

function Get-ServiceOwners {
    param($env)

    $sofile = "$PSScriptRoot\serviceowners.local.json"
    if (!(Test-Path $sofile)) {
        Write-Warning "$sofile not found. Copy it from serviceowners.json"
        Exit 1
    }

    $fileContent = Get-Content -Raw -Path $sofile | ConvertFrom-Json 

    $so = @{}
    $fileContent.orgs.psobject.properties 
        | ForEach-Object { $so[$_.Name] = $_.Value }
    $so.Values 
        | Where-Object { $_.environments -and $_.environments.Contains($env) } 
        | Select-Object -ExpandProperty name -Property orgnr 
        | ForEach-Object {
            [PSCustomObject]@{
                OrgNo   = $_.orgnr
                Name   = $_.nb
            }}
}

function Get-ReportOrg {
    param($env, $org)
    $scopes = Get-Scopes

    $report = [ordered]@{}
    foreach ($scope in $scopes) {
        $report[$scope] = $false
    }

    $orgscopes = . $ScopeAccess -env $env -operator get -org $org
    foreach ($orgscope in $orgscopes) {
        Write-Verbose $orgscope
        if ($report.Keys -contains $orgscope.scope -and $orgscope.state -eq "APPROVED") {
            $report[$orgscope.scope] = $true
        }
    }
    $report
}

function Patch-Org {
    param($env, $org)

    $report = Get-ReportOrg -env $env -org $org

    $report | Format-Table -AutoSize

    foreach ($item in $report.GetEnumerator()) {
        if ($item.Value -eq $false) {
            Write-Warning ("Giving $org access to " + $item.Key)
            . $ScopeAccess -env $env -operator add -scope $item.Key -org $org
        }
    }
}

function Patch-All {
    param($env, $scope)
    
    $scopes = Get-Scopes

    if ($scopes -notcontains $scope) {
        Write-Error "Scope $scope not found in scopes.local.json"
        Exit 1
    }

    $orgs = Get-ServiceOwners -env $env

    foreach ($org in $orgs) {
        Write-Verbose ("Checking " + $org.Name + " ..." + $org.OrgNo)

        $report = Get-ReportOrg -env $env -org $org.OrgNo
        $report | Format-Table -AutoSize

        if ($report[$scope] -eq $false) {
            Write-Warning ("Giving " + $org.Name + " access to " + $scope)
            . $ScopeAccess -env $env -operator add -scope $scope -org $org.OrgNo
        }
    }
}


# ----------------------------------------------------------------------------------------------------------------- #

if ($Operator -eq "report") {
    if ($Org -eq "") {
        Write-Error "Organization number must be supplied"
        Exit 1
    }
    Get-ReportOrg -env $Env -org $Org | Format-Table -AutoSize
}

if ($Operator -eq "patch") {
    if ($Org -eq "") {
        Write-Error "Organization number must be supplied"
        Exit 1
    }
    Patch-Org -env $Env -org $Org
}

if ($Operator -eq "patch_all") {
    if ($Scope -eq "") {
        Write-Error "A scope must be supplied. Also remember that the scope must be defined in scopes.local.json"
        Exit 1
    }
    Patch-All -env $Env -scope $Scope
}
