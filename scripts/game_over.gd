extends Control
## Game Over: star rating, animated count-up, route record, optional leaderboard entry.

const UIFactory := preload("res://ui/ui_factory.gd")

var _title_lbl: Label
var _record_lbl: Label
var _route_record_lbl: Label
var _star_row: _StarRating
var _score_lbl: Label
var _dist_lbl: Label
var _coins_lbl: Label
var _pass_lbl: Label
var _best_lbl: Label
var _goal_lbl: Label
var _tagline_lbl: Label
var _play_btn: Button
var _menu_btn: Button
var _lb_btn: Button
var _share_btn: Button
var _continue_btn: Button
var _double_btn: Button
var _ad_msg_lbl: Label

var _anim_score: float = 0.0
var _anim_coins: float = 0.0
var _anim_pass:  float = 0.0
var _anim_done: bool = false
const ANIM_SPEED := 3.5

var _name_edit: LineEdit = null
var _submit_btn: Button = null
var _score_submitted: bool = false

func _ready() -> void:
	UIFactory.paint_background(self, UIFactory.COL_BG)

	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_top = 0.0
	v.anchor_right = 0.5
	v.anchor_bottom = 0.0
	v.offset_left = -210
	v.offset_right = 210
	v.offset_top = 18
	v.add_theme_constant_override("separation", 10)
	add_child(v)

	# Slide-in entrance
	v.position.y = 60.0
	v.modulate.a = 0.0
	var entrance := v.create_tween()
	entrance.tween_property(v, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.parallel().tween_property(v, "modulate:a", 1.0, 0.35)

	# ── Title ──
	_title_lbl = UIFactory.make_title("", 42)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title_lbl)

	# ── Overall new record ──
	_record_lbl = UIFactory.make_label("", 28, UIFactory.COL_ACCENT)
	_record_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_lbl.visible = GameState.last_is_new_record
	v.add_child(_record_lbl)
	if GameState.last_is_new_record:
		_pulse_label(_record_lbl)

	# ── Route record (shown only when it's a route best but NOT overall best) ──
	_route_record_lbl = UIFactory.make_label("", 18, UIFactory.COL_PRIMARY)
	_route_record_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_record_lbl.visible = GameState.last_is_route_record and not GameState.last_is_new_record
	v.add_child(_route_record_lbl)

	# ── Stars ──
	_star_row = _StarRating.new()
	_star_row.custom_minimum_size = Vector2(0, 56)
	_star_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_star_row.star_count = _calc_stars()
	v.add_child(_star_row)

	# ── Tagline ──
	_tagline_lbl = UIFactory.make_label("", 20, UIFactory.COL_MUTED)
	_tagline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_tagline_lbl)

	# ── Stats panel ──
	var panel := UIFactory.make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(panel)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	panel.add_child(stats)
	_score_lbl = _stat_label(stats)
	_dist_lbl  = _stat_label(stats, UIFactory.COL_MUTED, 18)
	_coins_lbl = _stat_label(stats, UIFactory.COL_ACCENT)
	_pass_lbl  = _stat_label(stats)
	_goal_lbl  = _stat_label(stats, UIFactory.COL_PRIMARY, 18)
	_best_lbl  = _stat_label(stats, UIFactory.COL_MUTED, 16)

	# ── Leaderboard name entry (when score qualifies) ──
	if SaveSystem.qualifies_for_leaderboard(GameState.last_score):
		var lb_panel := UIFactory.make_panel()
		lb_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(lb_panel)
		var lb_vb := VBoxContainer.new()
		lb_vb.add_theme_constant_override("separation", 8)
		lb_panel.add_child(lb_vb)

		var enter_lbl := UIFactory.make_label(LocaleManager.t("ENTER_NAME"), 15, UIFactory.COL_ACCENT)
		lb_vb.add_child(enter_lbl)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		lb_vb.add_child(hb)

		_name_edit = LineEdit.new()
		_name_edit.max_length = 3
		_name_edit.placeholder_text = "AAA"
		_name_edit.custom_minimum_size = Vector2(80, 44)
		_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(_name_edit)

		_submit_btn = UIFactory.make_button(LocaleManager.t("SUBMIT"))
		_submit_btn.custom_minimum_size = Vector2(110, 44)
		_submit_btn.pressed.connect(_on_submit_score)
		hb.add_child(_submit_btn)

	v.add_child(_spacer(4))

	_ad_msg_lbl = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
	_ad_msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_ad_msg_lbl)

	var ad_row := HBoxContainer.new()
	ad_row.add_theme_constant_override("separation", 8)
	ad_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(ad_row)

	_continue_btn = UIFactory.make_button("", false)
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_btn.custom_minimum_size = Vector2(0, 50)
	_continue_btn.pressed.connect(_on_continue_ad)
	ad_row.add_child(_continue_btn)

	_double_btn = UIFactory.make_button("", false)
	_double_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_double_btn.custom_minimum_size = Vector2(0, 50)
	_double_btn.pressed.connect(_on_double_coins_ad)
	ad_row.add_child(_double_btn)

	# ── Buttons ──
	_play_btn = UIFactory.make_button("")
	_play_btn.pressed.connect(_on_play_again)
	v.add_child(_play_btn)

	_menu_btn = UIFactory.make_button("", false)
	_menu_btn.pressed.connect(_on_main_menu)
	v.add_child(_menu_btn)

	_lb_btn = UIFactory.make_button("", false)
	_lb_btn.pressed.connect(_on_view_leaderboard)
	v.add_child(_lb_btn)

	_share_btn = UIFactory.make_button("", false)
	_share_btn.pressed.connect(_on_share)
	v.add_child(_share_btn)

	LocaleManager.locale_changed.connect(_refresh)
	_refresh()
	set_process(true)

