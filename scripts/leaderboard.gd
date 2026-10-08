extends Control
## Personal, friends, and world score views. Online views are deliberately
## opt-in and labelled unverified until run verification exists server-side.

const UIFactory := preload("res://ui/ui_factory.gd")
const Routes := preload("res://data/routes.gd")
const GhostDataLib := preload("res://data/ghost_data.gd")

const TAB_PERSONAL := "personal"
const TAB_FRIENDS := "friends"
const TAB_WORLD := "world"

var _title: Label
var _subtitle: Label
var _route_label: Label
var _name_edit: LineEdit
var _save_name_btn: Button
var _join_btn: Button
var _status: Label
var _rows: VBoxContainer
var _personal_btn: Button
var _friends_btn: Button
var _world_btn: Button
var _friend_code_btn: Button
var _copy_friend_code_btn: Button
var _add_friend_btn: Button
var _refresh_btn: Button
var _manage_friends_btn: Button
var _leave_online_btn: Button
var _ghost_msg: Label
var _copy_ghost_btn: Button
var _import_ghost_btn: Button
var _back_btn: Button
var _page_scroll: ScrollContainer
var _upload_status: Label

var _tab := TAB_PERSONAL
var _route_index := 0
var _remote_scores: Array = []
var _friend_code := ""
var _joining_online := false
var _request_serial: int = 0
var _active_request_id: int = 0
var _friends: Array = []
var _blocked_friends: Array = []
var _cached_status: String = ""
var _cached_fetched_at: int = 0
var _remote_state: String = "idle"

func _ready() -> void:
	UIFactory.paint_background(self)
	_page_scroll = ScrollContainer.new()
	_page_scroll.anchor_right = 1.0
	_page_scroll.anchor_bottom = 1.0
	_page_scroll.offset_left = 18
	_page_scroll.offset_right = -18
	_page_scroll.offset_top = 18 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	_page_scroll.offset_bottom = -16 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	_page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_page_scroll)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	_page_scroll.add_child(root)

	_title = UIFactory.make_title("", 30)
	root.add_child(_title)
	_subtitle = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_subtitle)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	root.add_child(name_row)
	_name_edit = LineEdit.new()
	_name_edit.max_length = 16
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.custom_minimum_size = Vector2(0, 46)
	_name_edit.text_submitted.connect(func(_text: String): _on_name_submitted())
	_name_edit.focus_entered.connect(_scroll_name_into_view)
	name_row.add_child(_name_edit)
	_save_name_btn = UIFactory.make_button("", false)
	_save_name_btn.custom_minimum_size = Vector2(112, 46)
	_save_name_btn.pressed.connect(_on_save_name_pressed)
	name_row.add_child(_save_name_btn)

	_join_btn = UIFactory.make_button("", false)
	_join_btn.custom_minimum_size = Vector2(0, 46)
	_join_btn.pressed.connect(_confirm_join_online)
	root.add_child(_join_btn)

	var route_row := HBoxContainer.new()
	route_row.add_theme_constant_override("separation", 8)
	root.add_child(route_row)
	var previous := UIFactory.make_button("‹", false)
	previous.custom_minimum_size = Vector2(54, 46)
	previous.add_theme_font_size_override("font_size", 30)
	previous.pressed.connect(func(): _change_route(-1))
	route_row.add_child(previous)
	_route_label = UIFactory.make_label("", 17, UIFactory.COL_ACCENT)
	_route_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_row.add_child(_route_label)
	var next := UIFactory.make_button("›", false)
	next.custom_minimum_size = Vector2(54, 46)
	next.add_theme_font_size_override("font_size", 30)
	next.pressed.connect(func(): _change_route(1))
	route_row.add_child(next)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	root.add_child(tabs)
	_personal_btn = _make_tab_button(TAB_PERSONAL)
	_friends_btn = _make_tab_button(TAB_FRIENDS)
	_world_btn = _make_tab_button(TAB_WORLD)
	tabs.add_child(_personal_btn)
	tabs.add_child(_friends_btn)
	tabs.add_child(_world_btn)

	var online_actions := HBoxContainer.new()
	online_actions.add_theme_constant_override("separation", 8)
	root.add_child(online_actions)
	_refresh_btn = UIFactory.make_button("", false)
	_refresh_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_refresh_btn.custom_minimum_size = Vector2(0, 44)
	_refresh_btn.pressed.connect(_refresh_remote_scores)
	online_actions.add_child(_refresh_btn)
	_manage_friends_btn = UIFactory.make_button("", false)
	_manage_friends_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_manage_friends_btn.custom_minimum_size = Vector2(0, 44)
	_manage_friends_btn.pressed.connect(_request_friend_list)
	online_actions.add_child(_manage_friends_btn)
	_leave_online_btn = UIFactory.make_button("", false)
	_leave_online_btn.custom_minimum_size = Vector2(0, 42)
	UIFactory.tint_button(_leave_online_btn, UIFactory.COL_DANGER)
	_leave_online_btn.pressed.connect(_confirm_leave_online)
	root.add_child(_leave_online_btn)

	_status = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)
	_upload_status = UIFactory.make_label("", 14, UIFactory.COL_ACCENT)
	_upload_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_upload_status)

	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 6)
	root.add_child(_rows)

	var friend_actions := HBoxContainer.new()
	friend_actions.add_theme_constant_override("separation", 8)
	root.add_child(friend_actions)
	_friend_code_btn = UIFactory.make_button("", false)
	_friend_code_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_friend_code_btn.custom_minimum_size = Vector2(0, 46)
	_friend_code_btn.pressed.connect(_create_friend_code)
	friend_actions.add_child(_friend_code_btn)
	_copy_friend_code_btn = UIFactory.make_button("", false)
	_copy_friend_code_btn.custom_minimum_size = Vector2(80, 46)
	_copy_friend_code_btn.pressed.connect(_copy_friend_code)
	friend_actions.add_child(_copy_friend_code_btn)
	_add_friend_btn = UIFactory.make_button("", false)
	_add_friend_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_friend_btn.custom_minimum_size = Vector2(0, 46)
	_add_friend_btn.pressed.connect(_show_friend_claim_dialog)
	friend_actions.add_child(_add_friend_btn)

	_ghost_msg = UIFactory.make_label("", 13, UIFactory.COL_MUTED)
	root.add_child(_ghost_msg)
	var ghost_row := HBoxContainer.new()
	ghost_row.add_theme_constant_override("separation", 8)
	root.add_child(ghost_row)
	_copy_ghost_btn = UIFactory.make_button("", false)
	_copy_ghost_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_copy_ghost_btn.custom_minimum_size = Vector2(0, 44)
	_copy_ghost_btn.pressed.connect(_on_copy_ghost)
	ghost_row.add_child(_copy_ghost_btn)
	_import_ghost_btn = UIFactory.make_button("", false)
	_import_ghost_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_import_ghost_btn.custom_minimum_size = Vector2(0, 44)
	_import_ghost_btn.pressed.connect(_on_import_ghost)
	ghost_row.add_child(_import_ghost_btn)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.custom_minimum_size = Vector2(0, 48)
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)

	LocaleManager.locale_changed.connect(func(_locale := ""): _refresh())
	OnlineService.request_finished.connect(_on_online_request_finished)
	_refresh()
	if _tab != TAB_PERSONAL:
		_request_remote_scores()

