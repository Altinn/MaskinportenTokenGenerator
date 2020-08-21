@echo off
if not ["%~1"]==[""] (
    call %~dp0\maskinporten_token_generator.cmd servermode test1 "%~1"
) else (
    call %~dp0\maskinporten_token_generator.cmd servermode test1
)