func _stat_label(parent: Control, col: Color = UIFactory.COL_TEXT, font_size: int = 22) -> Label:
	var l := UIFactory.make_label("", font_size, col)
	parent.add_child(l)
	return l

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

# ─── Count-up animation ───────────────────────────────────────────

func _process(delta: float) -> void:
	if _anim_done:
		return
	var ts: float = float(GameState.last_score)
	var tc: float = float(GameState.last_coins)
	var tp: float = float(GameState.last_passengers)
	_anim_score = move_toward(_anim_score, ts, ts * ANIM_SPEED * delta + 1.0)
	_anim_coins = move_toward(_anim_coins, tc, tc * ANIM_SPEED * delta + 1.0)
	_anim_pass  = move_toward(_anim_pass,  tp, max(1.0, tp * ANIM_SPEED * delta))
	if _anim_score >= ts and _anim_coins >= tc and _anim_pass >= tp:
		_anim_done = true
	_update_stats_labels()

func _update_stats_labels() -> void:
	_score_lbl.text = "%s: %d"    % [LocaleManager.t("SCORE"),      int(_anim_score)]
	_dist_lbl.text  = "%s: %.0f m" % [LocaleManager.t("DISTANCE"),  GameState.last_distance]
	_coins_lbl.text = "%s: %d"    % [LocaleManager.t("COINS"),      int(_anim_coins)]
	if GameState.last_bonus_coins > 0:
		_coins_lbl.text += " (+%d)" % GameState.last_bonus_coins
	_pass_lbl.text  = "%s: %d"    % [LocaleManager.t("PASSENGERS"), int(_anim_pass)]
	var goal_status := LocaleManager.t("GOAL_COMPLETE") if GameState.last_route_goal_met else LocaleManager.t("GOAL_FAILED")
	_goal_lbl.text  = "%s: %s  %s" % [LocaleManager.t("ROUTE_GOAL"), goal_status, GameState.last_route_goal_progress]
	_best_lbl.text  = "%s: %d"    % [LocaleManager.t("BEST"),       int(SaveSystem.get_value("best_score", 0))]

