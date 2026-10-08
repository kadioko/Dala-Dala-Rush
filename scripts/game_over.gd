extends Control
## Game Over: star rating, animated count-up, route record, optional leaderboard entry.

const UIFactory := preload("res://ui/ui_factory.gd")
const RouteContracts := preload("res://data/route_contracts.gd")
const Vehicles := preload("res://data/vehicles.gd")
const GhostDataLib := preload("res://data/ghost_data.gd")

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
var _daily_lbl: Label
var _contract_lbl: Label
var _tagline_lbl: Label
var _mastery_lbl: Label
var _flow_lbl: Label
var _coach_title_lbl: Label
var _coach_body_lbl: Label
var _next_step_lbl: Label
var _reputation_title_lbl: Label
var _reputation_body_lbl: Label
var _discovery_lbl: Label
var _progression_lbl: Label
var _play_btn: Button
var _menu_btn: Button
var _lb_btn: Button
var _share_btn: Button
var _replay_btn: Button
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
var _pending_nav_path: String = ""
var _interstitial_in_progress: bool = false
var _reward_in_progress: bool = false
var _navigation_in_progress: bool = false
var _ad_row: HBoxContainer

const END_TIP_KEYS := {
	"bodaboda": "RUN_TIP_BODABODA",
	"bajaji": "RUN_TIP_BAJAJI",
	"car": "RUN_TIP_CAR",
	"pothole": "RUN_TIP_POTHOLE",
	"cone": "RUN_TIP_ROADWORKS",
	"police": "RUN_TIP_POLICE",
	"barrier": "RUN_TIP_ROADWORKS",
	"truck": "RUN_TIP_TRUCK",
	"pedestrian": "RUN_TIP_PEDESTRIAN",
	"tire": "RUN_TIP_TIRE",
	"mbuzi": "RUN_TIP_MBUZI",
	"fuel": "RUN_TIP_FUEL",
}

