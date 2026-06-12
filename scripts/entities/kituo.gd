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
	# Shelter roof
	draw_rect(Rect2(Vector2(tl.x, tl.y), Vector2(SIZE.x, 14)), Color("#1f8fff"))
	# Posts
	draw_rect(Rect2(Vector2(tl.x + 4, tl.y + 14), Vector2(6, SIZE.y - 30)), Color("#aab"))
	draw_rect(Rect2(Vector2(tl.x + SIZE.x - 10, tl.y + 14), Vector2(6, SIZE.y - 30)), Color("#aab"))
	# Sign
	draw_circle(Vector2(0, tl.y - 10), 13.0, Color("#ffd23f"))
	draw_circle(Vector2(0, tl.y - 10), 10.0, Color("#1b2230"))
	# Bench
	draw_rect(Rect2(Vector2(tl.x + 8, tl.y + SIZE.y - 22), Vector2(SIZE.x - 16, 8)), Color("#8d6e63"))
	# Waiting passengers (simple heads), capped at 5 drawn
	if served:
		return
	var shown: int = mini(waiting, 5)
	for i in range(shown):
		var px: float = tl.x + 14 + i * 12.0
		var py: float = tl.y + SIZE.y - 36 + sin(_pulse_t * 3.0 + i) * 1.5
		draw_circle(Vector2(px, py), 5.0, Color("#fab1a0"))
		draw_rect(Rect2(Vector2(px - 4, py + 4), Vector2(8, 10)), Color("#6c5ce7"))
