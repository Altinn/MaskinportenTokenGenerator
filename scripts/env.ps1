$validenv = "prod", "test"

if ($validenv -notcontains $env) {
    Write-Error ("Invalid env supplied. Valid environments: " + $validenv) 
    Exit 1
}

if ($env -eq "prod") {
    $envurl = "https://integrasjon.difi.no"
}
else {
    if ($validenv -eq "test") {
        $envurl = "https://integrasjon-ver2.difi.no"    
    }
    else {
        $envurl = "https://integrasjon-$env.difi.no"
    }
}

#$envurl = "http://localhost:8000"

function Invoke-API {
    param($Verb, $Path, $Body)
    $access_token = Get-Token
    $url = $envUrl + $Path

    try {
        $headers = @{
            Accept = "application/json"
            Authorization = "Bearer $access_token"
        }
        $result = Invoke-RestMethod -Uri $url -Method $Verb -Headers $headers -Body $Body -ContentType "application/json; charset=utf-8"
    }
    catch {
        Write-Warning "Request $verb $url failed"
        #Write-Warning ("Server gave status code: " + $_.Exception.Response.StatusCode + " " + $_.Exception.Response.ReasonPhrase)
        $_ | Format-List -Property * | Out-String | Write-Warning
        Exit 1
    }

    return $result
}