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
	draw_rect(Rect2(Vector2(road_x - 12, 0), Vector2(12, h)), Color("#9b9187"))
	draw_rect(Rect2(Vector2(road_x + road_w, 0), Vector2(12, h)), Color("#9b9187"))
	draw_rect(Rect2(Vector2(road_x, 0), Vector2(road_w, h)), road_color)
	# Subtle asphalt repairs add motion and texture without competing with obstacles.
	var patch_y: float = -170.0 + fposmod(scroll_near * 1.7, 170.0)
	var patch_index: int = 0
	while patch_y < h:
		var patch_x: float = road_x + lane_w * (0.35 + float(patch_index % num_lanes))
		draw_rect(Rect2(Vector2(patch_x, patch_y), Vector2(lane_w * 0.30, 9)), road_color.darkened(0.09), true)
		draw_line(Vector2(patch_x + 5, patch_y + 3), Vector2(patch_x + lane_w * 0.23, patch_y + 6),
			road_color.lightened(0.07), 1.0)
		patch_y += 170.0
		patch_index += 1

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
	_draw_curbs_and_street_furniture(road_x, road_w, h)

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
	draw_rect(Rect2(Vector2(x0 + 6, y + 44), Vector2(bw, 60)), Color(0.02, 0.03, 0.04, 0.20))
	draw_rect(Rect2(Vector2(x0 + 3, y + 40), Vector2(bw, 60)), Color("#ecf0f1"))
	# Colorful awning
	var awning_colors := [Color("#e74c3c"), Color("#3498db"), Color("#f1c40f"), Color("#27ae60")]
	var ac: Color = awning_colors[int(y * 0.01 + x0) % awning_colors.size()]
	draw_rect(Rect2(Vector2(x0, y + 30), Vector2(sw, 14)), ac.darkened(0.12))
	var awning_w: float = maxf(6.0, sw / 5.0)
	for stripe in range(5):
		draw_rect(Rect2(Vector2(x0 + stripe * awning_w, y + 30), Vector2(awning_w * 0.55, 14)), ac.lightened(0.26), true)
	# Window/goods display
	draw_rect(Rect2(Vector2(x0 + 8, y + 52), Vector2(bw - 10, 18)), Color("#aed6f1"))
	for goods_x in range(3):
		draw_circle(Vector2(x0 + 12 + goods_x * 10, y + 77), 4.0,
			[Color("#e74c3c"), Color("#f1c40f"), Color("#27ae60")][goods_x])
	draw_rect(Rect2(Vector2(x0 + 8, y + 85), Vector2(bw - 12, 5)), Color("#8d6e63"), true)
	# Palm tree beside it
	_draw_tree(Vector2(x0 + sw * 0.76, y + 102), 0.8)

func _draw_residential(x0: float, sw: float, y: float) -> void:
	# Mwenge: residential with trees
	var bw: float = min(sw - 8, 44)
	draw_rect(Rect2(Vector2(x0 + 7, y + 35), Vector2(bw, 80)), Color(0.02, 0.03, 0.04, 0.18))
	draw_rect(Rect2(Vector2(x0 + 4, y + 30), Vector2(bw, 80)), Color("#d5d8dc"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x0 + 1, y + 31), Vector2(x0 + bw * 0.5 + 4, y + 17), Vector2(x0 + bw + 7, y + 31),
	]), Color("#c05a47"))
	draw_rect(Rect2(Vector2(x0 + 10, y + 40), Vector2(14, 14)), Color("#2c3e50"))
	draw_rect(Rect2(Vector2(x0 + 28, y + 40), Vector2(14, 14)), Color("#2c3e50"))
	draw_rect(Rect2(Vector2(x0 + bw * 0.38, y + 78), Vector2(14, 32)), Color("#8d6e63"), true)
	# Trees
	_draw_tree(Vector2(x0 + 5, y + 109), 0.7)

func _draw_modern_block(x0: float, sw: float, y: float) -> void:
	# Mbezi: newer apartment blocks, clean lines
	var bw: float = min(sw - 6, 50)
	draw_rect(Rect2(Vector2(x0 + 6, y + 15), Vector2(bw, 100)), Color(0.02, 0.03, 0.04, 0.18))
	draw_rect(Rect2(Vector2(x0 + 3, y + 10), Vector2(bw, 100)), Color("#bdc3c7"))
	draw_rect(Rect2(Vector2(x0 + 3, y + 10), Vector2(7, 100)), Color("#f5f6f7"), true)
	# Grid windows
	for row in range(4):
		for col in range(2):
			draw_rect(Rect2(Vector2(x0 + 10 + col * 18, y + 18 + row * 22), Vector2(12, 14)), Color("#2980b9"))
		draw_line(Vector2(x0 + 8, y + 36 + row * 22), Vector2(x0 + bw, y + 36 + row * 22), Color("#7f8c8d"), 2.0)

