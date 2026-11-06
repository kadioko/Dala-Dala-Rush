extends Control

const UIFactory := preload("res://ui/ui_factory.gd")
const PRIVACY_POLICY_URL := "https://kadioko.github.io/Dala-Dala-Rush/privacy-policy.html"

var _title: Label
var _music_btn: CheckButton
var _sfx_btn: CheckButton
var _haptics_btn: CheckButton
var _ghost_btn: CheckButton
var _effects_btn: CheckButton
var _cloud_btn: CheckButton
var _telemetry_btn: CheckButton
var _hub_presence_btn: CheckButton
var _sw_btn: Button
var _en_btn: Button
var _privacy_btn: Button
var _back_btn: Button
var _cloud_backup_btn: Button
var _cloud_restore_btn: Button
var _cloud_delete_btn: Button
var _cloud_transfer_out_btn: Button
var _cloud_transfer_in_btn: Button
var _music_label: Label
var _sfx_label: Label
var _haptics_label: Label
var _ghost_label: Label
var _effects_label: Label
var _lang_label: Label
var _cloud_label: Label
var _telemetry_label: Label
var _hub_presence_label: Label
var _hub_presence_status: Label
var _telemetry_status: Label
var _cloud_status: Label
var _cloud_pending_enable: bool = false
var _cloud_notice_key: String = ""
var _cloud_notice_text: String = ""
var _telemetry_pending_enable: bool = false
var _skip_tutorial_btn: Button
var _ad_privacy_btn: Button
var _battery_label: Label
var _battery_btn: CheckButton
var _perf_btn: Button
var _perf_status: Label
var _perf_notice_key: String = ""

