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
}

var type_id: String = "car"
var size: Vector2 = Vector2(70, 100)
var color: Color = Color("#9b59b6")
var active: bool = false

func setup(t: String, lane_x: float, top_y: float) -> void:
	type_id = t
	var def: Dictionary = TYPES.get(t, TYPES["car"])
	color = def.color
	size = def.size
	position = Vector2(lane_x, top_y)
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
		_:
			# Generic vehicle-shaped obstacle (cars, trucks, bodaboda, bajaji, police).
			draw_rect(Rect2(top_left, size), color, true)
			draw_rect(Rect2(top_left + Vector2(6, 10), Vector2(size.x - 12, 16)), Color("#a8d0ff"))
			draw_rect(Rect2(top_left + Vector2(6, size.y - 26), Vector2(size.x - 12, 16)), Color("#a8d0ff"))
			if type_id == "police":
				draw_rect(Rect2(top_left + Vector2(size.x * 0.25, -4), Vector2(size.x * 0.5, 6)), Color("#e74c3c"))
				draw_rect(Rect2(top_left + Vector2(size.x * 0.5, -4), Vector2(size.x * 0.25, 6)), Color("#1f8fff"))
