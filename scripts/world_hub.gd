extends Control
## A small walkable Kariakoo neighborhood between endless-run sessions.

const UIFactory := preload("res://ui/ui_factory.gd")
const Vehicles := preload("res://data/vehicles.gd")
const DECOR: Array[Dictionary] = [
	{"id": "kanga_flag", "price": 90, "key": "HUB_DECOR_FLAG"},
	{"id": "soko_lanterns", "price": 150, "key": "HUB_DECOR_LANTERNS"},
	{"id": "kituo_bench", "price": 210, "key": "HUB_DECOR_BENCH"},
]
const SPOTS: Array[Dictionary] = [
	{"id": "stop", "position": Vector2(270, 738), "key": "HUB_FIND_STOP", "icon": "K"},
	{"id": "market", "position": Vector2(425, 430), "key": "HUB_FIND_MARKET", "icon": "S"},
	{"id": "garage", "position": Vector2(112, 380), "key": "HUB_FIND_GARAGE", "icon": "D"},
	{"id": "plaza", "position": Vector2(270, 250), "key": "HUB_FIND_PLAZA", "icon": "★"},
]
const ERRAND_STOPS: Array[String] = ["market", "garage", "plaza"]
const ERRAND_REWARD := 30

var _player_position := Vector2(270, 738)
var _move_vector := Vector2.ZERO
var _buttons: Dictionary = {}
var _action_button: Button
var _status_label: Label
var _objective_label: Label
var _coin_label: Label
var _nearby_id := ""
var _owned_decor: Array[String] = []
var _errand_started := false
var _errand_progress: Array[String] = []
var _errand_completed := false
var _toast_timer := 0.0
var _toast_text := ""
var _popup: Control
var _map_scale := 1.0
var _map_offset := Vector2.ZERO
var _title_label: Label
var _subtitle_label: Label
var _crowd_players: Array[Dictionary] = []
var _crowd_list: VBoxContainer
var _presence_elapsed := 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(_layout_hud)
	LocaleManager.locale_changed.connect(_on_locale_changed)
	OnlineService.request_finished.connect(_on_online_request_finished)
	_owned_decor.assign(SaveSystem.get_value("hub_owned_decor", []))
	var today := Time.get_date_string_from_system()
	_errand_completed = String(SaveSystem.get_value("hub_daily_completed_date", "")) == today
	_errand_started = String(SaveSystem.get_value("hub_daily_started_date", "")) == today
	_errand_progress.assign(SaveSystem.get_value("hub_daily_progress", []) if _errand_started else [])
	if not _errand_started and not SaveSystem.get_value("hub_daily_progress", []).is_empty():
		SaveSystem.set_value("hub_daily_progress", [])
	_build_hud()
	_layout_hud()
	_refresh_labels()
	set_process(true)
	_sync_online_presence(true)

func _exit_tree() -> void:
	if LocaleManager.locale_changed.is_connected(_on_locale_changed):
		LocaleManager.locale_changed.disconnect(_on_locale_changed)
	if OnlineService.request_finished.is_connected(_on_online_request_finished):
		OnlineService.request_finished.disconnect(_on_online_request_finished)
	if bool(SaveSystem.get_value("hub_presence_opt_in", false)):
		OnlineService.leave_hub_presence()

