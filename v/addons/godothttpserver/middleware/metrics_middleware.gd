class_name MetricsMiddleware
extends HTTPMiddleware

## Prometheus text-exposition metrics. Serves request counts and cumulative
## latency at a configurable HTTP path (default /metrics).

var enabled: bool = true
var endpoint_path: String = "/metrics"

var _lock := Mutex.new()
var _total_count: int = 0
var _total_duration: float = 0.0
var _counts: Dictionary = {}  # method -> { status: count }


func process_request(request: HTTPMessage) -> Variant:
	if enabled and request.method == "GET" and _normalize(request.clean_path) == endpoint_path:
		return _render()
	request.set_meta("_metrics_start", Time.get_ticks_msec() / 1000.0)
	return null


func process_response(request: HTTPMessage, response: HTTPResponse) -> HTTPResponse:
	var duration: float = 0.0
	if request.has_meta("_metrics_start"):
		duration = Time.get_ticks_msec() / 1000.0 - float(request.get_meta("_metrics_start"))

	_lock.lock()
	_total_count += 1
	_total_duration += duration
	var method := request.method.to_upper()
	var status := str(response.code)
	if not _counts.has(method):
		_counts[method] = {}
	var by_status: Dictionary = _counts[method]
	by_status[status] = int(by_status.get(status, 0)) + 1
	_lock.unlock()

	return response


func _render() -> HTTPResponse:
	_lock.lock()
	var lines: Array[String] = []

	lines.append("# HELP godot_http_requests_total Total HTTP requests processed.")
	lines.append("# TYPE godot_http_requests_total counter")
	lines.append("godot_http_requests_total %d" % _total_count)

	lines.append("# HELP godot_http_request_duration_seconds_total Cumulative request duration in seconds.")
	lines.append("# TYPE godot_http_request_duration_seconds_total counter")
	lines.append("godot_http_request_duration_seconds_total %f" % _total_duration)

	lines.append("# HELP godot_http_requests_by_status_total Requests by method and status.")
	lines.append("# TYPE godot_http_requests_by_status_total counter")
	for method in _counts.keys():
		var by_status: Dictionary = _counts[method]
		for status: String in by_status.keys():
			lines.append("godot_http_requests_by_status_total{method=\"%s\",status=\"%s\"} %d" % [method, status, int(by_status[status])])

	_lock.unlock()

	var response := HTTPResponse.ok("\n".join(lines))
	response.set_content_type("text/plain; version=0.0.4")
	return response


func _normalize(p: String) -> String:
	var out := p
	while out.length() > 1 and out.ends_with("/"):
		out = out.substr(0, out.length() - 1)
	return out