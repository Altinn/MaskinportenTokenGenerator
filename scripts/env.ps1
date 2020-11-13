$validenv = "test1", "ver1", "ver2", "prod"

if ($validenv -notcontains $env) {
    Write-Error ("Invalid env supplied. Valid environments: " + $validenv) 
    Exit 1
}

if ($env -eq "prod") {
    $envurl = "https://integrasjon.difi.no"
}
else {
    $envurl = "https://integrasjon-$env.difi.no"

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
        Write-Warning ("Server gave status code: " + $_.Exception.Response.StatusCode + " " + $_.Exception.Response.ReasonPhrase)
        Exit 1
    }

    return $result
}