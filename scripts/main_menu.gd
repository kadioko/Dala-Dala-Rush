extends Control
## Main menu with animated scrolling road background and pulsing play button.

const UIFactory  := preload("res://ui/ui_factory.gd")
const RoadCls    := preload("res://scripts/entities/road.gd")
const Vehicles   := preload("res://data/vehicles.gd")
const Routes     := preload("res://data/routes.gd")
const DailyChallengesData := preload("res://data/daily_challenges.gd")
const DailyRouteChallengeData := preload("res://data/daily_route_challenge.gd")
const LoginStreakData := preload("res://data/login_streak.gd")
const ReferralsData := preload("res://data/referrals.gd")
const STREAK_PULSE_SCALE := 1.03

var _title: Label
var _subtitle: Label
var _high_score_label: Label
var _coin_label: Label
var _daily_label: Label
var _daily_route_btn: Button
var _event_label: Label
var _last_event_banner: String = ""
var _streak_label: Label
var _streak_result: Dictionary = {}
var _rank_label: Label
var _rank_up: Dictionary = {}
var _btn_play: Button
var _btn_current_route: Button
var _btn_garage: Button
var _btn_shop: Button
var _btn_settings: Button
var _btn_how: Button
var _btn_stats: Button
var _btn_leaderboard: Button
var _btn_missions: Button
var _btn_referrals: Button
var _btn_more: Button
var _secondary_content: VBoxContainer
var _more_expanded: bool = false
var _info_grid: GridContainer
var _utility_grid: GridContainer

# Animated background
var _scroll_t: float = 0.0
var _dala_x: float = 0.0
var _dala_dir: int = 1
var _dala_draw: _DalaDalaAnim