func _draw_office_block(x0: float, sw: float, y: float) -> void:
	# Posta: tall glass office buildings
	var bw: float = min(sw - 4, 48)
	draw_rect(Rect2(Vector2(x0 + 5, y - 5), Vector2(bw, 130)), Color(0.02, 0.03, 0.04, 0.18))
	draw_rect(Rect2(Vector2(x0 + 2, y - 10), Vector2(bw, 130)), Color("#758b99"))
	for row in range(6):
		draw_rect(Rect2(Vector2(x0 + 6, y + 4 + row * 20), Vector2(bw - 8, 14)), Color("#5dade2", 0.78))
		draw_line(Vector2(x0 + bw * 0.5, y + 5 + row * 20), Vector2(x0 + bw * 0.5, y + 17 + row * 20), Color("#d6eef8"), 1.0)
	# Antenna
	draw_rect(Rect2(Vector2(x0 + bw * 0.5, y - 24), Vector2(3, 18)), Color("#7f8c8d"))

func _draw_coastal(x0: float, sw: float, y: float) -> void:
	# Kigamboni: palms, water hint in sky gap
	draw_rect(Rect2(Vector2(x0, y + 60), Vector2(sw, 60)), Color("#a2d9ce", 0.5))  # water tint
	# Two palms
	for i in range(2):
		var px: float = x0 + sw * (0.25 + i * 0.5)
		draw_line(Vector2(px - 3, y + 110), Vector2(px, y + 68), Color("#8d5a2b"), 6.0, true)
		# Fronds
		draw_line(Vector2(px, y + 68), Vector2(px - 20, y + 52), Color("#27ae60"), 3)
		draw_line(Vector2(px, y + 68), Vector2(px + 18, y + 50), Color("#27ae60"), 3)
		draw_line(Vector2(px, y + 68), Vector2(px, y + 42), Color("#27ae60"), 3)
		draw_line(Vector2(px, y + 68), Vector2(px - 22, y + 70), Color("#1e8449"), 3)
		draw_line(Vector2(px, y + 68), Vector2(px + 22, y + 70), Color("#1e8449"), 3)

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

func _draw_curbs_and_street_furniture(road_x: float, road_w: float, h: float) -> void:
	# Alternating curb blocks, storm drains, lights and route-colored signs.
	var curb_y: float = -48.0 + fposmod(scroll_near, 48.0)
	var curb_index: int = 0
	while curb_y < h:
		var curb_color := Color("#f4f6f7") if curb_index % 2 == 0 else Color("#4d5656")
		draw_rect(Rect2(Vector2(road_x - 8, curb_y), Vector2(5, 24)), curb_color, true)
		draw_rect(Rect2(Vector2(road_x + road_w + 3, curb_y), Vector2(5, 24)), curb_color, true)
		curb_y += 24.0
		curb_index += 1

	var furniture_y: float = -220.0 + fposmod(scroll_mid, 220.0)
	var route_color := _route_accent()
	while furniture_y < h:
		for side in [-1, 1]:
			var edge_x: float = road_x - 13.0 if side < 0 else road_x + road_w + 13.0
			draw_line(Vector2(edge_x, furniture_y + 8), Vector2(edge_x, furniture_y + 66), Color("#59636b"), 3.0, true)
			draw_line(Vector2(edge_x, furniture_y + 8), Vector2(edge_x + 10.0 * -side, furniture_y + 8), Color("#59636b"), 3.0, true)
			draw_circle(Vector2(edge_x + 11.0 * -side, furniture_y + 9), 4.5, Color("#fff3a6"))
			draw_circle(Vector2(edge_x, furniture_y + 37), 8.0, route_color)
			draw_circle(Vector2(edge_x, furniture_y + 37), 4.5, Color("#f4f8fb"))
		furniture_y += 220.0

	var drain_y: float = -150.0 + fposmod(scroll_near * 0.9, 150.0)
	while drain_y < h:
		for drain_x in [road_x + 5.0, road_x + road_w - 17.0]:
			draw_rect(Rect2(Vector2(drain_x, drain_y), Vector2(12, 20)), Color("#343a40"), true)
			for slit in range(3):
				draw_line(Vector2(drain_x + 3 + slit * 3, drain_y + 3), Vector2(drain_x + 3 + slit * 3, drain_y + 17), Color("#69727a"), 1.0)
		drain_y += 150.0

func _route_accent() -> Color:
	match route_id:
		"kariakoo": return Color("#e74c3c")
		"mwenge": return Color("#27ae60")
		"mbezi": return Color("#f0b429")
		"posta": return Color("#3498db")
		"kigamboni": return Color("#00a8a8")
		"ubungo": return Color("#e67e22")
	return Color("#1f8fff")

func _draw_tree(base: Vector2, scale_factor: float) -> void:
	draw_line(base, base + Vector2(0, -28) * scale_factor, Color("#7b4a23"), 5.0 * scale_factor, true)
	var crown: Vector2 = base + Vector2(0, -31) * scale_factor
	draw_circle(crown + Vector2(-7, 0) * scale_factor, 10.0 * scale_factor, Color("#1e8449"))
	draw_circle(crown + Vector2(7, 1) * scale_factor, 11.0 * scale_factor, Color("#239b56"))
	draw_circle(crown + Vector2(0, -7) * scale_factor, 12.0 * scale_factor, Color("#2ecc71"))
