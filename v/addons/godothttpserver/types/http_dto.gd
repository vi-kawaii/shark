class_name HTTPDto
extends RefCounted

## Base class for Data Transfer Objects (DTOs).
## Provides type-safe validation of JSON request bodies with support for:
## - Required and optional fields
## - Nested DTOs
## - Arrays of primitives or DTOs
## - Custom validation callbacks
## - Type coercion (int/float)

var _fields: Dictionary = {}       # { name: { "type": Variant.Type, "required": bool, "validator": Callable } }
var _values: Dictionary = {}


## Registers a required field with a specific type.
func register_field(field_name: String, type: Variant.Type) -> void:
	_fields[field_name] = {"type": type, "required": true, "validator": Callable()}


## Registers an optional field. Missing fields are allowed.
func register_optional_field(field_name: String, type: Variant.Type) -> void:
	_fields[field_name] = {"type": type, "required": false, "validator": Callable()}


## Registers a field with a custom validation callback.
## The callback receives the field value and must return true/false.
func register_validated_field(field_name: String, type: Variant.Type, validator: Callable, required: bool = true) -> void:
	_fields[field_name] = {"type": type, "required": required, "validator": validator}


## Registers a nested DTO field. The value must be a Dictionary that resolves against the DTO class.
func register_nested_dto(field_name: String, dto_class: Script, required: bool = true) -> void:
	_fields[field_name] = {"type": TYPE_OBJECT, "dto_class": dto_class, "required": required, "validator": Callable()}


## Registers an array field. `element_type` can be a Variant.Type or a Script (for DTO arrays).
func register_array_field(field_name: String, element_type: Variant, required: bool = true) -> void:
	_fields[field_name] = {"type": TYPE_ARRAY, "element_type": element_type, "required": required, "validator": Callable()}


## Resolves the DTO from a JSON string. Returns true if valid, false otherwise.
func resolve(body: String) -> bool:
	_values.clear()

	var json := JSON.new()
	var err := json.parse(body)

	# Fail if it's not valid JSON or not a JSON Object (Dictionary)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false

	var parsed_dict: Dictionary = json.data

	for field_name in _fields.keys():
		var field_def: Dictionary = _fields[field_name]

		# Check if the field is present
		if not parsed_dict.has(field_name):
			if field_def.get("required", true):
				return false  # Missing required field
			continue  # Optional field missing - skip

		var value: Variant = parsed_dict[field_name]

		# Handle nested DTOs
		if field_def.has("dto_class"):
			if typeof(value) != TYPE_DICTIONARY:
				return false
			var nested_dto: HTTPDto = field_def["dto_class"].new()
			if not nested_dto.resolve(JSON.stringify(value)):
				return false
			_values[field_name] = nested_dto
			continue

		# Handle arrays
		if field_def.get("type", TYPE_NIL) == TYPE_ARRAY:
			if typeof(value) != TYPE_ARRAY:
				return false
			var element_type: Variant = field_def.get("element_type", TYPE_NIL)
			var arr: Array = value
			var validated_arr: Array = []

			for element in arr:
				if element_type is Script:
					# Array of DTOs
					if typeof(element) != TYPE_DICTIONARY:
						return false
					var element_dto: HTTPDto = element_type.new()
					if not element_dto.resolve(JSON.stringify(element)):
						return false
					validated_arr.append(element_dto)
				else:
					# Array of primitives
					if not _validate_type(element, element_type):
						return false
					validated_arr.append(element)

			_values[field_name] = validated_arr
			continue

		# Handle primitive types
		var expected_type: Variant.Type = field_def.get("type", TYPE_NIL)
		if not _validate_type(value, expected_type):
			return false

		# Run custom validator if provided
		var validator: Callable = field_def.get("validator", Callable())
		if validator.is_valid():
			if not validator.call(value):
				return false

		_values[field_name] = value

	return true


## Returns the value of a field, or null if not set.
func get_value(field_name: String) -> Variant:
	return _values.get(field_name, null)


## Returns true if the field was provided in the request.
func has_value(field_name: String) -> bool:
	return _values.has(field_name)


## Returns all resolved values as a Dictionary.
func to_dict() -> Dictionary:
	var result := {}
	for key in _values:
		var value: Variant = _values[key]
		if value is HTTPDto:
			result[key] = (value as HTTPDto).to_dict()
		elif value is Array:
			var arr: Array = []
			for element in value:
				if element is HTTPDto:
					arr.append((element as HTTPDto).to_dict())
				else:
					arr.append(element)
			result[key] = arr
		else:
			result[key] = value
	return result


func _validate_type(value: Variant, expected_type: Variant.Type) -> bool:
	var actual_type := typeof(value)

	# Allow int for float fields (and vice versa if the value is integral)
	if expected_type == TYPE_FLOAT and actual_type == TYPE_INT:
		return true
	if expected_type == TYPE_INT and actual_type == TYPE_FLOAT:
		return value == int(value)

	return actual_type == expected_type