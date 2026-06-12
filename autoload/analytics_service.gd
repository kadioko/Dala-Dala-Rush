extends Node
## Analytics seam. Offline-first: events queue to a local JSON log so
## nothing is lost; when a real SDK (Firebase plugin) is wired in,
## flush goes there instead. Zero network use until then.
##
## Usage anywhere: AnalyticsService.log_event("run_end", {"score": 1234})

const LOG_PATH := "user://analytics_log.json"
const MAX_LOG_EVENTS := 500

var _queue: Array = []

func _ready() -> void:
	_load_log()

func log_event(event_name: String, params: Dictionary = {}) -> void:
	var entry := {
		"e": event_name,
		"p": params,
		"t": Time.get_unix_time_from_system(),
	}
	_queue.append(entry)
	if _queue.size() > MAX_LOG_EVENTS:
		_queue = _queue.slice(_queue.size() - MAX_LOG_EVENTS)
	_save_log()
	_send_to_sdk(entry)

## TODO Firebase: install a GodotFirebase / Firebase Analytics plugin and
## forward events here. Until then this is a no-op.
func _send_to_sdk(_entry: Dictionary) -> void:
	pass

func _load_log() -> void:
	if not FileAccess.file_exists(LOG_PATH):
		return
	var f := FileAccess.open(LOG_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_ARRAY:
		_queue = parsed

func _save_log() -> void:
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_queue))
	f.close()
