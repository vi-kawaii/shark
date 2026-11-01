class_name RequestIdMiddleware
extends HTTPMiddleware

## Adds an X-Request-Id to each request, generating one when the client omitted it.
## The id is stored in request metadata as "request_id" and echoed on the response.

var header_name: String = "X-Request-Id"
var generate_when_missing: bool = true


func process_request(request: HTTPMessage) -> Variant:
	var id := request.header(header_name).strip_edges()
	if id.is_empty() and generate_when_missing:
		id = _new_id()
	request.set_meta("request_id", id)
	if id.is_empty():
		return null
	if not request.headers.has(header_name.to_lower()):
		request.headers[header_name.to_lower()] = id
	return null


func process_response(request: HTTPMessage, response: HTTPResponse) -> HTTPResponse:
	var id := str(request.get_meta("request_id", ""))
	if not id.is_empty():
		response.set_header(header_name, id)
	return response


func _new_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()