class_name Obstacle
extends Node2D
## Generic obstacle. Type controls draw + size.
## Add a new obstacle: append a TYPES entry (id, color, size, draw_fn key).

const TYPES := {
	"bodaboda":   {"color": Color("#e74c3c"), "size": Vector2(46, 70)},
	"bajaji":     {"color": Color("#27ae60"), "size": Vector2(60, 80)},
	"car":        {"color": Color("#9b59b6"), "size": Vector2(70, 100)},
	"pothole":    {"color": Color("#1a1a1a"), "size": Vector2(72, 28)},
	"cone":       {"color": Color("#ff7f00"), "size": Vector2(28, 38)},
	"police":     {"color": Color("#1f4e79"), "size": Vector2(80, 110)},
	"barrier":    {"color": Color("#f1c40f"), "size": Vector2(80, 22)},
	"truck":      {"color": Color("#34495e"), "size": Vector2(76, 130)},
	"pedestrian": {"color": Color("#fdcb6e"), "size": Vector2(80, 22)},
	"tire":       {"color": Color("#2c3e50"), "size": Vector2(36, 36)},
	"mbuzi":      {"color": Color("#d7ccc8"), "size": Vector2(44, 52)},
}

var type_id: String = "car"
var size: Vector2 = Vector2(70, 100)
var color: Color = Color("#9b59b6")
var active: bool = false
var _tex: Texture2D = null
# Movement behaviour (used by game.gd): weaving / wandering
var base_x: float = 0.0
var drift_phase: float = 0.0
var walk_dir: int = 1
var warning_announced: bool = false
var visual_variant: int = 0

func setup(t: String, lane_x: float, top_y: float) -> void:
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	z_index = 0
	type_id = t
	var def: Dictionary = TYPES.get(t, TYPES["car"])
	color = def.color
	visual_variant = randi() % 4
	if t == "car":
		var car_colors: Array[Color] = [Color("#9b59b6"), Color("#e85d75"), Color("#2d98da"), Color("#f0b429")]
		color = car_colors[visual_variant]
	elif t == "bajaji":
		var bajaji_colors: Array[Color] = [Color("#27ae60"), Color("#f1c40f"), Color("#2980b9"), Color("#e67e22")]
		color = bajaji_colors[visual_variant]
	size = def.size
	position = Vector2(lane_x, top_y)
	base_x = lane_x
	drift_phase = randf() * TAU
	walk_dir = 1 if randf() < 0.5 else -1
	warning_announced = false
	_tex = SpriteLib.get_tex("obstacle", t)
	active = true
	visible = true
	queue_redraw()

func get_aabb() -> Rect2:
	return Rect2(global_position - size * 0.5, size)

## Keep collision inside the visible object so a clean-looking dodge is safe.
func get_collision_aabb() -> Rect2:
	var hit_scale := Vector2(0.84, 0.84)
	match type_id:
		"pothole", "cone", "tire":
			hit_scale = Vector2(0.72, 0.72)
		"pedestrian", "barrier":
			hit_scale = Vector2(0.78, 0.68)
	var hit_size: Vector2 = size * hit_scale
	return Rect2(global_position - hit_size * 0.5, hit_size)

func deactivate() -> void:
	active = false
	visible = false

func _draw() -> void:
	var top_left := -size * 0.5
	if _tex:
		draw_texture_rect(_tex, Rect2(top_left, size), false)
		return
	match type_id:
		"bodaboda": _draw_bodaboda(top_left)
		"bajaji": _draw_bajaji(top_left)
		"car": _draw_car(top_left, color, false)
		"police": _draw_car(top_left, Color("#1f4e79"), true)
		"truck": _draw_truck(top_left)
		"pothole": _draw_pothole()
		"cone": _draw_cone(top_left)
		"barrier": _draw_barrier(top_left)
		"pedestrian": _draw_crossing(top_left)
		"tire": _draw_tire()
		"mbuzi": _draw_goat(top_left)

func _draw_vehicle_shadow(top_left: Vector2, inset: float = 3.0) -> void:
	draw_rect(Rect2(top_left + Vector2(inset + 3.0, 6.0), size - Vector2(inset * 2.0, 4.0)),
		Color(0.02, 0.03, 0.04, 0.30), true)

