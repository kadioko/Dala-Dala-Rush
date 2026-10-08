class_name DailyRouteChallenge
## A deterministic, offline daily run. Every player receives the same route,
## starter vehicle, traffic seed, and gameplay rules for a given UTC date.
## Scores remain unverified until a future server-side run validator exists.

const ROUTE_IDS: Array[String] = ["kariakoo", "mwenge", "mbezi", "posta", "kigamboni", "ubungo"]
const STARTER_VEHICLE_ID := "classic_blue"

static func today_key() -> String:
	return Time.get_date_string_from_system(true)

static func current() -> Dictionary:
	var date: String = today_key()
	var seed_value: int = 216613626
	for index in range(date.length()):
		seed_value = int((seed_value * 16777619 + date.unicode_at(index)) & 0x7fffffff)
	return {
		"id": "route_daily_" + date,
		"date": date,
		"route_id": ROUTE_IDS[posmod(seed_value, ROUTE_IDS.size())],
		"vehicle_id": STARTER_VEHICLE_ID,
		"traffic_seed": seed_value,
		"revives_allowed": false,
	}
