class_name HTTPMiddleware
extends RefCounted

## Base class for HTTP middleware.
## Override `process_request` to inspect, validate, or modify incoming requests.
## Override `process_response` to modify outgoing responses.
##
## - `process_request` returns `null` to continue the chain, or an HTTPResponse to abort.
## - `process_response` receives the response and returns the (possibly modified) response.

## Called for each incoming request before routing.
## Return `null` to continue, or an HTTPResponse to abort and send immediately.
func process_request(_request: HTTPMessage) -> Variant:
	return null


## Called for each outgoing response after routing.
## Return the (possibly modified) response.
func process_response(_request: HTTPMessage, response: HTTPResponse) -> HTTPResponse:
	return response