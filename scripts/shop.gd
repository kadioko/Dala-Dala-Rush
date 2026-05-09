extends Control
## In-game-coin shop. No real-money purchases.
## Currently mirrors the garage to keep purchasing focused on vehicle skins.

const UIFactory := preload("res://ui/ui_factory.gd")
const Vehicles := preload("res://data/vehicles.gd")

var _title: Label
var _back_btn: Button
var _list_box: VBoxContainer
var _coin_label: Label
var _msg: Label
var _entries: Array = []

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
	_msg = UIFactory.make_label("", 16, UIFactory.COL_DANGER)
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
	for c in _list_box.get_children():
		c.queue_free()
	_entries.clear()
	for v in Vehicles.LIST:
		if SaveSystem.is_vehicle_unlocked(v.id):
			continue
		var btn := UIFactory.make_button("")
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 88)
		btn.add_theme_font_size_override("font_size", 16)
		var vid: String = v.id
		btn.pressed.connect(func(): _try_buy(vid))
		_list_box.add_child(btn)
		_entries.append({"btn": btn, "veh": v})

func _refresh(_l := "") -> void:
	_title.text = LocaleManager.t("SHOP")
	_back_btn.text = LocaleManager.t("BACK")
	_coin_label.text = "%s: %d" % [LocaleManager.t("COINS"), int(SaveSystem.get_value("total_coins", 0))]
	for e in _entries:
		var v: Dictionary = e.veh
		e.btn.text = "%s - %d\n%s" % [LocaleManager.t(v.name_key), int(v.price), _vehicle_stats(v)]

func _try_buy(id: String) -> void:
	var v: Dictionary = Vehicles.get_by_id(id)
	if not SaveSystem.spend_coins(int(v.price)):
		_msg.text = LocaleManager.t("NOT_ENOUGH_COINS")
		AudioManager.play_sfx("crash")
		return
	SaveSystem.unlock_vehicle(id)
	AudioManager.play_sfx("powerup")
	_msg.text = ""
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
