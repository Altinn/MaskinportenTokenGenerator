# Script to updates service owner access to Altinn service owner scopes defined in ID/Maskinporten
# Author: bdl@digdir.no
# -----------------------------------------------------------------------------------------------------------------
# NOTE! Requires a "scopes-admin.config.local.cmd" file present in same directory as script.
# -----------------------------------------------------------------------------------------------------------------
#
# Examples: 
# ./admin.ps1 -Env ver2 -Report         --> Generates a report showing all orgs having access to a scope
# ./admin.ps1 -Env ver2 -ShowMissing   --> List all serviceowners missing scope access
# ./admin.ps1 -Env ver2 -ShowExtra     --> List all scopes having orgs with access that are not serviceowners
# ./admin.ps1 -Env ver2 -AddMissing    --> Grant service owners access to missing scopes, if any
# ./admin.ps1 -Env ver2 -RemoveExtra   --> Revoke non-service owners access to scopes, if any


[cmdletbinding()]
param (
    [Parameter(Mandatory=$true)][string]$Env,
    [Parameter(ParameterSetName="Report")][Switch]$Report,
    [Parameter(ParameterSetName="ShowMissing")][Switch]$ShowMissing,
    [Parameter(ParameterSetName="ShowExtra")][Switch]$ShowExtra,
    [Parameter(ParameterSetName="AddMissing")][Switch]$AddMissing,
    [Parameter(ParameterSetName="RemoveExtra")][Switch]$RemoveExtrase
)

$ScopeAccess = ($PSScriptRoot + "\scopeaccess.ps1")

function Get-ServiceOwners {
    param($Env)
    $sofile = "$PSScriptRoot\serviceowners.local.json"
    if (!(Test-Path $sofile)) {
        Write-Warning "$sofile not found. Copy it from serviceowners.json"
        Exit 1
    }
    $tmp = Get-Content -Raw -Path $sofile | ConvertFrom-Json 
    $so = @{}
    $tmp.orgs.psobject.properties | Foreach { $so[$_.Name] = $_.Value }
    $so.Values | Where { $_.environments -and $_.environments.Contains($Env) }
}

function Generate-Full-Report {
    $report = @{}
    Write-Verbose "Getting list of serviceowner scopes ..."
    $scopes = . $ScopeAccess -env $Env -operator listprefix -scope altinn:serviceowner | ForEach-Object { $_.name }
    Write-Verbose ($scopes.Count.ToString() + " scopes received.")
    foreach ($scope in $scopes) {
        Write-Verbose("Getting orgs with access to scope '$scope' ...")
        $orgs = . $ScopeAccess -env $Env -operator get -scope $scope | ForEach-Object { $_.consumer_orgno }
        $report[$scope] = $orgs        
    }
    $report
}

function Generate-Missing-Report {
    $report = Generate-Full-Report
    $serviceOwners = Get-ServiceOwners -Env $env

    $missingReport = @{}
    foreach ($so in $serviceOwners) {
        $missing = @()
        Write-Verbose $so
        foreach ($scopeaccess in $report.GetEnumerator()) {
            if ($null -ne $scopeaccess.Value -and $scopeaccess.Value.Contains($so.orgnr)) {
                Write-Verbose ($so.name.en + " (" + $so.orgnr + ") has access to " + $scopeaccess.Key)                
            } else {
                Write-Verbose ($so.name.en + " (" + $so.orgnr + ") MISSING access to " + $scopeaccess.Key)
                $missing += $scopeaccess.Key
            }
        }
        if ($missing.Count) {
            $missingReport[$so] = $missing
        }
    }

    $missingReport
}

function Generate-Extra-Report {
    
}

function Add-Missing {
    $missingReport = Generate-Missing-Report

    foreach ($missing in $missingReport.GetEnumerator()) {
        foreach ($scope in $missing.Value) {
            Write-Output ("Giving " + $missing.Key.name.en + " (" + $missing.Key.orgnr + ") access to " + $scope)
            . $ScopeAccess -env $Env -operator add -scope $scope -org $missing.Key.orgnr
        }
    }
}


if ($Report) {
    Generate-Full-Report 
}
elseif ($ShowMissing) {
    $missingReport = Generate-Missing-Report
    if (!$missingReport.Keys.Count) {
        Write-Output "No service owners are found missing scope access"
    }
    else {
        $missingReport 
    }
}
elseif ($ShowExtra) {
    Generate-Extra-Report
}
elseif ($AddMissing) {
    Add-Missing
}
elseif ($RemoveExtra) {
    Remove-Extra
}

