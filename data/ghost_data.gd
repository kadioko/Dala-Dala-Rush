class_name GhostData
## Validation and compact sharing for offline ghost runs.
## Imported clipboard data is untrusted and must pass through sanitize().

const CODE_PREFIX := "DDRTZ-GHOST:"
const MAX_CODE_CHARS := 65536
const MAX_EVENTS := 2048
const MIN_DURATION := 5.0
const MAX_DURATION := 21600.0
const MAX_SCORE := 1000000000
const ROUTE_IDS := ["kariakoo", "mwenge", "mbezi", "posta", "kigamboni", "ubungo", "arusha"]
const MAX_SEED := 2147483647

static func sanitize(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var events_value: Variant = source.get("events", null)
	if typeof(events_value) != TYPE_ARRAY:
		return {}
	var source_events := events_value as Array
	if source_events.size() > MAX_EVENTS:
		return {}

	var end_value: Variant = source.get("end", null)
	if typeof(end_value) not in [TYPE_INT, TYPE_FLOAT]:
		return {}
	var end_time := float(end_value)
	if is_nan(end_time) or is_inf(end_time) \
		or end_time < MIN_DURATION or end_time > MAX_DURATION:
		return {}

	var clean_events: Array = []
	var previous_time := -1.0
	for event_value in source_events:
		if typeof(event_value) != TYPE_ARRAY:
			return {}
		var event := event_value as Array
		if event.size() < 2:
			return {}
		if typeof(event[0]) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(event[1]) not in [TYPE_INT, TYPE_FLOAT]:
			return {}
		var event_time := float(event[0])
		var lane := int(event[1])
		if is_nan(event_time) or is_inf(event_time) \
			or event_time < previous_time or event_time < 0.0 \
			or event_time > end_time or lane < 0 or lane > 2:
			return {}
		clean_events.append([event_time, lane])
		previous_time = event_time
	if clean_events.is_empty():
		clean_events.append([0.0, 1])

	var score_value: Variant = source.get("score", 0)
	if typeof(score_value) not in [TYPE_INT, TYPE_FLOAT]:
		return {}
	var score := clampi(int(score_value), 0, MAX_SCORE)
	var player_name := String(source.get("name", "RIVAL")) \
		.strip_edges().to_upper().substr(0, 8)
	if player_name.is_empty():
		player_name = "RIVAL"
	var route_id := String(source.get("route", "")).strip_edges().to_lower()
	if not route_id.is_empty() and route_id not in ROUTE_IDS:
		return {}
	var vehicle_id := String(source.get("vehicle_id", "")).strip_edges().to_lower()
	if vehicle_id.length() > 32 or not vehicle_id.is_valid_identifier() and not vehicle_id.is_empty():
		return {}
	var challenge_id := String(source.get("challenge_id", "")).strip_edges()
	if challenge_id.length() > 40 or (not challenge_id.is_empty() and not challenge_id.begins_with("route_daily_")):
		return {}
	var traffic_seed_value: Variant = source.get("traffic_seed", 0)
	if typeof(traffic_seed_value) not in [TYPE_INT, TYPE_FLOAT]:
		return {}
	var traffic_seed: int = int(traffic_seed_value)
	if traffic_seed < 0 or traffic_seed > MAX_SEED:
		return {}
	return {
		"version": 2,
		"events": clean_events,
		"end": end_time,
		"score": score,
		"name": player_name,
		"route": route_id,
		"vehicle_id": vehicle_id,
		"challenge_id": challenge_id,
		"traffic_seed": traffic_seed,
	}

static func matches_daily_challenge(value: Variant, challenge: Dictionary) -> bool:
	var clean := sanitize(value)
	if clean.is_empty() or challenge.is_empty():
		return false
	return String(clean.get("challenge_id", "")) == String(challenge.get("id", "")) \
		and String(clean.get("route", "")) == String(challenge.get("route_id", "")) \
		and String(clean.get("vehicle_id", "")) == String(challenge.get("vehicle_id", "")) \
		and int(clean.get("traffic_seed", -1)) == int(challenge.get("traffic_seed", -2))

static func encode(value: Variant) -> String:
	var clean := sanitize(value)
	if clean.is_empty():
		return ""
	return CODE_PREFIX + Marshalls.utf8_to_base64(JSON.stringify(clean))

static func decode(text: String) -> Dictionary:
	var code := text.strip_edges()
	if not code.begins_with(CODE_PREFIX) or code.length() > MAX_CODE_CHARS:
		return {}
	var json_text := Marshalls.base64_to_utf8(code.trim_prefix(CODE_PREFIX))
	if json_text.is_empty():
		return {}
	return sanitize(JSON.parse_string(json_text))
