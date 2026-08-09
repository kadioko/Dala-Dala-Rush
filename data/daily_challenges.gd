class_name DailyChallenges
## Offline daily challenge helper.
## Picks a deterministic challenge from the local date, no network/account required.

const LIST: Array = [
	{
		"id": "daily_passengers",
		"key": "DAILY_PASSENGERS",
		"type": "passengers",
		"target": 10,
		"reward": 60,
	},
	{
		"id": "daily_coins",
		"key": "DAILY_COINS",
		"type": "coins",
		"target": 25,
		"reward": 70,
	},
	{
		"id": "daily_distance",
		"key": "DAILY_DISTANCE",
		"type": "distance",
		"target": 2200,
		"reward": 80,
	},
	{
		"id": "daily_near_misses",
		"key": "DAILY_NEAR_MISSES",
		"type": "near_misses",
		"target": 8,
		"reward": 90,
	},
	{
		"id": "daily_score",
		"key": "DAILY_SCORE",
		"type": "score",
		"target": 1500,
		"reward": 100,
	},
]

static func today_key() -> String:
	return Time.get_date_string_from_system(false)

static func current() -> Dictionary:
	var date := today_key()
	var parts := date.split("-")
	var day_seed := 0
	for part in parts:
		day_seed += int(part)
	return LIST[day_seed % LIST.size()]

static func is_completed_today() -> bool:
	return SaveSystem.get_value("daily_challenge_claimed_date", "") == today_key()

static func mark_completed_today() -> void:
	SaveSystem.begin_batch()
	SaveSystem.set_value("daily_challenge_claimed_date", today_key())
	SaveSystem.set_value(
		"daily_challenges_completed",
		int(SaveSystem.get_value("daily_challenges_completed", 0)) + 1
	)
	SaveSystem.end_batch()

static func is_met(challenge: Dictionary, stats: Dictionary) -> bool:
	return _value(String(challenge.get("type", "score")), stats) >= float(challenge.get("target", 0))

static func progress(challenge: Dictionary, stats: Dictionary) -> String:
	var challenge_type := String(challenge.get("type", "score"))
	var target := float(challenge.get("target", 0))
	var current_value: float = minf(_value(challenge_type, stats), target)
	if challenge_type == "distance":
		return "%dm/%dm" % [int(current_value), int(target)]
	return "%d/%d" % [int(current_value), int(target)]

static func empty_progress(challenge: Dictionary) -> String:
	var target := int(challenge.get("target", 0))
	if String(challenge.get("type", "score")) == "distance":
		return "0m/%dm" % target
	return "0/%d" % target

static func _value(challenge_type: String, stats: Dictionary) -> float:
	match challenge_type:
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
