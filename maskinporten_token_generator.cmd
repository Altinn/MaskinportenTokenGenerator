@echo off >NUL
setlocal

cd %~dp0 >NUL
set MPEXE=%~dp0\src\MaskinportenTokenGenerator\bin\Debug\MaskinportenTokenGenerator.exe
if not exist %MPEXE% (
	echo %MPEXE% not found. Build it first.
	pause
	exit /b 1
)

set server_mode_opt=
set only_token_opt=
if ["%~1"]==["servermode"] (
	set server_mode_opt=--server_mode --server_port=17823
)

if ["%~1"]==["onlytoken"] (
	set only_token_opt="--only_token"
)


set local_config=
if ["%~3"]==[""] (
	set local_config=config.local.cmd
) else (
	if not exist "%~3" (
		echo Unable to load cusom config file: %~3
		pause
		exit /b 1
	)
	if ["%only_token_opt%"]==[""] (
		echo Using custom config file: %~3
	)
	set local_config=%~3
) 

call config.cmd
if exist "%local_config%" (
	call "%local_config%"
)

set certificate_thumbprint=
set keystore_path=
set keystore_password=
set kid=
set client_id=
set resource=
set scopes=
set audience=
set token_endpoint=
set authorize_endpoint=
set person_mode=
set consumer_org=

if ["%~2"]==["test1"] (

	if "%dev_client_id%"=="" (
		echo Missing configuration for TEST1/DEV environment. Check the configuration, and make sure that any config.local.cmd is up-to-date with fields defined in config.cmd
		pause
		exit /b 1
	)

	set certificate_thumbprint=%dev_certificate_thumbprint%
	set keystore_path=%dev_keystore_path%
	set keystore_password=%dev_keystore_password%
	set kid=%dev_kid%
	set client_id=%dev_client_id%
	set resource=%dev_resource%
	set scopes=%dev_scopes%
	set audience=%dev_audience%
	set token_endpoint=%dev_token_endpoint%
	set authorize_endpoint=%dev_authorize_endpoint%
	set person_mode=%dev_person_mode%
	set consumer_org=%dev_consumer_org%
)

if ["%~2"]==["ver2"] (

	if "%test_client_id%"=="" (
		echo Missing configuration for VER2/ATxx/TT02 environment. Check the configuration, and make sure that any config.local.cmd is up-to-date with fields defined in config.cmd
		pause
		exit /b 1
	)

	set certificate_thumbprint=%test_certificate_thumbprint%
	set keystore_path=%test_keystore_path%
	set keystore_password=%test_keystore_password%
	set kid=%test_kid%
	set client_id=%test_client_id%
	set resource=%test_resource%
	set scopes=%test_scopes%
	set audience=%test_audience%
	set token_endpoint=%test_token_endpoint%
	set authorize_endpoint=%test_authorize_endpoint%
	set person_mode=%test_person_mode%
	set consumer_org=%test_consumer_org%
)

if ["%~2"]==["prod"] (
	if "%production_client_id%"=="" (
		echo Missing configuration for PROD environment. Check the configuration, and make sure that any config.local.cmd is up-to-date with fields defined in config.cmd
		pause
		exit /b 1
	)

	set certificate_thumbprint=%production_certificate_thumbprint%
	set keystore_path=%production_keystore_path%
	set keystore_password=%production_keystore_password%
	set kid=%production_kid%
	set client_id=%production_client_id%
	set resource=%production_resource%
	set scopes=%production_scopes%
	set audience=%production_audience%
	set token_endpoint=%production_token_endpoint%
	set authorize_endpoint=%production_authorize_endpoint%
	set person_mode=%production_person_mode%
	set consumer_org=%prod_consumer_org%
)

set resource_opt=
if not ["%resource%"]==[""] (
	set resource_opt=--resource=%resource%
)

set certificate_thumbprint_opt=
if not ["%certificate_thumbprint%"]==[""] (
	set certificate_thumbprint_opt=--certificate_thumbprint=%certificate_thumbprint%
)

set keystore_opt=
if not ["%keystore_path%"]==[""] (
	set keystore_opt=--keystore_path=%keystore_path% --keystore_password=%keystore_password%
)

set kid_opt=
if not ["%kid%"]==[""] (
	set kid_opt=--kid=%kid%	
)

set person_mode_opt=
if not ["%person_mode%"]==[""] (
	set person_mode_opt=--person_mode=%person_mode%
)

set consumer_org_opt=
if not ["%consumer_org%"]==[""] (
	set consumer_org_opt=--consumer_org=%consumer_org%
)

set cmd=%MPEXE% --client_id=%client_id% --audience=%audience% --token_endpoint=%token_endpoint% --authorize_endpoint=%authorize_endpoint% --scopes=%scopes% %only_token_opt% %person_mode_opt% %server_mode_opt% %resource_opt% %certificate_thumbprint_opt% %keystore_opt% %kid_opt% %consumer_org_opt%
if ["%only_token_opt%"]==[""] (
	echo -------------------------------
	echo %cmd%
	echo -------------------------------
)
%cmd%
