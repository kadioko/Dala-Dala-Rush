class_name Vehicles
## Vehicle catalog. Add new dala dalas by appending entries to LIST.
## To add a new vehicle: pick an id, name key, price, colors, and small perk stats.

const LIST: Array = [
	{
		"id": "classic_blue",
		"name_key": "VEH_CLASSIC_BLUE",
		"price": 0,
		"body": Color("#1f8fff"),
		"accent": Color("#ffd23f"),
		"lane_time": 0.14,
		"fuel_drain_mult": 1.0,
		"coin_mult": 1.0,
		"horn_charges": 3,
	},
	{
		"id": "kariakoo_yellow",
		"name_key": "VEH_KARIAKOO_YELLOW",
		"price": 250,
		"body": Color("#f7c531"),
		"accent": Color("#0a3d62"),
		"lane_time": 0.13,
		"fuel_drain_mult": 1.03,
		"coin_mult": 1.12,
		"horn_charges": 3,
	},
	{
		"id": "mwendokasi_red",
		"name_key": "VEH_MWENDOKASI_RED",
		"price": 500,
		"body": Color("#e63946"),
		"accent": Color("#f1faee"),
		"lane_time": 0.11,
		"fuel_drain_mult": 1.08,
		"coin_mult": 1.0,
		"horn_charges": 3,
	},
	{
		"id": "night_bus",
		"name_key": "VEH_NIGHT_BUS",
		"price": 750,
		"body": Color("#2d3142"),
		"accent": Color("#7c3aed"),
		"lane_time": 0.15,
		"fuel_drain_mult": 0.88,
		"coin_mult": 1.0,
		"horn_charges": 4,
	},
	{
		"id": "vip",
		"name_key": "VEH_VIP",
		"price": 1500,
		"body": Color("#0a0a0a"),
		"accent": Color("#d4af37"),
		"lane_time": 0.12,
		"fuel_drain_mult": 0.92,
		"coin_mult": 1.18,
		"horn_charges": 4,
	},
	{
		"id": "old_school",
		"name_key": "VEH_OLD_SCHOOL",
		"price": 1000,
		"body": Color("#7d8a4a"),
		"accent": Color("#c0392b"),
		"lane_time": 0.17,
		"fuel_drain_mult": 0.78,
		"coin_mult": 1.08,
		"horn_charges": 3,
	},
]

static func get_by_id(id: String) -> Dictionary:
	for v in LIST:
		if v.id == id:
			return v
	return LIST[0]
