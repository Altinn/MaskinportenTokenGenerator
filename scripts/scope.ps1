# Script to administrate scopes defined in ID/Maskinporten
# Author: bdl@digdir.no
# -----------------------------------------------------------------------------------------------------------------
# NOTE! Requires a "scopes-admin.config.local.cmd" file present in same directory as script.
# -----------------------------------------------------------------------------------------------------------------
#
# Examples: 
# ./scope.ps1 get -prefix altinn
# ./scope.ps1 get -scope altinn:foo 
# ./scope.ps1 new -file definition.json
# ./scope.ps1 new -definition $definition
# ./scope.ps1 update -file definition.json
# ./scope.ps1 update -definition $definition
# ./scope.ps1 update -definition $definition
# ./scope.ps1 export-to-csv -prefix altin
# ./scope.ps1 import-from-csv -file somefile.csv
# ./scope.ps1 export-to-json -prefix altinn
# 
# Environment defaults to "VER2". Can be overridden by supplying a -env parameter containing "test1", "ver1", ver2" or "prod"
# 


param (
    [Parameter(Mandatory=$true)][string]$operator,
    [Parameter()][string]$scope,
    [Parameter()][string]$file,
    [Parameter()][string]$definition,
    [Parameter()][string]$prefix,
    [Parameter()][string]$env = "ver2"
)

. ($PSScriptRoot + "/config.ps1")
. ($PSScriptRoot + "/token.ps1")
. ($PSScriptRoot + "/env.ps1")

function Get-Scope {
    param($scope, $prefix)
    if ($scope -ne "") {
        $result = Invoke-API -Verb GET -Path "/scopes?scope=$scope"
    }
    else {
        $result = Invoke-API -Verb GET -Path "/scopes"
    }

    if ($null -eq $result) {
        Write-Output "No scope found"
    }
    elseif ($prefix -ne "") {
        $result | Where-Object { $_.prefix -eq $prefix }
    }
    else {
        $result
    }
}

function New-Scope-From-File {
    param($file)
    if (!(Test-Path $file)) {
        Write-Error "$file not found"
        Exit 1
    }
    $JsonBody = Get-Content $file 
    Write-Verbose($JsonBody | ConvertFrom-Json | Format-List | Out-String)
    Invoke-API -Verb POST -Path "/scopes" -Body $JsonBody
}

function New-Scope-From-Definition {
    param($definition)
    $JsonBody = $definition | ConvertTo-Json
    Write-Verbose($JsonBody | ConvertFrom-Json | Format-List | Out-String)
    Invoke-API -Verb POST -Path "/scopes" -Body $JsonBody
}

function Update-Scope-From-File {
    param($file)
    if (!(Test-Path $file)) {
        Write-Error "$file not found"
        Exit 1
    }
    $JsonBody = Get-Content $file 
    $scope = ($JsonBody | ConvertFrom-Json).name
    Write-Verbose($JsonBody | ConvertFrom-Json | Format-List | Out-String)
    $result = Invoke-API -Verb PUT -Path "/scopes?scope=$scope" -Body $JsonBody
    if ($null -ne $result.name) {
        Write-Output ("Updated " + $result.name)
    }
    else {
        Write-Warning "Failed updating from file: $file"
    }
}

function Update-Scope-From-Definition {
    param($definition)
    $scope = $definition.name
    $JsonBody = $definition | ConvertTo-Json
    Write-Verbose($JsonBody | ConvertFrom-Json | Format-List | Out-String)
    $result = Invoke-API -Verb PUT -Path "/scopes?scope=$scope" -Body $JsonBody
    if ($null -ne $result.name) {
        Write-Output ("Updated " + $result.name)
    }
    else {
        Write-Warning "Failed updating from definition:"
        $definition
    }
}

function Export-To-JSONs {
    param($prefix)
    $scopes = Get-Scope "" $prefix
    Convert-Scopes-To-Json-Files $scopes "exported"
}

function Convert-Scopes-To-Json-Files {
    param($scopes, $dir)
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $scopes | Select-Object -Property * -ExcludeProperty created,last_updated | ForEach-Object {
        $fullpath = "$dir/scopes/$($_.prefix)/$($_.subscope).json"; 
        $parts = $fullpath.Split("/"); 
        $path = $parts | Select-Object -skiplast 1; 
        $path = $path -join "/"

        New-Item -Name $path -ItemType "directory" -ErrorAction Ignore | Out-Null
        
        Write-Verbose "Exporting to $fullpath ..."

        $_ | ConvertTo-Json | Out-File -FilePath $fullpath
    }
}

function Export-To-CSV {
    param($prefix);
    $scopes = Get-Scope "" $prefix
    if (!(Test-Path "exported")) {
        New-Item -ItemType Directory -Force -Path "exported" | Out-Null
    }
    $filename = "exported/export-"
    if ($prefix -ne "") {
        $filename += $prefix + "-"
    }
    $filename += (Get-Date -Format "yyyy-MM-dd_HHmmss") + ".csv"
    $scopes = ProcessToCsv $scopes
    $scopes | Select-Object -Property * -ExcludeProperty created,last_updated | Export-Csv -Path .\$filename -NoTypeInformation -Encoding unicode
    Write-Output "Exported to $filename."
}

function Import-From-CSV {
    param($file)
    $scopes = Get-Content -Raw $file | ConvertFrom-Csv 
    $scopes = ProcessFromCsv $scopes
    Convert-Scopes-To-Json-Files $scopes "imported"
}

function ProcessToCsv {
    param($scopes)
    $newscopes = [System.Collections.ArrayList]::new(); 
    $scopes | ForEach-Object { 
        # We cannot handle arrays in CSV
        $_.allowed_integration_types = [system.String]::Join(",", $_.allowed_integration_types); 

        # delegation_source might be omitted, always include even if not supplied
        if (!("delegation_source" -in $_.PSobject.Properties.Name)) {
            $_ | Add-Member -NotePropertyName "delegation_source" -NotePropertyValue ""
        }

        [void]$newscopes.Add($_); 
    }
    $newscopes
}

# This effectively does the reverse of ProcessToCsv
function ProcessFromCsv {
    param($scopes)
    $newscopes = [System.Collections.ArrayList]::new(); 
    $scopes | ForEach-Object { 
        # Convert from comma separated list to array
        $_.allowed_integration_types = $_.allowed_integration_types.Split(",");

        # Drop delegation_schemes without value
        if ($_.delegation_source -eq "") {
            $_ = $_ | Select-Object -Property * -ExcludeProperty delegation_source
        }

        [void]$newscopes.Add($_); 
    }
    $newscopes
}

#####################################################

if ($operator -eq 'get') {
    Get-Scope $scope $prefix
}
elseif ($operator -eq 'export-to-json') {
    Export-To-JSONs $prefix
}
elseif ($operator -eq 'export-to-csv') {
    Export-To-CSV $prefix
}
elseif ($operator -eq 'import-from-csv') {
    Import-From-CSV $file
}
elseif ($operator -eq 'new') {
    if ($file -ne $null) {
        New-Scope-From-File $file
    }
    elseif ($definition -ne $null) {
        New-Scope-From-Definition $definition
    }
}
elseif ($operator -eq 'update') {
    if ($file -ne $null) {
        Update-Scope-From-File $file
    }
    elseif ($definition -ne $null) {
        Update-Scope-From-Definition $definition
    }
}