func _ready() -> void:
	UIFactory.paint_background(self, UIFactory.COL_BG)

	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 18
	scroll.offset_right = -18
	scroll.offset_top = 12 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	scroll.offset_bottom = -76 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	scroll.add_child(v)

	# A light entrance without fighting ScrollContainer's layout positioning.
	v.modulate.a = 0.0
	var entrance := v.create_tween()
	entrance.tween_property(v, "modulate:a", 1.0, 0.35)

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

	# Contextual coaching turns a failed run into a useful next decision.
	var coach_panel := PanelContainer.new()
	var coach_style := StyleBoxFlat.new()
	coach_style.bg_color = Color("#2b191c")
	coach_style.border_color = UIFactory.COL_DANGER.darkened(0.20)
	coach_style.border_width_left = 4
	coach_style.corner_radius_top_left = 8
	coach_style.corner_radius_top_right = 8
	coach_style.corner_radius_bottom_left = 8
	coach_style.corner_radius_bottom_right = 8
	coach_style.content_margin_left = 12
	coach_style.content_margin_right = 12
	coach_style.content_margin_top = 8
	coach_style.content_margin_bottom = 8
	coach_panel.add_theme_stylebox_override("panel", coach_style)
	v.add_child(coach_panel)
	var coach_content := VBoxContainer.new()
	coach_content.add_theme_constant_override("separation", 3)
	coach_panel.add_child(coach_content)
	_coach_title_lbl = UIFactory.make_label("", 13, UIFactory.COL_ACCENT)
	_coach_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	coach_content.add_child(_coach_title_lbl)
	_coach_body_lbl = UIFactory.make_label("", 15, UIFactory.COL_TEXT)
	_coach_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_coach_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coach_content.add_child(_coach_body_lbl)

	_next_step_lbl = UIFactory.make_label("", 16, UIFactory.COL_PRIMARY)
	_next_step_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_step_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_next_step_lbl)

	# One compact service-quality panel makes a failed run feel useful without
	# adding another currency or turning the results screen into a dashboard.
	var reputation_panel := UIFactory.make_panel()
	reputation_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(reputation_panel)
	var reputation_box := VBoxContainer.new()
	reputation_box.add_theme_constant_override("separation", 4)
	reputation_panel.add_child(reputation_box)
	_reputation_title_lbl = UIFactory.make_label("", 16, UIFactory.COL_PRIMARY)
	reputation_box.add_child(_reputation_title_lbl)
	_reputation_body_lbl = UIFactory.make_label("", 15, UIFactory.COL_TEXT)
	_reputation_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reputation_box.add_child(_reputation_body_lbl)
	_discovery_lbl = UIFactory.make_label("", 15, UIFactory.COL_ACCENT)
	_discovery_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_discovery_lbl)

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
	_contract_lbl = _stat_label(stats, Color("#2ecc71"), 18)
	_daily_lbl = _stat_label(stats, UIFactory.COL_ACCENT, 18)
	_mastery_lbl = _stat_label(stats, UIFactory.COL_PRIMARY, 18)
	_flow_lbl = _stat_label(stats, UIFactory.COL_ACCENT, 18)
	_best_lbl  = _stat_label(stats, UIFactory.COL_MUTED, 16)

	_progression_lbl = UIFactory.make_label("", 16, UIFactory.COL_PRIMARY)
	_progression_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_progression_lbl)

	# Completed missions banner
	for t in GameState.last_missions_completed:
		var m_lbl := _stat_label(stats, Color("#2ecc71"), 16)
		m_lbl.text = "✓ %s  +%d 🪙" % [
			LocaleManager.t(String(t.key)).replace("{n}", str(int(t.target))),
			int(t.reward),
		]

	# The local Top-5 and online route personal bests have separate rules.
	# A route PB can be queued for upload even if it does not enter Top-5.
	if SaveSystem.qualifies_for_leaderboard(GameState.last_score) or GameState.last_is_route_record:
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
		_name_edit.max_length = 16
		_name_edit.placeholder_text = LocaleManager.t("LEADERBOARD_NAME_HINT")
		_name_edit.text = SaveSystem.get_leaderboard_display_name()
		_name_edit.custom_minimum_size = Vector2(150, 44)
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

	_ad_row = HBoxContainer.new()
	_ad_row.add_theme_constant_override("separation", 8)
	_ad_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_ad_row)

	_continue_btn = UIFactory.make_button("", false)
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_btn.custom_minimum_size = Vector2(0, 50)
	_continue_btn.pressed.connect(_on_continue_ad)
	_ad_row.add_child(_continue_btn)

	_double_btn = UIFactory.make_button("", false)
	_double_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_double_btn.custom_minimum_size = Vector2(0, 50)
	_double_btn.pressed.connect(_on_double_coins_ad)
	_ad_row.add_child(_double_btn)

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
	_replay_btn = UIFactory.make_button("", false)
	_replay_btn.pressed.connect(_on_copy_replay)
	v.add_child(_replay_btn)
	# Keep the final action comfortably above the fixed results banner after the
	# player scrolls to the bottom on short portrait screens.
	v.add_child(_spacer(18))

	AdService.rewarded_result.connect(_on_rewarded_result)
	AdService.interstitial_closed.connect(_on_interstitial_closed)
	AdService.show_banner(self, AdService.PLACEMENT_BANNER_RESULTS)
	_refresh_reward_actions()

	LocaleManager.locale_changed.connect(_refresh)
	_refresh()
	set_process(true)

func _exit_tree() -> void:
	AdService.hide_banner()

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
	if GameState.last_mastery_bonus_coins > 0:
		_coins_lbl.text += " (+%d)" % GameState.last_mastery_bonus_coins
	_pass_lbl.text  = "%s: %d   |   %s: %d (+%d 🪙)" % [
		LocaleManager.t("PASSENGERS"), int(_anim_pass),
		LocaleManager.t("DROPOFFS"), GameState.last_dropoffs, GameState.last_fares,
	]
	var goal_status := LocaleManager.t("GOAL_COMPLETE") if GameState.last_route_goal_met else LocaleManager.t("GOAL_FAILED")
	_goal_lbl.text  = "%s: %s  %s" % [LocaleManager.t("ROUTE_GOAL"), goal_status, GameState.last_route_goal_progress]
	_contract_lbl.text = _contract_result_text()
	_contract_lbl.visible = not _contract_lbl.text.is_empty()
	_daily_lbl.text = _daily_result_text()
	_mastery_lbl.text = _mastery_result_text()
	_flow_lbl.text = LocaleManager.t("FLOW_RESULT").replace("{n}", str(GameState.last_combo_peak))
	_flow_lbl.visible = GameState.last_combo_peak >= 2
	_best_lbl.text  = "%s: %d"    % [LocaleManager.t("BEST"),       int(SaveSystem.get_value("best_score", 0))]

