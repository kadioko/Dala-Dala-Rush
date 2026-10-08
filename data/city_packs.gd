class_name CityPacks
## City catalog. Route gameplay remains data-driven so a new city can add
## routes without duplicating the driving scene or vehicle systems.

const LIST: Array[Dictionary] = [
	{
		"id": "dar",
		"name_key": "CITY_DAR",
		"routes": ["kariakoo", "mwenge", "mbezi", "posta", "kigamboni", "ubungo"],
		"status": "live",
	},
	{
		"id": "arusha",
		"name_key": "CITY_ARUSHA",
		"routes": ["arusha"],
		"status": "live",
	},
]

static func get_by_id(city_id: String) -> Dictionary:
	for pack in LIST:
		if String(pack.get("id", "")) == city_id:
			return pack
	return {}

static func route_ids() -> Array[String]:
	var ids: Array[String] = []
	for pack in LIST:
		for value in pack.get("routes", []):
			var route_id := String(value)
			if route_id not in ids:
				ids.append(route_id)
	return ids
