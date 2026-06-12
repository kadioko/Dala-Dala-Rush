class_name Routes
## Route catalog. Add new routes by appending entries to LIST.
## difficulty multiplier scales obstacle spawn rate and base speed.
## obstacle_weights and collectible_weights make every route feel different.
## unlock_goals: total route-goal completions needed to unlock for free.
## unlock_price: coin price to unlock immediately instead.

const LIST: Array = [
	{
		"id": "kariakoo",
		"name_key": "ROUTE_KARIAKOO",
		"difficulty": 1.0,
		"spawn_interval_mult": 1.18,
		"flavor_key": "ROUTE_KARIAKOO_D",
		"goal_key": "GOAL_KARIAKOO",
		"goal_type": "passengers",
		"goal_target": 8,
		"goal_reward": 35,
		"sky": Color("#f7d794"),
		"road": Color("#3d3d3d"),
		"obstacle_weights": {
			"bodaboda": 16, "bajaji": 18, "car": 12, "pothole": 8, "cone": 10,
			"police": 5, "barrier": 7, "truck": 5, "pedestrian": 13, "tire": 6,
			"mbuzi": 6,
		},
		"collectible_weights": {
			"coin": 55, "passenger": 28, "fuel": 8, "shield": 4,
			"magnet": 3, "speed_boost": 1, "slow": 1,
		},
	},
	{
		"id": "mwenge",
		"name_key": "ROUTE_MWENGE",
		"unlock_goals": 1,
		"unlock_price": 150,
		"difficulty": 1.1,
		"spawn_interval_mult": 1.1,
		"flavor_key": "ROUTE_MWENGE_D",
		"goal_key": "GOAL_MWENGE",
		"goal_type": "near_misses",
		"goal_target": 6,
		"goal_reward": 45,
		"sky": Color("#a8e6cf"),
		"road": Color("#2f3640"),
		"obstacle_weights": {
			"bodaboda": 20, "bajaji": 12, "car": 14, "pothole": 9, "cone": 8,
			"police": 6, "barrier": 7, "truck": 8, "pedestrian": 8, "tire": 8,
		},
		"collectible_weights": {
			"coin": 58, "passenger": 22, "fuel": 7, "shield": 4,
			"magnet": 4, "speed_boost": 3, "slow": 2,
		},
	},
	{
		"id": "mbezi",
		"name_key": "ROUTE_MBEZI",
		"unlock_goals": 3,
		"unlock_price": 350,
		"difficulty": 1.22,
		"spawn_interval_mult": 1.02,
		"flavor_key": "ROUTE_MBEZI_D",
		"goal_key": "GOAL_MBEZI",
		"goal_type": "distance",
		"goal_target": 1800,
		"goal_reward": 55,
		"sky": Color("#74b9ff"),
		"road": Color("#353b48"),
		"obstacle_weights": {
			"bodaboda": 10, "bajaji": 8, "car": 18, "pothole": 10, "cone": 6,
			"police": 5, "barrier": 7, "truck": 18, "pedestrian": 5, "tire": 13,
		},
		"collectible_weights": {
			"coin": 56, "passenger": 18, "fuel": 12, "shield": 4,
			"magnet": 3, "speed_boost": 5, "slow": 2,
		},
	},
	{
		"id": "posta",
		"name_key": "ROUTE_POSTA",
		"unlock_goals": 5,
		"unlock_price": 600,
		"difficulty": 1.34,
		"spawn_interval_mult": 0.96,
		"flavor_key": "ROUTE_POSTA_D",
		"goal_key": "GOAL_POSTA",
		"goal_type": "score",
		"goal_target": 700,
		"goal_reward": 65,
		"sky": Color("#ffeaa7"),
		"road": Color("#2d3436"),
		"obstacle_weights": {
			"bodaboda": 8, "bajaji": 9, "car": 17, "pothole": 5, "cone": 18,
			"police": 12, "barrier": 16, "truck": 6, "pedestrian": 7, "tire": 2,
		},
		"collectible_weights": {
			"coin": 54, "passenger": 20, "fuel": 7, "shield": 7,
			"magnet": 4, "speed_boost": 2, "slow": 6,
		},
	},
	{
		"id": "kigamboni",
		"name_key": "ROUTE_KIGAMBONI",
		"unlock_goals": 8,
		"unlock_price": 900,
		"difficulty": 1.46,
		"spawn_interval_mult": 0.92,
		"flavor_key": "ROUTE_KIGAMBONI_D",
		"goal_key": "GOAL_KIGAMBONI",
		"goal_type": "coins",
		"goal_target": 18,
		"goal_reward": 75,
		"sky": Color("#fab1a0"),
		"road": Color("#3a3a3a"),
		"obstacle_weights": {
			"bodaboda": 12, "bajaji": 8, "car": 12, "pothole": 18, "cone": 7,
			"police": 5, "barrier": 8, "truck": 10, "pedestrian": 5, "tire": 15,
			"mbuzi": 10,
		},
		"collectible_weights": {
			"coin": 52, "passenger": 16, "fuel": 15, "shield": 5,
			"magnet": 3, "speed_boost": 6, "slow": 3,
		},
	},
	{
		"id": "ubungo",
		"name_key": "ROUTE_UBUNGO",
		"unlock_goals": 12,
		"unlock_price": 1400,
		"difficulty": 1.58,
		"spawn_interval_mult": 0.88,
		"flavor_key": "ROUTE_UBUNGO_D",
		"goal_key": "GOAL_UBUNGO",
		"goal_type": "score",
		"goal_target": 1200,
		"goal_reward": 100,
		"sky": Color("#535c68"),
		"road": Color("#1e1e1e"),
		"obstacle_weights": {
			"bodaboda": 14, "bajaji": 10, "car": 16, "pothole": 8, "cone": 9,
			"police": 7, "barrier": 10, "truck": 18, "pedestrian": 3, "tire": 5,
		},
		"collectible_weights": {
			"coin": 50, "passenger": 15, "fuel": 10, "shield": 7,
			"magnet": 5, "speed_boost": 3, "slow": 10,
		},
	},
]

