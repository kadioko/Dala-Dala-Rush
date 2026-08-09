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
var _tex: Texture2D = null

func setup(t: String, lane_x: float, top_y: float) -> void:
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	z_index = 0
	type_id = t
	var def: Dictionary = TYPES.get(t, TYPES["coin"])
	color = def.color
	size = def.size
	_tex = SpriteLib.get_tex("collectible", t)
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
	if _tex:
		# Gentle bob + pulse so sprites still feel alive
		var pulse: float = 1.0 + 0.06 * sin(spin)
		var sz: Vector2 = size * pulse
		draw_texture_rect(_tex, Rect2(-sz * 0.5, sz), false)
		return
	var aura_radius: float = maxf(size.x, size.y) * (0.54 + 0.025 * sin(spin * 1.7))
	var aura_color := Color(color.r, color.g, color.b, 0.14)
	draw_circle(Vector2.ZERO, aura_radius, aura_color)
	draw_arc(Vector2.ZERO, aura_radius - 1.0, 0.0, TAU, 24,
		Color(color.r, color.g, color.b, 0.38), 1.5, true)
	match type_id:
		"coin":
			var coin_scale_x: float = 0.28 + 0.72 * absf(cos(spin))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(coin_scale_x, 1.0))
			draw_circle(Vector2.ZERO, 16.0, color.darkened(0.16))
			draw_circle(Vector2.ZERO, 13.0, color)
			draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 20, color.lightened(0.38), 2.0, true)
			draw_line(Vector2(0, -6), Vector2(0, 6), color.darkened(0.28), 2.2, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"passenger":
			# Friendly passenger silhouette with a bright kitenge-style shirt.
			draw_circle(Vector2(0, -14), 10.0, color)
			draw_arc(Vector2(0, -15), 9.0, PI, TAU, 12, Color("#273746"), 4.0, true)
			draw_circle(Vector2(-3.2, -14), 1.1, Color("#273746"))
			draw_circle(Vector2(3.2, -14), 1.1, Color("#273746"))
			var body := PackedVector2Array([
				Vector2(-12, -4), Vector2(12, -4), Vector2(15, 24), Vector2(-15, 24),
			])
			draw_colored_polygon(body, Color("#6c5ce7"))
			draw_line(Vector2(-9, 5), Vector2(9, 15), Color("#ffd23f"), 3.0, true)
			draw_line(Vector2(9, 5), Vector2(-9, 15), Color("#2ecc71"), 3.0, true)
		"fuel":
			draw_rect(Rect2(top_left + Vector2(2, 4), size - Vector2(4, 4)), color.darkened(0.22), true)
			draw_rect(Rect2(top_left + Vector2(5, 7), size - Vector2(10, 10)), color, true)
			draw_rect(Rect2(Vector2(-7, top_left.y), Vector2(14, 8)), color.darkened(0.24), true)
			draw_rect(Rect2(Vector2(-4, top_left.y + 2), Vector2(8, 5)), Color("#202a35"), true)
			draw_line(Vector2(9, -13), Vector2(15, -7), color.darkened(0.18), 4.0, true)
			draw_circle(Vector2.ZERO, 7.0, Color(0.95, 0.97, 0.98, 0.94))
			var drop := PackedVector2Array([Vector2(0, -5), Vector2(-4, 2), Vector2(0, 6), Vector2(4, 2)])
			draw_colored_polygon(drop, color.darkened(0.15))
		"shield":
			var pts := PackedVector2Array([
				Vector2(0, top_left.y),
				Vector2(top_left.x, top_left.y + 14),
				Vector2(top_left.x + size.x * 0.3, top_left.y + size.y),
				Vector2(-top_left.x - size.x * 0.3, top_left.y + size.y),
				Vector2(-top_left.x, top_left.y + 14),
			])
			draw_colored_polygon(pts, color.darkened(0.20))
			var inner := PackedVector2Array([
				Vector2(0, top_left.y + 5), Vector2(top_left.x + 6, top_left.y + 17),
				Vector2(-7, top_left.y + size.y - 6), Vector2(0, top_left.y + size.y - 2),
				Vector2(7, top_left.y + size.y - 6), Vector2(-top_left.x - 6, top_left.y + 17),
			])
			draw_colored_polygon(inner, color)
			draw_line(Vector2(-6, 1), Vector2(-1, 7), Color.WHITE, 2.5, true)
			draw_line(Vector2(-1, 7), Vector2(8, -5), Color.WHITE, 2.5, true)
		"magnet":
			draw_arc(Vector2.ZERO, 13.0, 0.0, PI, 24, color, 8.0, true)
			draw_line(Vector2(-13, 0), Vector2(-13, -14), color, 8.0, true)
			draw_line(Vector2(13, 0), Vector2(13, -14), color, 8.0, true)
			draw_line(Vector2(-17, -14), Vector2(-9, -14), Color.WHITE, 5.0, true)
			draw_line(Vector2(9, -14), Vector2(17, -14), Color("#ffd23f"), 5.0, true)
		"speed_boost":
			var bolt := PackedVector2Array([
				Vector2(3, -19), Vector2(-13, 2), Vector2(-3, 2),
				Vector2(-8, 19), Vector2(15, -7), Vector2(4, -7),
			])
			draw_colored_polygon(bolt, color)
			draw_polyline(PackedVector2Array([bolt[0], bolt[1], bolt[2], bolt[3], bolt[4], bolt[5], bolt[0]]),
				color.lightened(0.40), 1.5, true)
		"slow":
			for angle in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
				var arm := Vector2(cos(angle), sin(angle)) * 16.0
				draw_line(-arm, arm, color, 3.0, true)
				var branch := arm.normalized().rotated(PI * 0.25) * 5.0
				draw_line(arm * 0.64, arm * 0.64 - branch, color, 2.0, true)
				draw_line(-arm * 0.64, -arm * 0.64 + branch, color, 2.0, true)
			draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
