class_name RouteContracts
## One compact daily contract per route. Contracts add a short-term reason to
## revisit a familiar route without introducing another currency or live timer.

const CONTRACTS := {
	"kariakoo": [
		{"id": "k_fares", "key": "CONTRACT_FARES", "type": "fares", "target": 16, "reward": 30},
		{"id": "k_passengers", "key": "CONTRACT_PASSENGERS", "type": "passengers", "target": 6, "reward": 28},
	],
	"mwenge": [
		{"id": "m_near", "key": "CONTRACT_NEAR_MISSES", "type": "near_misses", "target": 4, "reward": 32},
		{"id": "m_horn", "key": "CONTRACT_HORN", "type": "horn_uses", "target": 3, "reward": 28},
	],
	"mbezi": [
		{"id": "mb_distance", "key": "CONTRACT_DISTANCE", "type": "distance", "target": 900, "reward": 35},
		{"id": "mb_score", "key": "CONTRACT_SCORE", "type": "score", "target": 650, "reward": 30},
	],
	"posta": [
		{"id": "p_checkpoint", "key": "CONTRACT_CHECKPOINT", "type": "clean_checkpoints", "target": 1, "reward": 36},
		{"id": "p_near", "key": "CONTRACT_NEAR_MISSES", "type": "near_misses", "target": 3, "reward": 30},
	],
	"kigamboni": [
		{"id": "ki_moment", "key": "CONTRACT_ROUTE_MOMENT", "type": "route_moments", "target": 1, "reward": 38},
		{"id": "ki_coins", "key": "CONTRACT_COINS", "type": "coins", "target": 12, "reward": 30},
	],
	"ubungo": [
		{"id": "u_horn", "key": "CONTRACT_HORN", "type": "horn_uses", "target": 3, "reward": 40},
		{"id": "u_boost", "key": "CONTRACT_BOOSTS", "type": "boosts", "target": 1, "reward": 36},
	],
	"arusha": [
		{"id": "a_distance", "key": "CONTRACT_DISTANCE", "type": "distance", "target": 800, "reward": 38},
		{"id": "a_passengers", "key": "CONTRACT_PASSENGERS", "type": "passengers", "target": 5, "reward": 34},
	],
}

static func today_key() -> String:
	return Time.get_date_string_from_system(false)

## A deterministic date seed lets every player see the same contract for a
## route on a given day without requiring an account or a network request.
static func current(route_id: String, date_key: String = "") -> Dictionary:
	var choices_value: Variant = CONTRACTS.get(route_id, [])
	if typeof(choices_value) != TYPE_ARRAY or (choices_value as Array).is_empty():
		return {}
	var seed_text: String = route_id + (today_key() if date_key.is_empty() else date_key)
	var seed: int = 0
	for byte_value in seed_text.to_utf8_buffer():
		seed += int(byte_value)
	var choices: Array = choices_value
	return (choices[seed % choices.size()] as Dictionary).duplicate(true)

static func is_available(route_id: String) -> bool:
	return int(SaveSystem.get_value("total_runs", 0)) >= 3 and CONTRACTS.has(route_id)

static func is_completed_today(route_id: String) -> bool:
	var claims_value: Variant = SaveSystem.get_value("route_contract_claimed_on", {})
	if typeof(claims_value) != TYPE_DICTIONARY:
		return false
	return String((claims_value as Dictionary).get(route_id, "")) == today_key()

static func mark_completed(route_id: String) -> bool:
	if route_id.is_empty() or is_completed_today(route_id):
		return false
	var claims_value: Variant = SaveSystem.get_value("route_contract_claimed_on", {})
	var claims: Dictionary = (claims_value as Dictionary).duplicate(true) \
		if typeof(claims_value) == TYPE_DICTIONARY else {}
	claims[route_id] = today_key()
	SaveSystem.set_value("route_contract_claimed_on", claims)
	return true

static func is_met(contract: Dictionary, stats: Dictionary) -> bool:
	return _value(String(contract.get("type", "score")), stats) >= float(contract.get("target", 0))

static func progress(contract: Dictionary, stats: Dictionary) -> String:
	var contract_type: String = String(contract.get("type", "score"))
	var target: float = float(contract.get("target", 0))
	var current_value: float = minf(_value(contract_type, stats), target)
	if contract_type == "distance":
		return "%dm/%dm" % [int(current_value), int(target)]
	return "%d/%d" % [int(current_value), int(target)]

static func describe(contract: Dictionary) -> String:
	return LocaleManager.t(String(contract.get("key", ""))).replace(
		"{n}", str(int(contract.get("target", 0))))

static func _value(contract_type: String, stats: Dictionary) -> float:
	match contract_type:
		"distance":
			return float(stats.get("distance", 0.0))
		"clean_checkpoints":
			return float(stats.get("clean_checkpoints", 0))
		"route_moments":
			return float(stats.get("route_moments", 0))
		_:
			return float(stats.get(contract_type, 0))
