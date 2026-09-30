extends Node
## Remote-tunable game config without app updates.
## Priority: fetched remote JSON > local override file > defaults.
## Fully offline-safe: failures silently keep last known values.
##
## Usage: RemoteConfig.get_value("spawn_interval_mult", 1.0)
## Test locally by writing JSON to user://remote_config.json.

## Published from this repository's GitHub Pages `docs/` source. Fetching is
## optional: a bad response always leaves the last safe cache/defaults in use.
const REMOTE_URL := "https://kadioko.github.io/Dala-Dala-Rush/docs/remote-config.json"
const CACHE_PATH := "user://remote_config.json"

const ROUTE_TUNING_KEYS := [
	"spawn", "fuel", "coins", "kituo_min", "kituo_max",
	"passengers", "kituo_gap", "rush",
]
const EVENT_TEXT_KEYS := ["event_banner", "event_banner_sw", "event_banner_en"]

const DEFAULTS := {
	"event_banner": "",            # text banner shown on the main menu
	"event_banner_sw": "",         # localized event banner, preferred in Swahili
	"event_banner_en": "",         # localized event banner, preferred in English
	"spawn_interval_global": 1.0,  # global difficulty knob
	"fuel_drain_global": 0.90,     # global fuel tuning; lower = longer runs
	"coin_reward_global": 1.0,     # global coin economy; vehicle perks stack
	"speed_ramp_global": 0.95,     # scales the 20-second speed increases
	"daily_reward_mult": 1.0,      # event: multiply daily/streak rewards
	"kituo_min_gap": 18.0,
	"kituo_max_gap": 28.0,
	# Optional per-route map, e.g. {"kariakoo": {"spawn": 1.10, "fuel": 0.9}}
	"route_tuning": {},
}

var _values: Dictionary = {}

func _ready() -> void:
	_values = DEFAULTS.duplicate(true)
	_load_cache()
	if REMOTE_URL != "":
		_fetch()

func get_value(key: String, fallback: Variant = null) -> Variant:
	return _values.get(key, fallback if fallback != null else DEFAULTS.get(key))

func get_float(key: String, fallback: float, minimum: float, maximum: float) -> float:
	var value: Variant = get_value(key, fallback)
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return fallback
	return clampf(float(value), minimum, maximum)

func get_route_float(route_id: String, key: String, fallback: float,
		minimum: float, maximum: float) -> float:
	var all_routes: Variant = get_value("route_tuning", {})
	if typeof(all_routes) != TYPE_DICTIONARY:
		return fallback
	var route_values: Variant = (all_routes as Dictionary).get(route_id, {})
	if typeof(route_values) != TYPE_DICTIONARY:
		return fallback
	var value: Variant = (route_values as Dictionary).get(key, fallback)
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return fallback
	return clampf(float(value), minimum, maximum)

func event_banner_for(locale_id: String) -> String:
	var localized: Variant = get_value("event_banner_" + locale_id, "")
	if typeof(localized) == TYPE_STRING and not String(localized).strip_edges().is_empty():
		return String(localized).strip_edges()
	var fallback: Variant = get_value("event_banner", "")
	return String(fallback).strip_edges() if typeof(fallback) == TYPE_STRING else ""

func _load_cache() -> void:
	if not FileAccess.file_exists(CACHE_PATH):
		return
	var f := FileAccess.open(CACHE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY and _merge_config(parsed as Dictionary):
		AnalyticsService.log_event("remote_config_loaded", {"source": "cache"})

func _fetch() -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray):
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			return
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed) != TYPE_DICTIONARY:
			return
		if not _merge_config(parsed as Dictionary):
			return
		AnalyticsService.log_event("remote_config_loaded", {"source": "network"})
		var f := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(parsed))
			f.close()
	)
	var result: Error = req.request(REMOTE_URL)
	if result != OK:
		req.queue_free()

## Only documented, primitive tuning values may change the live defaults. This
## keeps a malformed or accidentally edited public JSON file from becoming an
## unbounded gameplay or UI input surface.
func _merge_config(source: Dictionary) -> bool:
	var merged: bool = false
	for raw_key in source.keys():
		var key: String = String(raw_key)
		if not DEFAULTS.has(key):
			continue
		var value: Variant = source[raw_key]
		if key == "route_tuning":
			if typeof(value) != TYPE_DICTIONARY:
				continue
			_values[key] = _sanitize_route_tuning(value as Dictionary)
			merged = true
			continue
		if key in EVENT_TEXT_KEYS:
			if typeof(value) == TYPE_STRING:
				_values[key] = String(value).strip_edges().substr(0, 96)
				merged = true
			continue
		if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
			_values[key] = float(value)
			merged = true
	return merged

func _sanitize_route_tuning(raw_routes: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	for raw_route_id in raw_routes.keys():
		var route_id: String = String(raw_route_id).strip_edges().to_lower()
		if route_id.is_empty() or route_id.length() > 32:
			continue
		var values: Variant = raw_routes[raw_route_id]
		if typeof(values) != TYPE_DICTIONARY:
			continue
		var clean_values: Dictionary = {}
		for raw_key in (values as Dictionary).keys():
			var key: String = String(raw_key)
			var value: Variant = (values as Dictionary)[raw_key]
			if key in ROUTE_TUNING_KEYS and typeof(value) in [TYPE_INT, TYPE_FLOAT]:
				clean_values[key] = float(value)
		if not clean_values.is_empty():
			clean[route_id] = clean_values
	return clean
