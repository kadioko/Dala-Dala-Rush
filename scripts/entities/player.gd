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
var _queued_direction: int = 0
var _steering_paused: bool = false

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
	_queued_direction = 0
	_steering_paused = false
	queue_redraw()

func move_left() -> void:
	_request_direction(-1)

func move_right() -> void:
	_request_direction(1)

func _request_direction(direction: int) -> void:
	if _steering_paused:
		return
	if _lane_switching:
		_queued_direction = direction
		return
	var next_lane: int = clampi(current_lane + direction, 0, lanes.size() - 1)
	if next_lane != current_lane:
		current_lane = next_lane
		_tween_to_lane(direction)

func set_steering_paused(value: bool) -> void:
	_steering_paused = value
	_queued_direction = 0
	for motion in [tween, _tilt_tween]:
		if motion != null and motion.is_valid():
			if value: motion.pause()
			else: motion.play()

func aligned_with_lane(lane: int) -> bool:
	return lane >= 0 and lane < lanes.size() and not _lane_switching \
		and absf(position.x - float(lanes[lane])) <= 12.0

func is_lane_switching() -> bool:
	return _lane_switching

func _tween_to_lane(direction: int = 0) -> void:
	if tween and tween.is_valid():
		tween.kill()
	_lane_switching = true
	tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position:x", lanes[current_lane], lane_switch_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		_lane_switching = false
		tween = null
		var queued: int = _queued_direction
		_queued_direction = 0
		if queued != 0:
			_request_direction.call_deferred(queued)
	)
	# Juice: lean into the turn, then settle back upright.
	if direction != 0 and not reduced_motion:
		if _tilt_tween and _tilt_tween.is_valid():
			_tilt_tween.kill()
		rotation = 0.13 * direction
		_tilt_tween = create_tween()
		_tilt_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
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
	LiveryLib.draw_bus(self, top_left, s, body_color, accent_color, pattern, slogan, _vehicle_id)
