class_name StaticFileServer
extends RefCounted

## Serves static files from a directory with MIME type detection, ETag/Last-Modified
## caching, byte-range support, and path traversal protection.

var root_dir: String = ""
var index_file: String = "index.html"
var cache_control: String = "public, max-age=3600"
## When true, a request for a directory path lists its contents if no index exists.
var enable_directory_listing: bool = false
## When true, large files are streamed in chunks instead of being read fully into memory.
var enable_streaming: bool = false
## Files at or above this size (bytes) are streamed when `enable_streaming` is true.
var stream_threshold_bytes: int = 2 * 1024 * 1024
## When true, an unknown non-file path serves index.html (SPA fallback).
var enable_spa_fallback: bool = false
## When true, serves a precompressed `.gz` sibling when the client accepts gzip.
var serve_precompressed: bool = true

const STREAM_CHUNK_SIZE := 65536

var _mime_types := {
	".html": "text/html",
	".htm": "text/html",
	".css": "text/css",
	".js": "application/javascript",
	".mjs": "application/javascript",
	".json": "application/json",
	".xml": "application/xml",
	".txt": "text/plain",
	".md": "text/markdown",
	".png": "image/png",
	".jpg": "image/jpeg",
	".jpeg": "image/jpeg",
	".gif": "image/gif",
	".svg": "image/svg+xml",
	".webp": "image/webp",
	".ico": "image/x-icon",
	".bmp": "image/bmp",
	".woff": "font/woff",
	".woff2": "font/woff2",
	".ttf": "font/ttf",
	".otf": "font/otf",
	".eot": "application/vnd.ms-fontobject",
	".mp3": "audio/mpeg",
	".wav": "audio/wav",
	".ogg": "audio/ogg",
	".mp4": "video/mp4",
	".webm": "video/webm",
	".zip": "application/zip",
	".gz": "application/gzip",
	".pdf": "application/pdf",
	".wasm": "application/wasm",
	".map": "application/json",
}


func _init(p_root_dir: String) -> void:
	root_dir = p_root_dir


## Handles a request. Returns an HTTPResponse or null if the file was not found.
func handle(request: HTTPMessage) -> HTTPResponse:
	if request.method != "GET" and request.method != "HEAD":
		return HTTPResponse.method_not_allowed()

	var relative_path := request.clean_path.trim_prefix("/")
	if relative_path.is_empty():
		relative_path = index_file
	if relative_path.contains("..") or relative_path.contains("\\"):
		return HTTPResponse.forbidden("Invalid path")

	var full_path := root_dir.path_join(relative_path)

	# Handle directory paths.
	if full_path.ends_with("/") or DirAccess.dir_exists_absolute(full_path):
		return _handle_directory(full_path, relative_path, request)

	if not FileAccess.file_exists(full_path):
		if enable_spa_fallback:
			var index_path := root_dir.path_join(index_file)
			if FileAccess.file_exists(index_path):
				return _serve_file(index_path, index_file.get_extension(), request, "/")
		return HTTPResponse.not_found("File not found")

	# Serve a precompressed .gz sibling when accepted by the client.
	if serve_precompressed and request.header("accept-encoding").to_lower().contains("gzip"):
		var gz_path := full_path + ".gz"
		if FileAccess.file_exists(gz_path):
			return _serve_file(gz_path, full_path.get_extension(), request, relative_path, true)

	return _serve_file(full_path, full_path.get_extension(), request, relative_path)


## Serves a single file with caching and range support.
## When `is_precompressed` is true the file is served whole with Content-Encoding: gzip.
func _serve_file(file_path: String, ext: String, request: HTTPMessage, relative_path: String, is_precompressed: bool = false) -> HTTPResponse:
	var file_length := _file_length(file_path)
	if file_length < 0:
		return HTTPResponse.not_found("File not found")

	var modified_time := int(FileAccess.get_modified_time(file_path))
	var etag := '"%x-%x"' % [modified_time, file_length]
	var content_type := _mime_types.get("." + ext.to_lower(), "application/octet-stream")

	# Conditional GET via ETag.
	if request.header("if-none-match") == etag:
		return HTTPResponse.new(304, "Not Modified").set_header("ETag", etag)

	# Conditional GET via If-Modified-Since (compare against the exact date we emit).
	var if_modified := request.header("if-modified-since")
	if not if_modified.is_empty() and if_modified == HTTPDate.format(modified_time):
		return HTTPResponse.new(304, "Not Modified").set_header("ETag", etag)

	var start_byte := 0
	var end_byte := file_length - 1
	var is_partial := false

	if not is_precompressed:
		var range_result: Variant = _parse_range(request.header("range"), file_length)
		if range_result is Array:
			start_byte = range_result[0]
			end_byte = range_result[1]
			is_partial = true
		elif range_result != null and int(range_result) == 416:
			return HTTPResponse.range_not_satisfiable().set_header("Content-Range", "bytes */%d" % file_length)

	var response := HTTPResponse.new(206 if is_partial else 200, "Partial Content" if is_partial else "OK")
	response.set_content_type(content_type)
	response.set_header("Cache-Control", cache_control)
	response.set_header("ETag", etag)
	response.set_header("Last-Modified", HTTPDate.format(modified_time))
	response.set_header("Accept-Ranges", "bytes")
	if is_partial:
		response.set_header("Content-Range", "bytes %d-%d/%d" % [start_byte, end_byte, file_length])
	if is_precompressed:
		response.set_header("Content-Encoding", "gzip")
		response.set_header("Vary", "Accept-Encoding")

	# Stream large files in chunks instead of loading them fully into memory.
	var conn: HTTPConnection = request.connection
	if enable_streaming and not is_precompressed and file_length >= stream_threshold_bytes and conn != null:
		response.is_chunked = true
		response.set_body_stream(_make_stream_callback(file_path, start_byte, end_byte))

	# Read the requested range into memory (used when not streamed).
	if not response.is_chunked:
		var file := FileAccess.open(file_path, FileAccess.READ)
		file.seek(start_byte)
		var chunk_size := (end_byte - start_byte) + 1
		response.set_body_bytes(file.get_buffer(chunk_size))
		file.close()

	return response


