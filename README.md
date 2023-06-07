# MaskinportenTokenGenerator

This is a utilty for helping out with generating access_tokens from ID/Maskinporten, supporting integration with Postman for automating retrieval of access_tokens via a local web server.

## Requirements
* A recent Windows and Visual Studio 2017 or newer for building
* Either
	* A enterprise certificate owned installed owned by the organization that has been given access to one or more scopes in machineporten
	* A JSON file containing a JWK. Used if the client has been configured with a pre-configured key. See https://mkjwk.org/ for examples on how to construct JWKs. NOTE! As of now only RS256 algorithm is supported.
	* A password-protected PKCS#12 file containing the public/private key pair. Can also be used if the client has been configured with a pre-configured key.	
* A client id for an integration in Maskinporten provisioned with one or more scopes

## Building
Open a Visual Studio 2017 or newer commandline environment, and run `msbuild` in the `src`-directory, or open the solution file and build within Visual Studio.

## Usage
1. Copy `config.cmd` to `config.local.cmd` and configure the production and/or TEST-settings 
2. Run either of the following utility scripts:
	* `get_${env}_token` Gets a access_token and places it on the clipboard (for easy pasting in Postman etc)
	* `start_${env}_token_server` Starts a simple HTTP-server listening on all interfaces on port 17823 by default. Any GET-request to `http://localhost:17823` will attempt to fetch a access_token from Maskinporten and proxy the response.

You can keep multiple configuration files for various settings, and can pass those as a single parameter to the scripts, like `start_test_token_server config.local.my-custom-config.cmd` 

This can also be done by dragging and dropping the custom config-file over the script you want to run.

## Postman integration
By using the token server, you can add a "Pre-request script" in Postman, with somelike the following:

    /* Adding "?cache=true" returns the same token as long as it is valid (ie. does not request a new token from Maskinporten) */
    pm.sendRequest("http://localhost:17823/?cache=true", function (err, response) {
	    var json = response.json();
	    if (typeof json.access_token !== "undefined") {
	        pm.environment.set("BearerToken", json.access_token);
	    }
	    else {
	        console.error("Failed getting token", json);
	    }
    });

Here "BearerToken" is an environment variable, which can be put in the "Token"-field in the "Authorization"-tab when type is set to "Bearer Token".

*If you are testing MaskinportenAPI, see https://github.com/Altinn/MaskinportenApiPostman for a pre-configured Postman collection*

## License
MIT

## Changelog (since Sep. 2020)
* 2023-06-07: Set new "test" environment as default replacing "ver2". 
* 2022-07-21: Add support for supplying a JWK-file instead of PKCS#12 for self-generated keys
* 2020-11-13: Bugfixes and refactorings
* 2020-10-16: Added support for [supplier integrations](https://difi.github.io/felleslosninger/maskinporten_guide_apikonsument.html#bruke-delegering-som-leverand%C3%B8r) for delegated Maskinporten scopes
* 2020-09-15: Added preliminary support for ID-porten personal login / authcode flow
* 2020-09-15: Added scripts for managing scope access