func _scroll_name_into_view() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(_page_scroll) or not is_instance_valid(_name_edit):
		return
	var field_bottom: float = _name_edit.get_global_rect().end.y
	var viewport_bottom: float = _page_scroll.get_global_rect().end.y
	if field_bottom > viewport_bottom:
		_page_scroll.scroll_vertical += int(ceil(field_bottom - viewport_bottom + 24.0))

func _on_name_submitted() -> void:
	_on_save_name_pressed()

func _on_save_name_pressed() -> void:
	_save_name()
	_name_edit.release_focus()
	DisplayServer.virtual_keyboard_hide()

func _make_tab_button(tab_id: String) -> Button:
	var button := UIFactory.make_button("", false)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(func(): _select_tab(tab_id))
	return button

static func dialog_width_for_viewport(viewport_width: float, preferred_width: int) -> int:
	return maxi(240, mini(preferred_width, int(viewport_width) - 32))

func _current_route() -> Dictionary:
	if Routes.LIST.is_empty():
		return {}
	_route_index = posmod(_route_index, Routes.LIST.size())
	return Routes.LIST[_route_index] as Dictionary

func _current_route_id() -> String:
	return String(_current_route().get("id", "kariakoo"))

func _refresh() -> void:
	_title.text = LocaleManager.t("LEADERBOARD")
	_subtitle.text = LocaleManager.t("LEADERBOARD_ONLINE_BODY")
	_name_edit.placeholder_text = LocaleManager.t("LEADERBOARD_NAME_HINT")
	if not _name_edit.has_focus():
		_name_edit.text = SaveSystem.get_leaderboard_display_name()
	_save_name_btn.text = LocaleManager.t("LEADERBOARD_SAVE_NAME")
	_join_btn.text = LocaleManager.t("LEADERBOARD_ONLINE_JOIN")
	_join_btn.visible = not SaveSystem.is_online_leaderboard_opted_in()
	_join_btn.disabled = not OnlineService.is_enabled()
	var route: Dictionary = _current_route()
	_route_label.text = LocaleManager.t("LEADERBOARD_ROUTE") + ": " + LocaleManager.t(String(route.get("name_key", "ROUTE_KARIAKOO")))
	_personal_btn.text = LocaleManager.t("LEADERBOARD_PERSONAL")
	_friends_btn.text = LocaleManager.t("LEADERBOARD_FRIENDS")
	_world_btn.text = LocaleManager.t("LEADERBOARD_WORLD")
	_refresh_tab_style(_personal_btn, TAB_PERSONAL)
	_refresh_tab_style(_friends_btn, TAB_FRIENDS)
	_refresh_tab_style(_world_btn, TAB_WORLD)
	_friend_code_btn.text = LocaleManager.t("LEADERBOARD_CREATE_CODE")
	_copy_friend_code_btn.text = "📋"
	_copy_friend_code_btn.tooltip_text = LocaleManager.t("LEADERBOARD_COPY_CODE")
	_add_friend_btn.text = LocaleManager.t("LEADERBOARD_ADD_FRIEND")
	_refresh_btn.text = LocaleManager.t("LEADERBOARD_REFRESH")
	_manage_friends_btn.text = LocaleManager.t("LEADERBOARD_MANAGE_FRIENDS")
	_leave_online_btn.text = LocaleManager.t("LEADERBOARD_LEAVE")
	var show_friend_actions: bool = _tab == TAB_FRIENDS
	_friend_code_btn.visible = show_friend_actions
	_copy_friend_code_btn.visible = show_friend_actions and not _friend_code.is_empty()
	_add_friend_btn.visible = show_friend_actions
	var friend_controls_ready: bool = OnlineService.is_enabled() and SaveSystem.is_online_leaderboard_opted_in() and OnlineService.has_identity()
	_friend_code_btn.disabled = not friend_controls_ready
	_add_friend_btn.disabled = not friend_controls_ready
	var pending: int = OnlineService.pending_leaderboard_submission_count()
	_refresh_btn.visible = _tab != TAB_PERSONAL or pending > 0
	_refresh_btn.disabled = not OnlineService.is_enabled() or OnlineService.leaderboard_submission_wait_seconds() > 0
	_refresh_btn.text = LocaleManager.t("LEADERBOARD_RETRY") if pending > 0 else LocaleManager.t("LEADERBOARD_REFRESH")
	_manage_friends_btn.visible = show_friend_actions
	_manage_friends_btn.disabled = not friend_controls_ready
	_leave_online_btn.visible = SaveSystem.is_online_leaderboard_opted_in()
	_leave_online_btn.disabled = not OnlineService.is_enabled() or not OnlineService.has_identity()
	_ghost_msg.text = ""
	var rival: Variant = SaveSystem.get_value("ghost_rival", null)
	if typeof(rival) == TYPE_DICTIONARY:
		_ghost_msg.text = LocaleManager.t("GHOST_RIVAL_SET").replace("{n}", str(int((rival as Dictionary).get("score", 0))))
	_copy_ghost_btn.text = "👻 " + LocaleManager.t("GHOST_COPY")
	_import_ghost_btn.text = "📥 " + LocaleManager.t("GHOST_IMPORT")
	_back_btn.text = LocaleManager.t("BACK")
	if _tab == TAB_PERSONAL:
		_status.text = LocaleManager.t("LEADERBOARD_PERSONAL_BODY")
	elif not OnlineService.is_enabled():
		_status.text = LocaleManager.t("LEADERBOARD_ONLINE_DISABLED")
	elif _tab == TAB_WORLD:
		_status.text = LocaleManager.t("LEADERBOARD_UNVERIFIED") if SaveSystem.is_online_leaderboard_opted_in() \
			else LocaleManager.t("LEADERBOARD_WORLD_OPEN")
	elif _tab == TAB_FRIENDS and not SaveSystem.is_online_leaderboard_opted_in():
		_status.text = LocaleManager.t("LEADERBOARD_FRIENDS_OPT_IN")
	else:
		_status.text = LocaleManager.t("LEADERBOARD_ONLINE_BODY")
	_refresh_upload_status(pending)
	_refresh_rows()