func _refresh(_l := "") -> void:
	_title_lbl.text = LocaleManager.t("GAME_OVER")
	_record_lbl.text = LocaleManager.t("NEW_RECORD")
	_route_record_lbl.text = LocaleManager.t("ROUTE_RECORD")
	var star_key := "STARS_%d" % clamp(_calc_stars(), 1, 3)
	_tagline_lbl.text = LocaleManager.t(star_key)
	_coach_title_lbl.text = LocaleManager.t("RUN_COACH_TITLE")
	var tip_key: String = String(END_TIP_KEYS.get(GameState.last_end_reason, "RUN_TIP_GENERAL"))
	_coach_body_lbl.text = LocaleManager.t(tip_key)
	_next_step_lbl.text = _next_step_text()
	_reputation_title_lbl.text = "%s: %s  %d/100" % [
		LocaleManager.t("HUDUMA_RATING"), GameState.last_reputation_grade, GameState.last_reputation,
	]
	_reputation_title_lbl.add_theme_color_override("font_color", _reputation_color())
	_reputation_body_lbl.text = _reputation_summary_text()
	_progression_lbl.text = _progression_text()
	_discovery_lbl.visible = not GameState.last_discovery_key.is_empty()
	_discovery_lbl.text = "%s\n%s" % [
		LocaleManager.t("DISCOVERY_TITLE"), LocaleManager.t(GameState.last_discovery_key),
	]
	_play_btn.text  = LocaleManager.t("PLAY_AGAIN")
	_menu_btn.text  = LocaleManager.t("MAIN_MENU")
	_lb_btn.text    = LocaleManager.t("LEADERBOARD")
	_share_btn.text = LocaleManager.t("SHARE_SCORE")
	_replay_btn.text = LocaleManager.t("REPLAY_CLIP_COPY")
	_replay_btn.disabled = GhostDataLib.encode(SaveSystem.get_value("latest_replay", {})).is_empty()
	_continue_btn.text = LocaleManager.t("CONTINUE_AD")
	_double_btn.text = LocaleManager.t("DOUBLE_COINS_VALUE").replace("{n}", str(GameState.last_coins))
	if _ad_row.visible and not _reward_in_progress:
		_ad_msg_lbl.text = LocaleManager.t("REWARDED_CHOICE")
	if _submit_btn and not _score_submitted:
		_submit_btn.text = LocaleManager.t("SUBMIT")
	_update_stats_labels()

func _next_step_text() -> String:
	# A fuel failure needs an immediate, actionable recovery hint before progression.
	if GameState.last_end_reason == "fuel":
		return "%s: %s" % [LocaleManager.t("NEXT_STEP"), LocaleManager.t("NEXT_STEP_FUEL")]
	var route: Dictionary = Routes.get_by_id(GameState.selected_route_id)
	var focus: Dictionary = Routes.next_mastery_target(route, GameState.last_mastery_stars)
	if GameState.last_mastery_gained > 0 or not bool(focus.get("complete", false)):
		return "%s: %s" % [LocaleManager.t("NEXT_STEP"), _mastery_target_text(focus)]
	if GameState.last_route_goal_met:
		return "%s: %s" % [LocaleManager.t("NEXT_STEP"), LocaleManager.t("NEXT_STEP_ROUTE")]
	return "%s: %s" % [LocaleManager.t("NEXT_STEP"), LocaleManager.t("NEXT_STEP_RETRY")]