func _vehicle_outline(top_left: Vector2, inset: float = 0.0) -> PackedVector2Array:
	var left: float = top_left.x + inset
	var right: float = top_left.x + size.x - inset
	var top: float = top_left.y
	var bottom: float = top_left.y + size.y
	return PackedVector2Array([
		Vector2(left + 7, top), Vector2(right - 7, top), Vector2(right, top + 10),
		Vector2(right, bottom - 12), Vector2(right - 8, bottom), Vector2(left + 8, bottom),
		Vector2(left, bottom - 12), Vector2(left, top + 10),
	])

func _draw_wheels(top_left: Vector2, front_y: float, rear_y: float, wheel_h: float = 20.0) -> void:
	for wheel_y in [front_y, rear_y]:
		draw_rect(Rect2(Vector2(top_left.x - 4, wheel_y), Vector2(8, wheel_h)), Color("#15191d"), true)
		draw_rect(Rect2(Vector2(top_left.x + size.x - 4, wheel_y), Vector2(8, wheel_h)), Color("#15191d"), true)
		draw_rect(Rect2(Vector2(top_left.x - 2, wheel_y + 4), Vector2(4, wheel_h - 8)), Color("#515a62"), true)
		draw_rect(Rect2(Vector2(top_left.x + size.x - 2, wheel_y + 4), Vector2(4, wheel_h - 8)), Color("#515a62"), true)

func _draw_car(top_left: Vector2, body_color: Color, is_police: bool) -> void:
	_draw_vehicle_shadow(top_left)
	_draw_wheels(top_left, top_left.y + 17, top_left.y + size.y - 38, 21)
	draw_colored_polygon(_vehicle_outline(top_left, 2.0), body_color.darkened(0.20))
	draw_colored_polygon(_vehicle_outline(top_left + Vector2(3, 3), 5.0), body_color)
	# Roof and glass separate the bonnet, cabin, and boot at a glance.
	var glass := Color("#8fd3e8")
	draw_colored_polygon(PackedVector2Array([
		Vector2(top_left.x + 12, top_left.y + 21), Vector2(top_left.x + size.x - 12, top_left.y + 21),
		Vector2(top_left.x + size.x - 9, top_left.y + 40), Vector2(top_left.x + 9, top_left.y + 40),
	]), glass.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([
		Vector2(top_left.x + 9, top_left.y + 49), Vector2(top_left.x + size.x - 9, top_left.y + 49),
		Vector2(top_left.x + size.x - 13, top_left.y + 70), Vector2(top_left.x + 13, top_left.y + 70),
	]), glass)
	draw_line(Vector2(top_left.x + size.x * 0.5, top_left.y + 22),
		Vector2(top_left.x + size.x * 0.5, top_left.y + 69), body_color.darkened(0.34), 2.0)
	if is_police:
		draw_rect(Rect2(Vector2(top_left.x + 2, top_left.y + 43), Vector2(size.x - 4, 10)), Color.WHITE, true)
		draw_rect(Rect2(Vector2(top_left.x + size.x * 0.23, top_left.y + 44), Vector2(size.x * 0.27, 7)), Color("#e74c3c"), true)
		draw_rect(Rect2(Vector2(top_left.x + size.x * 0.50, top_left.y + 44), Vector2(size.x * 0.27, 7)), Color("#1f8fff"), true)
	# Oncoming headlights sit at the lower/front edge.
	for light_x in [top_left.x + 9.0, top_left.x + size.x - 17.0]:
		draw_rect(Rect2(Vector2(light_x, top_left.y + size.y - 8), Vector2(8, 5)), Color("#fff3a6"), true)
	draw_rect(Rect2(Vector2(top_left.x + size.x * 0.35, top_left.y + size.y - 5), Vector2(size.x * 0.30, 3)), Color("#272d33"), true)

func _draw_truck(top_left: Vector2) -> void:
	_draw_vehicle_shadow(top_left)
	_draw_wheels(top_left, top_left.y + 16, top_left.y + size.y - 42, 24)
	# Ribbed cargo box.
	draw_rect(Rect2(top_left + Vector2(2, 2), Vector2(size.x - 4, 76)), Color("#263746"), true)
	draw_rect(Rect2(top_left + Vector2(7, 7), Vector2(size.x - 14, 66)), Color("#566573"), true)
	for rib in range(4):
		draw_line(Vector2(top_left.x + 11, top_left.y + 17 + rib * 14),
			Vector2(top_left.x + size.x - 11, top_left.y + 17 + rib * 14), Color("#7f8c8d"), 2.0)
	# Cab.
	draw_colored_polygon(PackedVector2Array([
		Vector2(top_left.x + 3, top_left.y + 80), Vector2(top_left.x + size.x - 3, top_left.y + 80),
		Vector2(top_left.x + size.x, top_left.y + size.y - 10), Vector2(top_left.x + size.x - 8, top_left.y + size.y),
		Vector2(top_left.x + 8, top_left.y + size.y), Vector2(top_left.x, top_left.y + size.y - 10),
	]), Color("#e67e22"))
	draw_rect(Rect2(Vector2(top_left.x + 9, top_left.y + 86), Vector2(size.x - 18, 20)), Color("#8fd3e8"), true)
	draw_line(Vector2(0, top_left.y + 87), Vector2(0, top_left.y + 106), Color("#3f5665"), 2.0)
	for light_x in [top_left.x + 8.0, top_left.x + size.x - 16.0]:
		draw_rect(Rect2(Vector2(light_x, top_left.y + size.y - 7), Vector2(8, 5)), Color("#fff3a6"), true)