func _refresh(_l := "") -> void:
	_title_lbl.text = LocaleManager.t("GAME_OVER")
	_record_lbl.text = LocaleManager.t("NEW_RECORD")
	_route_record_lbl.text = LocaleManager.t("ROUTE_RECORD")
	var star_key := "STARS_%d" % clamp(_calc_stars(), 1, 3)
	_tagline_lbl.text = LocaleManager.t(star_key)
	_play_btn.text  = LocaleManager.t("PLAY_AGAIN")
	_menu_btn.text  = LocaleManager.t("MAIN_MENU")
	_lb_btn.text    = LocaleManager.t("LEADERBOARD")
	_share_btn.text = LocaleManager.t("SHARE_SCORE")
	_continue_btn.text = LocaleManager.t("CONTINUE_AD")
	_double_btn.text = LocaleManager.t("DOUBLE_COINS")
	_ad_msg_lbl.text = LocaleManager.t("AD_PLACEHOLDER")
	if _submit_btn and not _score_submitted:
		_submit_btn.text = LocaleManager.t("SUBMIT")
	_update_stats_labels()

func _calc_stars() -> int:
	var sc: int = GameState.last_score
	if sc >= 2000: return 3
	if sc >= 500:  return 2
	return 1

func _pulse_label(lbl: Label) -> void:
	if not is_instance_valid(lbl):
		return
	var tw := lbl.create_tween()
	tw.set_loops(6)
	tw.tween_property(lbl, "scale", Vector2(1.12, 1.12), 0.22)
	tw.tween_property(lbl, "scale", Vector2(1.0,  1.0),  0.22)
	lbl.pivot_offset = lbl.size * 0.5

# ─── Navigation ───────────────────────────────────────────────────

func _on_submit_score() -> void:
	if _score_submitted or _name_edit == null:
		return
	var nm: String = _name_edit.text.strip_edges().to_upper()
	if nm.length() == 0:
		nm = "AAA"
	SaveSystem.add_to_leaderboard(nm, GameState.last_score, GameState.selected_route_id)
	_score_submitted = true
	if _submit_btn:
		_submit_btn.text = "✓"
		_submit_btn.disabled = true
	if _name_edit:
		_name_edit.editable = false
	AudioManager.play_sfx("powerup")

func _on_play_again() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/game.tscn")

func _on_main_menu() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")

func _on_view_leaderboard() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/leaderboard.tscn")

func _on_continue_ad() -> void:
	AudioManager.play_sfx("click")
	if AdService.show_rewarded_continue():
		TransitionManager.go_to("res://scenes/game.tscn")
		return
	_ad_msg_lbl.text = LocaleManager.t("ADS_SOON")

func _on_double_coins_ad() -> void:
	AudioManager.play_sfx("click")
	if AdService.show_rewarded_double_coins():
		SaveSystem.add_coins(GameState.last_coins)
		_ad_msg_lbl.text = "+%d %s" % [GameState.last_coins, LocaleManager.t("COINS")]
		_double_btn.disabled = true
		return
	_ad_msg_lbl.text = LocaleManager.t("ADS_SOON")

func _on_share() -> void:
	AudioManager.play_sfx("click")
	var text: String = LocaleManager.t("SHARE_TEXT").replace("{score}", str(GameState.last_score))
	if OS.get_name() == "Android":
		OS.shell_open("intent:#Intent;action=android.intent.action.SEND;type=text/plain;S.android.intent.extra.TEXT=" + text.uri_encode() + ";end")
	else:
		DisplayServer.clipboard_set(text)
		_ad_msg_lbl.text = LocaleManager.t("SHARE_COPIED")

# ══════════════════════ Inner draw node ═══════════════════════════

class _StarRating extends Control:
	var star_count: int = 1

	func _draw() -> void:
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.5
		var spacing: float = 56.0
		var r: float = 20.0
		var start_x: float = cx - spacing
		for i in range(3):
			var sx: float = start_x + i * spacing
			var filled: bool = i < star_count
			var col: Color = Color("#ffd23f") if filled else Color(0.3, 0.3, 0.3, 0.5)
			_draw_star(Vector2(sx, cy), r, col, filled)

	func _draw_star(center: Vector2, radius: float, col: Color, filled: bool) -> void:
		var pts := PackedVector2Array()
		for i in range(10):
			var angle: float = (i * PI / 5.0) - PI * 0.5
			var dist: float = radius if i % 2 == 0 else radius * 0.42
			pts.append(center + Vector2(cos(angle), sin(angle)) * dist)
		if filled:
			draw_polygon(pts, PackedColorArray([col, col, col, col, col, col, col, col, col, col]))
		else:
			draw_polyline(pts + PackedVector2Array([pts[0]]), col, 2.0)
