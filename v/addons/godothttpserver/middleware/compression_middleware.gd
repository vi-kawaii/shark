class_name CompressionMiddleware
extends HTTPMiddleware

## Compresses outgoing HTTP responses using GZIP.
## Automatically strips Godot's proprietary 4-byte header size prefix.

var min_size_bytes: int = 1024

func process_response(request: HTTPMessage, response: HTTPResponse) -> HTTPResponse:
	# Don't compress tiny payloads or already encoded/chunked data
	if response.body.size() < min_size_bytes or response.is_chunked:
		return response
	if response.headers.has("Content-Encoding"):
		return response
		
	var accept_enc := request.header("accept-encoding")
	if accept_enc.contains("gzip"):
		var compressed := response.body.compress(FileAccess.COMPRESSION_GZIP)
		# Godot prepends a 4-byte size header to compressed arrays. 
		# We must slice it off to create a standard web-compliant GZIP payload.
		response.body = compressed.slice(4)
		response.set_header("Content-Encoding", "gzip")
		response.set_header("Vary", "Accept-Encoding")

	return response