func _process(delta: float) -> void:
	var input_vector := _move_vector
	if input_vector == Vector2.ZERO:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		_player_position += input_vector * 205.0 * delta
		_player_position.x = clampf(_player_position.x, 50.0, 490.0)
		_player_position.y = clampf(_player_position.y, 205.0, 890.0)
		queue_redraw()
	_update_nearby()
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_text = ""
			_refresh_labels()
	if bool(SaveSystem.get_value("hub_presence_opt_in", false)):
		_presence_elapsed += delta
		if _presence_elapsed >= 8.0:
			_presence_elapsed = 0.0
			_sync_online_presence(true)

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	_map_scale = minf(viewport_size.x / 540.0, viewport_size.y / 960.0)
	_map_offset = (viewport_size - Vector2(540, 960) * _map_scale) * 0.5
	draw_set_transform(_map_offset, 0.0, Vector2.ONE * _map_scale)
	_draw_district()
	_draw_spots()
	_draw_avatar()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_district() -> void:
	draw_rect(Rect2(0, 0, 540, 960), Color("#9bc6a1"))
	# A compact Dar block: warm shopfronts around a shaded, pedestrian plaza.
	draw_rect(Rect2(0, 160, 540, 70), Color("#b8a98e"))
	draw_rect(Rect2(0, 637, 540, 76), Color("#b8a98e"))
	draw_rect(Rect2(0, 230, 540, 407), Color("#dfcfae"))
	draw_rect(Rect2(0, 330, 540, 95), Color("#7b8581"))
	draw_rect(Rect2(0, 497, 540, 92), Color("#7b8581"))
	for x in range(20, 540, 90):
		draw_rect(Rect2(x, 374, 42, 6), Color("#f1dfa0"))
		draw_rect(Rect2(x + 38, 539, 42, 6), Color("#f1dfa0"))
	# Buildings, stalls and painted awnings make the map read as a place, not a menu.
	_draw_shop(Vector2(35, 270), Vector2(122, 87), Color("#e57352"), "KARIAKOO")
	_draw_shop(Vector2(193, 270), Vector2(142, 87), Color("#338d83"), "M-PESA • DUKA")
	_draw_shop(Vector2(380, 270), Vector2(123, 87), Color("#d5a338"), "VITU VYA NYUMBANI")
	_draw_shop(Vector2(35, 602), Vector2(142, 82), Color("#4d8d91"), "KARAKANA")
	_draw_shop(Vector2(206, 602), Vector2(125, 82), Color("#dc7952"), "CHAI • MAANDAZI")
	_draw_shop(Vector2(384, 602), Vector2(118, 82), Color("#597f51"), "MATUNDA")
	# Central shade, paved square and public gathering point.
	draw_rect(Rect2(151, 438, 238, 52), Color("#bd9b5d"), true)
	draw_rect(Rect2(159, 445, 222, 38), Color("#4d6155"), true)
	for x in [180.0, 235.0, 290.0, 345.0]:
		draw_rect(Rect2(x, 454, 26, 14), Color("#f2c66d"), true)
	draw_rect(Rect2(206, 500, 128, 86), Color("#d8bf91"), true)
	draw_rect(Rect2(211, 505, 118, 76), Color("#ead8b5"), true)
	for tree in [Vector2(58, 246), Vector2(482, 246), Vector2(58, 615), Vector2(482, 615), Vector2(115, 530), Vector2(425, 530)]:
		_draw_palm(tree)
	# The player's bus remains parked at the dala stand, rendered with the game's chosen skin.
	var vehicle: Dictionary = Vehicles.get_by_id(GameState.selected_vehicle_id)
	var texture: Texture2D = SpriteLib.get_tex("vehicle", String(vehicle.get("id", "classic_blue")))
	if texture != null:
		draw_texture_rect(texture, Rect2(223, 765, 94, 126), false)
	else:
		draw_rect(Rect2(230, 768, 80, 117), vehicle.get("body", Color("#1f8fff")), true)
		draw_rect(Rect2(237, 780, 66, 24), Color("#1b2938"), true)
		draw_rect(Rect2(237, 818, 66, 31), vehicle.get("accent", Color("#ffd23f")), true)
	# Owned items visibly alter the shared neighborhood.
	if "kanga_flag" in _owned_decor:
		draw_line(Vector2(449, 320), Vector2(449, 276), Color("#f7f0d1"), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(450, 278), Vector2(492, 288), Vector2(450, 300)]), Color("#e7553c"))
		draw_rect(Rect2(458, 284, 12, 7), Color("#1b7c68"))
	if "soko_lanterns" in _owned_decor:
		for lamp_x in [404.0, 450.0, 489.0]:
			draw_line(Vector2(lamp_x, 330), Vector2(lamp_x, 310), Color("#5d4938"), 2.0)
			draw_circle(Vector2(lamp_x, 308), 6.0, Color("#ffd56b"))
	if "kituo_bench" in _owned_decor:
		draw_rect(Rect2(345, 756, 54, 9), Color("#814c32"), true)
		draw_rect(Rect2(351, 765, 5, 13), Color("#60402f"))
		draw_rect(Rect2(388, 765, 5, 13), Color("#60402f"))
	# Route banner and paving details.
	draw_rect(Rect2(167, 203, 206, 8), Color("#f1cb6d"), true)
	draw_rect(Rect2(167, 212, 206, 5), Color("#b2533f"), true)
	for x in range(32, 540, 64):
		draw_line(Vector2(x, 720), Vector2(x + 28, 720), Color("#c7b68f"), 2.0)

