class_name Collectible
extends Node2D
## Coin / passenger / fuel / shield / magnet / slow / speed_boost.
## Add a new collectible: append to TYPES and handle effect in game.gd._on_collect().

const TYPES := {
	"coin":         {"color": Color("#ffd23f"), "size": Vector2(36, 36)},
	"passenger":    {"color": Color("#fab1a0"), "size": Vector2(40, 56)},
	"fuel":         {"color": Color("#e74c3c"), "size": Vector2(36, 46)},
	"shield":       {"color": Color("#1f8fff"), "size": Vector2(40, 46)},
	"magnet":       {"color": Color("#a55eea"), "size": Vector2(40, 40)},
	"speed_boost":  {"color": Color("#2ecc71"), "size": Vector2(40, 40)},
	"slow":         {"color": Color("#74b9ff"), "size": Vector2(40, 40)},
}

var type_id: String = "coin"
var size: Vector2 = Vector2(36, 36)
var color: Color = Color("#ffd23f")
var active: bool = false
var spin: float = 0.0

func setup(t: String, lane_x: float, top_y: float) -> void:
	type_id = t
	var def: Dictionary = TYPES.get(t, TYPES["coin"])
	color = def.color
	size = def.size
	position = Vector2(lane_x, top_y)
	active = true
	visible = true
	spin = 0.0
	queue_redraw()

func get_aabb() -> Rect2:
	return Rect2(global_position - size * 0.5, size)

func deactivate() -> void:
	active = false
	visible = false

func _process(delta: float) -> void:
	if not active:
		return
	spin += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var top_left := -size * 0.5
	match type_id:
		"coin":
			var w: float = size.x * (0.6 + 0.4 * abs(sin(spin)))
			draw_rect(Rect2(Vector2(-w * 0.5, top_left.y), Vector2(w, size.y)), color)
			draw_rect(Rect2(Vector2(-w * 0.5 + 4, top_left.y + 4), Vector2(max(0.0, w - 8), size.y - 8)), color.darkened(0.2))
		"passenger":
			draw_circle(Vector2(0, top_left.y + 12), 12.0, color)
			draw_rect(Rect2(Vector2(top_left.x + 8, top_left.y + 22), Vector2(size.x - 16, size.y - 22)), Color("#6c5ce7"))
		"fuel":
			draw_rect(Rect2(top_left, size), color)
			draw_rect(Rect2(top_left + Vector2(6, 8), Vector2(size.x - 12, 10)), Color.WHITE)
		"shield":
			var pts := PackedVector2Array([
				Vector2(0, top_left.y),
				Vector2(top_left.x, top_left.y + 14),
				Vector2(top_left.x + size.x * 0.3, top_left.y + size.y),
				Vector2(-top_left.x - size.x * 0.3, top_left.y + size.y),
				Vector2(-top_left.x, top_left.y + 14),
			])
			draw_polygon(pts, PackedColorArray([color, color, color, color, color]))
		"magnet":
			draw_rect(Rect2(top_left, Vector2(size.x, size.y * 0.5)), color)
			draw_rect(Rect2(Vector2(top_left.x, 0), Vector2(size.x * 0.3, size.y * 0.5)), color)
			draw_rect(Rect2(Vector2(-top_left.x - size.x * 0.3, 0), Vector2(size.x * 0.3, size.y * 0.5)), color)
		"speed_boost":
			var p1 := PackedVector2Array([
				Vector2(top_left.x, 0), Vector2(0, top_left.y),
				Vector2(0, 0)])
			draw_polygon(p1, PackedColorArray([color, color, color]))
			var p2 := PackedVector2Array([
				Vector2(0, 0), Vector2(0, top_left.y),
				Vector2(-top_left.x, 0)])
			draw_polygon(p2, PackedColorArray([color, color, color]))
		"slow":
			draw_circle(Vector2.ZERO, size.x * 0.5, color)
			draw_arc(Vector2.ZERO, size.x * 0.3, 0, TAU, 16, Color.WHITE, 3.0)
