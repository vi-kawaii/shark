class_name HTTPRouter
extends RefCounted

## Routes incoming HTTP requests to registered callbacks.
## Supports path parameters, query parameters, DTO validation, route groups, scoped middleware, and regex constraints.

enum Method { UNKNOWN, GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS }

var _routes: Dictionary = {}
var _param_regex: RegEx = RegEx.new()

# State for route grouping
var _current_group_prefix: String = ""
var _current_group_middlewares: Array[HTTPMiddleware] = []
var _not_found_handler: Callable = Callable()


func _init() -> void:
	for method in Method.keys():
		if method == "UNKNOWN":
			continue
		_routes[method] = {}

	# Compiled to support parameter constraints: {name} or {name:regex}
	_param_regex.compile("\\{([a-zA-Z0-9_]+)(?::([^}]+))?\\}")


## Creates a routing group with a shared prefix and scoped middlewares.
func group(prefix: String, setup_callback: Callable, middlewares: Array[HTTPMiddleware] = []) -> void:
	var previous_prefix := _current_group_prefix
	var previous_middlewares := _current_group_middlewares.duplicate()
	
	_current_group_prefix += prefix
	_current_group_middlewares.append_array(middlewares)
	
	setup_callback.call(self)
	
	_current_group_prefix = previous_prefix
	_current_group_middlewares = previous_middlewares


func register_route(method: Method, path: String, callback: Callable, dto_class: Script = null, route_middlewares: Array[HTTPMiddleware] = []) -> void:
	if method == Method.UNKNOWN:
		return

	var full_path := _normalize_path(_current_group_prefix + path)
	var method_str: String = Method.keys()[method]
	var param_names: Array = []
	var regex_pattern := "^" + full_path + "$"

	for regex_match in _param_regex.search_all(full_path):
		var param_name: String = regex_match.get_string(1)
		var custom_regex: String = regex_match.get_string(2)
		param_names.append(param_name)
		
		# Use the custom regex constraint if provided, else match anything but a slash
		var replacement := "(%s)" % custom_regex if not custom_regex.is_empty() else "([^/]+)"
		regex_pattern = regex_pattern.replace(regex_match.get_string(0), replacement)

	var route_regex := RegEx.new()
	var compile_err := route_regex.compile(regex_pattern)
	if compile_err != OK:
		push_error("HTTPRouter: Failed to compile route regex for path: %s" % full_path)
		return

	# Combine group middlewares with route-specific middlewares
	var combined_middlewares := _current_group_middlewares.duplicate()
	combined_middlewares.append_array(route_middlewares)

	_routes[method_str][full_path] = {
		"regex": route_regex,
		"param_names": param_names,
		"callback": callback,
		"dto_class": dto_class,
		"middlewares": combined_middlewares
	}


## Convenience methods for each HTTP method.
func handle_get(path: String, callback: Callable, dto_class: Script = null, mws: Array[HTTPMiddleware] = []) -> void:
	register_route(Method.GET, path, callback, dto_class, mws)


func handle_post(path: String, callback: Callable, dto_class: Script = null, mws: Array[HTTPMiddleware] = []) -> void:
	register_route(Method.POST, path, callback, dto_class, mws)


func handle_put(path: String, callback: Callable, dto_class: Script = null, mws: Array[HTTPMiddleware] = []) -> void:
	register_route(Method.PUT, path, callback, dto_class, mws)


func handle_delete(path: String, callback: Callable, dto_class: Script = null, mws: Array[HTTPMiddleware] = []) -> void:
	register_route(Method.DELETE, path, callback, dto_class, mws)


func handle_patch(path: String, callback: Callable, dto_class: Script = null, mws: Array[HTTPMiddleware] = []) -> void:
	register_route(Method.PATCH, path, callback, dto_class, mws)


func handle_head(path: String, callback: Callable, dto_class: Script = null, mws: Array[HTTPMiddleware] = []) -> void:
	register_route(Method.HEAD, path, callback, dto_class, mws)


func handle_options(path: String, callback: Callable, dto_class: Script = null, mws: Array[HTTPMiddleware] = []) -> void:
	register_route(Method.OPTIONS, path, callback, dto_class, mws)


## Registers a handler called when no route matches the request.
## The handler receives (path, query_params, headers) and returns an HTTPResponse.
func set_not_found_handler(callback: Callable) -> void:
	_not_found_handler = callback