func _refresh_upload_status(pending: int) -> void:
	var state: Dictionary = SaveSystem.get_leaderboard_upload_state()
	var status: String = String(state.get("status", ""))
	if pending > 0:
		match status:
			"retry":
				_upload_status.text = LocaleManager.t("LEADERBOARD_UPLOAD_RETRY")
			"rate_limited":
				_upload_status.text = LocaleManager.t("LEADERBOARD_UPLOAD_RATE_LIMITED")
			"invalid_name":
				_upload_status.text = LocaleManager.t("LEADERBOARD_UPLOAD_NAME_INVALID")
			_:
				_upload_status.text = LocaleManager.t("LEADERBOARD_PENDING").replace("{n}", str(pending))
		return
	match status:
		"submitted":
			_upload_status.text = _upload_result_text("LEADERBOARD_UPLOAD_DONE", state)
		"superseded":
			_upload_status.text = LocaleManager.t("LEADERBOARD_UPLOAD_SUPERSEDED")
		"retry":
			_upload_status.text = LocaleManager.t("LEADERBOARD_UPLOAD_RETRY")
		"rate_limited":
			_upload_status.text = LocaleManager.t("LEADERBOARD_UPLOAD_RATE_LIMITED")
		"invalid_name":
			_upload_status.text = LocaleManager.t("LEADERBOARD_UPLOAD_NAME_INVALID")
		_:
			_upload_status.text = ""

