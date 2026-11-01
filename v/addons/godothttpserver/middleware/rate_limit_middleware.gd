class_name RateLimitMiddleware
extends HTTPMiddleware

## Token-bucket rate limiting middleware.
## Limits requests per client IP within a time window with automatic memory cleanup.

var max_requests: int = 100
var window_seconds: float = 60.0
var cleanup_interval: float = 60.0

var _buckets: Dictionary = {}  # { ip: { "tokens": float, "last_refill": float } }
var _last_cleanup: float = 0.0


func _init(p_max_requests: int = 100, p_window_seconds: float = 60.0) -> void:
	max_requests = p_max_requests
	window_seconds = p_window_seconds
	cleanup_interval = p_window_seconds


func process_request(request: HTTPMessage) -> Variant:
	var ip := request.client_ip
	if ip.is_empty():
		ip = "unknown"

	var now := Time.get_ticks_msec() / 1000.0

	# Periodically purge stale IP entries to prevent memory growth
	if now - _last_cleanup >= cleanup_interval:
		_cleanup_stale_buckets(now)

	if not _buckets.has(ip):
		_buckets[ip] = {"tokens": float(max_requests), "last_refill": now}

	var bucket: Dictionary = _buckets[ip]
	var elapsed : float = now - bucket["last_refill"]
	var refill : float = elapsed / window_seconds * float(max_requests)
	bucket["tokens"] = min(float(max_requests), bucket["tokens"] + refill)
	bucket["last_refill"] = now

	if bucket["tokens"] < 1.0:
		var response := HTTPResponse.too_many_requests("Rate limit exceeded")
		# True remaining wait: time until the bucket refills to a full token.
		var deficit := 1.0 - float(bucket["tokens"])
		var seconds_to_refill := deficit * window_seconds / float(max_requests)
		response.set_header("Retry-After", str(int(ceil(seconds_to_refill))))
		return response

	bucket["tokens"] -= 1.0
	return null


## Clears all rate limit state.
func reset() -> void:
	_buckets.clear()
	_last_cleanup = Time.get_ticks_msec() / 1000.0


## Removes IP entries that have been inactive for at least one full window.
func _cleanup_stale_buckets(now: float) -> void:
	_last_cleanup = now
	var stale_ips: Array = []

	for client_ip in _buckets:
		var bucket: Dictionary = _buckets[client_ip]
		if now - bucket["last_refill"] >= window_seconds:
			stale_ips.append(client_ip)

	for client_ip in stale_ips:
		_buckets.erase(client_ip)
