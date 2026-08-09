class_name Kituo
extends Node2D
## Roadside bus stop (kituo). Spawns on the shoulder next to an edge lane.
## Drive in the adjacent lane as it passes to drop passengers for fares
## and board the waiting ones. Drawn in code; sprite override: sprites/obstacle_kituo.png.

const SIZE := Vector2(74, 96)

var lane_idx: int = 0          # adjacent lane (0 = left edge, last = right edge)
var side: int = -1             # -1 shoulder left of road, +1 right
var waiting: int = 3           # passengers waiting to board
var served: bool = false
var missed: bool = false
var active: bool = false
var _tex: Texture2D = null
var _pulse_t: float = 0.0

func setup(p_lane_idx: int, p_side: int, shoulder_x: float, top_y: float, p_waiting: int) -> void:
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	_pulse_t = 0.0
	lane_idx = p_lane_idx
	side = p_side
	waiting = p_waiting
	served = false
	missed = false
	position = Vector2(shoulder_x, top_y)
	active = true
	visible = true
	_tex = SpriteLib.get_tex("obstacle", "kituo")
	queue_redraw()

func deactivate() -> void:
	active = false
	visible = false

func _process(delta: float) -> void:
	if not active:
		return
	_pulse_t += delta
	queue_redraw()

func _draw() -> void:
	if _tex:
		draw_texture_rect(_tex, Rect2(-SIZE * 0.5, SIZE), false)
		return
	var tl := -SIZE * 0.5
	# Pulsing ground marker (the "stop here" cue) extends toward the lane
	var glow_a: float = 0.25 + 0.15 * sin(_pulse_t * 5.0)
	if not served:
		draw_rect(Rect2(Vector2(tl.x - 14 * side, tl.y), Vector2(14, SIZE.y)),
			Color(1.0, 0.82, 0.25, glow_a))
	# Shelter shadow, colored canopy, glass back and metal posts.
	draw_rect(Rect2(tl + Vector2(4, 7), SIZE), Color(0.02, 0.03, 0.04, 0.24), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(tl.x - 4, tl.y + 3), Vector2(tl.x + 5, tl.y - 5),
		Vector2(tl.x + SIZE.x - 5, tl.y - 5), Vector2(tl.x + SIZE.x + 4, tl.y + 3),
		Vector2(tl.x + SIZE.x, tl.y + 14), Vector2(tl.x, tl.y + 14),
	]), Color("#1f8fff"))
	draw_rect(Rect2(Vector2(tl.x + 8, tl.y + 14), Vector2(SIZE.x - 16, SIZE.y - 34)), Color(0.56, 0.82, 0.90, 0.34), true)
	for post_x in [tl.x + 4.0, tl.x + SIZE.x - 10.0]:
		draw_rect(Rect2(Vector2(post_x, tl.y + 12), Vector2(6, SIZE.y - 27)), Color("#8e9aa4"), true)
		draw_line(Vector2(post_x + 1, tl.y + 14), Vector2(post_x + 1, tl.y + SIZE.y - 16), Color("#d5dce1"), 1.5)
	# Branded-free stop sign with a small bus pictogram.
	draw_line(Vector2(0, tl.y - 1), Vector2(0, tl.y + 20), Color("#6c757d"), 4.0, true)
	draw_circle(Vector2(0, tl.y - 12), 14.0, Color("#ffd23f"))
	draw_circle(Vector2(0, tl.y - 12), 10.5, Color("#1b2230"))
	draw_rect(Rect2(Vector2(-5, tl.y - 17), Vector2(10, 9)), Color("#f4f8fb"), true)
	draw_circle(Vector2(-3, tl.y - 7), 1.5, Color("#f4f8fb"))
	draw_circle(Vector2(3, tl.y - 7), 1.5, Color("#f4f8fb"))
	# Wood bench with supports.
	draw_rect(Rect2(Vector2(tl.x + 9, tl.y + SIZE.y - 24), Vector2(SIZE.x - 18, 7)), Color("#9a6432"), true)
	draw_rect(Rect2(Vector2(tl.x + 13, tl.y + SIZE.y - 17), Vector2(5, 10)), Color("#5d4037"), true)
	draw_rect(Rect2(Vector2(tl.x + SIZE.x - 18, tl.y + SIZE.y - 17), Vector2(5, 10)), Color("#5d4037"), true)
	# Waiting passengers (simple heads), capped at 5 drawn
	if served:
		return
	var shown: int = mini(waiting, 5)
	for i in range(shown):
		var px: float = tl.x + 14 + i * 12.0
		var py: float = tl.y + SIZE.y - 36 + sin(_pulse_t * 3.0 + i) * 1.5
		var shirt_colors: Array[Color] = [Color("#6c5ce7"), Color("#e74c3c"), Color("#27ae60"), Color("#f0b429"), Color("#2980b9")]
		draw_circle(Vector2(px, py), 5.0, Color("#b97850") if i % 2 == 0 else Color("#70462f"))
		draw_arc(Vector2(px, py - 1), 4.5, PI, TAU, 10, Color("#273746"), 2.0, true)
		draw_rect(Rect2(Vector2(px - 4, py + 4), Vector2(8, 10)), shirt_colors[i % shirt_colors.size()], true)
