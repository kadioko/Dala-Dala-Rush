extends Node
## Remote-tunable game config without app updates.
## Priority: fetched remote JSON > local override file > defaults.
## Fully offline-safe: failures silently keep last known values.
##
## Usage: RemoteConfig.get_value("spawn_interval_mult", 1.0)
## Test locally by writing JSON to user://remote_config.json.

## Set to your hosted JSON URL when ready (e.g. GitHub Pages / Firebase
## Hosting). Empty string disables fetching entirely.
const REMOTE_URL := ""
const CACHE_PATH := "user://remote_config.json"

const DEFAULTS := {
	"event_banner": "",            # text banner shown on the main menu
	"spawn_interval_global": 1.0,  # global difficulty knob
	"daily_reward_mult": 1.0,      # event: multiply daily/streak rewards
	"kituo_min_gap": 20.0,
	"kituo_max_gap": 32.0,
}

var _values: Dictionary = {}

func _ready() -> void:
	_values = DEFAULTS.duplicate(true)
	_load_cache()
	if REMOTE_URL != "":
		_fetch()

func get_value(key: String, fallback: Variant = null) -> Variant:
	return _values.get(key, fallback if fallback != null else DEFAULTS.get(key))

func _load_cache() -> void:
	if not FileAccess.file_exists(CACHE_PATH):
		return
	var f := FileAccess.open(CACHE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed.keys():
			_values[k] = parsed[k]

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
		for k in parsed.keys():
			_values[k] = parsed[k]
		var f := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(parsed))
			f.close()
	)
	req.request(REMOTE_URL)
