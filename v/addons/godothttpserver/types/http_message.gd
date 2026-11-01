class_name HTTPMessage
extends RefCounted

var method: String = ""
var path: String = ""
var clean_path: String = ""
var query_string: String = ""
var http_version: String = "HTTP/1.1"
var headers: Dictionary = {} 
var body: PackedByteArray = PackedByteArray()
var query_params: Dictionary = {}
var client_ip: String = ""
var is_websocket_upgrade: bool = false

## Parsed request cookies. Populated by HTTPConnection or via `parse_cookies()`.
var cookies: Dictionary = {}

# Reference back to the connection to allow streaming chunks
var connection: RefCounted = null 

func body_as_string() -> String:
	return body.get_string_from_utf8()

func header(name: String) -> String:
	return headers.get(name.to_lower(), "")

func has_header(name: String) -> bool:
	return headers.has(name.to_lower())

func json() -> Variant:
	if body.is_empty(): return null
	var j := JSON.new()
	if j.parse(body_as_string()) != OK: return null
	return j.data

## Parses the Cookie request header into `cookies`. Call after headers are set.
func parse_cookies() -> void:
	cookies.clear()
	var raw := header("cookie")
	if raw.is_empty():
		return
	for segment in raw.split(";"):
		var pair := segment.split("=", true, 1)
		var key := pair[0].strip_edges()
		if key.is_empty():
			continue
		cookies[key] = pair[1].strip_edges() if pair.size() > 1 else ""

## Returns the value of a request cookie, or an empty string when absent.
func get_cookie(name: String) -> String:
	return cookies.get(name, "")

## Parses an application/x-www-form-urlencoded body into a Dictionary.
## Multiple values for the same key become an Array.
func parse_form() -> Dictionary:
	var ct := header("content-type")
	if not ct.contains("application/x-www-form-urlencoded"):
		return {}
	return _parse_urlencoded(body_as_string())

## Parses urlencoded text into a Dictionary, decoding percent-encoding and `+` to space.
static func _parse_urlencoded(text: String) -> Dictionary:
	var result := {}
	if text.is_empty():
		return result
	for pair in text.split("&"):
		var kv := pair.split("=", true, 1)
		var key := kv[0].replace("+", " ").uri_decode()
		var value := kv[1].replace("+", " ").uri_decode() if kv.size() > 1 else ""
		if result.has(key):
			if result[key] is Array:
				result[key].append(value)
			else:
				result[key] = [result[key], value]
		else:
			result[key] = value
	return result

## Parses multipart/form-data into a Dictionary. 
## Returns { "field_name": { "filename": "x.png", "content_type": "...", "data": PackedByteArray } }
func parse_multipart() -> Dictionary:
	var result := {}
	var ct := header("content-type")
	if not ct.begins_with("multipart/form-data"): return result
	
	var b_idx := ct.find("boundary=")
	if b_idx == -1: return result
	var boundary_str := "--" + ct.substr(b_idx + 9).strip_edges()
	var boundary := boundary_str.to_utf8_buffer()
	
	var pos := 0
	while pos < body.size():
		var part_start := _find_subarray(body, boundary, pos)
		if part_start == -1: break
		part_start += boundary.size() + 2 # Skip \r\n
		
		var next_boundary := _find_subarray(body, boundary, part_start)
		if next_boundary == -1: break
		
		var part_data := body.slice(part_start, next_boundary - 2) # Exclude trailing \r\n
		pos = next_boundary
		
		var header_end := _find_subarray(part_data, "\r\n\r\n".to_utf8_buffer(), 0)
		if header_end == -1: continue
		
		var head_text := part_data.slice(0, header_end).get_string_from_utf8()
		var part_body := part_data.slice(header_end + 4)
		
		var disp_idx := head_text.find("name=\"")
		if disp_idx == -1: continue
		var name_end := head_text.find("\"", disp_idx + 6)
		var field_name := head_text.substr(disp_idx + 6, name_end - (disp_idx + 6))
		
		var filename := ""
		var fn_idx := head_text.find("filename=\"")
		if fn_idx != -1:
			var fn_end := head_text.find("\"", fn_idx + 10)
			filename = head_text.substr(fn_idx + 10, fn_end - (fn_idx + 10))

		result[field_name] = { "filename": filename, "data": part_body }
	return result

func _find_subarray(arr: PackedByteArray, sub: PackedByteArray, start: int) -> int:
	if sub.size() == 0 or arr.size() < sub.size(): return -1
	for i in range(start, arr.size() - sub.size() + 1):
		var match_found := true
		for j in range(sub.size()):
			if arr[i + j] != sub[j]:
				match_found = false
				break
		if match_found: return i
	return -1