func _draw_shop(position: Vector2, dimensions: Vector2, awning: Color, sign: String) -> void:
	draw_rect(Rect2(position + Vector2(5, 7), dimensions), Color(0.12, 0.15, 0.13, 0.22), true)
	draw_rect(Rect2(position, dimensions), Color("#eee0c2"), true)
	draw_rect(Rect2(position + Vector2(5, 4), Vector2(dimensions.x - 10, 24)), awning, true)
	draw_string(ThemeDB.fallback_font, position + Vector2(9, 21), sign,
		HORIZONTAL_ALIGNMENT_LEFT, dimensions.x - 18, 9, Color.WHITE)
	draw_rect(Rect2(position + Vector2(16, 39), Vector2(35, 34)), Color("#88b9b1"), true)
	draw_rect(Rect2(position + Vector2(62, 39), Vector2(dimensions.x - 76, 48)), Color("#8f664c"), true)
	draw_rect(Rect2(position + Vector2(67, 43), Vector2(dimensions.x - 86, 40)), Color("#c99662"), true)
	for goods_x in range(0, 3):
		draw_circle(position + Vector2(75 + goods_x * 11, 59), 4.0, [Color("#ec6e46"), Color("#f1bd42"), Color("#52966d")][goods_x])

func _draw_palm(center: Vector2) -> void:
	draw_rect(Rect2(center.x - 4, center.y + 4, 8, 22), Color("#93613d"), true)
	for leaf in range(6):
		var angle := TAU * float(leaf) / 6.0
		var tip := center + Vector2(cos(angle) * 20.0, sin(angle) * 14.0)
		draw_line(center, tip, Color("#347d55"), 6.0, true)
	draw_circle(center, 5.0, Color("#46945f"))

func _draw_spots() -> void:
	for spot in SPOTS:
		var point: Vector2 = spot.position
		var is_current := String(spot.id) == _nearby_id
		draw_circle(point + Vector2(0, 3), 23.0, Color(0.08, 0.12, 0.12, 0.2))
		draw_circle(point, 21.0, Color("#18272d"))
		draw_circle(point, 17.0, Color("#17a589") if is_current else Color("#ffd166"))
		draw_string(ThemeDB.fallback_font, point + Vector2(-9, 6), String(spot.icon),
			HORIZONTAL_ALIGNMENT_CENTER, 18, 16, Color("#17242a"))
		if String(spot.id) in _errand_progress:
			draw_circle(point + Vector2(15, -14), 6.0, Color("#30c779"))
	for player in _crowd_players:
		var other_position := Vector2(float(player.x) * 0.54, float(player.y) * 0.96)
		var vehicle: Dictionary = Vehicles.get_by_id(String(player.vehicleId))
		draw_circle(other_position, 13.0, Color(0.07, 0.11, 0.12, 0.3))
		draw_circle(other_position + Vector2(0, -10), 6.0, Color("#d99d6d"))
		draw_rect(Rect2(other_position + Vector2(-7, -5), Vector2(14, 16)), vehicle.get("body", Color("#388c84")), true)
		draw_rect(Rect2(other_position + Vector2(-8, -6), Vector2(16, 4)), vehicle.get("accent", Color("#ffd166")), true)
		if _is_recent_emote(String(player.get("emoteAt", ""))):
			var emote_text: String = {"wave": "👋", "horn": "!", "dance": "♪"}.get(String(player.emote), "")
			if not emote_text.is_empty():
				draw_string(ThemeDB.fallback_font, other_position + Vector2(8, -17), emote_text,
					HORIZONTAL_ALIGNMENT_LEFT, 22, 15, Color.WHITE)

