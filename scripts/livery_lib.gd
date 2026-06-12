class_name LiveryLib
## Custom paint jobs for the player's daladala: colors, patterns, slogan.
## Stored per vehicle in the save as "livery_<vehicle_id>".
## Real daladala culture: bold colors, patterns, and a slogan on the back.

const PATTERNS := ["none", "stripe", "flames", "checker"]

const BODY_PALETTE: Array = [
	Color("#1f8fff"), Color("#e63946"), Color("#f7c531"), Color("#27ae60"),
	Color("#6c5ce7"), Color("#0a0a0a"), Color("#e67e22"), Color("#f5f5f5"),
]
const ACCENT_PALETTE: Array = [
	Color("#ffd23f"), Color("#0a3d62"), Color("#f1faee"), Color("#c0392b"),
	Color("#00cec9"), Color("#d4af37"),
]

## Classic daladala slogans — players can also type their own.
const SLOGAN_PRESETS: Array = [
	"MUNGU ATUBARIKI", "SIMBA DAMU", "YANGA MOTO", "BABA LAO",
	"USIJALI", "HAKUNA MATATA", "MTAA KWA MTAA", "BOSS WA MJINI",
]

static func get_livery(vehicle: Dictionary) -> Dictionary:
	var defaults := {
		"body": (vehicle.get("body", Color("#1f8fff")) as Color).to_html(false),
		"accent": (vehicle.get("accent", Color("#ffd23f")) as Color).to_html(false),
		"pattern": "none",
		"slogan": "",
	}
	var saved: Variant = SaveSystem.get_value("livery_" + String(vehicle.get("id", "")), null)
	if typeof(saved) == TYPE_DICTIONARY:
		for k in saved.keys():
			defaults[k] = saved[k]
	return defaults

static func save_livery(vehicle_id: String, livery: Dictionary) -> void:
	SaveSystem.set_value("livery_" + vehicle_id, livery)

## Draws a complete daladala (body, livery pattern, windows, wheels,
## headlights, slogan) onto any CanvasItem. `s` is the full bus size.
static func draw_bus(ci: CanvasItem, top_left: Vector2, s: Vector2,
		body: Color, accent: Color, pattern: String, slogan: String) -> void:
	# Body
	ci.draw_rect(Rect2(top_left, s), body, true)

	# Pattern layer
	match pattern:
		"stripe":
			ci.draw_rect(Rect2(top_left + Vector2(s.x * 0.40, 0), Vector2(s.x * 0.20, s.y)), accent, true)
		"flames":
			for i in range(3):
				var fx: float = top_left.x + s.x * (0.15 + 0.35 * i)
				var pts := PackedVector2Array([
					Vector2(fx, top_left.y),
					Vector2(fx - s.x * 0.12, top_left.y + s.y * 0.30),
					Vector2(fx + s.x * 0.02, top_left.y + s.y * 0.16),
				])
				ci.draw_polygon(pts, PackedColorArray([accent, accent, accent]))
		"checker":
			var cell: float = s.x / 6.0
			for row in range(2):
				for col in range(6):
					if (row + col) % 2 == 0:
						ci.draw_rect(Rect2(
							top_left + Vector2(col * cell, s.y - (2 - row) * cell),
							Vector2(cell, cell)), accent, true)

	# Roof rack stripe
	ci.draw_rect(Rect2(top_left + Vector2(0, 10), Vector2(s.x, 8)), accent, true)
	# Windows
	var wy := top_left.y + 24
	var wh := 22.0 * (s.y / 110.0)
	ci.draw_rect(Rect2(Vector2(top_left.x + 6, wy), Vector2(s.x - 12, wh)), Color("#a8d0ff"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + 6, wy + wh + 6), Vector2(s.x - 12, wh)), Color("#a8d0ff"), true)
	# Wheels
	var wheel_col := Color("#1a1a1a")
	ci.draw_rect(Rect2(Vector2(top_left.x - 4, top_left.y + 18), Vector2(8, 24)), wheel_col, true)
	ci.draw_rect(Rect2(Vector2(top_left.x - 4, top_left.y + s.y - 42), Vector2(8, 24)), wheel_col, true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x - 4, top_left.y + 18), Vector2(8, 24)), wheel_col, true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x - 4, top_left.y + s.y - 42), Vector2(8, 24)), wheel_col, true)
	# Headlights
	ci.draw_rect(Rect2(Vector2(top_left.x + 6, top_left.y - 4), Vector2(14, 6)), Color("#fff7b3"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x - 20, top_left.y - 4), Vector2(14, 6)), Color("#fff7b3"), true)

	# Slogan on the rear (bottom of the bus, facing the camera)
	if slogan != "":
		var font := ThemeDB.fallback_font
		var fs: int = maxi(7, int(s.x * 0.115))
		var text_col: Color = accent if pattern != "stripe" else Color.WHITE
		ci.draw_string(font,
			Vector2(top_left.x, top_left.y + s.y - 6),
			slogan, HORIZONTAL_ALIGNMENT_CENTER, s.x, fs, text_col)