func _draw_bajaji(top_left: Vector2) -> void:
	_draw_vehicle_shadow(top_left, 5.0)
	# Three wheels and narrow nose make the tuk-tuk silhouette unmistakable.
	draw_circle(Vector2(0, top_left.y + size.y - 5), 6.0, Color("#161a1e"))
	for x in [top_left.x + 3.0, top_left.x + size.x - 3.0]:
		draw_rect(Rect2(Vector2(x - 4, top_left.y + 16), Vector2(8, 22)), Color("#161a1e"), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(top_left.x + 7, top_left.y + 6), Vector2(top_left.x + size.x - 7, top_left.y + 6),
		Vector2(top_left.x + size.x - 3, top_left.y + 54), Vector2(9, top_left.y + size.y),
		Vector2(-9, top_left.y + size.y), Vector2(top_left.x + 3, top_left.y + 54),
	]), color.darkened(0.12))
	draw_rect(Rect2(Vector2(top_left.x + 6, top_left.y + 10), Vector2(size.x - 12, 34)), Color("#202a35"), true)
	draw_rect(Rect2(Vector2(top_left.x + 11, top_left.y + 14), Vector2(size.x - 22, 24)), Color("#8fd3e8"), true)
	draw_rect(Rect2(Vector2(top_left.x + 3, top_left.y + 46), Vector2(size.x - 6, 8)), Color("#f4f6f7"), true)
	draw_circle(Vector2(0, top_left.y + size.y - 10), 3.5, Color("#fff3a6"))

func _draw_bodaboda(top_left: Vector2) -> void:
	draw_rect(Rect2(Vector2(-7, top_left.y + 5), Vector2(17, size.y - 4)), Color(0.02, 0.03, 0.04, 0.28), true)
	# Wheels, chassis, rider, helmet and handlebars.
	for wheel_y in [top_left.y + 8.0, top_left.y + size.y - 8.0]:
		draw_circle(Vector2(0, wheel_y), 7.0, Color("#15191d"))
		draw_circle(Vector2(0, wheel_y), 3.0, Color("#8b949c"))
	draw_line(Vector2(0, top_left.y + 15), Vector2(0, top_left.y + size.y - 14), Color("#d8dde2"), 5.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, 4), Vector2(0, -12), Vector2(10, 4), Vector2(7, 19), Vector2(-7, 19)]), color)
	draw_circle(Vector2(0, -14), 9.0, Color("#202a35"))
	draw_arc(Vector2.ZERO + Vector2(0, -14), 6.0, PI, TAU, 12, color.lightened(0.18), 4.0, true)
	draw_line(Vector2(-14, 11), Vector2(14, 11), Color("#273746"), 4.0, true)
	draw_circle(Vector2(0, top_left.y + size.y - 13), 3.0, Color("#fff3a6"))

func _draw_pothole() -> void:
	var outer := PackedVector2Array([
		Vector2(-34, -3), Vector2(-22, -12), Vector2(-5, -10), Vector2(12, -14),
		Vector2(31, -6), Vector2(35, 4), Vector2(19, 11), Vector2(2, 10), Vector2(-16, 13), Vector2(-32, 6),
	])
	draw_colored_polygon(outer, Color("#17191c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-23, -2), Vector2(-8, -7), Vector2(16, -8), Vector2(26, 1), Vector2(12, 7), Vector2(-14, 7)]), Color("#34383d"))
	for crack in [[Vector2(-24, -5), Vector2(-37, -12)], [Vector2(23, -4), Vector2(37, -10)], [Vector2(-15, 7), Vector2(-26, 17)]]:
		draw_line(crack[0], crack[1], Color("#202328"), 2.0, true)

func _draw_cone(top_left: Vector2) -> void:
	draw_rect(Rect2(Vector2(top_left.x - 4, top_left.y + size.y - 8), Vector2(size.x + 8, 9)), Color("#262b30"), true)
	var cone := PackedVector2Array([Vector2(0, top_left.y), Vector2(top_left.x + 4, top_left.y + size.y - 8), Vector2(-top_left.x - 4, top_left.y + size.y - 8)])
	draw_colored_polygon(cone, color)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -3), Vector2(7, -3), Vector2(10, 3), Vector2(-10, 3)]), Color.WHITE)
	draw_line(Vector2(-3, top_left.y + 4), Vector2(-8, top_left.y + size.y - 12), color.lightened(0.32), 2.0)