func _ready() -> void:
	UIFactory.paint_background(self)

	var scroll := ScrollContainer.new()
	scroll.anchor_left = 0.0
	scroll.anchor_top = 0.0
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 20
	scroll.offset_right = -20
	scroll.offset_top = 28 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	scroll.offset_bottom = -20 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	scroll.add_child(v)

	_title = UIFactory.make_title("", 34)
	v.add_child(_title)

	_music_label = _make_setting_label()
	_music_btn = _make_switch()
	_music_btn.toggled.connect(_toggle_music)
	v.add_child(_make_setting_row(_music_label, _music_btn))

	_sfx_label = _make_setting_label()
	_sfx_btn = _make_switch()
	_sfx_btn.toggled.connect(_toggle_sfx)
	v.add_child(_make_setting_row(_sfx_label, _sfx_btn))

	_haptics_label = _make_setting_label()
	_haptics_btn = _make_switch()
	_haptics_btn.toggled.connect(_toggle_haptics)
	v.add_child(_make_setting_row(_haptics_label, _haptics_btn))

	_ghost_label = _make_setting_label()
	_ghost_btn = _make_switch()
	_ghost_btn.toggled.connect(_toggle_ghost)
	v.add_child(_make_setting_row(_ghost_label, _ghost_btn))

	_effects_label = _make_setting_label()
	_effects_btn = _make_switch()
	_effects_btn.toggled.connect(_toggle_effects)
	v.add_child(_make_setting_row(_effects_label, _effects_btn))
	_battery_label = _make_setting_label()
	_battery_btn = _make_switch()
	_battery_btn.toggled.connect(func(enabled: bool):
		SaveSystem.set_value("battery_saver", enabled)
		Engine.max_fps = 30 if enabled else 60
		_refresh())
	v.add_child(_make_setting_row(_battery_label, _battery_btn))
	if OS.is_debug_build():
		_perf_btn = UIFactory.make_button("", false)
		_perf_btn.pressed.connect(func():
			if PerformanceRecorder.active:
				PerformanceRecorder.stop_capture()
			else:
				PerformanceRecorder.start_capture()
			_refresh())
		v.add_child(_perf_btn)
		_perf_status = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
		v.add_child(_perf_status)
		PerformanceRecorder.capture_finished.connect(func(_path: String, error: Error):
			_perf_notice_key = "PERF_SAVED" if error == OK else "SAVE_ERROR"
			_refresh())

	_cloud_label = _make_setting_label()
	_cloud_btn = _make_switch()
	_cloud_btn.toggled.connect(_toggle_cloud_sync)
	v.add_child(_make_setting_row(_cloud_label, _cloud_btn))

	_telemetry_label = _make_setting_label()
	_telemetry_btn = _make_switch()
	_telemetry_btn.toggled.connect(_toggle_telemetry)
	v.add_child(_make_setting_row(_telemetry_label, _telemetry_btn))
	_telemetry_status = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
	_telemetry_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_telemetry_status)
	_hub_presence_label = _make_setting_label()
	_hub_presence_btn = _make_switch()
	_hub_presence_btn.toggled.connect(_toggle_hub_presence)
	v.add_child(_make_setting_row(_hub_presence_label, _hub_presence_btn))
	_hub_presence_status = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
	_hub_presence_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_hub_presence_status)

	_cloud_status = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
	_cloud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cloud_status.custom_minimum_size = Vector2(0, 36)
	v.add_child(_cloud_status)

	var cloud_actions := UIFactory.make_action_row()
	cloud_actions.add_theme_constant_override("separation", 8)
	v.add_child(cloud_actions)
	_cloud_backup_btn = UIFactory.make_button("", false)
	_cloud_backup_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cloud_backup_btn.custom_minimum_size = Vector2(0, 46)
	_cloud_backup_btn.pressed.connect(_backup_cloud_save)
	cloud_actions.add_child(_cloud_backup_btn)
	_cloud_restore_btn = UIFactory.make_button("", false)
	_cloud_restore_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cloud_restore_btn.custom_minimum_size = Vector2(0, 46)
	_cloud_restore_btn.pressed.connect(_confirm_cloud_restore)
	cloud_actions.add_child(_cloud_restore_btn)
	_cloud_delete_btn = UIFactory.make_button("", false)
	_cloud_delete_btn.custom_minimum_size = Vector2(0, 42)
	UIFactory.tint_button(_cloud_delete_btn, UIFactory.COL_DANGER)
	_cloud_delete_btn.pressed.connect(_confirm_cloud_delete)
	v.add_child(_cloud_delete_btn)
	var transfer_actions := UIFactory.make_action_row()
	transfer_actions.add_theme_constant_override("separation", 8)
	v.add_child(transfer_actions)
	_cloud_transfer_out_btn = UIFactory.make_button("", false)
	_cloud_transfer_out_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cloud_transfer_out_btn.custom_minimum_size = Vector2(0, 42)
	_cloud_transfer_out_btn.pressed.connect(_create_transfer_code)
	transfer_actions.add_child(_cloud_transfer_out_btn)
	_cloud_transfer_in_btn = UIFactory.make_button("", false)
	_cloud_transfer_in_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cloud_transfer_in_btn.custom_minimum_size = Vector2(0, 42)
	_cloud_transfer_in_btn.pressed.connect(_show_transfer_claim_dialog)
	transfer_actions.add_child(_cloud_transfer_in_btn)

	_lang_label = UIFactory.make_label("", 18, UIFactory.COL_MUTED)
	_lang_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(_lang_label)

	var lang_row := UIFactory.make_action_row(120.0)
	lang_row.add_theme_constant_override("separation", 8)
	lang_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(lang_row)

	_sw_btn = UIFactory.make_button("", false)
	_sw_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sw_btn.custom_minimum_size = Vector2(0, 54)
	_sw_btn.pressed.connect(func(): _set_lang("sw"))
	lang_row.add_child(_sw_btn)

	_en_btn = UIFactory.make_button("", false)
	_en_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_en_btn.custom_minimum_size = Vector2(0, 54)
	_en_btn.pressed.connect(func(): _set_lang("en"))
	lang_row.add_child(_en_btn)

	_privacy_btn = UIFactory.make_button("", false)
	_privacy_btn.custom_minimum_size = Vector2(0, 52)
	_privacy_btn.pressed.connect(_open_privacy_policy)
	v.add_child(_privacy_btn)
	_ad_privacy_btn = UIFactory.make_button("", false)
	_ad_privacy_btn.pressed.connect(AdService.show_privacy_options)
	v.add_child(_ad_privacy_btn)
	AdService.privacy_options_changed.connect(func(_required: bool): _refresh())

	_back_btn = UIFactory.make_button("", false)
	_back_btn.custom_minimum_size = Vector2(0, 56)
	_back_btn.pressed.connect(_on_back)
	v.add_child(_back_btn)
	_skip_tutorial_btn = UIFactory.make_button("", false)
	_skip_tutorial_btn.pressed.connect(func():
		_show_confirm("TUTORIAL_SKIP", "TUTORIAL_SKIP_CONFIRM", "TUTORIAL_SKIP", func():
			GameState.skip_tutorials()
			_refresh())
	)
	v.add_child(_skip_tutorial_btn)

	LocaleManager.locale_changed.connect(_refresh)
	OnlineService.request_finished.connect(_on_online_request_finished)
	SaveSystem.save_failed.connect(func(_error: Error):
		_refresh())
	_refresh()

