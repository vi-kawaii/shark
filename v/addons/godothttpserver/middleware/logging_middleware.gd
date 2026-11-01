class_name LoggingMiddleware
extends HTTPMiddleware

## Structured request logging middleware.
## Logs each request with method, path, status code, duration, and client IP.

var log_to_console: bool = true
var log_headers: bool = false
var log_body: bool = false


func process_request(request: HTTPMessage) -> Variant:
	# Attach the start time metadata directly to the individual HTTPMessage instance
	request.set_meta("_start_time", Time.get_ticks_msec() / 1000.0)
	return null


func process_response(request: HTTPMessage, response: HTTPResponse) -> HTTPResponse:
	var duration_ms: float = 0.0
	if request.has_meta("_start_time"):
		var start_time: float = request.get_meta("_start_time")
		duration_ms = (Time.get_ticks_msec() / 1000.0 - start_time) * 1000.0

	var log_line := "[HTTP] %s %s -> %d (%s) [%.1fms] from %s" % [
		request.method,
		request.path,
		response.code,
		response.status_text,
		duration_ms,
		request.client_ip
	]

	if log_headers:
		log_line += " Headers: %s" % JSON.stringify(request.headers)

	if log_body and not request.body.is_empty():
		log_line += " Body: %s" % request.body_as_string()

	if log_to_console:
		print(log_line)

	return response