func _progression_text() -> String:
	var coins: int = int(SaveSystem.get_value("total_coins", 0))
	for value in Vehicles.LIST:
		var vehicle: Dictionary = value
		var id: String = String(vehicle.get("id", ""))
		if SaveSystem.is_vehicle_unlocked(id):
			continue
		var price: int = int(vehicle.get("price", 0))
		var left: int = maxi(0, price - coins)
		return LocaleManager.t("NEXT_VEHICLE_PROGRESS") \
			.replace("{name}", LocaleManager.t(String(vehicle.get("name_key", "")))) \
			.replace("{perk}", _vehicle_primary_perk(vehicle)) \
			.replace("{coins}", str(left))
	return LocaleManager.t("NEXT_VEHICLE_ALL_OWNED")

func _vehicle_primary_perk(vehicle: Dictionary) -> String:
	var coin_bonus: int = int(round((float(vehicle.get("coin_mult", 1.0)) - 1.0) * 100.0))
	if coin_bonus > 0:
		return LocaleManager.t("VEHICLE_PERK_COINS").replace("{n}", str(coin_bonus))
	var fuel_bonus: int = int(round((1.0 / float(vehicle.get("fuel_drain_mult", 1.0)) - 1.0) * 100.0))
	if fuel_bonus > 0:
		return LocaleManager.t("VEHICLE_PERK_FUEL").replace("{n}", str(fuel_bonus))
	var handling_bonus: int = int(round((0.14 / float(vehicle.get("lane_time", 0.14)) - 1.0) * 100.0))
	if handling_bonus > 0:
		return LocaleManager.t("VEHICLE_PERK_HANDLING").replace("{n}", str(handling_bonus))
	return LocaleManager.t("VEHICLE_PERK_HORN").replace("{n}", str(int(vehicle.get("horn_charges", 3))))

func _mastery_target_text(focus: Dictionary) -> String:
	if bool(focus.get("complete", false)):
		return LocaleManager.t("MASTERY_COMPLETE")
	var level: int = clampi(int(focus.get("level", 1)), 1, 3)
	return LocaleManager.t("MASTERY_NEXT_%d" % level).replace(
		"{score}", str(int(focus.get("score", 0))))

func _reputation_summary_text() -> String:
	var breakdown: Dictionary = GameState.last_reputation_breakdown
	var lines: Array[String] = [
		LocaleManager.t("REPUTATION_BASE").replace("{n}", str(int(breakdown.get("base", 50))))
	]
	var gains: String = _reputation_items(breakdown, [
		{"field": "dropoffs", "key": "REPUTATION_DROPOFFS"},
		{"field": "passengers", "key": "REPUTATION_PASSENGERS"},
		{"field": "near_misses", "key": "REPUTATION_NEAR_MISSES"},
		{"field": "goal", "key": "REPUTATION_GOAL"},
		{"field": "checkpoints", "key": "REPUTATION_CHECKPOINTS"},
		{"field": "moments", "key": "REPUTATION_MOMENTS"},
	])
	var costs: String = _reputation_items(breakdown, [
		{"field": "missed", "key": "REPUTATION_MISSED_STOPS"},
		{"field": "fines", "key": "REPUTATION_FINES"},
		{"field": "fuel", "key": "REPUTATION_FUEL"},
		{"field": "crash", "key": "REPUTATION_CRASH"},
	])
	var gained: int = int(breakdown.get("positive_total", 0))
	var lost: int = int(breakdown.get("negative_total", 0))
	if gained > 0:
		lines.append(LocaleManager.t("REPUTATION_GAINED") \
			.replace("{n}", str(gained)).replace("{items}", gains))
	if lost > 0:
		lines.append(LocaleManager.t("REPUTATION_COST") \
			.replace("{n}", str(lost)).replace("{items}", costs))
	if GameState.last_best_score_delta > 0:
		lines.append(LocaleManager.t("HIGHLIGHT_BEST_DELTA").replace("{n}", str(GameState.last_best_score_delta)))
	return "\n".join(lines)

func _reputation_items(breakdown: Dictionary, definitions: Array) -> String:
	var parts: Array[String] = []
	for definition_value in definitions:
		var definition: Dictionary = definition_value
		var points: int = int(breakdown.get(String(definition.field), 0))
		if points > 0:
			parts.append(LocaleManager.t(String(definition.key)).replace("{n}", str(points)))
	return ", ".join(parts)

