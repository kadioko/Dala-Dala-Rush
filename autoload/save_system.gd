extends Node
## Persists all player data to user://save.json.

const SAVE_PATH := "user://save.json"

var data: Dictionary = {}

const DEFAULTS := {
	"schema_version": 2,
	"best_score": 0,
	"total_coins": 0,
	"selected_vehicle": "classic_blue",
	"selected_route": "kariakoo",
	"unlocked_vehicles": ["classic_blue"],
	"music_on": true,
	"sfx_on": true,
	"haptics_on": true,
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
	# Top-5 leaderboard: Array of {name, score, route}
	"leaderboard": [],
}

func _ready() -> void:
	load_data()

func load_data() -> void:
	data = DEFAULTS.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed.keys():
			data[k] = parsed[k]

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Save: cannot open file for writing.")
		return
	f.store_string(JSON.stringify(data))
	f.close()

func get_value(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)

func set_value(key: String, value: Variant) -> void:
	data[key] = value
	save()

# ── Coins ────────────────────────────────────────────────────────

func add_coins(amount: int) -> void:
	data["total_coins"] = int(data.get("total_coins", 0)) + amount
	save()

func spend_coins(amount: int) -> bool:
	var total := int(data.get("total_coins", 0))
	if amount < 0 or total < amount:
		return false
	data["total_coins"] = total - amount
	save()
	return true

# ── Vehicles ─────────────────────────────────────────────────────

func unlock_vehicle(id: String) -> void:
	var u: Array = data.get("unlocked_vehicles", [])
	if id not in u:
		u.append(id)
		data["unlocked_vehicles"] = u
		save()

func is_vehicle_unlocked(id: String) -> bool:
	return id in data.get("unlocked_vehicles", [])

# ── Scores ───────────────────────────────────────────────────────

func update_best_score(score: int) -> bool:
	if score > int(data.get("best_score", 0)):
		data["best_score"] = score
		save()
		return true
	return false

func update_route_best(route_id: String, score: int) -> bool:
	var key := "best_" + route_id
	if score > int(data.get(key, 0)):
		data[key] = score
		save()
		return true
	return false

func get_route_best(route_id: String) -> int:
	return int(data.get("best_" + route_id, 0))

# ── Career stats ─────────────────────────────────────────────────

func add_run_stats(distance: float, coins: int, passengers: int) -> void:
	data["total_runs"]          = int(data.get("total_runs", 0)) + 1
	data["total_distance_ever"] = float(data.get("total_distance_ever", 0.0)) + distance
	data["total_coins_ever"]    = int(data.get("total_coins_ever", 0)) + coins
	data["total_passengers_ever"] = int(data.get("total_passengers_ever", 0)) + passengers
	save()

func add_route_goal_completion(route_id: String) -> void:
	data["route_goals_completed"] = int(data.get("route_goals_completed", 0)) + 1
	var key := "route_goal_" + route_id
	data[key] = int(data.get(key, 0)) + 1
	save()

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
	save()

func get_leaderboard() -> Array:
	return data.get("leaderboard", [])