func _make_setting_label() -> Label:
	var label := UIFactory.make_label("", 19)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _make_switch() -> CheckButton:
	var button := CheckButton.new()
	button.custom_minimum_size = Vector2(112, 50)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", UIFactory.COL_MUTED)
	button.add_theme_color_override("font_pressed_color", UIFactory.COL_ACCENT)
	button.add_theme_color_override("font_hover_color", UIFactory.COL_TEXT)
	return button

func _make_setting_row(label: Label, button: CheckButton) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 52)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	row.add_child(label)
	row.add_child(button)
	return row

func _refresh(_locale: String = "") -> void:
	if is_instance_valid(_perf_btn):
		_perf_btn.text = LocaleManager.t("PERF_STOP" if PerformanceRecorder.active else "PERF_START")
		_perf_status.text = LocaleManager.t(_perf_notice_key) if not _perf_notice_key.is_empty() else ""
		_perf_status.visible = not _perf_notice_key.is_empty()
	_ad_privacy_btn.text = LocaleManager.t("AD_PRIVACY_OPTIONS")
	_ad_privacy_btn.visible = AdService.privacy_options_required()
	_battery_label.text = LocaleManager.t("BATTERY_SAVER")
	_refresh_switch(_battery_btn, bool(SaveSystem.get_value("battery_saver", false)))
	_skip_tutorial_btn.text = LocaleManager.t("TUTORIAL_SKIP")
	_skip_tutorial_btn.visible = int(SaveSystem.get_value("first_session_stage", 0)) < 3
	_title.text = LocaleManager.t("SETTINGS")
	_music_label.text = LocaleManager.t("MUSIC")
	_sfx_label.text = LocaleManager.t("SFX")
	_haptics_label.text = LocaleManager.t("HAPTICS")
	_ghost_label.text = LocaleManager.t("GHOST_SETTING")
	_effects_label.text = LocaleManager.t("REDUCED_EFFECTS")
	_cloud_label.text = LocaleManager.t("CLOUD_SYNC")
	_telemetry_label.text = LocaleManager.t("TELEMETRY")
	_hub_presence_label.text = LocaleManager.t("HUB_PRESENCE")
	_hub_presence_status.text = LocaleManager.t("HUB_PRESENCE_DETAILS")
	_lang_label.text = LocaleManager.t("SELECT_LANGUAGE")
	_refresh_switch(_music_btn, AudioManager.music_on)
	_refresh_switch(_sfx_btn, AudioManager.sfx_on)
	_refresh_switch(_haptics_btn, FeedbackManager.haptics_on)
	_refresh_switch(_ghost_btn, bool(SaveSystem.get_value("ghost_on", true)))
	_refresh_switch(_effects_btn, bool(SaveSystem.get_value("reduced_effects", false)))
	_refresh_switch(_cloud_btn, bool(SaveSystem.get_value("cloud_sync_opt_in", false)) or _cloud_pending_enable)
	_refresh_switch(_telemetry_btn, SaveSystem.is_online_telemetry_opted_in() or _telemetry_pending_enable)
	_refresh_switch(_hub_presence_btn, bool(SaveSystem.get_value("hub_presence_opt_in", false)))
	var cloud_available: bool = OnlineService.is_enabled()
	_cloud_btn.disabled = not cloud_available
	_telemetry_btn.disabled = not cloud_available
	_hub_presence_btn.disabled = not cloud_available or not OnlineService.has_identity() \
		or not SaveSystem.is_online_leaderboard_opted_in()
	_cloud_backup_btn.text = LocaleManager.t("CLOUD_BACKUP_NOW")
	_cloud_restore_btn.text = LocaleManager.t("CLOUD_RESTORE")
	_cloud_delete_btn.text = LocaleManager.t("ONLINE_DATA_DELETE")
	_cloud_transfer_out_btn.text = LocaleManager.t("CLOUD_MOVE_OUT")
	_cloud_transfer_in_btn.text = LocaleManager.t("CLOUD_MOVE_IN")
	_cloud_backup_btn.disabled = not cloud_available or not bool(SaveSystem.get_value("cloud_sync_opt_in", false))
	_cloud_restore_btn.disabled = _cloud_backup_btn.disabled
	_cloud_delete_btn.disabled = not cloud_available or not OnlineService.has_identity()
	_cloud_transfer_out_btn.disabled = not cloud_available or not OnlineService.has_identity()
	_cloud_transfer_in_btn.disabled = not cloud_available
	if not cloud_available:
		_cloud_status.text = LocaleManager.t("CLOUD_RELEASE_OFF")
	elif _cloud_pending_enable:
		_cloud_status.text = LocaleManager.t("CLOUD_WORKING")
	elif not bool(SaveSystem.get_value("cloud_sync_opt_in", false)):
		_cloud_status.text = LocaleManager.t("CLOUD_OPT_IN_DESC")
	elif OnlineService.has_identity():
		_cloud_status.text = LocaleManager.t("CLOUD_CONNECTED")
	else:
		_cloud_status.text = LocaleManager.t("CLOUD_NOT_CONNECTED")
	if not cloud_available:
		_telemetry_status.text = LocaleManager.t("TELEMETRY_RELEASE_OFF")
	elif SaveSystem.is_online_telemetry_opted_in():
		_telemetry_status.text = LocaleManager.t("TELEMETRY_ON")
	else:
		_telemetry_status.text = LocaleManager.t("TELEMETRY_DESC")
	_sw_btn.text = LocaleManager.t("SWAHILI")
	_en_btn.text = LocaleManager.t("ENGLISH")
	_sw_btn.modulate.a = 1.0 if LocaleManager.current_locale == "sw" else 0.62
	_en_btn.modulate.a = 1.0 if LocaleManager.current_locale == "en" else 0.62
	_privacy_btn.text = LocaleManager.t("PRIVACY_POLICY")
	_back_btn.text = LocaleManager.t("BACK")
	if SaveSystem.last_save_error != OK:
		_cloud_status.text = LocaleManager.t("SAVE_ERROR")
	elif not _cloud_notice_text.is_empty():
		_cloud_status.text = _cloud_notice_text
	elif not _cloud_notice_key.is_empty():
		_cloud_status.text = LocaleManager.t(_cloud_notice_key)

