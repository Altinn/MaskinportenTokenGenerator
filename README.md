# MaskinportenTokenGenerator

This is a utilty for helping out with generating access_tokens from Maskinporten, supporting integration with Postman for automating retrieval of access_tokens via a local web server.

## Requirements
* A recent Windows and Visual Studio 2017 or newer for building
* A enterprise certificate owned installed owned by the organization that has been given access to one or more scopes in machineporten
* A client id for an integration in Maskinporten provisioned with one or more scopes

## Building
Open a Visual Studio 2017 or newer commandline environment, and run `msbuild` in the `src`-directory, or open the solution file and build within Visual Studio.

## Usage
1. Make sure the Maskinporten public certificates are installed in local machine keystore. The Powershell-script `download_and_install_maskinporten_certs.ps1` can be used for this. 
2. Set up `config.cmd` and configure the production and/or VER2-settings (optional: copy config.cmd to `config.local.cmd` which is in .gitignore and takes precendence over `config.cmd`)
3. Run either of the following utility scripts:
	* `get_${env}_token` Gets a access_token and places it on the clipboard (for easy pasting in Postman etc)
	* `start_${env}_token_server` Starts a simple HTTP-server listening on all interfaces on port 17823 by default. Any GET-request to `http://localhost:17823` will attempt to fetch a access_token from Maskinporten and proxy the response.

## Postman integration
By using the token server, you can add a "Pre-request script" in Postman, with somelike the following:

    pm.sendRequest("http://localhost:17823/", function (err, response) {
	    var json = response.json();
	    if (typeof json.access_token !== "undefined") {
	        pm.environment.set("BearerToken", json.access_token);
	    }
	    else {
	        console.error("Failed getting token", json);
	    }
    });

Here "BearerToken" is an environment variable, which can be put in the "Token"-field in the "Authorization"-tab when type is set to "Bearer Token".

## License
MIT