## Routes a request to the matching callback. Returns an HTTPResponse.
func route_request(request: HTTPMessage) -> HTTPResponse:
	var method_str := request.method.to_upper()
	var match_path := _normalize_path(request.clean_path)

	if not _routes.has(method_str):
		return HTTPResponse.method_not_allowed("Method not allowed").set_header("Allow", ", ".join(_find_allowed_methods(match_path)))

	var routes: Dictionary = _routes[method_str]

	# First try exact match for performance
	if routes.has(match_path):
		return _execute_route(routes[match_path], request)

	# Then try regex-based routes with path parameters
	for route in routes.values():
		var match: RegExMatch = route["regex"].search(match_path)
		if match:
			return _execute_route(route, request, match)

	# Determine which methods match this path.
	var allowed := _find_allowed_methods(match_path)

	# Automatic OPTIONS: report the allowed methods when no route handles it.
	if method_str == "OPTIONS" and not allowed.is_empty():
		var opt_resp := HTTPResponse.no_content()
		opt_resp.set_header("Allow", ", ".join(allowed))
		return opt_resp

	# The path exists on another method: return 405 with an Allow header.
	if not allowed.is_empty():
		return HTTPResponse.method_not_allowed("Method Not Allowed").set_header("Allow", ", ".join(allowed))

	if _not_found_handler.is_valid():
		return _resolve_handler_result(_not_found_handler.call(request.path, request.query_params, request.headers))

	return HTTPResponse.not_found("Route not found")


## Returns the list of HTTP methods for which the given path has at least one route.
func _find_allowed_methods(match_path: String) -> Array:
	var allowed: Array = []
	for method_name: String in _routes.keys():
		var routes: Dictionary = _routes[method_name]
		if routes.has(match_path):
			allowed.append(method_name)
			continue
		for route in routes.values():
			if route["regex"].search(match_path):
				allowed.append(method_name)
				break
	return allowed


## Strips trailing slashes so that "/users/" and "/users" resolve to the same route.
## The root path "/" is preserved.
func _normalize_path(p: String) -> String:
	var out := p
	while out.length() > 1 and out.ends_with("/"):
		out = out.substr(0, out.length() - 1)
	return out


## Coerces a value returned by the not-found handler into an HTTPResponse.
func _resolve_handler_result(result: Variant) -> HTTPResponse:
	if result is HTTPResponse:
		return result
	if result is Dictionary:
		return _dictionary_to_response(result)
	push_error("HTTPRouter: not-found handler must return HTTPResponse, got: %s" % typeof(result))
	return HTTPResponse.not_found("Route not found")


func _execute_route(route: Dictionary, request: HTTPMessage, match: RegExMatch = null) -> HTTPResponse:
	var path_params := {}
	if match != null:
		var param_names: Array = route["param_names"]
		for i in range(param_names.size()):
			var extracted_val := match.get_string(i + 1)
			path_params[param_names[i]] = extracted_val.uri_decode()

	var route_mws: Array[HTTPMiddleware] = route["middlewares"]
	
	# Run scoped request middlewares
	for mw in route_mws:
		var mw_res := mw.process_request(request)
		if mw_res is HTTPResponse:
			return mw_res

	var callback: Callable = route["callback"]
	var dto_class: Script = route["dto_class"]

	var body_arg: Variant
	if dto_class != null:
		var dto: HTTPDto = dto_class.new()
		if not dto.resolve(request.body_as_string()):
			return HTTPResponse.bad_request("Invalid DTO payload")
		body_arg = dto
	else:
		body_arg = request.body_as_string()

	var result: Variant = callback.callv([path_params, request.query_params, request.headers, body_arg])

	# Validate return value
	var response: HTTPResponse
	if result is HTTPResponse:
		response = result
	elif result is Dictionary:
		response = _dictionary_to_response(result)
	else:
		push_error("HTTPRouter: Route callback must return HTTPResponse or Dictionary, got: %s" % typeof(result))
		return HTTPResponse.internal_server_error("Invalid route handler return value")

	# Run scoped response middlewares in reverse
	for i in range(route_mws.size() - 1, -1, -1):
		response = route_mws[i].process_response(request, response)

	# HEAD requests must not include a body
	if request.method == "HEAD":
		response.body = PackedByteArray()

	return response


## Converts a Dictionary response to an HTTPResponse.
func _dictionary_to_response(dict: Dictionary) -> HTTPResponse:
	var code := int(dict.get("code", 200))
	var status := str(dict.get("status", ""))
	var body := str(dict.get("body", ""))
	var resp := HTTPResponse.new(code, status, body)
	if dict.has("headers") and dict["headers"] is Dictionary:
		for key in dict["headers"]:
			resp.set_header(str(key), str(dict["headers"][key]))
	return resp


## Warns if a new route could conflict with an existing one.
func _check_route_conflicts(method: Method, new_path: String, new_param_names: Array) -> void:
	var method_str: String = Method.keys()[method]
	var existing_routes: Dictionary = _routes[method_str]

	for existing_path: String in existing_routes.keys():
		var existing_params: Array = existing_routes[existing_path]["param_names"]

		var new_static: String = new_path
		var existing_static: String = existing_path
		for p in new_param_names:
			new_static = new_static.replace("{%s}" % p, "")
		for p in existing_params:
			existing_static = existing_static.replace("{%s}" % p, "")

		if new_static == existing_static and (new_param_names.size() > 0 or existing_params.size() > 0):
			push_warning("HTTPRouter: Route '%s' may conflict with existing route '%s' for method %s. Order matters." % [new_path, existing_path, method_str])