func _upload_result_text(key: String, state: Dictionary) -> String:
	var route_name: String = String(state.get("route", "kariakoo"))
	for route_value in Routes.LIST:
		var route: Dictionary = route_value
		if String(route.get("id", "")) == route_name:
			route_name = LocaleManager.t(String(route.get("name_key", "ROUTE_KARIAKOO")))
			break
	return LocaleManager.t(key).replace("{route}", route_name) \
		.replace("{score}", str(int(state.get("score", 0))))

func _refresh_tab_style(button: Button, tab_id: String) -> void:
	UIFactory.tint_button(button, UIFactory.COL_PRIMARY if _tab == tab_id else UIFactory.COL_PANEL)

func _refresh_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	var scores: Array = []
	if _tab == TAB_PERSONAL:
		scores = SaveSystem.get_personal_route_scores(_current_route_id())
	else:
		scores = _remote_scores
	if _tab == TAB_FRIENDS and not scores.is_empty():
		_add_friend_target(scores)
	elif _tab == TAB_WORLD and not scores.is_empty():
		_add_world_target(scores)
	if scores.is_empty():
		var empty_key := "NO_SCORES_YET"
		if _tab != TAB_PERSONAL and _remote_state == "loading" and _cached_status.is_empty():
			empty_key = "LEADERBOARD_LOADING"
		elif _tab != TAB_PERSONAL and _remote_state == "offline":
			empty_key = "LEADERBOARD_OFFLINE"
		elif _tab == TAB_FRIENDS and not SaveSystem.is_online_leaderboard_opted_in():
			empty_key = "LEADERBOARD_FRIENDS_OPT_IN"
		elif _tab == TAB_FRIENDS:
			empty_key = "LEADERBOARD_FRIENDS_EMPTY"
		elif _tab == TAB_WORLD:
			empty_key = "LEADERBOARD_WORLD_EMPTY"
		var empty := UIFactory.make_label(LocaleManager.t(empty_key), 18, UIFactory.COL_MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(0, 100)
		_rows.add_child(empty)
		return
	for index in range(scores.size()):
		var entry: Dictionary = scores[index] as Dictionary
		_add_score_row(int(entry.get("rank", index + 1)), entry)

func _add_friend_target(scores: Array) -> void:
	var your_score: int = SaveSystem.get_route_best(_current_route_id())
	var rival: Dictionary = {}
	for value in scores:
		if value is not Dictionary:
			continue
		var score: Dictionary = value
		if not bool(score.get("isYou", false)) and int(score.get("score", 0)) > your_score:
			rival = score
			break
	if rival.is_empty():
		return
	var target: int = int(rival.get("score", 0)) + 120
	var hint := UIFactory.make_label(LocaleManager.t("LEADERBOARD_BEAT_TARGET") \
		.replace("{name}", String(rival.get("displayName", ""))).replace("{score}", str(target)), 15, UIFactory.COL_PRIMARY)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(hint)

static func points_to_overtake(own_score: int, rival_score: int) -> int:
	return maxi(0, rival_score - own_score + 1)

func _add_world_target(scores: Array) -> void:
	var your_score: int = SaveSystem.get_route_best(_current_route_id())
	var rival: Dictionary = {}
	for value in scores:
		if value is not Dictionary:
			continue
		var score: Dictionary = value
		var score_value: int = int(score.get("score", 0))
		if bool(score.get("isYou", false)) or score_value <= your_score:
			continue
		if rival.is_empty() or score_value < int(rival.get("score", 0)):
			rival = score
	if rival.is_empty():
		return
	var points: int = points_to_overtake(your_score, int(rival.get("score", 0)))
	var hint := UIFactory.make_label(LocaleManager.t("LEADERBOARD_WORLD_TARGET") \
		.replace("{name}", String(rival.get("displayName", ""))) \
		.replace("{points}", str(points)), 15, UIFactory.COL_PRIMARY)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(hint)

func _add_score_row(rank: int, entry: Dictionary) -> void:
	var panel := UIFactory.make_panel(UIFactory.COL_PANEL.lightened(0.02))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 52)
	_rows.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var rank_label := UIFactory.make_label("#%d" % rank, 19, UIFactory.COL_ACCENT if rank == 1 else UIFactory.COL_MUTED)
	rank_label.custom_minimum_size = Vector2(38, 0)
	row.add_child(rank_label)
	var name := String(entry.get("displayName", entry.get("name", "Dereva")))
	if bool(entry.get("isYou", false)):
		name += " " + LocaleManager.t("LEADERBOARD_YOU")
	var name_label := UIFactory.make_label(name, 16, UIFactory.COL_PRIMARY if bool(entry.get("isYou", false)) else UIFactory.COL_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.tooltip_text = name
	row.add_child(name_label)
	var score_label := UIFactory.make_label(str(int(entry.get("score", 0))), 19, UIFactory.COL_ACCENT)
	score_label.custom_minimum_size = Vector2(82, 0)
	row.add_child(score_label)
	var report_ref: String = String(entry.get("reportRef", ""))
	if _tab != TAB_PERSONAL and not bool(entry.get("isYou", false)) and not report_ref.is_empty():
		var report := UIFactory.make_button("⚑", false)
		report.custom_minimum_size = Vector2(40, 40)
		report.tooltip_text = LocaleManager.t("LEADERBOARD_REPORT")
		report.pressed.connect(func(): _show_report_dialog(report_ref))
		row.add_child(report)

func _select_tab(tab_id: String) -> void:
	if _tab == tab_id:
		return
	AudioManager.play_sfx("click")
	_tab = tab_id
	_remote_scores.clear()
	_refresh()
	_request_remote_scores()

func _change_route(delta: int) -> void:
	if Routes.LIST.is_empty():
		return
	AudioManager.play_sfx("click")
	_route_index = posmod(_route_index + delta, Routes.LIST.size())
	_remote_scores.clear()
	_refresh()
	_request_remote_scores()

func _refresh_remote_scores() -> void:
	AudioManager.play_sfx("click")
	_request_remote_scores()

func _request_remote_scores() -> void:
	if not OnlineService.is_enabled():
		return
	OnlineService.retry_pending_leaderboard_submissions()
	if _tab == TAB_PERSONAL:
		return
	_request_serial += 1
	_active_request_id = _request_serial
	_cached_status = ""
	_cached_fetched_at = 0
	_remote_state = "loading"
	var cached: Dictionary = SaveSystem.get_cached_online_leaderboard(_tab, _current_route_id())
	var cached_scores: Variant = cached.get("scores", [])
	if cached_scores is Array:
		_remote_scores = cached_scores as Array
		_refresh_rows()
		var fetched_at: int = int(cached.get("fetched_at", 0))
		if fetched_at > 0:
			_cached_fetched_at = fetched_at
			_cached_status = LocaleManager.t("LEADERBOARD_CACHED").replace("{time}", _cache_time_text(fetched_at))
	_status.text = LocaleManager.t("LEADERBOARD_LOADING") if _cached_status.is_empty() else LocaleManager.t("LEADERBOARD_REFRESHING_CACHED").replace("{time}", _cache_time_text(_cached_fetched_at))
	if _tab == TAB_FRIENDS:
		OnlineService.fetch_friends_leaderboard(_current_route_id(), _active_request_id)
	else:
		OnlineService.fetch_global_leaderboard(_current_route_id(), _active_request_id)

func _cache_time_text(fetched_at: int) -> String:
	var age: int = maxi(0, int(Time.get_unix_time_from_system()) - fetched_at)
	return "%dm" % maxi(0, age / 60)

func _save_name() -> bool:
	AudioManager.play_sfx("click")
	var candidate: String = SaveSystem.normalize_leaderboard_name(_name_edit.text)
	if SaveSystem.is_reserved_leaderboard_name(candidate):
		_status.text = LocaleManager.t("LEADERBOARD_NAME_RESERVED")
		return false
	var name: String = SaveSystem.set_leaderboard_display_name(candidate)
	_name_edit.text = name
	_status.text = LocaleManager.t("LEADERBOARD_PROFILE_SAVED")
	if OnlineService.is_enabled() and SaveSystem.is_online_leaderboard_opted_in() and OnlineService.has_identity():
		OnlineService.update_leaderboard_profile(name)
	return true

func _confirm_join_online() -> void:
	_name_edit.release_focus()
	DisplayServer.virtual_keyboard_hide()
	if not OnlineService.is_enabled():
		_status.text = LocaleManager.t("LEADERBOARD_ONLINE_DISABLED")
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("LEADERBOARD_ONLINE_JOIN")
	dialog.dialog_text = LocaleManager.t("LEADERBOARD_JOIN_CONFIRM")
	dialog.ok_button_text = LocaleManager.t("LEADERBOARD_ONLINE_JOIN")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	dialog.confirmed.connect(func():
		if not _save_name():
			return
		_joining_online = true
		if OnlineService.has_identity():
			OnlineService.update_leaderboard_profile(SaveSystem.get_leaderboard_display_name())
		else:
			OnlineService.register_installation()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(dialog_width_for_viewport(get_viewport_rect().size.x, 440), 0))

func _create_friend_code() -> void:
	AudioManager.play_sfx("click")
	_status.text = LocaleManager.t("LEADERBOARD_LOADING")
	OnlineService.create_leaderboard_friend_code()

func _copy_friend_code() -> void:
	if _friend_code.is_empty():
		return
	DisplayServer.clipboard_set(_friend_code)
	_status.text = LocaleManager.t("LEADERBOARD_CODE_COPIED")
	AudioManager.play_sfx("powerup")

func _show_friend_claim_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("LEADERBOARD_ADD_FRIEND_TITLE")
	dialog.dialog_text = LocaleManager.t("LEADERBOARD_ADD_FRIEND_BODY")
	dialog.ok_button_text = LocaleManager.t("LEADERBOARD_ADD_FRIEND")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	var field := LineEdit.new()
	field.placeholder_text = LocaleManager.t("LEADERBOARD_CODE_HINT")
	field.max_length = 40
	field.custom_minimum_size = Vector2(0, 48)
	dialog.add_child(field)
	dialog.confirmed.connect(func():
		_status.text = LocaleManager.t("LEADERBOARD_LOADING")
		OnlineService.claim_leaderboard_friend_code(field.text)
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(dialog_width_for_viewport(get_viewport_rect().size.x, 440), 0))
	field.grab_focus()

func _request_friend_list() -> void:
	_request_serial += 1
	OnlineService.fetch_leaderboard_friends(_request_serial)

func _show_friend_manager() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = LocaleManager.t("LEADERBOARD_MANAGE_FRIENDS")
	dialog.ok_button_text = LocaleManager.t("BACK")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var blocked_button := UIFactory.make_button(LocaleManager.t("LEADERBOARD_MANAGE_BLOCKED"), false)
	blocked_button.custom_minimum_size = Vector2(0, 42)
	blocked_button.pressed.connect(func():
		OnlineService.fetch_leaderboard_blocks()
		dialog.queue_free()
	)
	list.add_child(blocked_button)
	if _friends.is_empty():
		list.add_child(UIFactory.make_label(LocaleManager.t("LEADERBOARD_NO_FRIENDS"), 16, UIFactory.COL_MUTED))
	for value in _friends:
		if value is not Dictionary:
			continue
		var friend: Dictionary = value
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 46)
		list.add_child(row)
		var name := UIFactory.make_label(String(friend.get("displayName", "Dereva")), 17)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.clip_text = true
		name.tooltip_text = name.text
		row.add_child(name)
		var remove := UIFactory.make_button(LocaleManager.t("LEADERBOARD_REMOVE_FRIEND"), false)
		remove.custom_minimum_size = Vector2(82, 40)
		remove.pressed.connect(func():
			OnlineService.remove_leaderboard_friend(String(friend.get("friendId", "")))
			dialog.queue_free()
		)
		row.add_child(remove)
		var block := UIFactory.make_button(LocaleManager.t("LEADERBOARD_BLOCK_FRIEND"), false)
		block.custom_minimum_size = Vector2(82, 40)
		UIFactory.tint_button(block, UIFactory.COL_DANGER)
		block.pressed.connect(func():
			_show_block_dialog(String(friend.get("friendId", "")), String(friend.get("displayName", "Dereva")))
			dialog.queue_free()
		)
		row.add_child(block)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(dialog_width_for_viewport(get_viewport_rect().size.x, 460), 0))

