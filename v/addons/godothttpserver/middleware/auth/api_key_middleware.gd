class_name ApiKeyMiddleware
extends HTTPMiddleware

## API-key authentication middleware.
## Reads a key from a request header or query parameter and checks it against a
## list of valid keys. The accepted key is stored in request metadata.

var valid_keys: Array = []
var header_name: String = "X-API-Key"
var query_param: String = "api_key"
var meta_name: String = "api_key"
var unauthorized_body: String = "Invalid API key"


func _init(p_valid_keys: Array, p_header_name: String = "X-API-Key", p_query_param: String = "api_key") -> void:
	valid_keys = p_valid_keys
	header_name = p_header_name
	query_param = p_query_param


func process_request(request: HTTPMessage) -> Variant:
	var key := request.header(header_name)
	if key.is_empty():
		key = str(request.query_params.get(query_param, ""))

	if key.is_empty() or key not in valid_keys:
		return HTTPResponse.unauthorized(unauthorized_body)

	request.set_meta(meta_name, key)
	return null