func _ready() -> void:
	GameState.finish_daily_route_challenge()
	get_viewport().size_changed.connect(_apply_responsive_layout)
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
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	var menu_inset := minf(24.0, vsize.x * 0.05)
	scroll.offset_left = menu_inset
	scroll.offset_right = -menu_inset
	scroll.offset_top = 22 + UIFactory.safe_top_inset(vsize.y)
	scroll.offset_bottom = -76 - UIFactory.safe_bottom_inset(vsize.y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 7)
	scroll.add_child(v)

	_title = UIFactory.make_title("", 34)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_title)

	_subtitle = UIFactory.make_label("", 16, UIFactory.COL_MUTED)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_subtitle)
	_event_label = UIFactory.make_label("", 15, Color("#2ecc71"))
	_event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_label.visible = false
	v.add_child(_event_label)

	# The first decision on the menu is always the route, not a secondary system.
	_btn_play = UIFactory.make_button("")
	_btn_play.custom_minimum_size = Vector2(0, 64)
	_btn_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_play.pressed.connect(_on_play)
	v.add_child(_btn_play)
	_btn_current_route = UIFactory.make_button("", false)
	_btn_current_route.custom_minimum_size = Vector2(0, 50)
	_btn_current_route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_current_route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_btn_current_route.add_theme_font_size_override("font_size", 18)
	_btn_current_route.pressed.connect(func(): _go("res://scenes/routes.tscn"))
	v.add_child(_btn_current_route)

	var primary_grid := GridContainer.new()
	primary_grid.columns = 2
	primary_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_grid.add_theme_constant_override("h_separation", 8)
	primary_grid.add_theme_constant_override("v_separation", 8)
	v.add_child(primary_grid)
	_btn_garage = UIFactory.make_button("", false)
	_btn_garage.custom_minimum_size = Vector2(0, 56)
	_btn_garage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_garage.add_theme_font_size_override("font_size", 18)
	_btn_garage.pressed.connect(func(): _go("res://scenes/garage.tscn"))
	primary_grid.add_child(_btn_garage)
	_btn_leaderboard = UIFactory.make_button("", false)
	_btn_leaderboard.custom_minimum_size = Vector2(0, 56)
	_btn_leaderboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_leaderboard.add_theme_font_size_override("font_size", 18)
	_btn_leaderboard.pressed.connect(func(): _go("res://scenes/leaderboard.tscn"))
	primary_grid.add_child(_btn_leaderboard)

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

	_btn_more = UIFactory.make_button("", false)
	_btn_more.custom_minimum_size = Vector2(0, 44)
	_btn_more.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_more.add_theme_font_size_override("font_size", 16)
	_btn_more.pressed.connect(_toggle_more)
	v.add_child(_btn_more)
	_secondary_content = VBoxContainer.new()
	_secondary_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secondary_content.add_theme_constant_override("separation", 7)
	_secondary_content.visible = false
	v.add_child(_secondary_content)

	_daily_label = UIFactory.make_label("", 15, UIFactory.COL_ACCENT)
	_daily_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_daily_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secondary_content.add_child(_daily_label)
	_daily_route_btn = UIFactory.make_button("", false)
	_daily_route_btn.custom_minimum_size = Vector2(0, 50)
	_daily_route_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daily_route_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_daily_route_btn.add_theme_font_size_override("font_size", 20)
	_daily_route_btn.pressed.connect(_on_daily_route)
	_secondary_content.add_child(_daily_route_btn)

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
	_secondary_content.add_child(_streak_label)
	if _streak_result.get("claimed_now", false):
		_pulse_streak_label()

	_secondary_content.add_child(_spacer(4))

	# This row becomes a vertical list below the compact-width breakpoint.
	_info_grid = GridContainer.new()
	_info_grid.columns = info_menu_columns_for_width(vsize.x)
	_info_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_grid.add_theme_constant_override("h_separation", 6)
	_info_grid.add_theme_constant_override("v_separation", 6)
	_secondary_content.add_child(_info_grid)

	_btn_stats = UIFactory.make_button("", false)
	# Compact navigation shares one row on phones. Clear UIFactory's 280px
	# default so localized labels never push the menu wider than the viewport.
	_btn_stats.custom_minimum_size = Vector2(0, 56)
	_btn_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_stats.add_theme_font_size_override("font_size", 17)
	_btn_stats.pressed.connect(func(): _go("res://scenes/stats.tscn"))
	_info_grid.add_child(_btn_stats)

	_btn_missions = UIFactory.make_button("", false)
	_btn_missions.custom_minimum_size = Vector2(0, 56)
	_btn_missions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_missions.add_theme_font_size_override("font_size", 17)
	_btn_missions.pressed.connect(func(): _go("res://scenes/missions.tscn"))
	_info_grid.add_child(_btn_missions)

	_utility_grid = GridContainer.new()
	_utility_grid.columns = utility_menu_columns_for_width(vsize.x)
	_utility_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_utility_grid.add_theme_constant_override("h_separation", 8)
	_utility_grid.add_theme_constant_override("v_separation", 8)
	_secondary_content.add_child(_utility_grid)

	for pair in [
		["", "res://scenes/shop.tscn"],
		["", "res://scenes/settings.tscn"],
	]:
		var path: String = pair[1]
		var btn := UIFactory.make_button("", false)
		btn.custom_minimum_size = Vector2(0, 54)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(): _go(path))
		_utility_grid.add_child(btn)
		match path:
			"res://scenes/shop.tscn":     _btn_shop     = btn
			_:                            _btn_settings = btn

	_btn_referrals = UIFactory.make_button("", false)
	_btn_referrals.custom_minimum_size = Vector2(0, 54)
	_btn_referrals.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_referrals.add_theme_font_size_override("font_size", 18)
	UIFactory.tint_button(_btn_referrals, Color("#0f8a59"))
	_btn_referrals.pressed.connect(func(): _go("res://scenes/referrals.tscn"))
	_secondary_content.add_child(_btn_referrals)

	_btn_how = UIFactory.make_button("", false)
	_btn_how.custom_minimum_size = Vector2(0, 52)
	_btn_how.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_how.add_theme_font_size_override("font_size", 18)
	_btn_how.pressed.connect(func(): _go("res://scenes/how_to_play.tscn"))
	_secondary_content.add_child(_btn_how)

	_pulse_play_btn()

	LocaleManager.locale_changed.connect(_refresh_text)
	RemoteConfig.config_updated.connect(_refresh_event_banner)
	_refresh_text()
	call_deferred("_apply_responsive_layout")
	AdService.show_banner(self, AdService.PLACEMENT_BANNER_MENU)
	set_process(true)

