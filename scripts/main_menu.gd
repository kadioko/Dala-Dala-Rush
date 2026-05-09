extends Control
## Main menu with animated scrolling road background and pulsing play button.

const UIFactory  := preload("res://ui/ui_factory.gd")
const RoadCls    := preload("res://scripts/entities/road.gd")
const Vehicles   := preload("res://data/vehicles.gd")
const Routes     := preload("res://data/routes.gd")

var _title: Label
var _subtitle: Label
var _high_score_label: Label
var _coin_label: Label
var _btn_play: Button
var _btn_routes: Button
var _btn_garage: Button
var _btn_shop: Button
var _btn_settings: Button
var _btn_how: Button
var _btn_stats: Button
var _btn_leaderboard: Button

# Animated background
var _scroll_t: float = 0.0
var _dala_x: float = 0.0
var _dala_dir: int = 1
var _dala_draw: _DalaDalaAnim

func _ready() -> void:
	# ── Animated road background ──────────────────────────────────
	var vsize := get_viewport_rect().size
	var bg_road := RoadCls.new()
	var route_data := Routes.get_by_id(GameState.selected_route_id)
	bg_road.setup(vsize, route_data.sky, route_data.road, route_data.id)
	bg_road.num_lanes = 3
	bg_road.modulate.a = 0.55
	add_child(bg_road)

	_dala_draw = _DalaDalaAnim.new()
	_dala_draw.veh_color = Vehicles.get_by_id(GameState.selected_vehicle_id).body
	_dala_draw.custom_minimum_size = vsize
	add_child(_dala_draw)
	_dala_x = vsize.x * 0.3

	var overlay := _GradientOverlay.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# ── UI layer ─────────────────────────────────────────────────
	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_top = 0.0
	v.anchor_right = 0.5
	v.anchor_bottom = 1.0
	v.offset_left = -168
	v.offset_right = 168
	v.offset_top = 40
	v.offset_bottom = -110
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	add_child(v)

	_title = UIFactory.make_title("", 42)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)

	_subtitle = UIFactory.make_label("", 16, UIFactory.COL_MUTED)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_subtitle)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 20)
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(stats_row)

	_high_score_label = UIFactory.make_label("", 18, UIFactory.COL_TEXT)
	stats_row.add_child(_high_score_label)
	_coin_label = UIFactory.make_label("", 18, UIFactory.COL_ACCENT)
	stats_row.add_child(_coin_label)

	v.add_child(_spacer(4))

	_btn_play = UIFactory.make_button("")
	_btn_play.custom_minimum_size = Vector2(320, 68)
	_btn_play.pressed.connect(_on_play)
	v.add_child(_btn_play)

	# Stats / Leaderboard side-by-side row
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 6)
	info_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(info_row)

	_btn_stats = UIFactory.make_button("", false)
	_btn_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_stats.pressed.connect(func(): _go("res://scenes/stats.tscn"))
	info_row.add_child(_btn_stats)

	_btn_leaderboard = UIFactory.make_button("", false)
	_btn_leaderboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_leaderboard.pressed.connect(func(): _go("res://scenes/leaderboard.tscn"))
	info_row.add_child(_btn_leaderboard)

	for pair in [
		["", "res://scenes/routes.tscn"],
		["", "res://scenes/garage.tscn"],
		["", "res://scenes/shop.tscn"],
		["", "res://scenes/settings.tscn"],
		["", "res://scenes/how_to_play.tscn"],
	]:
		var path: String = pair[1]
		var btn := UIFactory.make_button("", false)
		btn.pressed.connect(func(): _go(path))
		v.add_child(btn)
		match path:
			"res://scenes/routes.tscn":   _btn_routes   = btn
			"res://scenes/garage.tscn":   _btn_garage   = btn
			"res://scenes/shop.tscn":     _btn_shop     = btn
			"res://scenes/settings.tscn": _btn_settings = btn
			_:                            _btn_how      = btn

	_pulse_play_btn()

	LocaleManager.locale_changed.connect(_refresh_text)
	_refresh_text()
	set_process(true)