func _reputation_color() -> Color:
	match GameState.last_reputation_grade:
		"A": return Color("#2ecc71")
		"B": return UIFactory.COL_PRIMARY
		"C": return UIFactory.COL_ACCENT
		_: return UIFactory.COL_DANGER

func _refresh_reward_actions() -> void:
	var reward_available: bool = AdService.is_rewarded_available()
	var choice_available: bool = GameState.can_claim_rewarded_choice()
	_continue_btn.visible = reward_available and choice_available and not GameState.continue_used
	_double_btn.visible = reward_available and choice_available and GameState.last_coins > 0
	_ad_row.visible = _continue_btn.visible or _double_btn.visible
	_ad_msg_lbl.visible = _ad_row.visible

func _calc_stars() -> int:
	var sc: int = GameState.last_score
	if sc >= 2000: return 3
	if sc >= 500:  return 2
	return 1

func _daily_result_text() -> String:
	if GameState.last_daily_challenge_rewarded:
		return "%s: %s (+%d)" % [
			LocaleManager.t("DAILY_CHALLENGE"),
			LocaleManager.t("GOAL_COMPLETE"),
			GameState.last_daily_bonus_coins,
		]
	if GameState.last_daily_challenge_met:
		return "%s: %s" % [LocaleManager.t("DAILY_CHALLENGE"), LocaleManager.t("DAILY_COMPLETE")]
	return "%s: %s  %s" % [
		LocaleManager.t("DAILY_CHALLENGE"),
		LocaleManager.t("GOAL_FAILED"),
		GameState.last_daily_challenge_progress,
	]

func _contract_result_text() -> String:
	if GameState.last_route_contract.is_empty():
		return ""
	var description: String = RouteContracts.describe(GameState.last_route_contract)
	if GameState.last_route_contract_rewarded:
		return "%s: %s  +%d 🪙" % [
			LocaleManager.t("ROUTE_CONTRACT"), description, GameState.last_route_contract_bonus_coins,
		]
	var status: String = LocaleManager.t("CONTRACT_COMPLETE") if GameState.last_route_contract_met \
		else GameState.last_route_contract_progress
	return "%s: %s  %s" % [LocaleManager.t("ROUTE_CONTRACT"), description, status]

func _mastery_result_text() -> String:
	var marks: String = _mastery_marks(GameState.last_mastery_stars)
	var text: String = "%s: %s" % [LocaleManager.t("ROUTE_MASTERY"), marks]
	if GameState.last_mastery_gained > 0:
		text += "  " + LocaleManager.t("MASTERY_EARNED").replace(
			"{n}", str(GameState.last_mastery_bonus_coins))
	return text

func _mastery_marks(stars: int) -> String:
	var marks := ""
	for index in range(3):
		marks += "★" if index < clampi(stars, 0, 3) else "☆"
	return marks

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
	var nm: String = SaveSystem.set_leaderboard_display_name(_name_edit.text)
	if SaveSystem.qualifies_for_leaderboard(GameState.last_score):
		SaveSystem.add_to_leaderboard(nm, GameState.last_score, GameState.selected_route_id)
	if OnlineService.is_enabled() and SaveSystem.is_online_leaderboard_opted_in() \
		and OnlineService.has_identity() and GameState.last_is_route_record:
		OnlineService.update_leaderboard_profile(nm)
		OnlineService.queue_leaderboard_submission(GameState.selected_route_id, GameState.last_score)
	_score_submitted = true
	if _submit_btn:
		_submit_btn.text = "✓"
		_submit_btn.disabled = true
	if _name_edit:
		_name_edit.editable = false
	AudioManager.play_sfx("powerup")

func _on_play_again() -> void:
	AudioManager.play_sfx("click")
	_go_after_optional_interstitial("res://scenes/game.tscn")

func _on_main_menu() -> void:
	AudioManager.play_sfx("click")
	_go_after_optional_interstitial("res://scenes/main_menu.tscn")

func _on_view_leaderboard() -> void:
	AudioManager.play_sfx("click")
	_go_after_optional_interstitial("res://scenes/leaderboard.tscn")

