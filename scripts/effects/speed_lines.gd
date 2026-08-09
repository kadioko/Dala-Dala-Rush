class_name SpeedLines
extends Node2D
## Draws white streaks at high speed to convey velocity.
## Add as child of entity_layer in game.gd; call advance() each frame.

var speed_ref: float = 0.0
var view_size: Vector2 = Vector2(540, 960)
var reduced_effects: bool = false

const SPEED_THRESHOLD: float = 420.0
const SPEED_MAX: float = 900.0
const LINE_COUNT: int = 18

var _lines: Array = []

func setup(vsize: Vector2, reduce_effects: bool = false) -> void:
	view_size = vsize
	reduced_effects = reduce_effects
	_lines.clear()
	var line_count: int = 8 if reduced_effects else LINE_COUNT
	for i in range(line_count):
		_lines.append({
			"x": randf_range(view_size.x * 0.1, view_size.x * 0.9),
			"y": randf_range(0.0, view_size.y),
			"len": randf_range(28.0, 72.0),
			"spd": randf_range(0.85, 1.3),
		})

func advance(move: float) -> void:
	for ld in _lines:
		ld.y = fposmod(ld.y + move * ld.spd * 1.6, view_size.y + 80.0)
	queue_redraw()

func _draw() -> void:
	if speed_ref <= SPEED_THRESHOLD:
		return
	var alpha: float = clamp((speed_ref - SPEED_THRESHOLD) / (SPEED_MAX - SPEED_THRESHOLD), 0.0, 1.0)
	var line_alpha: float = alpha * (0.22 if reduced_effects else 0.45)
	for ld in _lines:
		var col := Color(1.0, 1.0, 1.0, line_alpha)
		var y0: float = ld.y
		var y1: float = ld.y + ld.len * alpha
		draw_line(Vector2(ld.x, y0), Vector2(ld.x, y1), col, 1.5)
