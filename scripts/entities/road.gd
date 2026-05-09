class_name Road
extends Node2D
## Scrolling road with 3-layer parallax and route-specific decorations.
## Layer speeds relative to road: far=0.18x  mid=0.44x  near=1.0x

var road_color: Color  = Color("#3d3d3d")
var sky_color: Color   = Color("#f7d794")
var view_size: Vector2 = Vector2(540, 960)
var num_lanes: int     = 3
var route_id: String   = "kariakoo"

var scroll_near: float = 0.0      # lane stripes, 1.0x
var scroll_mid: float  = 0.0      # buildings, 0.44x
var scroll_far: float  = 0.0      # skyline, 0.18x
const STRIPE_SPACING := 80.0
const MID_PERIOD     := 240.0
const FAR_PERIOD     := 340.0

func setup(view: Vector2, sky: Color, road: Color, route: String = "kariakoo") -> void:
	view_size = view
	sky_color = sky
	road_color = road
	route_id = route
	queue_redraw()

func advance(distance: float) -> void:
	scroll_near = fposmod(scroll_near + distance,        STRIPE_SPACING)
	scroll_mid  = fposmod(scroll_mid  + distance * 0.44, MID_PERIOD)
	scroll_far  = fposmod(scroll_far  + distance * 0.18, FAR_PERIOD)
	queue_redraw()

func _draw() -> void:
	var w: float = view_size.x
	var h: float = view_size.y
	var road_w: float = w * 0.8
	var road_x: float = (w - road_w) * 0.5
	var lane_w: float = road_w / num_lanes

	# ── 1. SKY ────────────────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, view_size), sky_color)

	# ── 2. FAR LAYER: distant city silhouette (very slow) ─────────
	_draw_far_layer(road_x, road_w, h)

	# ── 3. MID LAYER: route-specific buildings (slow) ─────────────
	_draw_mid_layer(road_x, road_w, h)

	# ── 4. ROAD SURFACE ───────────────────────────────────────────
	# Shoulders
	draw_rect(Rect2(Vector2(road_x - 10, 0), Vector2(10, h)), Color("#b0a090"))
	draw_rect(Rect2(Vector2(road_x + road_w, 0), Vector2(10, h)), Color("#b0a090"))
	draw_rect(Rect2(Vector2(road_x, 0), Vector2(road_w, h)), road_color)

	# ── 5. LANE MARKINGS ──────────────────────────────────────────
	for lane in range(1, num_lanes):
		var lx: float = road_x + lane * lane_w
		var y: float = -STRIPE_SPACING + scroll_near
		while y < h:
			draw_rect(Rect2(Vector2(lx - 3, y), Vector2(6, 34)), Color("#fff7b3"))
			y += STRIPE_SPACING

	# Edge white lines
	draw_rect(Rect2(Vector2(road_x - 4, 0), Vector2(4, h)), Color("#efefef"))
	draw_rect(Rect2(Vector2(road_x + road_w, 0), Vector2(4, h)), Color("#efefef"))

# ──────────────────────────────────────────────────────────────────

func _draw_far_layer(road_x: float, road_w: float, h: float) -> void:
	# Distant flat building silhouette, same shape for all routes but color varies.
	var sil_col: Color = sky_color.darkened(0.28)
	var side_l: float = road_x - 14
	var side_r: float = road_x + road_w + 4
	var widths := [side_l, view_size.x - (road_x + road_w + 4)]

	for side in range(2):
		var x0: float = 0.0 if side == 0 else road_x + road_w + 4
		var avail_w: float = widths[side]
		if avail_w <= 0:
			continue
		var bw: float = avail_w * 0.85
		# Draw 3 repeating silhouette buildings
		var period: float = FAR_PERIOD
		var y_base: float = h * 0.28
		var y: float = -period + scroll_far
		while y < h:
			for bi in range(4):
				var bh: float = [34.0, 54.0, 42.0, 28.0][bi % 4]
				var bx: float = x0 + avail_w * 0.05 + (bw / 4.0) * bi
				draw_rect(Rect2(Vector2(bx, y_base - bh), Vector2(bw / 4.0 - 3, bh)), sil_col)
			y += period

func _draw_mid_layer(road_x: float, road_w: float, h: float) -> void:
	# Left and right sides
	var side_defs := [
		{"x0": 0.0,            "w": road_x - 12},
		{"x0": road_x + road_w + 12, "w": view_size.x - (road_x + road_w + 12)},
	]
	for sd in side_defs:
		_draw_route_side(sd.x0, sd.w, h)

func _draw_route_side(x0: float, sw: float, h: float) -> void:
	if sw < 8:
		return
	var y: float = -MID_PERIOD + scroll_mid
	while y < h:
		match route_id:
			"kariakoo":  _draw_market_stall(x0, sw, y)
			"mwenge":    _draw_residential(x0, sw, y)
			"mbezi":     _draw_modern_block(x0, sw, y)
			"posta":     _draw_office_block(x0, sw, y)
			"kigamboni": _draw_coastal(x0, sw, y)
			"ubungo":    _draw_overpass(x0, sw, y)
			_:           _draw_residential(x0, sw, y)
		y += MID_PERIOD