func _show_block_manager() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = LocaleManager.t("LEADERBOARD_MANAGE_BLOCKED")
	dialog.ok_button_text = LocaleManager.t("BACK")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	if _blocked_friends.is_empty():
		list.add_child(UIFactory.make_label(LocaleManager.t("LEADERBOARD_NO_BLOCKED"), 16, UIFactory.COL_MUTED))
	for value in _blocked_friends:
		if value is not Dictionary:
			continue
		var blocked: Dictionary = value
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 46)
		list.add_child(row)
		var driver_name := UIFactory.make_label(String(blocked.get("displayName", "Dereva")), 16)
		driver_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		driver_name.clip_text = true
		driver_name.tooltip_text = driver_name.text
		row.add_child(driver_name)
		var unblock := UIFactory.make_button(LocaleManager.t("LEADERBOARD_UNBLOCK"), false)
		unblock.custom_minimum_size = Vector2(100, 40)
		unblock.pressed.connect(func():
			OnlineService.unblock_leaderboard_friend(String(blocked.get("friendId", "")))
			dialog.queue_free()
		)
		row.add_child(unblock)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(dialog_width_for_viewport(get_viewport_rect().size.x, 420), 0))

func _show_report_dialog(report_ref: String) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("LEADERBOARD_REPORT_TITLE")
	dialog.dialog_text = LocaleManager.t("LEADERBOARD_REPORT_BODY")
	dialog.ok_button_text = LocaleManager.t("LEADERBOARD_REPORT")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	var reason := OptionButton.new()
	var reason_ids := ["impersonation", "offensive_name", "other"]
	var reason_keys := ["LEADERBOARD_REPORT_IMPERSONATION", "LEADERBOARD_REPORT_OFFENSIVE", "LEADERBOARD_REPORT_OTHER"]
	for key in reason_keys:
		reason.add_item(LocaleManager.t(key))
	dialog.add_child(reason)
	dialog.confirmed.connect(func():
		OnlineService.report_leaderboard_entry(report_ref, _current_route_id(), reason_ids[reason.selected])
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(dialog_width_for_viewport(get_viewport_rect().size.x, 440), 0))