func _go_after_optional_interstitial(path: String) -> void:
	if _navigation_in_progress:
		return
	_navigation_in_progress = true
	_play_btn.disabled = true
	_menu_btn.disabled = true
	_lb_btn.disabled = true
	AdService.note_completed_run()
	if AdService.is_interstitial_available() and AdService.consume_pending_interstitial():
		_pending_nav_path = path
		_interstitial_in_progress = true
		_ad_msg_lbl.visible = true
		_ad_msg_lbl.text = LocaleManager.t("AD_INTERSTITIAL_LOADING")
		AdService.show_interstitial(AdService.PLACEMENT_INTERSTITIAL_RUN_END)
		return
	TransitionManager.go_to(path)

func _on_interstitial_closed(_placement: String) -> void:
	if not _interstitial_in_progress:
		return
	var path := _pending_nav_path
	_pending_nav_path = ""
	_interstitial_in_progress = false
	if path == "":
		path = "res://scenes/main_menu.tscn"
	TransitionManager.go_to(path)

func _on_continue_ad() -> void:
	AudioManager.play_sfx("click")
	if _reward_in_progress or GameState.continue_used or not GameState.can_claim_rewarded_choice():
		return
	if not AdService.is_rewarded_available():
		_ad_msg_lbl.text = LocaleManager.t("ADS_SOON")
		return
	_reward_in_progress = true
	_continue_btn.disabled = true
	_double_btn.disabled = true
	_ad_msg_lbl.text = LocaleManager.t("AD_LOADING")
	AdService.show_rewarded(AdService.PLACEMENT_CONTINUE)

func _on_double_coins_ad() -> void:
	AudioManager.play_sfx("click")
	if _reward_in_progress or GameState.last_coins <= 0 or not GameState.can_claim_rewarded_choice():
		return
	if not AdService.is_rewarded_available():
		_ad_msg_lbl.text = LocaleManager.t("ADS_SOON")
		return
	_reward_in_progress = true
	_double_btn.disabled = true
	_continue_btn.disabled = true
	_ad_msg_lbl.text = LocaleManager.t("AD_LOADING")
	AdService.show_rewarded(AdService.PLACEMENT_DOUBLE_COINS)

func _on_rewarded_result(placement: String, success: bool) -> void:
	if not _reward_in_progress:
		return
	_reward_in_progress = false
	if not success:
		_ad_msg_lbl.text = LocaleManager.t("AD_FAILED")
		_continue_btn.disabled = false
		_double_btn.disabled = false
		_refresh_reward_actions()
		return
	match placement:
		AdService.PLACEMENT_CONTINUE:
			if GameState.request_continue():
				TransitionManager.go_to("res://scenes/game.tscn")
		AdService.PLACEMENT_DOUBLE_COINS:
			var doubled_amount: int = GameState.claim_double_coins()
			if doubled_amount > 0:
				AudioManager.play_sfx("powerup")
				_ad_msg_lbl.visible = true
				_ad_msg_lbl.text = "+%d %s" % [doubled_amount, LocaleManager.t("COINS")]
				_ad_row.visible = false
			else:
				_refresh_reward_actions()

func _on_share() -> void:
	AudioManager.play_sfx("click")
	var text: String = LocaleManager.t("SHARE_TEXT").replace("{score}", str(GameState.last_score))
	if OS.get_name() == "Android":
		OS.shell_open("intent:#Intent;action=android.intent.action.SEND;type=text/plain;S.android.intent.extra.TEXT=" + text.uri_encode() + ";end")
	else:
		DisplayServer.clipboard_set(text)
		_ad_msg_lbl.text = LocaleManager.t("SHARE_COPIED")

func _on_copy_replay() -> void:
	var code: String = GhostDataLib.encode(SaveSystem.get_value("latest_replay", {}))
	if code.is_empty():
		_ad_msg_lbl.text = LocaleManager.t("REPLAY_CLIP_MISSING")
		return
	DisplayServer.clipboard_set(code)
	_ad_msg_lbl.visible = true
	_ad_msg_lbl.text = LocaleManager.t("REPLAY_CLIP_COPIED")

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
