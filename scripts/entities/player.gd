class_name Player
extends Node2D
## Player dala dala. Moves between 3 lanes via tween.
## Drawn via _draw() so the project runs without external sprites.

signal lane_changed(new_lane: int)

const SIZE := Vector2(72, 110)

var lanes: Array = []
var current_lane: int = 1
var _tex: Texture2D = null
var _vehicle_id: String = ""
var tween: Tween
var body_color: Color = Color("#1f8fff")
var accent_color: Color = Color("#ffd23f")
var pattern: String = "none"
var slogan: String = ""
var lane_switch_time: float = 0.14
var reduced_motion: bool = false
var _tilt_tween: Tween
var _lane_switching: bool = false

func setup(lane_xs: Array, vehicle: Dictionary) -> void:
	lanes = lane_xs
	current_lane = int(lanes.size() / 2)
	# Livery overrides the catalog colors when the player has customised
	var livery := LiveryLib.get_livery(vehicle)
	body_color = Color(String(livery.body))
	accent_color = Color(String(livery.accent))
	pattern = String(livery.pattern)
	slogan = String(livery.slogan)
	lane_switch_time = float(vehicle.get("lane_time", lane_switch_time))
	_vehicle_id = String(vehicle.get("id", ""))
	_tex = SpriteLib.get_tex("vehicle", _vehicle_id)
	position.x = lanes[current_lane]
	_lane_switching = false
	queue_redraw()

func move_left() -> void:
	if _lane_switching:
		return
	if current_lane > 0:
		current_lane -= 1
		_tween_to_lane(-1)

func move_right() -> void:
	if _lane_switching:
		return
	if current_lane < lanes.size() - 1:
		current_lane += 1
		_tween_to_lane(1)

func is_lane_switching() -> bool:
	return _lane_switching

func _tween_to_lane(direction: int = 0) -> void:
	if tween and tween.is_valid():
		tween.kill()
	_lane_switching = true
	tween = create_tween()
	tween.tween_property(self, "position:x", lanes[current_lane], lane_switch_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _lane_switching = false)
	# Juice: lean into the turn, then settle back upright.
	if direction != 0 and not reduced_motion:
		if _tilt_tween and _tilt_tween.is_valid():
			_tilt_tween.kill()
		rotation = 0.13 * direction
		_tilt_tween = create_tween()
		_tilt_tween.tween_property(self, "rotation", 0.0, lane_switch_time * 1.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	emit_signal("lane_changed", current_lane)

func get_aabb() -> Rect2:
	return Rect2(global_position - SIZE * 0.5, SIZE)

## Slightly smaller than the painted bus so near-edge dodges feel earned.
func get_collision_aabb() -> Rect2:
	var hit_size: Vector2 = SIZE * Vector2(0.78, 0.84)
	return Rect2(global_position - hit_size * 0.5, hit_size)

func _draw() -> void:
	var s := SIZE
	var top_left := -s * 0.5
	if _tex:
		draw_texture_rect(_tex, Rect2(top_left, s), false)
		return
	LiveryLib.draw_bus(self, top_left, s, body_color, accent_color, pattern, slogan)
