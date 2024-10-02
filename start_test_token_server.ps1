if ($args.Length -gt 0) {
    & "$PSScriptRoot/maskinporten_token_generator.ps1" servermode test $args[0]
} else {
    & "$PSScriptRoot/maskinporten_token_generator.ps1" servermode test
}
