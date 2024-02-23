if ($args.Length -gt 0) {
    & "$PSScriptRoot/maskinporten_token_generator.ps1" single prod $args[0]
} else {
    & "$PSScriptRoot/maskinporten_token_generator.ps1" single prod
}