# ── Route-specific side decorations ──────────────────────────────

func _draw_market_stall(x0: float, sw: float, y: float) -> void:
	# Kariakoo: colorful market stalls with awnings
	var bw: float = min(sw - 6, 52)
	draw_rect(Rect2(Vector2(x0 + 3, y + 40), Vector2(bw, 60)), Color("#ecf0f1"))
	# Colorful awning
	var awning_colors := [Color("#e74c3c"), Color("#3498db"), Color("#f1c40f"), Color("#27ae60")]
	var ac: Color = awning_colors[int(y * 0.01 + x0) % awning_colors.size()]
	draw_rect(Rect2(Vector2(x0, y + 30), Vector2(sw, 14)), ac)
	# Window/goods display
	draw_rect(Rect2(Vector2(x0 + 8, y + 52), Vector2(bw - 10, 18)), Color("#aed6f1"))
	# Palm tree beside it
	draw_rect(Rect2(Vector2(x0 + sw * 0.7, y + 90), Vector2(6, 30)), Color("#6e3b10"))
	draw_circle(Vector2(x0 + sw * 0.7 + 3, y + 88), 13, Color("#27ae60"))

func _draw_residential(x0: float, sw: float, y: float) -> void:
	# Mwenge: residential with trees
	var bw: float = min(sw - 8, 44)
	draw_rect(Rect2(Vector2(x0 + 4, y + 30), Vector2(bw, 80)), Color("#d5d8dc"))
	draw_rect(Rect2(Vector2(x0 + 10, y + 40), Vector2(14, 14)), Color("#2c3e50"))
	draw_rect(Rect2(Vector2(x0 + 28, y + 40), Vector2(14, 14)), Color("#2c3e50"))
	# Trees
	draw_rect(Rect2(Vector2(x0 + 2, y + 95), Vector2(5, 20)), Color("#6e3b10"))
	draw_circle(Vector2(x0 + 4, y + 92), 11, Color("#2ecc71"))
	draw_circle(Vector2(x0 + 4, y + 94), 9, Color("#27ae60"))

func _draw_modern_block(x0: float, sw: float, y: float) -> void:
	# Mbezi: newer apartment blocks, clean lines
	var bw: float = min(sw - 6, 50)
	draw_rect(Rect2(Vector2(x0 + 3, y + 10), Vector2(bw, 100)), Color("#bdc3c7"))
	# Grid windows
	for row in range(4):
		for col in range(2):
			draw_rect(Rect2(Vector2(x0 + 10 + col * 18, y + 18 + row * 22), Vector2(12, 14)), Color("#2980b9"))

func _draw_office_block(x0: float, sw: float, y: float) -> void:
	# Posta: tall glass office buildings
	var bw: float = min(sw - 4, 48)
	draw_rect(Rect2(Vector2(x0 + 2, y - 10), Vector2(bw, 130)), Color("#95a5a6"))
	for row in range(6):
		draw_rect(Rect2(Vector2(x0 + 6, y + 4 + row * 20), Vector2(bw - 8, 14)), Color("#5dade2", 0.7))
	# Antenna
	draw_rect(Rect2(Vector2(x0 + bw * 0.5, y - 24), Vector2(3, 18)), Color("#7f8c8d"))

func _draw_coastal(x0: float, sw: float, y: float) -> void:
	# Kigamboni: palms, water hint in sky gap
	draw_rect(Rect2(Vector2(x0, y + 60), Vector2(sw, 60)), Color("#a2d9ce", 0.5))  # water tint
	# Two palms
	for i in range(2):
		var px: float = x0 + sw * (0.25 + i * 0.5)
		draw_rect(Rect2(Vector2(px - 3, y + 70), Vector2(6, 40)), Color("#6e3b10"))
		# Fronds
		draw_line(Vector2(px, y + 68), Vector2(px - 20, y + 52), Color("#27ae60"), 3)
		draw_line(Vector2(px, y + 68), Vector2(px + 18, y + 50), Color("#27ae60"), 3)
		draw_line(Vector2(px, y + 68), Vector2(px, y + 42), Color("#27ae60"), 3)

func _draw_overpass(x0: float, sw: float, y: float) -> void:
	# Ubungo: concrete pillars + bridge deck
	var pillar_x: float = x0 + sw * 0.4
	# Pillar
	draw_rect(Rect2(Vector2(pillar_x, y + 20), Vector2(14, 90)), Color("#7f8c8d"))
	# Cross beam
	draw_rect(Rect2(Vector2(x0, y + 18), Vector2(sw, 10)), Color("#95a5a6"))
	# Guardrail dots
	for d in range(4):
		draw_circle(Vector2(x0 + 5 + d * (sw / 4), y + 14), 3, Color("#bdc3c7"))
