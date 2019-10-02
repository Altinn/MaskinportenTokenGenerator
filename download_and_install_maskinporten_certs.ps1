$header = "-----BEGIN CERTIFICATE-----`r`n"
$footer = "`r`n-----END CERTIFICATE-----`r`n"

Write-Host 
Read-Host -Prompt "Importing Difi Maskinporten public certificates to Cert:\LocalMachine\My. Press ENTER to continue or CTRL-C to cancel"

foreach ($env in @("oidc-ver2", "oidc")) {
    $url = "https://${env}.difi.no/idporten-oidc-provider/jwk"
    Write-Host "Fetching from $url ..."
    $jwk = Invoke-WebRequest -Uri $url | ConvertFrom-Json
    $cert = $jwk.keys[0].x5c[0];
    $file = New-TemporaryFile
    "${header}${cert}${footer}" | Set-Content $file.FullName
    $import = Import-Certificate -FilePath $file.FullName -CertStoreLocation Cert:\LocalMachine\My
    Remove-Item $file.FullName
    $thumbprint = $import.Thumbprint
    $subject = $import.Subject
    Write-Host "Imported thumbprint:${thumbprint} subject:${subject}"
    Write-Host
}

