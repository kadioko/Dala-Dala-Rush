extends Control

const UIFactory := preload("res://ui/ui_factory.gd")

var _title: Label
var _music_btn: Button
var _sfx_btn: Button
var _haptics_btn: Button
var _sw_btn: Button
var _en_btn: Button
var _back_btn: Button
var _music_label: Label
var _sfx_label: Label
var _haptics_label: Label
var _lang_label: Label

func _ready() -> void:
	UIFactory.paint_background(self)

	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_top = 0.0
	v.anchor_right = 0.5
	v.anchor_bottom = 1.0
	v.offset_left = -180
	v.offset_right = 180
	v.offset_top = 60
	v.offset_bottom = -40
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	add_child(v)

	_title = UIFactory.make_title("", 34)
	v.add_child(_title)

	_music_label = UIFactory.make_label("", 18)
	v.add_child(_music_label)
	_music_btn = UIFactory.make_button("", false)
	_music_btn.pressed.connect(_toggle_music)
	v.add_child(_music_btn)

	_sfx_label = UIFactory.make_label("", 18)
	v.add_child(_sfx_label)
	_sfx_btn = UIFactory.make_button("", false)
	_sfx_btn.pressed.connect(_toggle_sfx)
	v.add_child(_sfx_btn)

	_haptics_label = UIFactory.make_label("", 18)
	v.add_child(_haptics_label)
	_haptics_btn = UIFactory.make_button("", false)
	_haptics_btn.pressed.connect(_toggle_haptics)
	v.add_child(_haptics_btn)

	_lang_label = UIFactory.make_label("", 18)
	v.add_child(_lang_label)
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 8)
	lang_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(lang_row)

	_sw_btn = UIFactory.make_button("", false)
	_sw_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sw_btn.custom_minimum_size = Vector2(0, 56)
	_sw_btn.pressed.connect(func(): _set_lang("sw"))
	lang_row.add_child(_sw_btn)

	_en_btn = UIFactory.make_button("", false)
	_en_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_en_btn.custom_minimum_size = Vector2(0, 56)
	_en_btn.pressed.connect(func(): _set_lang("en"))
	lang_row.add_child(_en_btn)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.pressed.connect(_on_back)
	v.add_child(_back_btn)

	LocaleManager.locale_changed.connect(_refresh)
	_refresh()

func _refresh(_l := "") -> void:
	_title.text = LocaleManager.t("SETTINGS")
	_music_label.text = LocaleManager.t("MUSIC")
	_sfx_label.text = LocaleManager.t("SFX")
	_haptics_label.text = LocaleManager.t("HAPTICS")
	_lang_label.text = LocaleManager.t("SELECT_LANGUAGE")
	_music_btn.text = LocaleManager.t("ON") if AudioManager.music_on else LocaleManager.t("OFF")
	_sfx_btn.text = LocaleManager.t("ON") if AudioManager.sfx_on else LocaleManager.t("OFF")
	_haptics_btn.text = LocaleManager.t("ON") if FeedbackManager.haptics_on else LocaleManager.t("OFF")
	_sw_btn.text = LocaleManager.t("SWAHILI")
	_en_btn.text = LocaleManager.t("ENGLISH")
	_sw_btn.modulate.a = 1.0 if LocaleManager.current_locale == "sw" else 0.62
	_en_btn.modulate.a = 1.0 if LocaleManager.current_locale == "en" else 0.62
	_back_btn.text = LocaleManager.t("BACK")

func _toggle_music() -> void:
	AudioManager.set_music_on(not AudioManager.music_on)
	AudioManager.play_sfx("click")
	_refresh()

func _toggle_sfx() -> void:
	AudioManager.set_sfx_on(not AudioManager.sfx_on)
	AudioManager.play_sfx("click")
	_refresh()

func _toggle_haptics() -> void:
	FeedbackManager.set_haptics_on(not FeedbackManager.haptics_on)
	FeedbackManager.tap()
	AudioManager.play_sfx("click")
	_refresh()

func _set_lang(locale: String) -> void:
	LocaleManager.set_locale(locale)
	FeedbackManager.tap()
	AudioManager.play_sfx("click")

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")
