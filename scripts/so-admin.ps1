# Script to updates service owner access to Altinn service owner scopes defined in ID/Maskinporten
# Author: bdl@digdir.no
# -----------------------------------------------------------------------------------------------------------------
# NOTE! Requires a "scopes-admin.config.local.cmd" file present in same directory as script.
# -----------------------------------------------------------------------------------------------------------------
#
# Examples: 
# ./so-admin -Env test -Report        --> Generates a report showing all orgs having access to a scope
# ./so-admin -Env test -ShowMissing   --> List all serviceowners missing scope access
# ./so-admin -Env test -ShowExtra     --> List all scopes having orgs with access that are not serviceowners
# ./so-admin -Env test -AddMissing    --> Grant service owners access to missing scopes, if any
# ./so-admin -Env test -RemoveExtra   --> Revoke non-service owners access to scopes, if any
# ./so-admin -Env test -RemoveSingle  --> 
# ./so-admin -Env test -AddSingle     --> 



[cmdletbinding()]
param (
    [Parameter(Mandatory=$true)][string]$Env,
    [Parameter(Mandatory=$false)][string]$Org,
    [Parameter(ParameterSetName="Report")][Switch]$Report,
    [Parameter(ParameterSetName="ShowMissing")][Switch]$ShowMissing,
    [Parameter(ParameterSetName="ShowExtra")][Switch]$ShowExtra,
    [Parameter(ParameterSetName="AddMissing")][Switch]$AddMissing,
    [Parameter(ParameterSetName="RemoveExtra")][Switch]$RemoveExtra,
    [Parameter(ParameterSetName="RemoveSingle")][Switch]$RemoveSingle,
    [Parameter(ParameterSetName="AddSingle")][Switch]$AddSingle
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
    $tmp.orgs.psobject.properties | ForEach-Object { $so[$_.Name] = $_.Value }
    $so.Values | Where-Object { $_.environments -and $_.environments.Contains($Env) }
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

function Generate-Extra-Report {
    $report = Generate-Full-Report
    $serviceOwners = @(Get-ServiceOwners -Env $env | select -ExpandProperty orgnr)

    $extraReport = @{}
    foreach ($scopeaccess in $report.GetEnumerator()) {
        $scope = $scopeaccess.Key;
        foreach ($org in $scopeaccess.Value) {
            Write-Verbose ("Checking if " + $org + " should have access to " + $scope);
            if (!$serviceOwners.Contains($org)) {
                Write-Verbose ($org + " is NOT service owner");
                if (!$extraReport.ContainsKey($org)) {
                    $extraReport[$org] = @();
                }
                $extraReport[$org] += $scope;
            }
            else {
                Write-Verbose ($org + " is service owner")
            }
        }
    }

    $extraReport
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

function Add-Missing {
    $missingReport = Generate-Missing-Report

    foreach ($missing in $missingReport.GetEnumerator()) {
        foreach ($scope in $missing.Value) {
            Write-Output ("Giving " + $missing.Key.name.en + " (" + $missing.Key.orgnr + ") access to " + $scope)
            . $ScopeAccess -env $Env -operator add -scope $scope -org $missing.Key.orgnr
        }
    }
}

function Remove-Single {
    $report = Generate-Full-Report;

    foreach ($sa in $report.GetEnumerator()) {
        $scope = $sa.Key;
        Write-Output ("Removing " + $Org + " access to " + $scope)
        . $ScopeAccess -env $Env -operator remove -scope $scope -org $Org
    }
}

function Add-Single {
    $report = Generate-Full-Report;

    foreach ($sa in $report.GetEnumerator()) {
        $scope = $sa.Key;
        Write-Output ("Adding " + $Org + " access to " + $scope)
        . $ScopeAccess -env $Env -operator add -scope $scope -org $Org
    }
 }

function Show-Missing {
    $missingReport = Generate-Missing-Report
    if (!$missingReport.Keys.Count) {
        Write-Output "No service owners are found missing scope access"
    }
    else {
        $missingList = @()
        foreach ($missing in $missingReport.GetEnumerator()) {
            foreach ($scope in $missing.Value) {
                Write-Verbose ("Org " + $missing.Key.name.en + " (" + $missing.Key.orgnr + ") missing access to " + $scope)
                $missingList += [PSCustomObject]@{ "Org" = $missing.Key.orgnr + " (" + $missing.Key.name.en + ")"; "Scope" = $scope }
            }
        }
        $missingList | Sort-Object -Property Org | Format-Table 
    }
}


if ($Report) {
    Generate-Full-Report 
}
elseif ($ShowMissing) {
    Show-Missing
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
elseif ($RemoveSingle) {
    if ($Org -eq "") {
        Write-Warning "Must supply -Org"
    }
    else {
       Remove-Single 
    }
}
elseif ($AddSingle) {
    if ($Org -eq "") {
        Write-Warning "Must supply -Org"
    }
    else {
       Add-Single 
    }
}
