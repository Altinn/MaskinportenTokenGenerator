# MaskinportenPortenTokenGenerator - scopes administration scripts

This directory contains scripts that can be useful for performing/automating various administrative tasks related to ID/Maskinporten.

> Warning! This is a tool with sharp edges, capable of messing up your Maskinporten scope and access setup.
> Use with extreme care!

## Setup

Copy `scopes-admin-config.cmd` to `scopes-admin-config.local.cmd` and fill in credentials for a Maskinporten- client with `idporten:scopes.write` scope.

## Administrating scopes

See `scope.ps1` for usage examples. Typical flow is:

1. Export all scopes definitions from Maskinporten to CSV, eg.:
   `./scope.ps1 export-to-csv -prefix altinn -Env ver2`

2. Edit the CSV to your liking:

    A very useful extension here is https://marketplace.visualstudio.com/items?itemName=janisdd.vscode-edit-csv, which lets you edit the CSV list of scopes visually.

3. Convert CSV to JSON, eg.
   `./scope.ps1 import-from-csv -file somefile.csv`

4. Apply the files you want, eg.

    `./scope.ps1 update -File .\exported\scopes\altinn\<path to scope definition>.json`

    You can use the following script to update all scopes. Use with extreme care!

    `Get-ChildItem -Recurse -Path .\imported\scopes\altinn\ -File -Filter *.json | Foreach-Object { Write-Host ".\scope.ps1 update -File" $_.FullName }`

## Administrating scope access

See `scopeaccess.ps1` for usage examples. 

## Administrating service owner access

See `so-admin.ps1`.

Used for easily granting all `altinn/serviceowner/*` scopes to all service owners as defined in serviceowners.json.

## Troubleshooting

Most commands takes a `-Verbose` flag which prints additional information. In case of errors with authentication, see `token.${env}.cache` files. These can be deleted to force a new token retrieval.