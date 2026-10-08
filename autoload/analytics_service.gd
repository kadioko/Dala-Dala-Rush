extends Node
## Analytics seam. Offline-first: events queue to a local JSON log so
## nothing is lost; when a real SDK (Firebase plugin) is wired in,
## flush goes there instead. Zero network use until then.
##
## Usage anywhere: AnalyticsService.log_event("run_end", {"score": 1234})

const LOG_PATH := "user://analytics_log.json"
const MAX_LOG_EVENTS := 500
const MAX_PARAMS := 20
const MAX_TEXT_LENGTH := 64
const RAILWAY_MAX_EVENT_AGE_SECONDS := 14 * 24 * 60 * 60
const RAILWAY_EVENT_NAMES: Array[String] = [
	"tutorial_stage_finished", "run_end", "online_leaderboard_submit",
	"online_leaderboard_global", "online_leaderboard_friends", "retention_return",
	"fuel_failure", "route_moment_start", "route_moment_complete", "route_moment_timeout",
	"vehicle_unlocked",
]

var _queue: Array = []

func _ready() -> void:
	_load_log()
	var now: int = int(Time.get_unix_time_from_system())
	var first_open: int = int(SaveSystem.get_value("analytics_first_open_unix", 0))
	var previous_open: int = int(SaveSystem.get_value("analytics_last_open_unix", 0))
	if first_open <= 0:
		first_open = now
	SaveSystem.begin_batch()
	SaveSystem.set_value("analytics_first_open_unix", first_open)
	SaveSystem.set_value("analytics_last_open_unix", now)
	SaveSystem.set_value("analytics_session_count", int(SaveSystem.get_value("analytics_session_count", 0)) + 1)
	SaveSystem.end_batch()
	log_event("app_open", {
		"platform": OS.get_name(),
		"debug": OS.is_debug_build(),
		"session": int(SaveSystem.get_value("analytics_session_count", 1)),
	})
	if previous_open > 0:
		var days_since_first: int = int((now - first_open) / 86400)
		if days_since_first == 1 or days_since_first == 7:
			log_event("retention_return", {"day": days_since_first})

func log_event(event_name: String, params: Dictionary = {}) -> void:
	var clean_name: String = event_name.strip_edges().to_lower()
	if clean_name.is_empty():
		return
	var entry := {
		"e": clean_name,
		"p": _sanitize_params(params),
		"t": int(Time.get_unix_time_from_system()),
	}
	_queue.append(entry)
	if _queue.size() > MAX_LOG_EVENTS:
		_queue = _queue.slice(_queue.size() - MAX_LOG_EVENTS)
	_save_log()
	_send_to_sdk(entry)

## Keeps analytics useful without accidentally writing player-entered text,
## codes, or arbitrary nested data into the local queue.
func _sanitize_params(params: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	var count: int = 0
	for raw_key in params.keys():
		if count >= MAX_PARAMS:
			break
		var key: String = String(raw_key).strip_edges().to_lower()
		if key.is_empty() or key.contains("code") or key.contains("name"):
			continue
		var value: Variant = params[raw_key]
		if typeof(value) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
			clean[key] = value
			count += 1
		elif typeof(value) == TYPE_STRING:
			clean[key] = String(value).substr(0, MAX_TEXT_LENGTH)
			count += 1
	return clean

func report_nonfatal(category: String, detail: String = "") -> void:
	log_event("nonfatal_" + category, {"detail": detail.substr(0, MAX_TEXT_LENGTH)})

func event_count() -> int:
	return _queue.size()

## A consented Railway batch contains only allowlisted, sanitized gameplay
## events. Player names, invite codes, device identifiers, and ad IDs are not
## logged by this service.
func get_railway_batch(max_events: int = 25) -> Array:
	var batch: Array = []
	var now: int = int(Time.get_unix_time_from_system())
	for entry_value in _queue:
		if batch.size() >= max_events or entry_value is not Dictionary:
			continue
		var entry: Dictionary = entry_value
		if String(entry.get("e", "")) not in RAILWAY_EVENT_NAMES:
			continue
		var raw_time: Variant = entry.get("t", 0)
		if typeof(raw_time) not in [TYPE_INT, TYPE_FLOAT] or entry.get("p", {}) is not Dictionary:
			continue
		var event_time: int = int(raw_time)
		if event_time < now - RAILWAY_MAX_EVENT_AGE_SECONDS or event_time > now + 300:
			continue
		# Older local logs used fractional seconds. Normalize the queued event too
		# so acknowledgement still matches it after the server accepts the batch.
		entry["t"] = event_time
		batch.append(entry.duplicate(true))
	return batch

func discard_railway_events() -> void:
	var keep: Array = []
	for entry_value in _queue:
		if entry_value is Dictionary and String((entry_value as Dictionary).get("e", "")) in RAILWAY_EVENT_NAMES:
			continue
		keep.append(entry_value)
	if keep.size() != _queue.size():
		_queue = keep
		_save_log()

func acknowledge_railway_batch(sent_events: Array) -> void:
	if sent_events.is_empty():
		return
	var remaining: Array = _queue.duplicate(true)
	for sent_value in sent_events:
		var target_json: String = JSON.stringify(sent_value)
		for index in range(remaining.size()):
			if JSON.stringify(remaining[index]) == target_json:
				remaining.remove_at(index)
				break
	_queue = remaining
	_save_log()

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
