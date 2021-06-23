This directory contains scripts that can be useful for performing/automating various administrative tasks related to ID/Maskinporten.

Typical flow:

1. Export all scopes from Maskinporten to CSV
   `./scope.ps1 export-to-csv -prefix altinn -Env ver2`

2. Edit CSV 
3. Convert CSV to JSON
   `./scope.ps1 import-from-csv -file somefile.csv`

4. Apply individual files, or all

# Get-ChildItem -Recurse -Path .\imported\scopes\altinn\ -File -Filter *.json | Foreach-Object { Write-Host ".\scope.ps1 update -File" $_.FullName }