extends Control
## Short app-opening arrival: a dala dala joins the moving Dar road, then menu.

const UIFactory := preload("res://ui/ui_factory.gd")
const Vehicles := preload("res://data/vehicles.gd")
const Routes := preload("res://data/routes.gd")

var _anim: _SplashAnim
var _transitioning: bool = false
var _arrived: bool = false
var _t: float = 0.0
var _dala_y: float = 1120.0
var _stop_y: float = 620.0

func _ready() -> void:
	UIFactory.paint_background(self, Color("#101820"))
	var view_size := get_viewport_rect().size
	_stop_y = view_size.y * 0.62
	_dala_y = view_size.y + 150.0

	_anim = _SplashAnim.new()
	_anim.anchor_right = 1.0
	_anim.anchor_bottom = 1.0
	_anim.bus_color = Vehicles.get_by_id(GameState.selected_vehicle_id).body
	_anim.route_color = Routes.get_by_id(GameState.selected_route_id).sky
	_anim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_anim)

	var brand := VBoxContainer.new()
	brand.anchor_left = 0.5
	brand.anchor_right = 0.5
	brand.anchor_top = 0.0
	brand.offset_left = -220
	brand.offset_right = 220
	brand.offset_top = 64 + UIFactory.safe_top_inset(view_size.y)
	brand.add_theme_constant_override("separation", 6)
	add_child(brand)

	var title := UIFactory.make_title(LocaleManager.t("GAME_TITLE"), 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brand.add_child(title)

	var route_name := LocaleManager.t(String(Routes.get_by_id(GameState.selected_route_id).get("name_key", "ROUTE_KARIAKOO")))
	var subtitle := UIFactory.make_label(LocaleManager.t("SPLASH_SUBTITLE"), 17, UIFactory.COL_TEXT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_child(subtitle)
	var route := UIFactory.make_label(route_name, 16, UIFactory.COL_ACCENT)
	route.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_child(route)

	var skip := UIFactory.make_label(LocaleManager.t("SPLASH_SKIP"), 14, UIFactory.COL_MUTED)
	skip.anchor_left = 0.5
	skip.anchor_right = 0.5
	skip.anchor_top = 1.0
	skip.anchor_bottom = 1.0
	skip.offset_left = -120
	skip.offset_right = 120
	skip.offset_top = -48 - UIFactory.safe_bottom_inset(view_size.y)
	skip.offset_bottom = -20 - UIFactory.safe_bottom_inset(view_size.y)
	add_child(skip)

	modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.28)
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	if not _arrived:
		_dala_y = move_toward(_dala_y, _stop_y, get_viewport_rect().size.y * 1.18 * delta)
		if _dala_y <= _stop_y:
			_arrived = true
			AudioManager.play_sfx("horn")
			var depart := create_tween()
			depart.tween_interval(1.05)
			depart.tween_callback(_go_to_menu)
	_anim.dala_y = _dala_y
	_anim.road_scroll += 340.0 * delta
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

class _SplashAnim extends Control:
	var dala_y: float = 1100.0
	var road_scroll: float = 0.0
	var t: float = 0.0
	var bus_color: Color = Color("#1f8fff")
	var route_color: Color = Color("#f7d794")

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 0.0 or h <= 0.0:
			return
		var road_x: float = w * 0.13
		var road_w: float = w * 0.74
		var lane_w: float = road_w / 3.0
		draw_rect(Rect2(Vector2.ZERO, size), route_color.darkened(0.48))
		_draw_city_sides(road_x, road_w, h)
		draw_rect(Rect2(road_x - 8, 0, road_w + 16, h), Color("#b5a998"))
		draw_rect(Rect2(road_x, 0, road_w, h), Color("#323a3e"))
		for lane in range(1, 3):
			var lane_x: float = road_x + lane_w * lane
			var y: float = fposmod(road_scroll, 96.0) - 96.0
			while y < h:
				draw_rect(Rect2(lane_x - 3, y, 6, 38), Color("#fff2ad"))
				y += 96.0
		draw_rect(Rect2(road_x - 3, 0, 3, h), Color("#f4f0df"))
		draw_rect(Rect2(road_x + road_w, 0, 3, h), Color("#f4f0df"))
		_draw_streetlights(road_x, road_w, h)
		_draw_bus(Vector2(road_x + lane_w * 1.5, dala_y))

	func _draw_city_sides(road_x: float, road_w: float, h: float) -> void:
		var side_defs := [
			{"x": 0.0, "width": road_x - 14.0},
			{"x": road_x + road_w + 14.0, "width": size.x - road_x - road_w - 14.0},
		]
		for side in side_defs:
			var x: float = side.x
			var side_width: float = side.width
			if side_width <= 4.0:
				continue
			var y: float = fposmod(road_scroll * 0.36, 188.0) - 188.0
			while y < h:
				draw_rect(Rect2(x + 4, y + 20, side_width - 8, 84), Color("#d8dee3"))
				draw_rect(Rect2(x + 9, y + 34, side_width - 18, 18), Color("#465966"))
				draw_rect(Rect2(x + 9, y + 58, side_width - 18, 18), Color("#465966"))
				draw_rect(Rect2(x, y + 106, side_width, 15), Color("#e67e22"))
				draw_rect(Rect2(x + side_width * 0.72, y + 115, 5, 30), Color("#6e3b10"))
				draw_circle(Vector2(x + side_width * 0.72 + 2, y + 112), 13, Color("#2ecc71"))
				y += 188.0

	func _draw_streetlights(road_x: float, road_w: float, h: float) -> void:
		var y: float = fposmod(road_scroll * 0.66, 180.0) - 180.0
		while y < h:
			for x in [road_x - 22.0, road_x + road_w + 12.0]:
				draw_rect(Rect2(x, y, 4, 34), Color("#b0bec5"))
				draw_circle(Vector2(x + 2, y), 7, Color("#ffd866", 0.88))
			y += 180.0

	func _draw_bus(center: Vector2) -> void:
		var bus_size := Vector2(82, 126)
		var top_left := center - bus_size * 0.5
		var bob: float = sin(t * 7.0) * 1.5
		top_left.y += bob
		_draw_preview_ellipse(center + Vector2(0, 54), Vector2(35, 10), Color(0.0, 0.0, 0.0, 0.28))
		draw_rect(Rect2(top_left, bus_size), bus_color)
		draw_rect(Rect2(top_left + Vector2(0, 10), Vector2(bus_size.x, 11)), Color("#ffd23f"))
		draw_rect(Rect2(top_left + Vector2(9, 28), Vector2(bus_size.x - 18, 17)), Color("#a8d0ff"))
		draw_rect(Rect2(top_left + Vector2(9, 51), Vector2(bus_size.x - 18, 17)), Color("#a8d0ff"))
		draw_line(top_left + Vector2(bus_size.x * 0.58, 25), top_left + Vector2(bus_size.x * 0.58, 117), bus_color.darkened(0.35), 2)
		for wheel_y in [30.0, 91.0]:
			draw_rect(Rect2(top_left.x - 5, top_left.y + wheel_y, 9, 24), Color("#151515"))
			draw_rect(Rect2(top_left.x + bus_size.x - 4, top_left.y + wheel_y, 9, 24), Color("#151515"))
		draw_rect(Rect2(top_left + Vector2(10, 3), Vector2(15, 7)), Color("#fff7b3"))
		draw_rect(Rect2(top_left + Vector2(57, 3), Vector2(15, 7)), Color("#fff7b3"))
		var exhaust_alpha: float = 0.08 + 0.07 * sin(t * 11.0)
		draw_circle(top_left + Vector2(bus_size.x * 0.5, bus_size.y + 16), 10, Color(0.75, 0.75, 0.75, exhaust_alpha))

	func _draw_preview_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var points := PackedVector2Array()
		for i in range(20):
			var angle: float = TAU * float(i) / 20.0
			points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
		draw_polygon(points, PackedColorArray([color]))
