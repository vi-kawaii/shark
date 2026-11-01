class_name BasicAuthMiddleware
extends HTTPMiddleware

## HTTP Basic authentication middleware.
## Validates the Authorization: Basic header. Configure either a `validator`
## callable `(username, password) -> bool` or a static `credentials` dictionary.

var realm: String = "Protected Area"
## Callable(username, password) -> bool, or -> HTTPResponse for a custom rejection.
var validator: Callable = Callable()
## Optional static credential map: { "user": "pass" }.
var credentials: Dictionary = {}
var unauthorized_body: String = "Unauthorized"


func _init(p_realm: String = "Protected Area", p_validator: Callable = Callable()) -> void:
	realm = p_realm
	validator = p_validator


func process_request(request: HTTPMessage) -> Variant:
	var auth := request.header("authorization")
	if not auth.begins_with("Basic "):
		return _unauthorized()

	var decoded := Marshalls.base64_to_raw(auth.substr(6))
	if decoded.size() == 0:
		return _unauthorized()

	var decoded_str := decoded.get_string_from_utf8()
	var sep := decoded_str.find(":")
	if sep == -1:
		return _unauthorized()

	var username := decoded_str.substr(0, sep)
	var password := decoded_str.substr(sep + 1)

	var result: Variant = _validate(username, password)
	if result is HTTPResponse:
		return result
	if not bool(result):
		return _unauthorized()
	return null


func _validate(username: String, password: String) -> Variant:
	if validator.is_valid():
		return validator.call(username, password)
	if credentials.is_empty():
		return false
	return credentials.get(username, "") == password


func _unauthorized() -> HTTPResponse:
	return HTTPResponse.unauthorized(unauthorized_body).set_header("WWW-Authenticate", "Basic realm=\"%s\"" % realm)