func _show_block_dialog(friend_id: String, friend_name: String) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("LEADERBOARD_BLOCK_FRIEND")
	dialog.dialog_text = LocaleManager.t("LEADERBOARD_BLOCK_CONFIRM") + "\n" + friend_name
	dialog.ok_button_text = LocaleManager.t("LEADERBOARD_BLOCK_FRIEND")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	dialog.confirmed.connect(func():
		OnlineService.block_leaderboard_friend(friend_id)
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(dialog_width_for_viewport(get_viewport_rect().size.x, 440), 0))

func _confirm_leave_online() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("LEADERBOARD_LEAVE")
	dialog.dialog_text = LocaleManager.t("LEADERBOARD_LEAVE_BODY")
	dialog.ok_button_text = LocaleManager.t("LEADERBOARD_LEAVE")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	dialog.confirmed.connect(func():
		OnlineService.leave_online_leaderboard()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(dialog_width_for_viewport(get_viewport_rect().size.x, 440), 0))

func _on_online_request_finished(operation: String, success: bool, payload: Dictionary) -> void:
	if operation == "registration":
		if success and _joining_online and OnlineService.has_identity():
			OnlineService.update_leaderboard_profile(SaveSystem.get_leaderboard_display_name())
			return
		if _joining_online:
			_joining_online = false
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_profile":
		if success and _joining_online:
			_joining_online = false
			SaveSystem.set_online_leaderboard_opt_in(true)
			OnlineService.queue_existing_route_personal_bests()
			_status.text = LocaleManager.t("LEADERBOARD_ONLINE_JOINED")
			_refresh()
			_request_remote_scores()
		elif not success:
			_joining_online = false
			_status.text = LocaleManager.t("LEADERBOARD_NAME_RESERVED") \
				if String(payload.get("error", "")) == "invalid_display_name" \
				else LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_global" or operation == "leaderboard_friends":
		if int(payload.get("request_id", -1)) != _active_request_id \
				or String(payload.get("route_id", "")) != _current_route_id() \
				or String(payload.get("tab_id", "")) != _tab:
			return
		if success:
			_remote_state = "success"
			var raw_scores: Variant = payload.get("scores", [])
			_remote_scores = raw_scores as Array if raw_scores is Array else []
			_status.text = LocaleManager.t("LEADERBOARD_UNVERIFIED")
		else:
			_remote_state = "offline"
			if not _cached_status.is_empty():
				_status.text = LocaleManager.t("LEADERBOARD_OFFLINE_CACHED").replace("{time}", _cache_time_text(_cached_fetched_at))
			else:
				_status.text = LocaleManager.t("LEADERBOARD_OFFLINE")
		_refresh_rows()
		return
	if operation == "leaderboard_submit":
		if success:
			_upload_status.text = LocaleManager.t("LEADERBOARD_UPLOAD_DONE") if bool(payload.get("accepted", true)) \
				else LocaleManager.t("LEADERBOARD_UPLOAD_SUPERSEDED")
			_refresh()
		else:
			var failure_key := "LEADERBOARD_UPLOAD_RETRY"
			var failure_reason: String = String(payload.get("error", ""))
			if failure_reason == "rate_limited":
				failure_key = "LEADERBOARD_UPLOAD_RATE_LIMITED"
				_refresh_btn.disabled = true
				var remaining: int = maxi(1, int(payload.get("retryAfterSeconds", 60)))
				get_tree().create_timer(remaining).timeout.connect(func():
					if is_inside_tree():
						_refresh()
				)
			elif failure_reason == "invalid_display_name":
				failure_key = "LEADERBOARD_UPLOAD_NAME_INVALID"
			_upload_status.text = LocaleManager.t(failure_key)
		return
	if operation == "leaderboard_friend_list":
		if success:
			var raw_friends: Variant = payload.get("friends", [])
			_friends = raw_friends as Array if raw_friends is Array else []
			_show_friend_manager()
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_block_list":
		if success:
			var raw_blocks: Variant = payload.get("blocks", [])
			_blocked_friends = raw_blocks as Array if raw_blocks is Array else []
			_show_block_manager()
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_friend_unblock":
		if success:
			_status.text = LocaleManager.t("LEADERBOARD_UNBLOCKED")
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_friend_remove":
		if success:
			_status.text = LocaleManager.t("LEADERBOARD_FRIEND_REMOVED")
			_request_remote_scores()
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_friend_block":
		if success:
			_status.text = LocaleManager.t("LEADERBOARD_BLOCKED")
			_request_remote_scores()
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_report":
		if success:
			_status.text = LocaleManager.t("LEADERBOARD_REPORT_DUPLICATE") if bool(payload.get("duplicate", false)) \
				else LocaleManager.t("LEADERBOARD_REPORT_SENT")
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_leave":
		if success:
			_remote_scores.clear()
			_friends.clear()
			_status.text = LocaleManager.t("LEADERBOARD_LEFT")
			_refresh()
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		return
	if operation == "leaderboard_friend_code":
		if success:
			_friend_code = String(payload.get("inviteCode", ""))
			_status.text = LocaleManager.t("LEADERBOARD_FRIEND_CODE").replace("{code}", _friend_code)
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")
		_refresh()
		return
	if operation == "leaderboard_friend_claim":
		if success:
			_status.text = LocaleManager.t("LEADERBOARD_FRIEND_ADDED")
			_request_remote_scores()
		else:
			_status.text = LocaleManager.t("LEADERBOARD_ERROR")

