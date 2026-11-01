class_name Jwt
extends RefCounted

## Minimal HMAC-SHA256 (HS256) JWT implementation built on Godot's HMACContext.
## Signing and verification are symmetric: both use the same `secret`.

## Builds and signs a JWT from a payload dictionary.
static func sign(payload: Dictionary, secret: String, algorithm: String = "HS256", header: Dictionary = {}) -> String:
	var h: Dictionary = {"alg": algorithm, "typ": "JWT"}
	h.merge(header, true)

	var header_enc := _b64url(JSON.stringify(h).to_utf8_buffer())
	var payload_enc := _b64url(JSON.stringify(payload).to_utf8_buffer())
	var signing_input := header_enc + "." + payload_enc

	var signature := _hmac_sha256(secret.to_utf8_buffer(), signing_input.to_utf8_buffer())
	return signing_input + "." + _b64url(signature)


## Verifies the HMAC signature of a token. Does not check token expiry.
static func verify(token: String, secret: String) -> bool:
	var parts := token.split(".")
	if parts.size() != 3:
		return false
	var signing_input := parts[0] + "." + parts[1]
	var expected := _b64url(_hmac_sha256(secret.to_utf8_buffer(), signing_input.to_utf8_buffer()))
	return _constant_time_equals(expected, parts[2])


## Decodes (without verifying) the header and payload of a token.
static func decode(token: String) -> Dictionary:
	var parts := token.split(".")
	if parts.size() != 3:
		return {}
	var header: Variant = JSON.parse_string(_b64_decode(parts[0]).get_string_from_utf8())
	var payload: Variant = JSON.parse_string(_b64_decode(parts[1]).get_string_from_utf8())
	return {"header": header, "payload": payload}


static func _hmac_sha256(key: PackedByteArray, data: PackedByteArray) -> PackedByteArray:
	var ctx := HMACContext.new()
	ctx.start(HashingContext.HASH_SHA256, key)
	ctx.update(data)
	return ctx.finish()


## Encodes bytes as base64url without padding.
static func _b64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").trim_suffix("=").trim_suffix("=")


## Decodes a base64url string (padding agnostic) back to bytes.
static func _b64_decode(text: String) -> PackedByteArray:
	var standard := text.replace("-", "+").replace("_", "/")
	while standard.length() % 4 != 0:
		standard += "="
	return Marshalls.base64_to_raw(standard)


## Compares two strings in constant time to reduce timing side channels.
static func _constant_time_equals(a: String, b: String) -> bool:
	if a.length() != b.length():
		return false
	var diff := 0
	for i in a.length():
		diff |= a.unicode_at(i) ^ b.unicode_at(i)
	return diff == 0