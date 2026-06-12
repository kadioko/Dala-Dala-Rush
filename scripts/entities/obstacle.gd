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

func setup(t: String, lane_x: float, top_y: float) -> void:
	type_id = t
	var def: Dictionary = TYPES.get(t, TYPES["car"])
	color = def.color
	size = def.size
	position = Vector2(lane_x, top_y)
	base_x = lane_x
	drift_phase = randf() * TAU
	walk_dir = 1 if randf() < 0.5 else -1
	_tex = SpriteLib.get_tex("obstacle", t)
	active = true
	visible = true
	queue_redraw()

func get_aabb() -> Rect2:
	return Rect2(global_position - size * 0.5, size)

func deactivate() -> void:
	active = false
	visible = false

func _draw() -> void:
	var top_left := -size * 0.5
	if _tex:
		draw_texture_rect(_tex, Rect2(top_left, size), false)
		return
	match type_id:
		"pothole":
			draw_circle(Vector2.ZERO, size.x * 0.5, color)
			draw_circle(Vector2.ZERO, size.x * 0.35, Color("#3a3a3a"))
		"cone":
			var pts := PackedVector2Array([
				Vector2(0, top_left.y),
				Vector2(top_left.x, top_left.y + size.y),
				Vector2(-top_left.x, top_left.y + size.y),
			])
			draw_polygon(pts, PackedColorArray([color, color, color]))
			draw_rect(Rect2(top_left + Vector2(2, size.y * 0.4), Vector2(size.x - 4, 5)), Color.WHITE)
		"barrier":
			var stripes := 6
			var sw := size.x / stripes
			for i in range(stripes):
				var c: Color = color if i % 2 == 0 else Color.BLACK
				draw_rect(Rect2(Vector2(top_left.x + i * sw, top_left.y), Vector2(sw, size.y)), c)
		"pedestrian":
			draw_rect(Rect2(top_left, size), Color("#222"))
			var stripes2 := 5
			var sw2 := size.x / stripes2
			for i in range(stripes2):
				draw_rect(Rect2(Vector2(top_left.x + i * sw2 + 3, top_left.y + 3), Vector2(sw2 - 6, size.y - 6)), Color.WHITE)
		"tire":
			draw_circle(Vector2.ZERO, size.x * 0.5, color)
			draw_circle(Vector2.ZERO, size.x * 0.25, Color("#555"))
		"mbuzi":
			# Goat wandering onto the road: body, head, horns, legs.
			var body_r := Rect2(Vector2(top_left.x, top_left.y + 14), Vector2(size.x, size.y * 0.5))
			draw_rect(body_r, color)
			# Head (top centre)
			draw_circle(Vector2(0, top_left.y + 10), 11.0, color)
			# Horns
			draw_line(Vector2(-7, top_left.y + 2), Vector2(-13, top_left.y - 8), Color("#8d6e63"), 3.0)
			draw_line(Vector2(7, top_left.y + 2), Vector2(13, top_left.y - 8), Color("#8d6e63"), 3.0)
			# Eyes
			draw_circle(Vector2(-4, top_left.y + 8), 2.0, Color("#222"))
			draw_circle(Vector2(4, top_left.y + 8), 2.0, Color("#222"))
			# Legs
			var leg_y := body_r.position.y + body_r.size.y
			for lx in [top_left.x + 6, top_left.x + size.x - 10]:
				draw_rect(Rect2(Vector2(lx, leg_y), Vector2(5, size.y - (leg_y - top_left.y))), Color("#a1887f"))
		_:
			# Generic vehicle-shaped obstacle (cars, trucks, bodaboda, bajaji, police).
			draw_rect(Rect2(top_left, size), color, true)
			draw_rect(Rect2(top_left + Vector2(6, 10), Vector2(size.x - 12, 16)), Color("#a8d0ff"))
			draw_rect(Rect2(top_left + Vector2(6, size.y - 26), Vector2(size.x - 12, 16)), Color("#a8d0ff"))
			if type_id == "police":
				draw_rect(Rect2(top_left + Vector2(size.x * 0.25, -4), Vector2(size.x * 0.5, 6)), Color("#e74c3c"))
				draw_rect(Rect2(top_left + Vector2(size.x * 0.5, -4), Vector2(size.x * 0.25, 6)), Color("#1f8fff"))
