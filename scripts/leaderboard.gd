extends Control
## Local top-5 leaderboard display.

const UIFactory := preload("res://ui/ui_factory.gd")
const Routes    := preload("res://data/routes.gd")

var _title: Label
var _back_btn: Button
var _content: VBoxContainer

func _ready() -> void:
	UIFactory.paint_background(self)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 36
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	_title = UIFactory.make_title("", 32)
	root.add_child(_title)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)

	LocaleManager.locale_changed.connect(func(_l := ""): _rebuild())
	_rebuild()

func _rebuild() -> void:
	_title.text = LocaleManager.t("LEADERBOARD")
	_back_btn.text = LocaleManager.t("BACK")
	for c in _content.get_children():
		c.queue_free()

	var lb: Array = SaveSystem.get_leaderboard()
	if lb.is_empty():
		var empty := UIFactory.make_label(LocaleManager.t("NO_SCORES_YET"), 20, UIFactory.COL_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content.add_child(empty)
		return

	var panel := UIFactory.make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	for i in range(lb.size()):
		var e: Dictionary = lb[i]
		var route_data := Routes.get_by_id(e.get("route", "kariakoo"))
		var is_top: bool = i == 0

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		vb.add_child(hb)

		# Rank
		var rank_lbl := UIFactory.make_label(
			"#%d" % (i + 1), 26,
			UIFactory.COL_ACCENT if is_top else Color(0.5, 0.5, 0.5))
		rank_lbl.custom_minimum_size = Vector2(44, 0)
		hb.add_child(rank_lbl)

		# Name (3-char initials)
		var name_lbl := UIFactory.make_label(
			str(e.get("name", "---")), 26,
			Color("#ffd23f") if is_top else UIFactory.COL_TEXT)
		name_lbl.custom_minimum_size = Vector2(60, 0)
		hb.add_child(name_lbl)

		# Score
		var score_lbl := UIFactory.make_label(
			str(int(e.get("score", 0))), 26,
			UIFactory.COL_PRIMARY if is_top else UIFactory.COL_TEXT)
		score_lbl.custom_minimum_size = Vector2(88, 0)
		hb.add_child(score_lbl)

		# Route name (truncated)
		var route_lbl := UIFactory.make_label(
			LocaleManager.t(route_data.name_key), 14, UIFactory.COL_MUTED)
		route_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		route_lbl.clip_text = true
		hb.add_child(route_lbl)

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")
