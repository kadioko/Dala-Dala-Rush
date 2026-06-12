extends Control
## Garage = vehicle picker. Owned vehicles are selectable; locked ones are bought via shop.

const UIFactory := preload("res://ui/ui_factory.gd")
const Vehicles := preload("res://data/vehicles.gd")

var _title: Label
var _back_btn: Button
var _list_box: VBoxContainer
var _entries: Array = []
var _coin_label: Label
var _livery_btn: Button

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
	_coin_label = UIFactory.make_label("", 18, UIFactory.COL_ACCENT)
	root.add_child(_coin_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 10)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_box)

	var livery_btn := UIFactory.make_button("", false)
	livery_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		TransitionManager.go_to("res://scenes/livery.tscn"))
	root.add_child(livery_btn)
	_livery_btn = livery_btn

	_back_btn = UIFactory.make_button("", false)
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)

	_build_rows()
	LocaleManager.locale_changed.connect(_refresh)
	_refresh()

func _build_rows() -> void:
	for c in _list_box.get_children():
		c.queue_free()
	_entries.clear()
	for v in Vehicles.LIST:
		var hb := HBoxContainer.new()
		hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_theme_constant_override("separation", 10)
		_list_box.add_child(hb)

		var preview := ColorRect.new()
		preview.custom_minimum_size = Vector2(64, 64)
		preview.color = v.body
		hb.add_child(preview)

		var btn := UIFactory.make_button("", v.id == GameState.selected_vehicle_id)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 88)
		btn.add_theme_font_size_override("font_size", 16)
		var vid: String = v.id
		btn.pressed.connect(func(): _on_vehicle_pressed(vid))
		hb.add_child(btn)

		_entries.append({"btn": btn, "veh": v})

func _refresh(_l := "") -> void:
	_title.text = LocaleManager.t("SELECT_VEHICLE")
	_back_btn.text = LocaleManager.t("BACK")
	_livery_btn.text = "🎨 " + LocaleManager.t("LIVERY")
	_coin_label.text = "%s: %d" % [LocaleManager.t("COINS"), int(SaveSystem.get_value("total_coins", 0))]
	for e in _entries:
		var v: Dictionary = e.veh
		var vehicle_name := LocaleManager.t(v.name_key)
		var owned := SaveSystem.is_vehicle_unlocked(v.id)
		var label: String
		if not owned:
			label = "%s - %s %d" % [vehicle_name, LocaleManager.t("UNLOCK"), int(v.price)]
		elif v.id == GameState.selected_vehicle_id:
			label = "%s - %s" % [vehicle_name, LocaleManager.t("SELECTED")]
		else:
			label = "%s - %s" % [vehicle_name, LocaleManager.t("SELECT")]
		e.btn.text = "%s\n%s" % [label, _vehicle_stats(v)]

func _on_vehicle_pressed(id: String) -> void:
	AudioManager.play_sfx("click")
	if SaveSystem.is_vehicle_unlocked(id):
		GameState.set_vehicle(id)
		_build_rows()
		_refresh()
		return
	var v: Dictionary = Vehicles.get_by_id(id)
	if SaveSystem.spend_coins(int(v.price)):
		SaveSystem.unlock_vehicle(id)
		GameState.set_vehicle(id)
		AudioManager.play_sfx("powerup")
		_build_rows()
	_refresh()

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")

func _vehicle_stats(vehicle: Dictionary) -> String:
	var handling := int(round((0.14 / float(vehicle.get("lane_time", 0.14)) - 1.0) * 100.0))
	var fuel := int(round((1.0 / float(vehicle.get("fuel_drain_mult", 1.0)) - 1.0) * 100.0))
	var coin := int(round((float(vehicle.get("coin_mult", 1.0)) - 1.0) * 100.0))
	var horns := int(vehicle.get("horn_charges", 3))
	return "%s %+d%% | %s %+d%% | %s %+d%% | %s %d" % [
		LocaleManager.t("HANDLING"), handling,
		LocaleManager.t("FUEL_EFFICIENCY"), fuel,
		LocaleManager.t("COIN_BONUS"), coin,
		LocaleManager.t("HORN_CHARGES"), horns,
	]
