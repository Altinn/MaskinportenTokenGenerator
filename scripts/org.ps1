param (
    [Parameter(Mandatory=$true)][string]$orgno
)

try {
    $unit = Invoke-RestMethod -Uri ("https://data.brreg.no/enhetsregisteret/api/enheter/" + $orgno)
}
catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        try {
            $unit = Invoke-RestMethod -Uri ("https://data.brreg.no/enhetsregisteret/api/underenheter/" + $orgno)            
        }
        catch {
            Write-Warning ("Server gave status code: " + $_.Exception.Response.StatusCode + " " + $_.Exception.Response.ReasonPhrase)
            Exit 1
        }
    }
    else {
        Write-Warning ("Server gave status code: " + $_.Exception.Response.StatusCode + " " + $_.Exception.Response.ReasonPhrase)
        Exit 1
    }
}

$unit