func _on_copy_ghost() -> void:
	AudioManager.play_sfx("click")
	var ghost: Variant = SaveSystem.get_value("ghost_best", null)
	var code := GhostDataLib.encode(ghost)
	if code.is_empty():
		_ghost_msg.text = LocaleManager.t("GHOST_NONE")
		return
	DisplayServer.clipboard_set(code)
	_ghost_msg.text = LocaleManager.t("GHOST_COPIED")

func _on_import_ghost() -> void:
	AudioManager.play_sfx("click")
	var parsed := GhostDataLib.decode(DisplayServer.clipboard_get())
	if parsed.is_empty():
		_ghost_msg.text = LocaleManager.t("GHOST_BAD_CODE")
		return
	SaveSystem.set_value("ghost_rival", parsed)
	var replay: Dictionary = parsed as Dictionary
	if not String(replay.get("challenge_id", "")).is_empty():
		_ghost_msg.text = LocaleManager.t("GHOST_DAILY_SET")
	elif not String(replay.get("route", "")).is_empty() \
			and String(replay.route) != _current_route_id():
		_ghost_msg.text = LocaleManager.t("GHOST_ROUTE_SET").replace("{route}",
			LocaleManager.t(String(Routes.get_by_id(String(replay.route)).get("name_key", "ROUTE_KARIAKOO"))))
	else:
		_ghost_msg.text = LocaleManager.t("GHOST_RIVAL_SET").replace("{n}", str(int(replay.get("score", 0))))
	AudioManager.play_sfx("powerup")

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")
