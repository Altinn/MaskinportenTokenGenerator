
function IsTokenCacheExpired {
    param($TokenCache)
    $token = Get-Content -Path $token_cache
    $parts = $token.Split(".")
    $parts[1] = $parts[1] + ('=' * ($parts[1].Length % 4))
    try {
        $payload = ConvertFrom-JSON([Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($parts[1])))
    }
    catch {
        return $True
    }
    $date = Get-Date "1/1/1970"
    $validto = $date.AddSeconds($payload.exp).ToLocalTime()
    if ($validto -lt (Get-Date)) {
        Write-Verbose "Token stale, expired at $validto"
        return $true
    }
    Write-Verbose "Token fresh, expires $validto"
    return $false
}

function Get-Token {

    if (!(Test-Path $CONFIG["TokenGenerator"])) {
        Write-Warning ($CONFIG["TokenGenerator"] + " not found, please check config.ps1")
        Exit 1
    }

    $tgconfig = $PSScriptRoot + "/scopes-admin.config.local.ps1";
    if (!(Test-Path $tgconfig)) {
        Write-Warning "$tgconfig not found. Copy it from scopes-admin.config.ps1"
        Exit 1
    }

    $token_cache = "./token.$env.cache"

    if ($CONFIG["AlwaysRefresh"] -eq $True -or !(Test-Path($token_cache)) -or (IsTokenCacheExpired($token_cache))) {
        $cmd =  $CONFIG["TokenGenerator"] + " onlytoken " + $env + " " + $tgconfig
        Write-Verbose "Running: $cmd"
        & pwsh -Command $cmd *> $token_cache
    }
    
    $token = Get-Content -Path $token_cache

    if ($null -eq $token) {
        Write-Error "Did not get token"
        Remove-Item $token_cache -ErrorAction Ignore
        Exit 1
    }

    return $token
}