static func get_by_id(id: String) -> Dictionary:
	for r in LIST:
		if r.id == id:
			return r
	return LIST[0]

## A route is unlocked if: no requirement, explicitly purchased,
## or the player has completed enough route goals overall.
static func is_unlocked(route: Dictionary) -> bool:
	var need := int(route.get("unlock_goals", 0))
	if need <= 0:
		return true
	if SaveSystem.is_route_unlocked(String(route.id)):
		return true
	return int(SaveSystem.get_value("route_goals_completed", 0)) >= need

static func weighted_pick(weights: Dictionary, allowed_ids: Array, fallback_id: String) -> String:
	var total := 0.0
	for id in allowed_ids:
		total += max(0.0, float(weights.get(String(id), 0.0)))
	if total <= 0.0:
		return fallback_id

	var roll := randf() * total
	for id in allowed_ids:
		var item_id := String(id)
		roll -= max(0.0, float(weights.get(item_id, 0.0)))
		if roll <= 0.0:
			return item_id
	return fallback_id

static func is_goal_met(route: Dictionary, stats: Dictionary) -> bool:
	var goal_type := String(route.get("goal_type", "score"))
	var target := float(route.get("goal_target", 0.0))
	return _goal_value(goal_type, stats) >= target

static func goal_progress(route: Dictionary, stats: Dictionary) -> String:
	var goal_type := String(route.get("goal_type", "score"))
	var target := float(route.get("goal_target", 0.0))
	var current: float = minf(_goal_value(goal_type, stats), target)
	if goal_type == "distance":
		return "%dm/%dm" % [int(current), int(target)]
	return "%d/%d" % [int(current), int(target)]

static func _goal_value(goal_type: String, stats: Dictionary) -> float:
	match goal_type:
		"coins":
			return float(stats.get("coins", 0))
		"distance":
			return float(stats.get("distance", 0.0))
		"near_misses":
			return float(stats.get("near_misses", 0))
		"passengers":
			return float(stats.get("passengers", 0))
		_:
			return float(stats.get("score", 0))