func _refresh_switch(button: CheckButton, enabled: bool) -> void:
	button.set_pressed_no_signal(enabled)
	button.text = LocaleManager.t("ON") if enabled else LocaleManager.t("OFF")

func _toggle_music(enabled: bool) -> void:
	AudioManager.set_music_on(enabled)
	AudioManager.play_sfx("click")
	_refresh()

func _toggle_sfx(enabled: bool) -> void:
	AudioManager.set_sfx_on(enabled)
	AudioManager.play_sfx("click")
	_refresh()

func _toggle_haptics(enabled: bool) -> void:
	FeedbackManager.set_haptics_on(enabled)
	FeedbackManager.tap()
	AudioManager.play_sfx("click")
	_refresh()

func _toggle_ghost(enabled: bool) -> void:
	SaveSystem.set_value("ghost_on", enabled)
	AudioManager.play_sfx("click")
	_refresh()

func _toggle_effects(enabled: bool) -> void:
	SaveSystem.set_value("reduced_effects", enabled)
	FeedbackManager.tap()
	AudioManager.play_sfx("click")
	_refresh()

func _toggle_cloud_sync(enabled: bool) -> void:
	_cloud_notice_key = ""
	_cloud_notice_text = ""
	if not enabled:
		_cloud_pending_enable = false
		SaveSystem.set_value("cloud_sync_opt_in", false)
		AudioManager.play_sfx("click")
		_refresh()
		return
	if not OnlineService.is_enabled():
		_refresh()
		return
	_show_confirm("CLOUD_ENABLE_TITLE", "CLOUD_ENABLE_BODY", "CLOUD_ENABLE", _begin_cloud_opt_in)