func _exit_tree() -> void:
	AdService.hide_banner()

static func info_menu_columns_for_width(viewport_width: float) -> int:
	return 1 if viewport_width < 500.0 else 2

static func utility_menu_columns_for_width(viewport_width: float) -> int:
	return 1 if viewport_width < 380.0 else 2

static func title_font_size_for_width(viewport_width: float) -> int:
	return 26 if viewport_width < 360.0 else (30 if viewport_width < 400.0 else 34)

func _apply_responsive_layout() -> void:
	if not is_instance_valid(_info_grid) or not is_instance_valid(_utility_grid):
		return
	var viewport_width: float = get_viewport_rect().size.x
	_info_grid.columns = info_menu_columns_for_width(viewport_width)
	_utility_grid.columns = utility_menu_columns_for_width(viewport_width)
	_title.add_theme_font_size_override("font_size", title_font_size_for_width(viewport_width))
	_subtitle.add_theme_font_size_override("font_size", 13 if viewport_width < 360.0 else 15)
	_btn_current_route.add_theme_font_size_override("font_size", 15 if viewport_width < 360.0 else 18)

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
	_subtitle.text         = LocaleManager.t("MAIN_SUBTITLE")
	_high_score_label.text = "★ %d" % int(SaveSystem.get_value("best_score", 0))
	_coin_label.text       = "🪙 %d" % int(SaveSystem.get_value("total_coins", 0))
	_btn_play.text         = LocaleManager.t("PLAY")
	var selected_route: Dictionary = Routes.get_by_id(GameState.selected_route_id)
	_btn_current_route.text = "%s: %s" % [LocaleManager.t("ROUTES"), LocaleManager.t(String(selected_route.get("name_key", "ROUTE_KARIAKOO")))]
	_btn_more.text = LocaleManager.t("MORE_OPTIONS" if not _more_expanded else "LESS_OPTIONS")
	_daily_label.text      = _daily_text()
	var daily_route: Dictionary = DailyRouteChallengeData.current()
	_daily_route_btn.text = LocaleManager.t("DAILY_ROUTE_PLAY").replace(
		"{route}", LocaleManager.t(String(Routes.get_by_id(String(daily_route.get("route_id", "kariakoo"))).get("name_key", "ROUTE_KARIAKOO"))))
	_refresh_event_banner()
	_streak_label.text     = _streak_text()
	var rank_txt := "🧢 %s" % LocaleManager.t(Career.rank_key())
	if not _rank_up.is_empty():
		rank_txt += "  ⬆ +%d 🪙" % int(_rank_up.reward)
	_rank_label.text = rank_txt
	_btn_stats.text        = LocaleManager.t("STATS")
	_btn_leaderboard.text  = LocaleManager.t("LEADERBOARD")
	_btn_missions.text     = LocaleManager.t("MISSIONS")
	_btn_garage.text       = LocaleManager.t("GARAGE")
	_btn_shop.text         = LocaleManager.t("SHOP")
	_btn_settings.text     = LocaleManager.t("SETTINGS")
	_btn_referrals.text    = LocaleManager.t("REFERRAL_MENU_PROMO") \
		.replace("{n}", str(ReferralsData.REFERRER_REWARD))
	_btn_how.text          = LocaleManager.t("HOW_TO_PLAY")

func _refresh_event_banner() -> void:
	var event_text: String = RemoteConfig.event_banner_for(LocaleManager.current_locale)
	_event_label.text = event_text
	_event_label.visible = not event_text.is_empty()
	if not event_text.is_empty() and event_text != _last_event_banner:
		_last_event_banner = event_text
		AnalyticsService.log_event("live_event_seen", {"active": true})

func _toggle_more() -> void:
	_more_expanded = not _more_expanded
	_secondary_content.visible = _more_expanded
	_refresh_text()

func _on_play() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/game.tscn")

func _on_daily_route() -> void:
	AudioManager.play_sfx("click")
	GameState.start_daily_route_challenge()
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
	tw.tween_property(_streak_label, "scale", Vector2.ONE * STREAK_PULSE_SCALE, 0.25)
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
