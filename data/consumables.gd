class_name Consumables
## One-run consumable items sold in the shop for coins.
## Owned items are auto-used at the start of the next run (one of each).

const LIST: Array = [
	{
		"id": "head_start_shield",
		"name_key": "ITEM_SHIELD",
		"desc_key": "ITEM_SHIELD_D",
		"price": 40,
		"icon": "★",
		"color": Color("#1f8fff"),
	},
	{
		"id": "horn_pack",
		"name_key": "ITEM_HORN",
		"desc_key": "ITEM_HORN_D",
		"price": 30,
		"icon": "📯",
		"color": Color("#e67e22"),
	},
	{
		"id": "fuel_saver",
		"name_key": "ITEM_FUEL",
		"desc_key": "ITEM_FUEL_D",
		"price": 25,
		"icon": "⛽",
		"color": Color("#2ecc71"),
	},
]

static func get_by_id(id: String) -> Dictionary:
	for c in LIST:
		if c.id == id:
			return c
	return {}
