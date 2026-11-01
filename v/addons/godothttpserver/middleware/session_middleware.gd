class_name SessionMiddleware
extends HTTPMiddleware

## In-memory session middleware backed by an HMAC-signed cookie.
## Sessions live on the server; the client only holds an opaque signed session id.

var cookie_name: String = "session"
var secret: String = "change-me"
var session_ttl: int = 3600
var cookie_path: String = "/"
var cookie_secure: bool = false
var cookie_http_only: bool = true
var cookie_same_site: String = "Lax"

var _sessions: Dictionary = {}  # id -> { "data": Dictionary, "expires": float }


func _init(p_secret: String = "change-me") -> void:
	secret = p_secret


func process_request(request: HTTPMessage) -> Variant:
	# Parse lazily so the middleware works even when the connection layer has not parsed cookies yet.
	if request.cookies.is_empty():
		request.parse_cookies()
	var raw := request.get_cookie(cookie_name)
	if raw.is_empty():
		return null

	var session_id := _decode_signed_id(raw)
	if session_id.is_empty():
		return null

	if not _sessions.has(session_id):
		return null

	var entry: Dictionary = _sessions[session_id]
	if Time.get_unix_time_from_system() > float(entry["expires"]):
		_sessions.erase(session_id)
		return null

	request.set_meta("session_id", session_id)
	request.set_meta("session", entry["data"] as Dictionary)
	return null


func process_response(request: HTTPMessage, response: HTTPResponse) -> HTTPResponse:
	if request.has_meta("pending_session_delete"):
		response.delete_cookie(cookie_name, cookie_path, "")
		return response
	if request.has_meta("pending_session_cookie"):
		var pc: Dictionary = request.get_meta("pending_session_cookie")
		response.set_cookie(pc["name"], pc["value"], cookie_path, session_ttl, "", cookie_secure, cookie_http_only, cookie_same_site)
	return response


## Returns the in-memory session data for a request (may be empty).
func get_session(request: HTTPMessage) -> Dictionary:
	if request.has_meta("session"):
		return request.get_meta("session")
	return {}


## Returns the stored session id for a request, or an empty string.
func get_session_id(request: HTTPMessage) -> String:
	return str(request.get_meta("session_id", ""))


## Replaces the session data and (re)issues the session cookie.
func set_session(request: HTTPMessage, data: Dictionary) -> void:
	var session_id := get_session_id(request)
	if session_id.is_empty():
		session_id = _new_id()
		request.set_meta("session_id", session_id)
	_sessions[session_id] = {"data": data, "expires": Time.get_unix_time_from_system() + session_ttl}
	request.set_meta("session", data)
	request.set_meta("pending_session_cookie", {"name": cookie_name, "value": _sign_id(session_id)})


## Clears the session server-side and expires the cookie on the client.
func destroy_session(request: HTTPMessage) -> void:
	var session_id := get_session_id(request)
	if not session_id.is_empty():
		_sessions.erase(session_id)
	request.remove_meta("session")
	request.remove_meta("session_id")
	request.remove_meta("pending_session_cookie")
	# The response middleware clears the cookie on the client.
	request.set_meta("pending_session_delete", true)


## Number of active sessions.
func session_count() -> int:
	return _sessions.size()


func _sign_id(session_id: String) -> String:
	var sig := _hmac(secret.to_utf8_buffer(), session_id.to_utf8_buffer())
	return session_id + "." + _b64url(sig)


func _decode_signed_id(raw: String) -> String:
	var parts := raw.split(".")
	if parts.size() != 2:
		return ""
	if _b64url(_hmac(secret.to_utf8_buffer(), parts[0].to_utf8_buffer())) != parts[1]:
		return ""
	return parts[0]


## Base64url (URL-safe, unpadded) so the value survives `set_cookie` encoding.
func _b64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").trim_suffix("=").trim_suffix("=")


func _hmac(key: PackedByteArray, data: PackedByteArray) -> PackedByteArray:
	var ctx := HMACContext.new()
	ctx.start(HashingContext.HASH_SHA256, key)
	ctx.update(data)
	return ctx.finish()


func _new_id() -> String:
	var bytes := Crypto.new().generate_random_bytes(24)
	return bytes.hex_encode()