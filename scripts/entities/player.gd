class_name Player
extends Node2D
## Player dala dala. Moves between 3 lanes via tween.
## Drawn via _draw() so the project runs without external sprites.

signal lane_changed(new_lane: int)

const SIZE := Vector2(72, 110)

var lanes: Array = []
var current_lane: int = 1
var tween: Tween
var body_color: Color = Color("#1f8fff")
var accent_color: Color = Color("#ffd23f")
var lane_switch_time: float = 0.14
## Set by game.gd; player pulses alpha when true.
var shield_active: bool = false

func setup(lane_xs: Array, vehicle: Dictionary) -> void:
	lanes = lane_xs
	current_lane = int(lanes.size() / 2)
	body_color = vehicle.get("body", body_color)
	accent_color = vehicle.get("accent", accent_color)
	lane_switch_time = float(vehicle.get("lane_time", lane_switch_time))
	position.x = lanes[current_lane]
	queue_redraw()

func move_left() -> void:
	if current_lane > 0:
		current_lane -= 1
		_tween_to_lane()

func move_right() -> void:
	if current_lane < lanes.size() - 1:
		current_lane += 1
		_tween_to_lane()

func _tween_to_lane() -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x", lanes[current_lane], lane_switch_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	emit_signal("lane_changed", current_lane)

func get_aabb() -> Rect2:
	return Rect2(global_position - SIZE * 0.5, SIZE)

func _draw() -> void:
	var s := SIZE
	var top_left := -s * 0.5
	# Body
	draw_rect(Rect2(top_left, s), body_color, true)
	# Roof rack stripe
	draw_rect(Rect2(top_left + Vector2(0, 10), Vector2(s.x, 8)), accent_color, true)
	# Windows
	var wy := top_left.y + 24
	var wh := 22.0
	draw_rect(Rect2(Vector2(top_left.x + 6, wy), Vector2(s.x - 12, wh)), Color("#a8d0ff"), true)
	draw_rect(Rect2(Vector2(top_left.x + 6, wy + wh + 6), Vector2(s.x - 12, wh)), Color("#a8d0ff"), true)
	# Wheels
	var wheel_col := Color("#1a1a1a")
	draw_rect(Rect2(Vector2(top_left.x - 4, top_left.y + 18), Vector2(8, 24)), wheel_col, true)
	draw_rect(Rect2(Vector2(top_left.x - 4, top_left.y + s.y - 42), Vector2(8, 24)), wheel_col, true)
	draw_rect(Rect2(Vector2(top_left.x + s.x - 4, top_left.y + 18), Vector2(8, 24)), wheel_col, true)
	draw_rect(Rect2(Vector2(top_left.x + s.x - 4, top_left.y + s.y - 42), Vector2(8, 24)), wheel_col, true)
	# Front headlights
	draw_rect(Rect2(Vector2(top_left.x + 6, top_left.y - 4), Vector2(14, 6)), Color("#fff7b3"), true)
	draw_rect(Rect2(Vector2(top_left.x + s.x - 20, top_left.y - 4), Vector2(14, 6)), Color("#fff7b3"), true)
