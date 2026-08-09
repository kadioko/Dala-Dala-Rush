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
	# Ground shadow and chamfered minibus shell create a readable top-down profile.
	ci.draw_rect(Rect2(top_left + Vector2(4, 7), s - Vector2(2, 3)),
		Color(0.02, 0.03, 0.04, 0.30), true)
	var shell := PackedVector2Array([
		Vector2(top_left.x + 8, top_left.y), Vector2(top_left.x + s.x - 8, top_left.y),
		Vector2(top_left.x + s.x, top_left.y + 10), Vector2(top_left.x + s.x, top_left.y + s.y - 9),
		Vector2(top_left.x + s.x - 7, top_left.y + s.y), Vector2(top_left.x + 7, top_left.y + s.y),
		Vector2(top_left.x, top_left.y + s.y - 9), Vector2(top_left.x, top_left.y + 10),
	])
	ci.draw_colored_polygon(shell, body.darkened(0.24))
	var inner_shell := PackedVector2Array([
		Vector2(top_left.x + 10, top_left.y + 3), Vector2(top_left.x + s.x - 10, top_left.y + 3),
		Vector2(top_left.x + s.x - 3, top_left.y + 12), Vector2(top_left.x + s.x - 3, top_left.y + s.y - 11),
		Vector2(top_left.x + s.x - 9, top_left.y + s.y - 3), Vector2(top_left.x + 9, top_left.y + s.y - 3),
		Vector2(top_left.x + 3, top_left.y + s.y - 11), Vector2(top_left.x + 3, top_left.y + 12),
	])
	ci.draw_colored_polygon(inner_shell, body)

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

	# Roof rack, rails and centre panel.
	ci.draw_rect(Rect2(top_left + Vector2(3, 10), Vector2(s.x - 6, 8)), accent.darkened(0.10), true)
	ci.draw_line(top_left + Vector2(10, 7), top_left + Vector2(10, s.y - 14), Color("#29323a"), 2.0)
	ci.draw_line(top_left + Vector2(s.x - 10, 7), top_left + Vector2(s.x - 10, s.y - 14), Color("#29323a"), 2.0)
	for rack_y in [top_left.y + 15.0, top_left.y + 48.0, top_left.y + 81.0]:
		ci.draw_line(Vector2(top_left.x + 10, rack_y), Vector2(top_left.x + s.x - 10, rack_y),
			Color(0.12, 0.15, 0.18, 0.70), 1.5)
	# Separated glass panels with reflections read better than two flat rectangles.
	var wy: float = top_left.y + 24
	var wh: float = 22.0 * (s.y / 110.0)
	var glass := Color("#8fd3e8")
	for row in range(2):
		var window_y: float = wy + row * (wh + 7.0)
		ci.draw_rect(Rect2(Vector2(top_left.x + 7, window_y), Vector2(s.x - 14, wh)), glass.darkened(0.18), true)
		for pane in range(3):
			var pane_x: float = top_left.x + 9 + pane * (s.x - 18) / 3.0
			var pane_w: float = (s.x - 22) / 3.0
			ci.draw_rect(Rect2(Vector2(pane_x, window_y + 2), Vector2(pane_w, wh - 4)), glass, true)
			ci.draw_line(Vector2(pane_x + 2, window_y + 4), Vector2(pane_x + pane_w - 3, window_y + 4),
				Color(0.90, 0.98, 1.0, 0.55), 1.5)
	# Roof vent and rear panel details.
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x * 0.37, top_left.y + s.y * 0.70),
		Vector2(s.x * 0.26, 9)), Color("#303942"), true)
	for vent in range(3):
		ci.draw_line(Vector2(top_left.x + s.x * 0.40 + vent * 6, top_left.y + s.y * 0.72),
			Vector2(top_left.x + s.x * 0.40 + vent * 6, top_left.y + s.y * 0.76), Color("#65717b"), 1.5)
	# Wheels
	var wheel_col := Color("#1a1a1a")
	ci.draw_rect(Rect2(Vector2(top_left.x - 4, top_left.y + 18), Vector2(8, 24)), wheel_col, true)
	ci.draw_rect(Rect2(Vector2(top_left.x - 4, top_left.y + s.y - 42), Vector2(8, 24)), wheel_col, true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x - 4, top_left.y + 18), Vector2(8, 24)), wheel_col, true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x - 4, top_left.y + s.y - 42), Vector2(8, 24)), wheel_col, true)
	# Mirrors, front lights, bumper and rear brake lights.
	ci.draw_rect(Rect2(Vector2(top_left.x - 7, top_left.y + 15), Vector2(7, 10)), Color("#20262c"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x, top_left.y + 15), Vector2(7, 10)), Color("#20262c"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + 7, top_left.y - 3), Vector2(13, 6)), Color("#fff3a6"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x - 20, top_left.y - 3), Vector2(13, 6)), Color("#fff3a6"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + 12, top_left.y + 4), Vector2(s.x - 24, 3)), Color("#26313a"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + 9, top_left.y + s.y - 4), Vector2(12, 5)), Color("#e74c3c"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x - 21, top_left.y + s.y - 4), Vector2(12, 5)), Color("#e74c3c"), true)
	ci.draw_rect(Rect2(Vector2(top_left.x + s.x * 0.30, top_left.y + s.y - 2), Vector2(s.x * 0.40, 4)), Color("#d7dbdd"), true)

	# Slogan on the rear (bottom of the bus, facing the camera)
	if slogan != "":
		var font := ThemeDB.fallback_font
		var fs: int = maxi(7, int(s.x * 0.115))
		var text_col: Color = accent if pattern != "stripe" else Color.WHITE
		ci.draw_string(font,
			Vector2(top_left.x, top_left.y + s.y - 6),
			slogan, HORIZONTAL_ALIGNMENT_CENTER, s.x, fs, text_col)
