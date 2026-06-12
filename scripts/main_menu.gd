extends Control
## Main menu with animated scrolling road background and pulsing play button.

const UIFactory  := preload("res://ui/ui_factory.gd")
const RoadCls    := preload("res://scripts/entities/road.gd")
const Vehicles   := preload("res://data/vehicles.gd")
const Routes     := preload("res://data/routes.gd")
const DailyChallengesData := preload("res://data/daily_challenges.gd")
const LoginStreakData := preload("res://data/login_streak.gd")

var _title: Label
var _subtitle: Label
var _high_score_label: Label
var _coin_label: Label
var _daily_label: Label
var _streak_label: Label
var _streak_result: Dictionary = {}
var _rank_label: Label
var _rank_up: Dictionary = {}
var _btn_play: Button
var _btn_routes: Button
var _btn_garage: Button
var _btn_shop: Button
var _btn_settings: Button
var _btn_how: Button
var _btn_stats: Button
var _btn_leaderboard: Button
var _btn_missions: Button

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
	v.anchor_left = 0.0
	v.anchor_top = 0.0
	v.anchor_right = 1.0
	v.anchor_bottom = 1.0
	v.offset_left = 24
	v.offset_right = -24
	v.offset_top = 28 + UIFactory.safe_top_inset(vsize.y)
	v.offset_bottom = -28
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 7)
	add_child(v)

	_title = UIFactory.make_title("", 34)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_title)

	_subtitle = UIFactory.make_label("", 16, UIFactory.COL_MUTED)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_subtitle)

	# Career rank badge (+ rank-up reward check)
	_rank_label = UIFactory.make_label("", 16, Color("#d4af37"))
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_rank_label)
	_rank_up = Career.check_rank_up()
	if not _rank_up.is_empty():
		AudioManager.play_sfx("powerup")
		var tw := _rank_label.create_tween()
		tw.set_loops(5)
		tw.tween_property(_rank_label, "modulate:a", 0.4, 0.25)
		tw.tween_property(_rank_label, "modulate:a", 1.0, 0.25)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 20)
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(stats_row)

	_high_score_label = UIFactory.make_label("", 18, UIFactory.COL_TEXT)
	stats_row.add_child(_high_score_label)
	_coin_label = UIFactory.make_label("", 18, UIFactory.COL_ACCENT)
	stats_row.add_child(_coin_label)

	_daily_label = UIFactory.make_label("", 15, UIFactory.COL_ACCENT)
	_daily_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_daily_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_daily_label)

	# Daily login streak (claims reward on first open of the day).
	# Tapping the row opens the 7-day reward calendar.
	_streak_result = LoginStreakData.claim_today()
	_streak_label = UIFactory.make_label("", 15, Color("#fd79a8"))
	_streak_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_streak_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_streak_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_streak_label.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) \
		or (ev is InputEventScreenTouch and ev.pressed):
			_show_streak_calendar()
	)
	v.add_child(_streak_label)
	if _streak_result.get("claimed_now", false):
		_pulse_streak_label()

	v.add_child(_spacer(4))

	_btn_play = UIFactory.make_button("")
	_btn_play.custom_minimum_size = Vector2(0, 64)
	_btn_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_play.pressed.connect(_on_play)
	v.add_child(_btn_play)

	# Stats / Leaderboard side-by-side row
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 6)
	info_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(info_row)

	_btn_stats = UIFactory.make_button("", false)
	_btn_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_stats.custom_minimum_size = Vector2(0, 56)
	_btn_stats.add_theme_font_size_override("font_size", 18)
	_btn_stats.pressed.connect(func(): _go("res://scenes/stats.tscn"))
	info_row.add_child(_btn_stats)

	_btn_leaderboard = UIFactory.make_button("", false)
	_btn_leaderboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_leaderboard.custom_minimum_size = Vector2(0, 56)
	_btn_leaderboard.add_theme_font_size_override("font_size", 18)
	_btn_leaderboard.pressed.connect(func(): _go("res://scenes/leaderboard.tscn"))
	info_row.add_child(_btn_leaderboard)

	_btn_missions = UIFactory.make_button("", false)
	_btn_missions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_missions.custom_minimum_size = Vector2(0, 56)
	_btn_missions.add_theme_font_size_override("font_size", 18)
	_btn_missions.pressed.connect(func(): _go("res://scenes/missions.tscn"))
	info_row.add_child(_btn_missions)

	for pair in [
		["", "res://scenes/routes.tscn"],
		["", "res://scenes/garage.tscn"],
		["", "res://scenes/shop.tscn"],
		["", "res://scenes/settings.tscn"],
		["", "res://scenes/how_to_play.tscn"],
	]:
		var path: String = pair[1]
		var btn := UIFactory.make_button("", false)
		btn.custom_minimum_size = Vector2(0, 58)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 20)
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
	await get_tree().process_frame
	var tw := _btn_play.create_tween()
	tw.set_loops()
	tw.tween_property(_btn_play, "scale", Vector2(1.04, 1.04), 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_btn_play, "scale", Vector2(1.0, 1.0), 0.55).set_trans(Tween.TRANS_SINE)
	_btn_play.pivot_offset = _btn_play.size * 0.5

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
	_daily_label.text      = _daily_text()
	_streak_label.text     = _streak_text()
	var rank_txt := "🧢 %s" % LocaleManager.t(Career.rank_key())
	if not _rank_up.is_empty():
		rank_txt += "  ⬆ +%d 🪙" % int(_rank_up.reward)
	_rank_label.text = rank_txt
	_btn_stats.text        = LocaleManager.t("STATS")
	_btn_leaderboard.text  = LocaleManager.t("LEADERBOARD")
	_btn_missions.text     = LocaleManager.t("MISSIONS")
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

