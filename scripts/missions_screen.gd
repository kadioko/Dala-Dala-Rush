extends Control
## Missions screen: 3 active missions with progress bars + season track.

const UIFactory := preload("res://ui/ui_factory.gd")
const MissionsData := preload("res://data/missions.gd")

var _title: Label
var _back_btn: Button
var _season_lbl: Label
var _season_bar: ProgressBar
var _list: VBoxContainer

func _ready() -> void:
	UIFactory.paint_background(self)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 40 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	root.offset_bottom = -24 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	_title = UIFactory.make_title("", 32)
	root.add_child(_title)

	# Season track panel
	var season_panel := UIFactory.make_panel()
	season_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(season_panel)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	season_panel.add_child(sv)
	_season_lbl = UIFactory.make_label("", 19, UIFactory.COL_ACCENT)
	sv.add_child(_season_lbl)
	_season_bar = ProgressBar.new()
	_season_bar.min_value = 0.0
	_season_bar.max_value = 1.0
	_season_bar.show_percentage = false
	_season_bar.custom_minimum_size = Vector2(0, 16)
	sv.add_child(_season_bar)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_list)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)

	LocaleManager.locale_changed.connect(_refresh)
	_refresh()

func _refresh(_l := "") -> void:
	_title.text = LocaleManager.t("MISSIONS")
	_back_btn.text = LocaleManager.t("BACK")
	_season_lbl.text = "%s %d   •   %d/%d XP" % [
		LocaleManager.t("SEASON_LEVEL"),
		MissionsData.season_level(),
		MissionsData.season_xp() % MissionsData.XP_PER_LEVEL,
		MissionsData.XP_PER_LEVEL,
	]
	_season_bar.value = MissionsData.season_progress()

	for c in _list.get_children():
		c.queue_free()
	for m in MissionsData.get_active():
		var t: Dictionary = MissionsData.template(String(m.tid))
		var panel := UIFactory.make_panel()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		panel.add_child(vb)

		var name_lbl := UIFactory.make_label(MissionsData.describe(t), 17, UIFactory.COL_TEXT)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(name_lbl)

		var bar := ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = float(t.target)
		bar.value = float(m.progress)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 12)
		vb.add_child(bar)

		var reward_lbl := UIFactory.make_label(
			"%d/%d   •   +%d 🪙  +%d XP" % [int(m.progress), int(t.target), int(t.reward), int(t.xp)],
			14, UIFactory.COL_MUTED)
		reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		vb.add_child(reward_lbl)

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")