func _draw_avatar() -> void:
	draw_set_transform(_map_offset + _player_position * _map_scale, 0.0, Vector2.ONE * _map_scale)
	# A friendly top-down conductor avatar follows the player's steering.
	draw_circle(Vector2(2, 4), 18, Color(0.08, 0.10, 0.10, 0.25))
	draw_circle(Vector2(0, -12), 8.0, Color("#ecaa62"))
	draw_rect(Rect2(-10, -2, 20, 22), Color("#178c78"), true)
	draw_rect(Rect2(-12, -10, 24, 7), Color("#ffd166"), true)
	draw_circle(Vector2(-4, -3), 1.5, Color("#17242a"))
	draw_circle(Vector2(4, -3), 1.5, Color("#17242a"))
	draw_line(Vector2(-6, 18), Vector2(-9, 25), Color("#253c4b"), 4.0)
	draw_line(Vector2(6, 18), Vector2(9, 25), Color("#253c4b"), 4.0)
	if "kanga_flag" in _owned_decor:
		draw_line(Vector2(10, -5), Vector2(19, -21), Color("#715038"), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(18, -21), Vector2(30, -18), Vector2(18, -13)]), Color("#e7553c"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _build_hud() -> void:
	var top := HBoxContainer.new()
	top.anchor_left = 0.04
	top.anchor_right = 0.96
	top.anchor_top = 0.0
	top.offset_top = 10 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	top.offset_bottom = top.offset_top + 48
	add_child(top)
	var back := UIFactory.make_button("‹", false)
	back.custom_minimum_size = Vector2(54, 48)
	back.pressed.connect(func(): TransitionManager.go_to("res://scenes/main_menu.tscn"))
	top.add_child(back)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label = UIFactory.make_label("", 19, UIFactory.COL_TEXT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(_title_label)
	_subtitle_label = UIFactory.make_label("", 11, UIFactory.COL_MUTED)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(_subtitle_label)
	top.add_child(title_box)
	var balance := PanelContainer.new()
	_coin_label = UIFactory.make_label("", 15, UIFactory.COL_ACCENT)
	balance.add_child(_coin_label)
	top.add_child(balance)
	_status_label = UIFactory.make_label("", 14, Color("#fff4d2"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.anchor_left = 0.08
	_status_label.anchor_right = 0.92
	_status_label.anchor_top = 0.10
	_status_label.offset_top = 64 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	_status_label.offset_bottom = _status_label.offset_top + 34
	add_child(_status_label)
	_objective_label = UIFactory.make_label("", 14, Color("#fff4d2"))
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.anchor_left = 0.08
	_objective_label.anchor_right = 0.92
	_objective_label.anchor_top = 0.16
	_objective_label.offset_top = 0
	_objective_label.offset_bottom = 34
	add_child(_objective_label)
	for direction in ["up", "left", "down", "right"]:
		var button := UIFactory.make_button({"up": "↑", "left": "←", "down": "↓", "right": "→"}[direction], false)
		button.custom_minimum_size = Vector2(52, 52)
		button.add_theme_font_size_override("font_size", 23)
		button.button_down.connect(func(d: String = direction): _set_direction(d, true))
		button.button_up.connect(func(d: String = direction): _set_direction(d, false))
		_buttons[direction] = button
		add_child(button)
	_action_button = UIFactory.make_button("", false)
	_action_button.custom_minimum_size = Vector2(150, 56)
	_action_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_button.add_theme_font_size_override("font_size", 15)
	_action_button.pressed.connect(_interact)
	add_child(_action_button)
	_on_locale_changed(LocaleManager.current_locale)

func _on_locale_changed(_locale: String) -> void:
	if is_instance_valid(_title_label):
		_title_label.text = LocaleManager.t("HUB_TITLE")
	if is_instance_valid(_subtitle_label):
		_subtitle_label.text = LocaleManager.t("HUB_SUBTITLE")
	_refresh_labels()

func _layout_hud() -> void:
	var viewport := get_viewport_rect().size
	var safe_bottom := UIFactory.safe_bottom_inset(viewport.y)
	var compact := viewport.x < 380.0
	var button_size := 44.0 if compact else 52.0
	var spacing := 44.0 if compact else 54.0
	var dpad_center := Vector2(90.0 if compact else 100.0, viewport.y - safe_bottom - 116)
	for button_value in _buttons.values():
		var button := button_value as Button
		button.custom_minimum_size = Vector2(button_size, button_size)
		button.size = Vector2(button_size, button_size)
	(_buttons.up as Button).position = dpad_center + Vector2(-button_size * 0.5, -spacing - button_size * 0.5)
	(_buttons.left as Button).position = dpad_center + Vector2(-spacing - button_size * 0.5, -button_size * 0.5)
	(_buttons.down as Button).position = dpad_center + Vector2(-button_size * 0.5, spacing - button_size * 0.5)
	(_buttons.right as Button).position = dpad_center + Vector2(spacing - button_size * 0.5, -button_size * 0.5)
	_action_button.anchor_left = 1.0
	_action_button.anchor_right = 1.0
	_action_button.anchor_top = 1.0
	_action_button.anchor_bottom = 1.0
	_action_button.offset_left = -170 if compact else -178
	_action_button.offset_right = -18
	_action_button.offset_top = -safe_bottom - (68 if compact else 88)
	_action_button.offset_bottom = -safe_bottom - (4 if compact else 24)

func _set_direction(direction: String, pressed: bool) -> void:
	if not pressed:
		_move_vector = Vector2.ZERO
		return
	_move_vector = {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}[direction]

func _update_nearby() -> void:
	var nearest := ""
	var distance := INF
	for spot in SPOTS:
		var candidate: float = _player_position.distance_to(spot.position)
		if candidate < distance:
			nearest = String(spot.id)
			distance = candidate
	if distance > 72.0:
		nearest = ""
	if nearest != _nearby_id:
		_nearby_id = nearest
		_refresh_labels()
		queue_redraw()
	if _errand_started and not _errand_completed:
		for stop in ERRAND_STOPS:
			if stop == nearest and stop not in _errand_progress:
				_errand_progress.append(stop)
				SaveSystem.set_value("hub_daily_progress", _errand_progress)
				if _errand_progress.size() >= ERRAND_STOPS.size():
					_finish_errand()
				else:
					_show_toast(LocaleManager.t("HUB_DAILY_PROGRESS").replace("{n}", str(_errand_progress.size())))
				queue_redraw()

func _refresh_labels() -> void:
	if not is_instance_valid(_action_button):
		return
	_coin_label.text = "🪙 %d" % int(SaveSystem.get_value("total_coins", 0))
	if not _toast_text.is_empty():
		_status_label.text = _toast_text
	elif _nearby_id.is_empty():
		_status_label.text = LocaleManager.t("HUB_SUBTITLE")
	else:
		var spot := _spot(_nearby_id)
		_status_label.text = LocaleManager.t(String(spot.get("key", "HUB_SUBTITLE")))
	if _errand_completed:
		_objective_label.text = LocaleManager.t("HUB_DAILY_DONE")
	elif _errand_started:
		_objective_label.text = LocaleManager.t("HUB_DAILY_PROGRESS").replace("{n}", str(_errand_progress.size()))
	else:
		_objective_label.text = LocaleManager.t("HUB_DAILY_START")
	_action_button.text = LocaleManager.t("HUB_ACTION") if _nearby_id.is_empty() else LocaleManager.t(String(_spot(_nearby_id).get("key", "HUB_ACTION")))
	_action_button.disabled = _nearby_id.is_empty()

func _spot(id: String) -> Dictionary:
	for spot in SPOTS:
		if String(spot.id) == id:
			return spot
	return {}

func _interact() -> void:
	match _nearby_id:
		"stop": _start_errand()
		"market": _open_market()
		"garage": TransitionManager.go_to("res://scenes/garage.tscn")
		"plaza": _open_friends_plaza()

func _start_errand() -> void:
	if _errand_completed:
		_show_toast(LocaleManager.t("HUB_DAILY_DONE"))
		return
	_errand_started = true
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_daily_started_date", Time.get_date_string_from_system())
	SaveSystem.end_batch()
	_show_toast(LocaleManager.t("HUB_DAILY_START"))

func _finish_errand() -> void:
	_errand_started = false
	_errand_completed = true
	var today := Time.get_date_string_from_system()
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_daily_completed_date", today)
	SaveSystem.set_value("hub_daily_started_date", "")
	SaveSystem.set_value("hub_daily_progress", [])
	SaveSystem.add_coins(ERRAND_REWARD)
	SaveSystem.end_batch()
	_show_toast(LocaleManager.t("HUB_DAILY_REWARD").replace("{n}", str(ERRAND_REWARD)))
	AnalyticsService.log_event("hub_errand_completed", {"district": "kariakoo"})

func _open_market() -> void:
	_open_popup(LocaleManager.t("HUB_SHOP_TITLE"), func(body: VBoxContainer):
		for item in DECOR:
			var decor_id := String(item.id)
			var price := int(item.price)
			var title := LocaleManager.t(String(item.key)).replace("{n}", str(price))
			var buy := UIFactory.make_button(title + ("  •  " + LocaleManager.t("HUB_OWNED") if decor_id in _owned_decor else ""), false)
			buy.custom_minimum_size = Vector2(0, 50)
			buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buy.disabled = decor_id in _owned_decor
			buy.pressed.connect(func(): _buy_decor(decor_id, price))
			body.add_child(buy)
	)

func _buy_decor(decor_id: String, price: int) -> void:
	if decor_id in _owned_decor:
		return
	var wallet_before := int(SaveSystem.get_value("total_coins", 0))
	SaveSystem.begin_batch()
	if not SaveSystem.spend_coins(price):
		SaveSystem.end_batch()
		_show_toast(LocaleManager.t("HUB_NO_COINS"))
		return
	_owned_decor.append(decor_id)
	SaveSystem.set_value("hub_owned_decor", _owned_decor)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_owned_decor.erase(decor_id)
		SaveSystem.data["total_coins"] = wallet_before
		SaveSystem.data["hub_owned_decor"] = _owned_decor
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	AudioManager.play_sfx("coin")
	_show_toast(LocaleManager.t("HUB_DECOR_BOUGHT"))
	queue_redraw()
	_open_market()

func _open_friends_plaza() -> void:
	OnlineService.fetch_hub_crowd()
	_open_popup(LocaleManager.t("HUB_SOCIAL"), func(body: VBoxContainer):
		var explanation := UIFactory.make_label(LocaleManager.t("HUB_SOCIAL_BODY"), 15, UIFactory.COL_TEXT)
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(explanation)
		var presence := CheckButton.new()
		presence.text = LocaleManager.t("HUB_PRESENCE")
		presence.button_pressed = bool(SaveSystem.get_value("hub_presence_opt_in", false))
		presence.disabled = not OnlineService.has_identity() or not SaveSystem.is_online_leaderboard_opted_in()
		presence.toggled.connect(func(enabled: bool):
			if enabled:
				presence.set_pressed_no_signal(false)
				_confirm_presence_opt_in(presence)
			else:
				_set_presence_opt_in(false))
		body.add_child(presence)
		var privacy := UIFactory.make_label(LocaleManager.t("HUB_PRESENCE_DETAILS"), 12, UIFactory.COL_MUTED)
		privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(privacy)
		if bool(SaveSystem.get_value("hub_presence_opt_in", false)):
			var emotes := HBoxContainer.new()
			for pair in [["👋", "wave"], ["🔊", "horn"], ["♪", "dance"]]:
				var emote_button := UIFactory.make_button(pair[0], false)
				emote_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				emote_button.custom_minimum_size = Vector2(0, 46)
				emote_button.pressed.connect(func(emote: String = pair[1]): _send_emote(emote))
				emotes.add_child(emote_button)
			body.add_child(emotes)
		var crowd_scroll := ScrollContainer.new()
		crowd_scroll.custom_minimum_size = Vector2(0, 118)
		crowd_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		crowd_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_crowd_list = VBoxContainer.new()
		_crowd_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		crowd_scroll.add_child(_crowd_list)
		body.add_child(crowd_scroll)
		_populate_crowd_list()
		var rankings := UIFactory.make_button(LocaleManager.t("LEADERBOARD"), false)
		rankings.custom_minimum_size = Vector2(0, 52)
		rankings.pressed.connect(func(): TransitionManager.go_to("res://scenes/leaderboard.tscn"))
		body.add_child(rankings)
		var invite := UIFactory.make_button(LocaleManager.t("REFERRAL_MENU"), false)
		invite.custom_minimum_size = Vector2(0, 52)
		invite.pressed.connect(func(): TransitionManager.go_to("res://scenes/referrals.tscn"))
		body.add_child(invite)
	)

func _sync_online_presence(fetch_crowd: bool) -> void:
	if not bool(SaveSystem.get_value("hub_presence_opt_in", false)):
		return
	if not OnlineService.has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		return
	var x := int(roundf(_player_position.x / 540.0 * 1000.0))
	var y := int(roundf(_player_position.y / 960.0 * 1000.0))
	OnlineService.update_hub_presence(x, y, GameState.selected_vehicle_id)
	if fetch_crowd:
		OnlineService.fetch_hub_crowd()

func _confirm_presence_opt_in(button: CheckButton) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("HUB_PRESENCE")
	dialog.dialog_text = LocaleManager.t("HUB_PRESENCE_CONFIRM")
	dialog.ok_button_text = LocaleManager.t("ON")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	dialog.confirmed.connect(func():
		_set_presence_opt_in(true)
		button.set_pressed_no_signal(true)
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(mini(420, int(get_viewport_rect().size.x) - 24), 0))

func _set_presence_opt_in(enabled: bool) -> void:
	SaveSystem.set_value("hub_presence_opt_in", enabled)
	if enabled:
		_sync_online_presence(true)
	else:
		OnlineService.leave_hub_presence()
		_crowd_players.clear()
	queue_redraw()
	_populate_crowd_list()
	_refresh_labels()

func _send_emote(emote: String) -> void:
	var x := int(roundf(_player_position.x / 540.0 * 1000.0))
	var y := int(roundf(_player_position.y / 960.0 * 1000.0))
	OnlineService.update_hub_presence(x, y, GameState.selected_vehicle_id, emote)
	AudioManager.play_sfx("horn" if emote == "horn" else "click")

func _block_hub_player(player_id: String) -> void:
	OnlineService.block_leaderboard_friend(player_id)
	_crowd_players = _crowd_players.filter(func(player: Dictionary) -> bool:
		return String(player.get("playerId", "")) != player_id)
	queue_redraw()
	_populate_crowd_list()
	_refresh_labels()

func _populate_crowd_list() -> void:
	if not is_instance_valid(_crowd_list):
		return
	for child in _crowd_list.get_children():
		child.queue_free()
	var summary := UIFactory.make_label(_crowd_summary(), 14, UIFactory.COL_TEXT)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_crowd_list.add_child(summary)
	for player in _crowd_players:
		var player_row := HBoxContainer.new()
		var player_name := UIFactory.make_label(String(player.displayName), 14, UIFactory.COL_TEXT)
		player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_row.add_child(player_name)
		var block := UIFactory.make_button(LocaleManager.t("HUB_BLOCK"), false)
		block.custom_minimum_size = Vector2(82, 42)
		block.pressed.connect(func(id: String = String(player.playerId)): _block_hub_player(id))
		player_row.add_child(block)
		_crowd_list.add_child(player_row)

func _on_online_request_finished(operation: String, success: bool, payload: Dictionary) -> void:
	if operation != "hub_crowd":
		return
	if success:
		_crowd_players.clear()
		for entry in payload.get("players", []):
			_crowd_players.append(entry)
		queue_redraw()
		_populate_crowd_list()
		_refresh_labels()

func _crowd_summary() -> String:
	if not bool(SaveSystem.get_value("hub_presence_opt_in", false)):
		return LocaleManager.t("HUB_PRESENCE_OFF")
	if not OnlineService.has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		return LocaleManager.t("HUB_PRESENCE_NEEDS_PROFILE")
	return LocaleManager.t("HUB_PLAYERS_NEARBY").replace("{n}", str(_crowd_players.size()))

func _is_recent_emote(value: String) -> bool:
	if value.is_empty():
		return false
	var parsed := Time.get_unix_time_from_datetime_string(value)
	return parsed > 0.0 and Time.get_unix_time_from_system() - parsed <= 4.0

func _open_popup(title: String, fill: Callable) -> void:
	if is_instance_valid(_popup):
		_popup.queue_free()
	_popup = Control.new()
	_popup.anchor_right = 1.0
	_popup.anchor_bottom = 1.0
	_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_popup)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.06, 0.07, 0.72)
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	_popup.add_child(shade)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	var popup_half_height := minf(300.0, get_viewport_rect().size.y * 0.44)
	panel.offset_top = -popup_half_height
	panel.offset_bottom = popup_half_height
	_popup.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	var heading := UIFactory.make_title(title, 23)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	fill.call(content)
	var close := UIFactory.make_button(LocaleManager.t("BACK"), false)
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func(): _popup.queue_free())
	content.add_child(close)

func _show_toast(message: String) -> void:
	_toast_text = message
	_toast_timer = 2.8
	_refresh_labels()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		TransitionManager.go_to("res://scenes/main_menu.tscn")
