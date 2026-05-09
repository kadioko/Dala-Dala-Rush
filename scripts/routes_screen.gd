extends Control

const UIFactory := preload("res://ui/ui_factory.gd")
const Routes := preload("res://data/routes.gd")

var _title: Label
var _back_btn: Button
var _list_box: VBoxContainer
var _row_buttons: Array = []

func _ready() -> void:
	UIFactory.paint_background(self)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 40
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	_title = UIFactory.make_title("", 32)
	root.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 10)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_box)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)

	_build_rows()
	LocaleManager.locale_changed.connect(_refresh)
	_refresh()

func _build_rows() -> void:
	for child in _list_box.get_children():
		child.queue_free()
	_row_buttons.clear()
	for r in Routes.LIST:
		var btn := UIFactory.make_button("", r.id == GameState.selected_route_id)
		btn.custom_minimum_size = Vector2(0, 118)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 15)
		var route_id: String = r.id
		btn.pressed.connect(func(): _select(route_id))
		_list_box.add_child(btn)
		_row_buttons.append({"btn": btn, "route": r})

func _refresh(_l := "") -> void:
	_title.text = LocaleManager.t("SELECT_ROUTE")
	_back_btn.text = LocaleManager.t("BACK")
	for entry in _row_buttons:
		var r: Dictionary = entry.route
		var label := LocaleManager.t(r.name_key)
		if r.id == GameState.selected_route_id:
			label += "  [%s]" % LocaleManager.t("SELECTED")
		var best := SaveSystem.get_route_best(r.id)
		var flavor := LocaleManager.t(r.get("flavor_key", ""))
		var goal := _goal_text(r)
		var difficulty := _difficulty_marks(float(r.difficulty))
		entry.btn.text = "%s\n%s\n%s: %s\n%s: %s   %s: %d" % [
			label,
			flavor,
			LocaleManager.t("ROUTE_GOAL"),
			goal,
			LocaleManager.t("DIFFICULTY"),
			difficulty,
			LocaleManager.t("BEST"),
			best,
		]

func _difficulty_marks(value: float) -> String:
	var count: int = clamp(roundi(value * 2.0), 2, 4)
	var marks := ""
	for _i in range(count):
		marks += "#"
	for _i in range(4 - count):
		marks += "-"
	return marks

func _goal_text(route: Dictionary) -> String:
	return LocaleManager.t(route.get("goal_key", "")).replace(
		"{n}",
		str(int(route.get("goal_target", 0)))
	)

func _select(id: String) -> void:
	AudioManager.play_sfx("click")
	GameState.set_route(id)
	_build_rows()
	_refresh()

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")
