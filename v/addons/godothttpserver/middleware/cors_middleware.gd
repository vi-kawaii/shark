class_name CORSMiddleware
extends HTTPMiddleware

## Configurable CORS middleware.
## By default, allows all origins. Configure `allowed_origins` to restrict.

var allowed_origins: Array[String] = ["*"]
var allowed_methods: Array[String] = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
var allowed_headers: Array[String] = ["Content-Type", "Authorization"]
var allow_credentials: bool = false
var max_age: int = 86400


func _init(p_allowed_origins: Array[String] = ["*"]) -> void:
	allowed_origins = p_allowed_origins


func process_request(request: HTTPMessage) -> Variant:
	# Handle CORS preflight requests
	if request.method == "OPTIONS" and request.has_header("origin"):
		var response := HTTPResponse.no_content()
		_apply_cors_headers(response, request.header("origin"))
		response.set_header("Access-Control-Max-Age", str(max_age))
		response.set_header("Access-Control-Allow-Methods", ",".join(allowed_methods))
		response.set_header("Access-Control-Allow-Headers", ",".join(allowed_headers))
		return response
	return null


func process_response(request: HTTPMessage, response: HTTPResponse) -> HTTPResponse:
	var origin := request.header("origin")
	if origin.is_empty():
		return response
	_apply_cors_headers(response, origin)
	return response


func _apply_cors_headers(response: HTTPResponse, origin: String) -> void:
	var is_allowed := ("*" in allowed_origins) or (origin in allowed_origins)
	if not is_allowed:
		return

	# When credentials are involved we must echo the concrete origin, never `*`,
	# and emit the Access-Control-Allow-Credentials header.
	if allow_credentials:
		response.set_header("Access-Control-Allow-Origin", origin)
		response.set_header("Access-Control-Allow-Credentials", "true")
	elif "*" in allowed_origins:
		response.set_header("Access-Control-Allow-Origin", "*")
	else:
		response.set_header("Access-Control-Allow-Origin", origin)