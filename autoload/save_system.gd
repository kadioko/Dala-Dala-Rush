extends Node
## Persists all player data to user://save.json.

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.json.bak"

var data: Dictionary = {}
var _batch_depth: int = 0
var _batch_dirty: bool = false

const DEFAULTS := {
	"schema_version": 2,
	"best_score": 0,
	"total_coins": 0,
	"selected_vehicle": "classic_blue",
	"selected_route": "kariakoo",
	"unlocked_vehicles": ["classic_blue"],
	"unlocked_routes": ["kariakoo"],
	"music_on": true,
	"sfx_on": true,
	"haptics_on": true,
	"reduced_effects": false,
	"locale": "sw",
	# Career stats
	"total_runs": 0,
	"total_distance_ever": 0.0,
	"total_coins_ever": 0,
	"total_passengers_ever": 0,
	# Route personal bests
	"best_kariakoo": 0,
	"best_mwenge": 0,
	"best_mbezi": 0,
	"best_posta": 0,
	"best_kigamboni": 0,
	"best_ubungo": 0,
	# Achievements (array of unlocked id strings)
	"achievements": [],
	"route_goals_completed": 0,
	"daily_challenge_claimed_date": "",
	"daily_challenges_completed": 0,
	# Ad pacing. Keep this local so interstitial cadence survives restarts.
	"ads_runs_since_interstitial": 0,
	"ads_next_interstitial_at": 2,
	"ads_pending_interstitial": false,
	# Daily login streak
	"streak_count": 0,
	"streak_last_date": "",
	# Consumable inventory: {item_id: count}
	"consumables": {},
	# Top-5 leaderboard: Array of {name, score, route}
	"leaderboard": [],
}

func _ready() -> void:
	load_data()

func load_data() -> void:
	data = DEFAULTS.duplicate(true)
	# Try the main save, fall back to the backup if missing/corrupt.
	if not _load_from(SAVE_PATH):
		if _load_from(BACKUP_PATH):
			push_warning("Save: main file corrupt or missing — restored from backup.")

func _load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	for k in parsed.keys():
		data[k] = parsed[k]
	return true

func save() -> bool:
	# Rotate the last good save to .bak before overwriting,
	# so a crash mid-write can never lose everything.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Save: cannot open file for writing.")
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	_batch_dirty = false
	return true

## Defers disk writes until the matching end_batch(). Calls may be nested.
func begin_batch() -> void:
	_batch_depth += 1

## Flushes all mutations once the outermost batch finishes.
func end_batch() -> void:
	if _batch_depth <= 0:
		push_warning("Save: end_batch called without begin_batch.")
		return
	_batch_depth -= 1
	if _batch_depth == 0 and _batch_dirty:
		save()

func _request_save() -> void:
	if _batch_depth > 0:
		_batch_dirty = true
	else:
		save()

func get_value(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)

func set_value(key: String, value: Variant) -> void:
	data[key] = value
	_request_save()

# ── Coins ────────────────────────────────────────────────────────

func add_coins(amount: int) -> void:
	if amount == 0:
		return
	data["total_coins"] = int(data.get("total_coins", 0)) + amount
	_request_save()

func spend_coins(amount: int) -> bool:
	var total := int(data.get("total_coins", 0))
	if amount < 0 or total < amount:
		return false
	data["total_coins"] = total - amount
	_request_save()
	return true

# ── Vehicles ─────────────────────────────────────────────────────

func unlock_vehicle(id: String) -> void:
	var u: Array = data.get("unlocked_vehicles", [])
	if id not in u:
		u.append(id)
		data["unlocked_vehicles"] = u
		_request_save()

func is_vehicle_unlocked(id: String) -> bool:
	return id in data.get("unlocked_vehicles", [])

# ── Consumables ──────────────────────────────────────────────────

func get_consumable_count(id: String) -> int:
	var inv: Dictionary = data.get("consumables", {})
	return int(inv.get(id, 0))

func add_consumable(id: String, amount: int = 1) -> void:
	var inv: Dictionary = data.get("consumables", {})
	inv[id] = int(inv.get(id, 0)) + amount
	data["consumables"] = inv
	_request_save()

## Returns true and decrements if at least one is owned.
func use_consumable(id: String) -> bool:
	var inv: Dictionary = data.get("consumables", {})
	var n := int(inv.get(id, 0))
	if n <= 0:
		return false
	inv[id] = n - 1
	data["consumables"] = inv
	_request_save()
	return true

# ── Routes ───────────────────────────────────────────────────────

func unlock_route(id: String) -> void:
	var u: Array = data.get("unlocked_routes", [])
	if id not in u:
		u.append(id)
		data["unlocked_routes"] = u
		_request_save()

func is_route_unlocked(id: String) -> bool:
	return id in data.get("unlocked_routes", [])

# ── Scores ───────────────────────────────────────────────────────

func update_best_score(score: int) -> bool:
	if score > int(data.get("best_score", 0)):
		data["best_score"] = score
		_request_save()
		return true
	return false

func update_route_best(route_id: String, score: int) -> bool:
	var key := "best_" + route_id
	if score > int(data.get(key, 0)):
		data[key] = score
		_request_save()
		return true
	return false

func get_route_best(route_id: String) -> int:
	return int(data.get("best_" + route_id, 0))

# ── Career stats ─────────────────────────────────────────────────

func add_run_stats(distance: float, coins: int, passengers: int, count_run: bool = true) -> void:
	if count_run:
		data["total_runs"]      = int(data.get("total_runs", 0)) + 1
	data["total_distance_ever"] = float(data.get("total_distance_ever", 0.0)) + distance
	data["total_coins_ever"]    = int(data.get("total_coins_ever", 0)) + coins
	data["total_passengers_ever"] = int(data.get("total_passengers_ever", 0)) + passengers
	_request_save()

func add_route_goal_completion(route_id: String) -> void:
	data["route_goals_completed"] = int(data.get("route_goals_completed", 0)) + 1
	var key := "route_goal_" + route_id
	data[key] = int(data.get(key, 0)) + 1
	_request_save()

# ── Leaderboard ──────────────────────────────────────────────────

func qualifies_for_leaderboard(score: int) -> bool:
	var lb: Array = data.get("leaderboard", [])
	if lb.size() < 5:
		return score > 0
	return score > int(lb[lb.size() - 1].get("score", 0))

func add_to_leaderboard(player_name: String, score: int, route_id: String) -> void:
	var lb: Array = data.get("leaderboard", [])
	lb.append({"name": player_name.to_upper().substr(0, 3), "score": score, "route": route_id})
	lb.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	if lb.size() > 5:
		lb.resize(5)
	data["leaderboard"] = lb
	_request_save()

func get_leaderboard() -> Array:
	return data.get("leaderboard", [])