func _toggle_telemetry(enabled: bool) -> void:
	if not enabled:
		_telemetry_pending_enable = false
		SaveSystem.set_online_telemetry_opt_in(false)
		AnalyticsService.discard_railway_events()
		AudioManager.play_sfx("click")
		_refresh()
		return
	if not OnlineService.is_enabled():
		_refresh()
		return
	_show_confirm("TELEMETRY_ENABLE_TITLE", "TELEMETRY_ENABLE_BODY", "ON", _begin_telemetry_opt_in)

func _toggle_hub_presence(enabled: bool) -> void:
	if not enabled:
		SaveSystem.set_value("hub_presence_opt_in", false)
		OnlineService.leave_hub_presence()
		_refresh()
		return
	if not OnlineService.has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_refresh()
		return
	_show_confirm("HUB_PRESENCE", "HUB_PRESENCE_CONFIRM", "ON", func():
		SaveSystem.set_value("hub_presence_opt_in", true)
		_refresh())

func _begin_telemetry_opt_in() -> void:
	_telemetry_pending_enable = true
	AnalyticsService.discard_railway_events()
	AudioManager.play_sfx("click")
	if OnlineService.has_identity():
		SaveSystem.set_online_telemetry_opt_in(true)
		_telemetry_pending_enable = false
		OnlineService.flush_telemetry()
	else:
		OnlineService.register_installation()
	_refresh()

func _begin_cloud_opt_in() -> void:
	_cloud_pending_enable = true
	_cloud_notice_key = "CLOUD_WORKING"
	AudioManager.play_sfx("click")
	if OnlineService.has_identity():
		OnlineService.upload_cloud_save()
	else:
		OnlineService.register_installation()
	_refresh()

func _backup_cloud_save() -> void:
	AudioManager.play_sfx("click")
	_cloud_notice_key = "CLOUD_WORKING"
	_cloud_notice_text = ""
	_refresh()
	OnlineService.upload_cloud_save()

func _confirm_cloud_restore() -> void:
	_show_confirm("CLOUD_RESTORE_TITLE", "CLOUD_RESTORE_BODY", "CLOUD_RESTORE", func():
		_cloud_notice_key = "CLOUD_WORKING"
		_cloud_notice_text = ""
		_refresh()
		OnlineService.download_cloud_save()
	)

func _confirm_cloud_delete() -> void:
	_show_confirm("ONLINE_DATA_DELETE_TITLE", "ONLINE_DATA_DELETE_BODY", "ONLINE_DATA_DELETE", func():
		_cloud_notice_key = "CLOUD_WORKING"
		_cloud_notice_text = ""
		_refresh()
		OnlineService.delete_online_account()
	)

func _create_transfer_code() -> void:
	_cloud_notice_key = "CLOUD_WORKING"
	_cloud_notice_text = ""
	_refresh()
	OnlineService.create_transfer_code()

