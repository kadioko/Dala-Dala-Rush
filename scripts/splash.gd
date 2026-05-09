extends Control
## Animated splash: dala dala drives in from the left, toots its horn, transitions.

const UIFactory := preload("res://ui/ui_factory.gd")

var _anim: _SplashAnim
var _transitioning: bool = false
var _dala_x: float = -110.0
const STOP_X := 270.0
var _arrived: bool = false
var _t: float = 0.0

func _ready() -> void:
	UIFactory.paint_background(self, Color("#0d1117"))

	_anim = _SplashAnim.new()
	_anim.anchor_right = 1.0
	_anim.anchor_bottom = 1.0
	_anim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_anim)

	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_top = 0.28
	v.anchor_right = 0.5
	v.offset_left = -170
	v.offset_right = 170
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	add_child(v)

	var title := UIFactory.make_title(LocaleManager.t("GAME_TITLE"), 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sub := UIFactory.make_label("Dar es Salaam • Tanzania", 16, UIFactory.COL_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.45)

	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	if not _arrived:
		_dala_x = move_toward(_dala_x, STOP_X, 320.0 * delta)
		if _dala_x >= STOP_X:
			_arrived = true
			AudioManager.play_sfx("horn")
			get_tree().create_timer(1.8).timeout.connect(_go_to_menu)
	_anim.dala_x = _dala_x
	_anim.t = _t
	_anim.queue_redraw()

func _input(event: InputEvent) -> void:
	if _transitioning:
		return
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventKey and event.pressed)
	if pressed:
		_go_to_menu()

func _go_to_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	TransitionManager.go_to("res://scenes/main_menu.tscn")

# ══════════════════════════════════════════════════════════════════

class _SplashAnim extends Control:
	var dala_x: float = -110.0
	var t: float = 0.0

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w == 0 or h == 0:
			return
		# Night sky
		draw_rect(Rect2(0, 0, w, h * 0.60), Color("#0d1117"))
		# Stars (fixed positions)
		for star in [
			Vector2(48, 28), Vector2(115, 55), Vector2(198, 38),
			Vector2(300, 20), Vector2(382, 68), Vector2(450, 44),
			Vector2(505, 25), Vector2(170, 82), Vector2(265, 48),
			Vector2(420, 30), Vector2(88, 70), Vector2(340, 76),
		]:
			draw_circle(star, 1.3, Color(1.0, 1.0, 1.0, 0.65))
		# Distant city glow
		draw_rect(Rect2(0, h * 0.52, w, h * 0.08), Color(0.1, 0.15, 0.25, 0.55))
		# Road
		var road_y: float = h * 0.60
		draw_rect(Rect2(0, road_y, w, h - road_y), Color("#2d3436"))
		draw_rect(Rect2(0, road_y, w, 3), Color("#efefef", 0.85))
		# Lane markings
		var lm_y: float = road_y + (h - road_y) * 0.38
		for lx in [w * 0.33, w * 0.66]:
			draw_rect(Rect2(lx - 2, lm_y - 18, 4, 36), Color("#fff7b3", 0.45))
		# Bus
		_draw_bus()

	func _draw_bus() -> void:
		var bw: float = 72.0
		var bh: float = 102.0
		var road_y: float = size.y * 0.60
		var cy: float = road_y + 14.0 + sin(t * 6.0) * 2.5
		var cx: float = dala_x
		# Shadow
		draw_circle(Vector2(cx, cy + bh + 6), 22.0, Color(0, 0, 0, 0.20))
		# Body
		draw_rect(Rect2(cx - bw * 0.5, cy, bw, bh), Color("#1f8fff"))
		# Roof stripe
		draw_rect(Rect2(cx - bw * 0.5, cy + 10, bw, 10), Color("#ffd23f"))
		# Windows
		draw_rect(Rect2(cx - bw * 0.5 + 8, cy + 24, bw - 16, 16), Color("#a8d0ff"))
		draw_rect(Rect2(cx - bw * 0.5 + 8, cy + 44, bw - 16, 16), Color("#a8d0ff"))
		# Door seam
		draw_line(
			Vector2(cx - bw * 0.5 + bw * 0.55, cy + 22),
			Vector2(cx - bw * 0.5 + bw * 0.55, cy + bh - 6),
			Color("#0d5c9e"), 2.0)
		# Wheels
		var wc := Color("#1a1a1a")
		for off in [-bw * 0.5 - 7, bw * 0.5 - 2]:
			draw_rect(Rect2(cx + off, cy + 18, 9, 22), wc)
			draw_rect(Rect2(cx + off, cy + bh - 40, 9, 22), wc)
		# Headlights
		draw_rect(Rect2(cx + bw * 0.5 - 2, cy + 5, 13, 8), Color("#fff7b3"))
		# Exhaust puff
		var pa: float = 0.10 + 0.08 * sin(t * 10.0)
		draw_circle(Vector2(cx - bw * 0.5 - 13, cy + bh - 14), 7.0, Color(0.7, 0.7, 0.7, pa))
