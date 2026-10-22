class_name DailyRouteChallenge
## An offline daily shared setup: route, starter vehicle, seed and rules.
## Traffic remains adaptive to steering; this is not an identical course.
## Scores remain unverified until a future server-side run validator exists.

const ROUTE_IDS: Array[String] = ["kariakoo", "mwenge", "mbezi", "posta", "kigamboni", "ubungo"]
const STARTER_VEHICLE_ID := "classic_blue"
const RULES_VERSION := 2

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
		"rules_version": RULES_VERSION,
	}
