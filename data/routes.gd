class_name Routes
## Route catalog. Add new routes by appending entries to LIST.
## difficulty multiplier scales obstacle spawn rate and base speed.
## obstacle_weights and collectible_weights make every route feel different.
## unlock_goals: total route-goal completions needed to unlock for free.
## unlock_price: coin price to unlock immediately instead.

const CONDITION_IDS := ["day", "dusk", "night", "rain"]

const LIST: Array = [
	{
		"id": "kariakoo",
		"name_key": "ROUTE_KARIAKOO",
		"difficulty": 1.0,
		"spawn_interval_mult": 1.24,
		"passenger_interval_mult": 0.78,
		"kituo_gap_mult": 0.82,
		"fuel_drain_route_mult": 1.00,
		"rush_hour_chance": 0.35,
		"condition_weights": {"day": 55, "dusk": 22, "night": 13, "rain": 10},
		"flavor_key": "ROUTE_KARIAKOO_D",
		"goal_key": "GOAL_KARIAKOO",
		"goal_type": "passengers",
		"goal_target": 8,
		"goal_reward": 35,
		"mastery_scores": [400, 800, 1300],
		"mastery_rewards": [15, 25, 45],
		"signature_id": "fare_rush",
		"signature_key": "ROUTE_MOMENT_FARE_RUSH",
		"signature_title_key": "MOMENT_FARE_RUSH",
		"signature_action_key": "MOMENT_ACTION_FARE_RUSH",
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
		"difficulty": 1.09,
		"spawn_interval_mult": 1.15,
		"passenger_interval_mult": 0.94,
		"kituo_gap_mult": 0.94,
		"fuel_drain_route_mult": 1.00,
		"rush_hour_chance": 0.30,
		"condition_weights": {"day": 42, "dusk": 25, "night": 20, "rain": 13},
		"flavor_key": "ROUTE_MWENGE_D",
		"goal_key": "GOAL_MWENGE",
		"goal_type": "near_misses",
		"goal_target": 6,
		"goal_reward": 45,
		"mastery_scores": [600, 1200, 2000],
		"mastery_rewards": [15, 25, 45],
		"signature_id": "boda_watch",
		"signature_key": "ROUTE_MOMENT_BODA_WATCH",
		"signature_title_key": "MOMENT_BODA_WATCH",
		"signature_action_key": "MOMENT_ACTION_BODA_WATCH",
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
		"difficulty": 1.19,
		"spawn_interval_mult": 1.06,
		"passenger_interval_mult": 1.08,
		"kituo_gap_mult": 1.12,
		"fuel_drain_route_mult": 0.88,
		"rush_hour_chance": 0.16,
		"condition_weights": {"day": 52, "dusk": 22, "night": 15, "rain": 11},
		"flavor_key": "ROUTE_MBEZI_D",
		"goal_key": "GOAL_MBEZI",
		"goal_type": "distance",
		"goal_target": 1800,
		"goal_reward": 55,
		"mastery_scores": [700, 1500, 2400],
		"mastery_rewards": [20, 30, 50],
		"signature_id": "truck_line",
		"signature_key": "ROUTE_MOMENT_TRUCK_LINE",
		"signature_title_key": "MOMENT_TRUCK_LINE",
		"signature_action_key": "MOMENT_ACTION_TRUCK_LINE",
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
		"difficulty": 1.29,
		"spawn_interval_mult": 0.98,
		"passenger_interval_mult": 0.92,
		"kituo_gap_mult": 0.95,
		"fuel_drain_route_mult": 0.98,
		"rush_hour_chance": 0.26,
		"condition_weights": {"day": 43, "dusk": 26, "night": 22, "rain": 9},
		"flavor_key": "ROUTE_POSTA_D",
		"goal_key": "GOAL_POSTA",
		"goal_type": "score",
		"goal_target": 700,
		"goal_reward": 65,
		"mastery_scores": [800, 1600, 2600],
		"mastery_rewards": [20, 30, 50],
		"signature_id": "checkpoint_clear",
		"signature_key": "ROUTE_MOMENT_CHECKPOINT_CLEAR",
		"signature_title_key": "MOMENT_CHECKPOINT_CLEAR",
		"signature_action_key": "MOMENT_ACTION_CHECKPOINT_CLEAR",
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
		"difficulty": 1.40,
		"spawn_interval_mult": 0.95,
		"passenger_interval_mult": 0.88,
		"kituo_gap_mult": 1.06,
		"fuel_drain_route_mult": 1.18,
		"rush_hour_chance": 0.18,
		"condition_weights": {"day": 28, "dusk": 18, "night": 18, "rain": 36},
		"flavor_key": "ROUTE_KIGAMBONI_D",
		"goal_key": "GOAL_KIGAMBONI",
		"goal_type": "coins",
		"goal_target": 18,
		"goal_reward": 75,
		"mastery_scores": [900, 1800, 2800],
		"mastery_rewards": [25, 35, 55],
		"signature_id": "fuel_scout",
		"signature_key": "ROUTE_MOMENT_FUEL_SCOUT",
		"signature_title_key": "MOMENT_FUEL_SCOUT",
		"signature_action_key": "MOMENT_ACTION_FUEL_SCOUT",
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
		"difficulty": 1.52,
		"spawn_interval_mult": 0.92,
		"passenger_interval_mult": 0.90,
		"kituo_gap_mult": 0.90,
		"fuel_drain_route_mult": 1.08,
		"rush_hour_chance": 0.62,
		"condition_weights": {"day": 32, "dusk": 22, "night": 18, "rain": 28},
		"flavor_key": "ROUTE_UBUNGO_D",
		"goal_key": "GOAL_UBUNGO",
		"goal_type": "score",
		"goal_target": 1200,
		"goal_reward": 100,
		"mastery_scores": [1200, 2400, 3600],
		"mastery_rewards": [25, 40, 60],
		"signature_id": "jam_breaker",
		"signature_key": "ROUTE_MOMENT_JAM_BREAKER",
		"signature_title_key": "MOMENT_JAM_BREAKER",
		"signature_action_key": "MOMENT_ACTION_JAM_BREAKER",
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

static func weighted_pick(weights: Dictionary, allowed_ids: Array, fallback_id: String,
		rng: RandomNumberGenerator = null) -> String:
	var total := 0.0
	for id in allowed_ids:
		total += max(0.0, float(weights.get(String(id), 0.0)))
	if total <= 0.0:
		return fallback_id

	var roll: float = (rng.randf() if rng != null else randf()) * total
	for id in allowed_ids:
		var item_id := String(id)
		roll -= max(0.0, float(weights.get(item_id, 0.0)))
		if roll <= 0.0:
			return item_id
	return fallback_id

## Conditions are route-weighted once the early lessons are complete. Passing a
## roll keeps the helper deterministic for contracts without changing live RNG.
static func pick_condition(route: Dictionary, roll: float = -1.0) -> String:
	var weights_value: Variant = route.get("condition_weights", {})
	if typeof(weights_value) != TYPE_DICTIONARY:
		return "day"
	var weights: Dictionary = weights_value
	var total: float = 0.0
	for id_value in CONDITION_IDS:
		total += maxf(0.0, float(weights.get(String(id_value), 0.0)))
	if total <= 0.0:
		return "day"
	var normalized_roll: float = randf() if roll < 0.0 else clampf(roll, 0.0, 0.999999)
	var remaining: float = normalized_roll * total
	for id_value in CONDITION_IDS:
		var id: String = String(id_value)
		remaining -= maxf(0.0, float(weights.get(id, 0.0)))
		if remaining <= 0.0:
			return id
	return "day"

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

## Three stars keep each route replayable without a new currency. The third
## star deliberately asks for clean driving as well as a high score.
static func mastery_stars(route: Dictionary, stats: Dictionary) -> int:
	var thresholds: Array = route.get("mastery_scores", [])
	if thresholds.size() != 3:
		return 0
	var score: int = int(stats.get("score", 0))
	var stars: int = 0
	if score >= int(thresholds[0]):
		stars = 1
	if score >= int(thresholds[1]) and is_goal_met(route, stats):
		stars = 2
	if score >= int(thresholds[2]) and is_goal_met(route, stats) \
	and int(stats.get("reputation", 0)) >= 85:
		stars = 3
	return stars

static func mastery_reward(route: Dictionary, old_stars: int, new_stars: int) -> int:
	var rewards: Array = route.get("mastery_rewards", [])
	var total: int = 0
	var start: int = clampi(old_stars, 0, 3)
	var finish: int = clampi(new_stars, start, 3)
	for index in range(start, finish):
		if index < rewards.size():
			total += maxi(0, int(rewards[index]))
	return total

## Returns the next visible target for a route. UI owns localization, while
## this data helper keeps the exact mastery rule consistent everywhere.
static func next_mastery_target(route: Dictionary, saved_stars: int) -> Dictionary:
	var stars: int = clampi(saved_stars, 0, 3)
	if stars >= 3:
		return {"complete": true, "level": 3, "score": 0, "needs_goal": false, "needs_reputation": false}
	var thresholds: Array = route.get("mastery_scores", [])
	if thresholds.size() != 3:
		return {"complete": false, "level": stars + 1, "score": 0, "needs_goal": false, "needs_reputation": false}
	return {
		"complete": false,
		"level": stars + 1,
		"score": int(thresholds[stars]),
		"needs_goal": stars >= 1,
		"needs_reputation": stars >= 2,
	}

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