func _daily_text() -> String:
	var daily := DailyChallengesData.current()
	var goal := LocaleManager.t(daily.get("key", "")).replace("{n}", str(int(daily.get("target", 0))))
	if DailyChallengesData.is_completed_today():
		return "%s: %s" % [LocaleManager.t("DAILY_CHALLENGE"), LocaleManager.t("DAILY_COMPLETE")]
	return "%s: %s (+%d)" % [
		LocaleManager.t("DAILY_CHALLENGE"),
		goal,
		int(daily.get("reward", 0)),
	]

func _streak_text() -> String:
	var streak := int(SaveSystem.get_value("streak_count", 0))
	if streak <= 0:
		return ""
	var txt := LocaleManager.t("STREAK_LABEL").replace("{n}", str(streak))
	if _streak_result.get("claimed_now", false):
		txt += "  +%d 🪙" % int(_streak_result.get("reward", 0))
	return "🔥 " + txt

## 7-day streak reward calendar popup.
func _show_streak_calendar() -> void:
	AudioManager.play_sfx("click")
	var streak := int(SaveSystem.get_value("streak_count", 0))
	var day_in_week: int = ((streak - 1) % 7) + 1 if streak > 0 else 0

	var overlay := Control.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	overlay.add_child(dim)

	var panel := UIFactory.make_panel()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5;  panel.anchor_bottom = 0.5
	panel.offset_left = -220; panel.offset_right = 220
	panel.offset_top = -200;  panel.offset_bottom = 200
	overlay.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	vb.add_child(UIFactory.make_title(LocaleManager.t("STREAK_TITLE"), 26))
	var sub := UIFactory.make_label(
		"🔥 " + LocaleManager.t("STREAK_LABEL").replace("{n}", str(streak)), 17, Color("#fd79a8"))
	vb.add_child(sub)

	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 6)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(grid)

	for i in range(1, 8):
		var cell := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		var is_today: bool = i == day_in_week
		var is_done: bool = i < day_in_week
		sb.bg_color = Color("#fd79a8") if is_today \
			else (Color("#444c66") if is_done else Color("#2d3436"))
		sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8; sb.corner_radius_bottom_right = 8
		sb.content_margin_left = 6; sb.content_margin_right = 6
		sb.content_margin_top = 8; sb.content_margin_bottom = 8
		cell.add_theme_stylebox_override("panel", sb)
		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 2)
		cell.add_child(cvb)
		var d := UIFactory.make_label(str(i), 14,
			Color.WHITE if is_today else UIFactory.COL_MUTED)
		cvb.add_child(d)
		var rw := UIFactory.make_label("%d🪙" % LoginStreakData.reward_for(i), 12,
			UIFactory.COL_ACCENT)
		cvb.add_child(rw)
		grid.add_child(cell)

	var hint := UIFactory.make_label(LocaleManager.t("STREAK_HINT"), 14, UIFactory.COL_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(hint)

	var close := UIFactory.make_button(LocaleManager.t("BACK"), false)
	close.pressed.connect(func():
		AudioManager.play_sfx("click")
		overlay.queue_free()
	)
	vb.add_child(close)

	# Entrance pop
	panel.pivot_offset = Vector2(220, 200)
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)

func _pulse_streak_label() -> void:
	await get_tree().process_frame
	if not is_instance_valid(_streak_label):
		return
	_streak_label.pivot_offset = _streak_label.size * 0.5
	var tw := _streak_label.create_tween()
	tw.set_loops(4)
	tw.tween_property(_streak_label, "scale", Vector2(1.1, 1.1), 0.25)
	tw.tween_property(_streak_label, "scale", Vector2.ONE, 0.25)

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
