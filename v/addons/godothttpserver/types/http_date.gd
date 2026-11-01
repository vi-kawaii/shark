class_name HTTPDate
extends RefCounted

## Formats Unix timestamps as RFC 1123 HTTP dates (always GMT).
## Used by the server for the Date and Last-Modified headers.

const WEEKDAYS := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

## Returns the current system time formatted as an RFC 1123 GMT date.
static func now() -> String:
	return format(int(Time.get_unix_time_from_system()))


## Formats a Unix timestamp as an RFC 1123 GMT date string.
static func format(unix_seconds: int) -> String:
	var utc := _epoch_to_utc(unix_seconds)
	var weekday: String = WEEKDAYS[utc["weekday"]]
	var month: String = MONTHS[utc["month"] - 1]
	return "%s, %02d %s %04d %02d:%02d:%02d GMT" % [
		weekday,
		utc["day"],
		month,
		utc["year"],
		utc["hour"],
		utc["minute"],
		utc["second"]
	]


## Converts a Unix timestamp (seconds) to a UTC date-time dictionary.
## The dictionary keys are: year, month (1-12), day, hour, minute, second, weekday (0 = Sunday).
static func _epoch_to_utc(unix_seconds: int) -> Dictionary:
	var days := _floor_div(unix_seconds, 86400)
	var secs_of_day := unix_seconds - days * 86400

	# Civil-from-days algorithm (Howard Hinnant). Returns date at the *day* boundary.
	var z := days + 719468
	var era := _floor_div(z, 146097)
	var doe := z - era * 146097
	var yoe := (doe - _floor_div(doe, 1460) + _floor_div(doe, 36524) - _floor_div(doe, 146096)) / 365
	var y := yoe + era * 400
	var doy := doe - (365 * yoe + _floor_div(yoe, 4) - _floor_div(yoe, 100))
	var mp := (5 * doy + 2) / 153
	var d := doy - _floor_div(153 * mp + 2, 5) + 1
	var m := mp + 3
	if m > 12:
		m -= 12
		y += 1

	var hour := _floor_div(secs_of_day, 3600)
	var minute := _floor_div(secs_of_day % 3600, 60)
	var second := secs_of_day % 60

	# 1970-01-01 was a Thursday. weekday 0 = Sunday.
	var weekday := _mod(days + 4, 7)

	return {
		"year": y,
		"month": m,
		"day": d,
		"hour": hour,
		"minute": minute,
		"second": second,
		"weekday": weekday
	}


static func _floor_div(a: int, b: int) -> int:
	return int(floor(float(a) / float(b)))


static func _mod(a: int, b: int) -> int:
	var r := a % b
	if r < 0:
		r += b
	return r