func _show_transfer_claim_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("CLOUD_MOVE_IN_TITLE")
	dialog.dialog_text = LocaleManager.t("CLOUD_MOVE_IN_BODY")
	dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.ok_button_text = LocaleManager.t("CLOUD_MOVE_IN")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	var code_field := LineEdit.new()
	code_field.placeholder_text = "DDR-T-..."
	code_field.custom_minimum_size = Vector2(0, 48)
	code_field.max_length = 40
	dialog.add_child(code_field)
	dialog.confirmed.connect(func():
		_cloud_notice_key = "CLOUD_WORKING"
		_cloud_notice_text = ""
		_refresh()
		OnlineService.claim_transfer_code(code_field.text)
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(mini(430, int(get_viewport_rect().size.x) - 24), 0))
	code_field.grab_focus()

func _show_confirm(title_key: String, body_key: String, action_key: String, callback: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t(title_key)
	dialog.dialog_text = LocaleManager.t(body_key)
	dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.ok_button_text = LocaleManager.t(action_key)
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	dialog.confirmed.connect(func():
		callback.call()
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
		_refresh()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2i(mini(430, int(get_viewport_rect().size.x) - 24), 0))

func _on_online_request_finished(operation: String, success: bool, payload: Dictionary) -> void:
	if operation == "registration":
		if not _cloud_pending_enable and not _telemetry_pending_enable:
			return
		if success and OnlineService.has_identity():
			if _cloud_pending_enable:
				OnlineService.upload_cloud_save()
			if _telemetry_pending_enable:
				SaveSystem.set_online_telemetry_opt_in(true)
				_telemetry_pending_enable = false
				OnlineService.flush_telemetry()
			return
		_cloud_pending_enable = false
		_telemetry_pending_enable = false
		_cloud_notice_key = "CLOUD_ERROR"
		_refresh()
		return
	if operation == "transfer_code":
		if success:
			var code: String = String(payload.get("transferCode", ""))
			_cloud_notice_key = ""
			_cloud_notice_text = LocaleManager.t("CLOUD_MOVE_CODE").replace("{code}", code)
		else:
			_cloud_notice_key = "CLOUD_ERROR"
			_cloud_notice_text = ""
		_refresh()
		return
	if operation == "transfer_claim":
		_cloud_notice_key = "CLOUD_WORKING" if success else "CLOUD_ERROR"
		_refresh()
		return
	if operation == "transfer_ack":
		if success and OnlineService.has_identity():
			SaveSystem.set_value("cloud_sync_opt_in", true)
			_cloud_notice_key = "CLOUD_MOVE_DONE"
			_cloud_notice_text = ""
		else:
			_cloud_notice_key = "CLOUD_ERROR"
			_cloud_notice_text = ""
		_refresh()
		return
	if operation == "cloud_upload":
		var was_enabling: bool = _cloud_pending_enable
		_cloud_pending_enable = false
		if success:
			if was_enabling:
				SaveSystem.set_value("cloud_sync_opt_in", true)
			_cloud_notice_key = "CLOUD_BACKUP_DONE"
		else:
			_cloud_notice_key = "CLOUD_ERROR"
	elif operation == "cloud_download":
		if success and OnlineService.apply_cloud_snapshot(payload):
			_cloud_notice_key = "CLOUD_RESTORED"
		else:
			_cloud_notice_key = "CLOUD_ERROR"
	if operation == "cloud_upload" and not success:
		if payload.get("error") == "stale_revision" and payload.has("currentRevision"):
			_show_confirm("CLOUD_CONFLICT_TITLE", "CLOUD_CONFLICT_BODY", "CLOUD_KEEP_PHONE", func():
				_cloud_notice_key = "CLOUD_WORKING"
				_refresh()
				OnlineService.resolve_cloud_conflict())
		elif payload.get("error") == "save_failed":
			_cloud_notice_key = "SAVE_ERROR"
	elif operation == "account_delete":
		_cloud_pending_enable = false
		_cloud_notice_key = "CLOUD_DELETED" if success else "CLOUD_ERROR"
	_refresh()

func _set_lang(locale: String) -> void:
	LocaleManager.set_locale(locale)
	FeedbackManager.tap()
	AudioManager.play_sfx("click")

func _open_privacy_policy() -> void:
	AudioManager.play_sfx("click")
	OS.shell_open(PRIVACY_POLICY_URL)

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")
