@echo off
cd %~dp0
set MPEXE=%~dp0\src\MaskinportenTokenGenerator\bin\Debug\MaskinportenTokenGenerator.exe
if not exist %MPEXE% (
	echo %MPEXE% not found. Build it first.
	goto :eof
)

set server_mode=
set only_token=
if ["%~1"]==["servermode"] (
	set server_mode="--server_mode"
)
if ["%~1"]==["onlytoken"] (
	set only_token="--only_token"
)

if exist config.local.cmd (
	call config.local.cmd
) else (
	call config.cmd
)

set certificate_thumbprint=%production_certificate_thumbprint%
set client_id=%production_client_id%
set resource=%production_resource%
set default_scopes=%production_scopes%
set audience=https://oidc.difi.no/idporten-oidc-provider/
set token_endpoint=https://oidc.difi.no/idporten-oidc-provider/token

if ["%~2"]==["ver2"] (
	set certificate_thumbprint=%test_certificate_thumbprint%
	set client_id=%test_client_id%
	set resource=%test_resource%
	set default_scopes=%test_scopes%
	set audience=https://oidc-ver2.difi.no/idporten-oidc-provider/
	set token_endpoint=https://oidc-ver2.difi.no/idporten-oidc-provider/token
)

powershell -Command Get-ChildItem Cert:\LocalMachine\My\%certificate_thumbprint% >NUL
if errorlevel 1 (
 	echo Certificate with thumbprint '%certificate_thumbprint%' was not found. Make sure it is installed in the 'LocalMachine\My' store
 	exit /b 1
)

set scopes=%~3
if ["%~3"]==[""] (
	set scopes=%default_scopes%
)

%MPEXE% --certificate_thumbprint=%certificate_thumbprint% --client_id=%client_id% --audience=%audience% --resource=%resource% --token_endpoint=%token_endpoint% --scopes=%scopes% %server_mode% --server_port=17823 %only_token%
