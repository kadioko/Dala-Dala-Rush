extends Control

const UIFactory := preload("res://ui/ui_factory.gd")
const PRIVACY_POLICY_URL := "https://kadioko.github.io/Dala-Dala-Rush/privacy-policy.html"

var _title: Label
var _music_btn: CheckButton
var _sfx_btn: CheckButton
var _haptics_btn: CheckButton
var _ghost_btn: CheckButton
var _effects_btn: CheckButton
var _sw_btn: Button
var _en_btn: Button
var _privacy_btn: Button
var _back_btn: Button
var _music_label: Label
var _sfx_label: Label
var _haptics_label: Label
var _ghost_label: Label
var _effects_label: Label
var _lang_label: Label

func _ready() -> void:
	UIFactory.paint_background(self)

	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_top = 0.0
	v.anchor_right = 0.5
	v.anchor_bottom = 1.0
	v.offset_left = -205
	v.offset_right = 205
	v.offset_top = 44 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	v.offset_bottom = -32 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	add_child(v)

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

	_lang_label = UIFactory.make_label("", 18, UIFactory.COL_MUTED)
	_lang_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(_lang_label)

	var lang_row := HBoxContainer.new()
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

	_back_btn = UIFactory.make_button("", false)
	_back_btn.custom_minimum_size = Vector2(0, 56)
	_back_btn.pressed.connect(_on_back)
	v.add_child(_back_btn)

	LocaleManager.locale_changed.connect(_refresh)
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
	_title.text = LocaleManager.t("SETTINGS")
	_music_label.text = LocaleManager.t("MUSIC")
	_sfx_label.text = LocaleManager.t("SFX")
	_haptics_label.text = LocaleManager.t("HAPTICS")
	_ghost_label.text = LocaleManager.t("GHOST_SETTING")
	_effects_label.text = LocaleManager.t("REDUCED_EFFECTS")
	_lang_label.text = LocaleManager.t("SELECT_LANGUAGE")
	_refresh_switch(_music_btn, AudioManager.music_on)
	_refresh_switch(_sfx_btn, AudioManager.sfx_on)
	_refresh_switch(_haptics_btn, FeedbackManager.haptics_on)
	_refresh_switch(_ghost_btn, bool(SaveSystem.get_value("ghost_on", true)))
	_refresh_switch(_effects_btn, bool(SaveSystem.get_value("reduced_effects", false)))
	_sw_btn.text = LocaleManager.t("SWAHILI")
	_en_btn.text = LocaleManager.t("ENGLISH")
	_sw_btn.modulate.a = 1.0 if LocaleManager.current_locale == "sw" else 0.62
	_en_btn.modulate.a = 1.0 if LocaleManager.current_locale == "en" else 0.62
	_privacy_btn.text = LocaleManager.t("PRIVACY_POLICY")
	_back_btn.text = LocaleManager.t("BACK")

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