## Builds a callback that streams the file range using chunked encoding.
func _make_stream_callback(file_path: String, start_byte: int, end_byte: int) -> Callable:
	return func(stream_conn: HTTPConnection) -> void:
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			stream_conn.finish_chunked_response()
			return
		file.seek(start_byte)
		var pos := start_byte
		while pos <= end_byte:
			var remaining := end_byte - pos + 1
			var take := min(STREAM_CHUNK_SIZE, remaining)
			var chunk := file.get_buffer(take)
			if chunk.is_empty():
				break
			stream_conn.send_chunk(chunk)
			pos += chunk.size()
		file.close()
		stream_conn.finish_chunked_response()
## Returns the size of a file on disk, or -1 if it cannot be opened for reading.
## The file handle is always closed.
func _file_length(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var length := file.get_length()
	file.close()
	return length


## Parses an HTTP Range header.
## Returns null when there is no range, an [int start, int end] array for a
## satisfiable range, or the integer 416 when the range cannot be satisfied.
func _parse_range(range_hdr: String, file_length: int) -> Variant:
	if not range_hdr.begins_with("bytes="):
		return null
	var spec := range_hdr.substr(6).split(",")[0].split("-")
	if spec.size() != 2:
		return null

	var start_str := spec[0].strip_edges()
	var end_str := spec[1].strip_edges()

	# Suffix range: bytes=-N  -> last N bytes.
	if start_str.is_empty():
		if not end_str.is_valid_int() or int(end_str) <= 0:
			return 416
		var suffix := int(end_str)
		return [maxi(file_length - suffix, 0), file_length - 1]

	if not start_str.is_valid_int():
		return 416
	var start_byte := int(start_str)

	# Open-ended range: bytes=N-
	if end_str.is_empty():
		if start_byte >= file_length:
			return 416
		return [start_byte, file_length - 1]

	if not end_str.is_valid_int():
		return 416
	var end_byte := int(end_str)
	if start_byte > end_byte or start_byte >= file_length:
		return 416

	return [start_byte, mini(end_byte, file_length - 1)]


## Serves the index file for a directory, lists its contents, or denies access.
func _handle_directory(full_path: String, relative_path: String, request: HTTPMessage) -> HTTPResponse:
	var index_path := full_path.path_join(index_file)
	if FileAccess.file_exists(index_path):
		return _serve_file(index_path, index_file.get_extension(), request, relative_path)

	if enable_directory_listing:
		return _list_directory(full_path, relative_path)

	return HTTPResponse.forbidden("Directory access denied")


## Builds a simple HTML index for a directory.
func _list_directory(dir_path: String, relative_path: String) -> HTTPResponse:
	var dir := DirAccess.open(dir_path)
	var title := "Index of /%s" % relative_path
	var html := "<!doctype html><html><head><meta charset=\"utf-8\"><title>%s</title></head><body><h1>%s</h1><ul>" % [title, title]

	if not relative_path.is_empty():
		html += "<li><a href=\"../\">../</a></li>"

	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if item == "." or item == "..":
			item = dir.get_next()
			continue
		var is_dir := dir.current_is_dir()
		var display := item + ("/" if is_dir else "")
		var href := "/"
		href += (relative_path.path_join(item) if not relative_path.is_empty() else item)
		if is_dir:
			href += "/"
		html += "<li><a href=\"%s\">%s</a></li>" % [href, display]
		item = dir.get_next()
	dir.list_dir_end()

	html += "</ul></body></html>"
	var resp := HTTPResponse.new(200, "OK")
	resp.set_body(html)
	resp.set_content_type("text/html")
	resp.set_header("Cache-Control", cache_control)
	return resp
