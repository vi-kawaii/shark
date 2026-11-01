class_name StaticFileMiddleware
extends HTTPMiddleware

var static_files := StaticFileServer.new("res://web")

func process_request(request: HTTPMessage) -> Variant:
	if request.method == "GET" and request.clean_path.begins_with("/static/"):
		return static_files.handle(request)
	return null
