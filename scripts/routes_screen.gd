extends Control

const UIFactory := preload("res://ui/ui_factory.gd")
const Routes := preload("res://data/routes.gd")

var _title: Label
var _back_btn: Button
var _list_box: VBoxContainer
var _row_buttons: Array = []
var _msg: Label
var _coin_label: Label

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

	_coin_label = UIFactory.make_label("", 17, UIFactory.COL_ACCENT)
	root.add_child(_coin_label)

	_msg = UIFactory.make_label("", 15, UIFactory.COL_DANGER)
	root.add_child(_msg)

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
	_coin_label.text = "🪙 %d   |   %s: %d" % [
		int(SaveSystem.get_value("total_coins", 0)),
		LocaleManager.t("GOALS_DONE"),
		int(SaveSystem.get_value("route_goals_completed", 0)),
	]
	for entry in _row_buttons:
		var r: Dictionary = entry.route
		var label := LocaleManager.t(r.name_key)
		if not Routes.is_unlocked(r):
			var req := LocaleManager.t("UNLOCK_REQ") \
				.replace("{n}", str(int(r.get("unlock_goals", 0)))) \
				.replace("{c}", str(int(r.get("unlock_price", 0))))
			entry.btn.text = "🔒 %s\n%s" % [label, req]
			entry.btn.modulate.a = 0.7
			continue
		entry.btn.modulate.a = 1.0
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
	var r := Routes.get_by_id(id)
	if not Routes.is_unlocked(r):
		# Offer instant coin unlock as the alternative to goal progress.
		var price := int(r.get("unlock_price", 0))
		if SaveSystem.spend_coins(price):
			SaveSystem.unlock_route(id)
			AudioManager.play_sfx("powerup")
			_msg.text = LocaleManager.t("ROUTE_UNLOCKED")
		else:
			AudioManager.play_sfx("crash")
			_msg.text = LocaleManager.t("NOT_ENOUGH_COINS")
		_build_rows()
		_refresh()
		return
	_msg.text = ""
	GameState.set_route(id)
	_build_rows()
	_refresh()

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")