func _process(delta: float) -> void:
	_scroll_t += delta
	var road_node: Road = get_child(0) as Road
	if road_node:
		road_node.advance(180.0 * delta)
	var vsize := get_viewport_rect().size
	_dala_x += 90.0 * _dala_dir * delta
	if _dala_x > vsize.x + 50:
		_dala_dir = -1
	elif _dala_x < -50:
		_dala_dir = 1
	if _dala_draw:
		_dala_draw.dala_x = _dala_x
		_dala_draw.dala_dir = _dala_dir
		_dala_draw.t = _scroll_t
		_dala_draw.queue_redraw()

func _pulse_play_btn() -> void:
	if not is_instance_valid(_btn_play):
		return
	var tw := _btn_play.create_tween()
	tw.set_loops()
	tw.tween_property(_btn_play, "scale", Vector2(1.04, 1.04), 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_btn_play, "scale", Vector2(1.0, 1.0), 0.55).set_trans(Tween.TRANS_SINE)
	_btn_play.pivot_offset = _btn_play.custom_minimum_size * 0.5

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _refresh_text(_l := "") -> void:
	_title.text            = LocaleManager.t("GAME_TITLE")
	_subtitle.text         = "Dar es Salaam • Endless Run"
	_high_score_label.text = "★ %d" % int(SaveSystem.get_value("best_score", 0))
	_coin_label.text       = "🪙 %d" % int(SaveSystem.get_value("total_coins", 0))
	_btn_play.text         = LocaleManager.t("PLAY")
	_btn_stats.text        = LocaleManager.t("STATS")
	_btn_leaderboard.text  = LocaleManager.t("LEADERBOARD")
	_btn_routes.text       = LocaleManager.t("ROUTES")
	_btn_garage.text       = LocaleManager.t("GARAGE")
	_btn_shop.text         = LocaleManager.t("SHOP")
	_btn_settings.text     = LocaleManager.t("SETTINGS")
	_btn_how.text          = LocaleManager.t("HOW_TO_PLAY")

func _on_play() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/game.tscn")

func _go(path: String) -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to(path)

# ══════════════════════ Inner draw nodes ══════════════════════════

class _GradientOverlay extends Control:
	func _draw() -> void:
		var h: float = size.y
		var w: float = size.x
		draw_rect(Rect2(0, 0, w, h * 0.55), Color(0.07, 0.08, 0.10, 0.72))
		draw_rect(Rect2(0, h * 0.78, w, h * 0.22), Color(0.05, 0.06, 0.08, 0.55))

class _DalaDalaAnim extends Control:
	var dala_x: float = 200.0
	var dala_dir: int = 1
	var t: float = 0.0
	var veh_color: Color = Color("#1f8fff")

	func _draw() -> void:
		var bw: float = 56.0
		var bh: float = 80.0
		var y: float = size.y - 100.0 + sin(t * 6.0) * 2.5
		var cx: float = dala_x
		var flip: float = float(dala_dir)
		draw_rect(Rect2(Vector2(cx - bw*0.5, y), Vector2(bw, bh)), veh_color)
		draw_rect(Rect2(Vector2(cx - bw*0.5, y + 8), Vector2(bw, 7)), Color("#ffd23f"))
		draw_rect(Rect2(Vector2(cx - bw*0.5 + 5, y + 18), Vector2(bw-10, 14)), Color("#a8d0ff"))
		draw_rect(Rect2(Vector2(cx - bw*0.5 + 5, y + 36), Vector2(bw-10, 14)), Color("#a8d0ff"))
		var wc := Color("#1a1a1a")
		draw_rect(Rect2(Vector2(cx - bw*0.5 - 5, y + 14), Vector2(8, 18)), wc)
		draw_rect(Rect2(Vector2(cx + bw*0.5 - 3, y + 14), Vector2(8, 18)), wc)
		draw_rect(Rect2(Vector2(cx - bw*0.5 - 5, y + bh - 32), Vector2(8, 18)), wc)
		draw_rect(Rect2(Vector2(cx + bw*0.5 - 3, y + bh - 32), Vector2(8, 18)), wc)
		var hl_x: float = cx + flip * (bw * 0.5 - 6)
		draw_rect(Rect2(Vector2(hl_x - 5, y - 4), Vector2(10, 5)), Color("#fff7b3"))
		var puff_x: float = cx - flip * (bw * 0.5 + 6)
		var puff_a: float = 0.15 + 0.1 * sin(t * 10.0)
		draw_circle(Vector2(puff_x, y + bh - 8), 6.0, Color(0.85, 0.85, 0.85, puff_a))
