class_name BearerAuthMiddleware
extends HTTPMiddleware

## HTTP Bearer token authentication middleware.
## Validates the Authorization: Bearer <token> header using a `verify_token`
## callable or a static list of accepted `tokens`.

var verify_token: Callable = Callable()
var tokens: Array = []
var unauthorized_body: String = "Unauthorized"


func _init(p_verify_token: Callable = Callable(), p_tokens: Array = []) -> void:
	verify_token = p_verify_token
	tokens = p_tokens


func process_request(request: HTTPMessage) -> Variant:
	var auth := request.header("authorization")
	if auth.begins_with("Bearer "):
		var token := auth.substr(7).strip_edges()
		if not _is_valid(token):
			return _unauthorized()
		request.set_meta("auth_token", token)
		return null
	if auth.begins_with("Basic "):
		# Allow the chain to keep going if Basic is configured elsewhere.
		return null
	return _unauthorized()


func _is_valid(token: String) -> bool:
	if verify_token.is_valid():
		return bool(verify_token.call(token))
	return token in tokens


func _unauthorized() -> HTTPResponse:
	return HTTPResponse.unauthorized(unauthorized_body).set_header("WWW-Authenticate", "Bearer")