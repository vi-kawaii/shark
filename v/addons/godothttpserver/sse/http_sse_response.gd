class_name HTTPSseResponse
extends RefCounted

## Server-Sent Events helper built on top of the chunked-transfer sender.
## Usage:
##   var sse := HTTPSseResponse.new()
##   sse.start(conn)                 # sends the 200 text/event-stream headers
##   sse.send_event("message", data) # one or more times
##   sse.end()                       # terminates the chunked stream

const MIME := "text/event-stream"

var _conn: HTTPConnection = null
var _started := false


func start(conn: HTTPConnection) -> void:
	if _started or conn == null:
		return
	_conn = conn
	var response := HTTPResponse.new(200, "OK")
	response.is_chunked = true
	response.set_content_type(MIME)
	response.set_header("Cache-Control", "no-cache")
	response.set_header("Connection", "keep-alive")
	response.set_header("X-Accel-Buffering", "no")
	_conn.send_response(response)
	_started = true


func is_started() -> bool:
	return _started


## Sends a named event with optional id and retry hint.
func send_event(event_name: String, data: String, event_id: String = "", retry: int = -1) -> void:
	if not _started:
		return

	var payload := ""
	if not event_id.is_empty():
		payload += "id: %s\n" % event_id
	if retry >= 0:
		payload += "retry: %d\n" % retry
	if not event_name.is_empty():
		payload += "event: %s\n" % event_name

	# A data line is required; each line in the payload becomes a "data:" field.
	var lines := data.split("\n")
	if lines.is_empty():
		lines = [""]
	for line in lines:
		payload += "data: %s\n" % line
	payload += "\n"

	_conn.send_chunk(payload.to_utf8_buffer())


## Sends a data-only event.
func send_data(data: String, event_id: String = "") -> void:
	send_event("", data, event_id)


## Terminates the event stream.
func end() -> void:
	if not _started:
		return
	_conn.finish_chunked_response()
	_started = false