func _draw_barrier(top_left: Vector2) -> void:
	draw_rect(Rect2(top_left + Vector2(0, 2), size), Color(0.02, 0.03, 0.04, 0.28), true)
	draw_rect(Rect2(top_left, size), Color("#f5f6f7"), true)
	var stripe_w: float = size.x / 7.0
	for i in range(7):
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([
				Vector2(top_left.x + i * stripe_w, top_left.y), Vector2(top_left.x + (i + 1) * stripe_w, top_left.y),
				Vector2(top_left.x + i * stripe_w, top_left.y + size.y), Vector2(top_left.x + (i - 1) * stripe_w, top_left.y + size.y),
			]), Color("#e67e22"))
	for leg_x in [top_left.x + 9.0, top_left.x + size.x - 15.0]:
		draw_rect(Rect2(Vector2(leg_x, top_left.y + size.y), Vector2(6, 10)), Color("#4d5656"), true)

func _draw_crossing(top_left: Vector2) -> void:
	draw_rect(Rect2(top_left, size), Color(0.03, 0.04, 0.05, 0.68), true)
	var stripe_w: float = size.x / 6.0
	for i in range(6):
		if i % 2 == 0:
			draw_rect(Rect2(Vector2(top_left.x + i * stripe_w + 2, top_left.y + 2), Vector2(stripe_w - 4, size.y - 4)), Color("#f4f6f7"), true)
	# Yellow warning sign in the centre.
	var sign := PackedVector2Array([Vector2(0, -15), Vector2(-11, 5), Vector2(11, 5)])
	draw_colored_polygon(sign, Color("#ffd23f"))
	draw_circle(Vector2(0, -7), 2.0, Color("#273746"))
	draw_line(Vector2(0, -5), Vector2(0, 1), Color("#273746"), 2.0)

func _draw_tire() -> void:
	draw_circle(Vector2(3, 4), 18.0, Color(0.02, 0.03, 0.04, 0.28))
	draw_circle(Vector2.ZERO, 18.0, Color("#15191d"))
	draw_circle(Vector2.ZERO, 10.0, Color("#495057"))
	draw_circle(Vector2.ZERO, 5.5, Color("#20252a"))
	for angle in range(0, 360, 45):
		var a: float = deg_to_rad(float(angle))
		draw_line(Vector2(cos(a), sin(a)) * 13.0, Vector2(cos(a), sin(a)) * 17.0, Color("#6c757d"), 2.0)

func _draw_goat(top_left: Vector2) -> void:
	draw_circle(Vector2(3, 7), 20.0, Color(0.02, 0.03, 0.04, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-19, -5), Vector2(-13, -16), Vector2(13, -16), Vector2(20, -3), Vector2(13, 13), Vector2(-14, 13)]), color)
	draw_circle(Vector2(0, top_left.y + 9), 11.0, color.lightened(0.06))
	draw_line(Vector2(-7, top_left.y + 2), Vector2(-14, top_left.y - 7), Color("#8d6e63"), 3.0, true)
	draw_line(Vector2(7, top_left.y + 2), Vector2(14, top_left.y - 7), Color("#8d6e63"), 3.0, true)
	draw_line(Vector2(-8, top_left.y + 10), Vector2(-18, top_left.y + 5), color, 4.0, true)
	draw_line(Vector2(8, top_left.y + 10), Vector2(18, top_left.y + 5), color, 4.0, true)
	draw_circle(Vector2(-4, top_left.y + 8), 1.7, Color("#222"))
	draw_circle(Vector2(4, top_left.y + 8), 1.7, Color("#222"))
	for leg_x in [-12.0, 11.0]:
		draw_line(Vector2(leg_x, 10), Vector2(leg_x - 2, 25), Color("#a1887f"), 5.0, true)
