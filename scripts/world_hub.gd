extends Control
## A small walkable Kariakoo neighborhood between endless-run sessions.

const UIFactory := preload("res://ui/ui_factory.gd")
const Vehicles := preload("res://data/vehicles.gd")
const RouteContractsData := preload("res://data/route_contracts.gd")
const DECOR: Array[Dictionary] = [
	{"id": "kanga_flag", "price": 90, "key": "HUB_DECOR_FLAG", "district": "kariakoo"},
	{"id": "soko_lanterns", "price": 150, "key": "HUB_DECOR_LANTERNS", "district": "kariakoo"},
	{"id": "kituo_bench", "price": 210, "key": "HUB_DECOR_BENCH", "district": "kariakoo"},
	{"id": "market_awning", "price": 220, "key": "HUB_DECOR_AWNING", "district": "kariakoo"},
	{"id": "mtaa_mural", "price": 180, "key": "HUB_DECOR_MURAL", "district": "kariakoo"},
	{"id": "bus_bay_bollards", "price": 120, "key": "HUB_DECOR_BOLLARDS", "district": "kariakoo"},
	{"id": "roof_ornament", "price": 240, "key": "HUB_DECOR_ROOF", "district": "kariakoo"},
	{"id": "seat_covers", "price": 280, "key": "HUB_DECOR_SEATS", "district": "kariakoo"},
	{"id": "side_mirrors", "price": 180, "key": "HUB_DECOR_MIRRORS", "district": "kariakoo"},
	{"id": "mwenge_reflectors", "price": 190, "key": "HUB_DECOR_REFLECTORS", "district": "mwenge"},
	{"id": "mbezi_roof_rack", "price": 260, "key": "HUB_DECOR_ROOF_RACK", "district": "mbezi"},
	{"id": "posta_placard", "price": 220, "key": "HUB_DECOR_PLACARD", "district": "posta"},
	{"id": "kigamboni_lamp", "price": 240, "key": "HUB_DECOR_LAMP", "district": "kigamboni"},
	{"id": "ubungo_flag", "price": 300, "key": "HUB_DECOR_TERMINAL_FLAG", "district": "ubungo"},
	{"id": "konda_cap", "price": 160, "key": "HUB_WEAR_KONDA_CAP", "district": "kariakoo", "avatar": true, "icon": "^"},
	{"id": "boda_helmet", "price": 200, "key": "HUB_WEAR_BODA_HELMET", "district": "mwenge", "avatar": true, "icon": "o"},
	{"id": "road_shades", "price": 180, "key": "HUB_WEAR_ROAD_SHADES", "district": "mbezi", "avatar": true, "icon": ":"},
	{"id": "conductor_sash", "price": 230, "key": "HUB_WEAR_CONDUCTOR_SASH", "district": "posta", "avatar": true, "icon": "/"},
	{"id": "coastal_kanga", "price": 250, "key": "HUB_WEAR_COASTAL_KANGA", "district": "kigamboni", "avatar": true, "icon": "~"},
	{"id": "dispatcher_badge", "price": 300, "key": "HUB_WEAR_DISPATCHER_BADGE", "district": "ubungo", "avatar": true, "icon": "*"},
	{"id": "posta_relay_stand", "price": 360, "key": "HUB_DECOR_POSTA_RELAY", "district": "posta", "property": "posta_flat", "level": 2, "icon": "+"},
	{"id": "mtaa_phone", "price": 420, "key": "HUB_ITEM_MTA_PHONE", "district": "kariakoo", "phone": true, "icon": "▣"},
	{"id": "juma_scarf", "price": 0, "key": "HUB_REWARD_JUMA_SCARF", "district": "kariakoo", "icon": "~", "avatar": true, "bond": "juma", "level": 3},
	{"id": "musa_spanner_pin", "price": 0, "key": "HUB_REWARD_MUSA_PIN", "district": "mbezi", "icon": "+", "avatar": true, "bond": "musa", "level": 3},
	{"id": "rehema_postbag", "price": 0, "key": "HUB_REWARD_REHEMA_BAG", "district": "posta", "icon": "P", "avatar": true, "bond": "rehema", "level": 3},
]
const PROPERTIES: Array[Dictionary] = [
	{"id": "kiosk", "price": 350, "upgrade_price": 250, "key": "HUB_PROPERTY_KIOSK", "perk": "HUB_PERK_KIOSK", "max_level": 2, "district": "kariakoo"},
	{"id": "home", "price": 600, "upgrade_price": 400, "key": "HUB_PROPERTY_HOME", "max_level": 3, "rental": true, "rent_per_level": 8, "district": "kariakoo"},
	{"id": "workshop", "price": 900, "upgrade_price": 500, "key": "HUB_PROPERTY_WORKSHOP", "perk": "HUB_PERK_WORKSHOP", "max_level": 2, "district": "kariakoo"},
	{"id": "guest_house", "price": 1100, "upgrade_price": 700, "key": "HUB_PROPERTY_GUEST", "max_level": 3, "rental": true, "rent_per_level": 12, "district": "kariakoo"},
	{"id": "mwenge_home", "price": 1000, "upgrade_price": 650, "key": "HUB_PROPERTY_MWENGE", "max_level": 3, "rental": true, "rent_per_level": 8, "district": "mwenge"},
	{"id": "mbezi_yard", "price": 1250, "upgrade_price": 800, "key": "HUB_PROPERTY_MBEZI", "perk": "HUB_PERK_MBEZI", "max_level": 2, "district": "mbezi"},
	{"id": "posta_flat", "price": 1450, "upgrade_price": 950, "key": "HUB_PROPERTY_POSTA", "perk": "HUB_PERK_POSTA", "max_level": 3, "rental": true, "rent_per_level": 10, "district": "posta"},
	{"id": "kigamboni_cottage", "price": 1500, "upgrade_price": 1000, "key": "HUB_PROPERTY_KIGAMBONI", "max_level": 3, "rental": true, "rent_per_level": 10, "district": "kigamboni"},
	{"id": "ubungo_rooms", "price": 1700, "upgrade_price": 1100, "key": "HUB_PROPERTY_UBUNGO", "max_level": 3, "rental": true, "rent_per_level": 6, "district": "ubungo"},
]
const CHAT_PHRASES: Array[Dictionary] = [
	{"id": "chat_hello", "key": "HUB_CHAT_HELLO"},
	{"id": "chat_route", "key": "HUB_CHAT_ROUTE"},
	{"id": "chat_business", "key": "HUB_CHAT_BUSINESS"},
	{"id": "chat_drive", "key": "HUB_CHAT_DRIVE"},
	{"id": "chat_thanks", "key": "HUB_CHAT_THANKS"},
]
const JOBS: Array[Dictionary] = [
	{"id": "passenger_escort", "start": "stop", "finish": "plaza", "reward": 12, "key": "HUB_JOB_PASSENGER"},
	{"id": "market_delivery", "start": "market", "finish": "stop", "reward": 15, "key": "HUB_JOB_DELIVERY", "property": "kiosk"},
	{"id": "parts_run", "start": "garage", "finish": "route_board", "reward": 15, "key": "HUB_JOB_PARTS", "property": "workshop"},
	{"id": "kiosk_stock", "start": "property_board", "finish": "market", "reward": 15, "key": "HUB_JOB_STOCK", "property": "kiosk", "level": 2},
	{"id": "mwenge_boda_delivery", "start": "boda_yard", "finish": "terminal", "reward": 16, "key": "HUB_JOB_MWENGE"},
	{"id": "mbezi_fuel_run", "start": "fuel_depot", "finish": "garage", "reward": 16, "key": "HUB_JOB_MBEZI"},
	{"id": "posta_courier", "start": "posta_office", "finish": "route_board", "reward": 18, "key": "HUB_JOB_POSTA"},
	{"id": "kigamboni_parcel", "start": "ferry", "finish": "market", "reward": 17, "key": "HUB_JOB_KIGAMBONI"},
	{"id": "ubungo_manifest", "start": "terminal", "finish": "boda_yard", "reward": 20, "key": "HUB_JOB_UBUNGO"},
]
const MAX_PAID_JOBS_PER_DAY := 2
const AREA_SIZE := Vector2(540, 960)
const WORLD_SIZE := Vector2(1620, 1920)
const DISTRICTS: Array[Dictionary] = [
	{"id": "kariakoo", "origin": Vector2.ZERO, "key": "HUB_AREA_KARIAKOO", "color": Color("#9bc6a1"), "route": "kariakoo"},
	{"id": "mwenge", "origin": Vector2(540, 0), "key": "HUB_AREA_MWENGE", "color": Color("#a8c59c"), "route": "mwenge"},
	{"id": "mbezi", "origin": Vector2(1080, 0), "key": "HUB_AREA_MBEZI", "color": Color("#a3c8bb"), "route": "mbezi"},
	{"id": "posta", "origin": Vector2(0, 960), "key": "HUB_AREA_POSTA", "color": Color("#c0c2a3"), "route": "posta"},
	{"id": "kigamboni", "origin": Vector2(540, 960), "key": "HUB_AREA_KIGAMBONI", "color": Color("#8ec6bd"), "route": "kigamboni"},
	{"id": "ubungo", "origin": Vector2(1080, 960), "key": "HUB_AREA_UBUNGO", "color": Color("#9ba7a0"), "route": "ubungo"},
]
const SPOTS: Array[Dictionary] = [
	{"id": "stop", "position": Vector2(270, 738), "key": "HUB_FIND_STOP", "icon": "K"},
	{"id": "market", "position": Vector2(425, 430), "key": "HUB_FIND_MARKET", "icon": "S"},
	{"id": "garage", "position": Vector2(112, 380), "key": "HUB_FIND_GARAGE", "icon": "D"},
	{"id": "plaza", "position": Vector2(270, 250), "key": "HUB_FIND_PLAZA", "icon": "★"},
	{"id": "route_board", "position": Vector2(98, 510), "key": "HUB_FIND_ROUTE_BOARD", "icon": "R"},
	{"id": "property_board", "position": Vector2(442, 510), "key": "HUB_FIND_PROPERTIES", "icon": "⌂"},
	{"id": "mwenge_market", "position": Vector2(960, 420), "key": "HUB_SHOP_MWENGE", "icon": "S", "district": "mwenge"},
	{"id": "boda_yard", "position": Vector2(630, 510), "key": "HUB_ACTIVITY_MWENGE", "icon": "B", "district": "mwenge"},
	{"id": "mbezi_market", "position": Vector2(1500, 420), "key": "HUB_SHOP_MBEZI", "icon": "S", "district": "mbezi"},
	{"id": "fuel_depot", "position": Vector2(1170, 510), "key": "HUB_ACTIVITY_MBEZI", "icon": "F", "district": "mbezi"},
	{"id": "posta_market", "position": Vector2(420, 1400), "key": "HUB_SHOP_POSTA", "icon": "S", "district": "posta"},
	{"id": "posta_office", "position": Vector2(100, 1470), "key": "HUB_ACTIVITY_POSTA", "icon": "P", "district": "posta"},
	{"id": "kigamboni_market", "position": Vector2(960, 1400), "key": "HUB_SHOP_KIGAMBONI", "icon": "S", "district": "kigamboni"},
	{"id": "ferry", "position": Vector2(630, 1470), "key": "HUB_ACTIVITY_KIGAMBONI", "icon": "F", "district": "kigamboni"},
	{"id": "ubungo_market", "position": Vector2(1500, 1400), "key": "HUB_SHOP_UBUNGO", "icon": "S", "district": "ubungo"},
	{"id": "terminal", "position": Vector2(1170, 1470), "key": "HUB_ACTIVITY_UBUNGO", "icon": "D", "district": "ubungo"},
	{"id": "mwenge_properties", "position": Vector2(970, 590), "key": "HUB_PROPERTY_OFFICE", "icon": "⌂", "district": "mwenge"},
	{"id": "mbezi_properties", "position": Vector2(1510, 590), "key": "HUB_PROPERTY_OFFICE", "icon": "⌂", "district": "mbezi"},
	{"id": "posta_properties", "position": Vector2(430, 1550), "key": "HUB_PROPERTY_OFFICE", "icon": "⌂", "district": "posta"},
	{"id": "kigamboni_properties", "position": Vector2(970, 1550), "key": "HUB_PROPERTY_OFFICE", "icon": "⌂", "district": "kigamboni"},
	{"id": "ubungo_properties", "position": Vector2(1510, 1550), "key": "HUB_PROPERTY_OFFICE", "icon": "⌂", "district": "ubungo"},
	{"id": "kiosk_plot", "position": Vector2(442, 482), "key": "HUB_PROPERTY_KIOSK", "icon": "D", "district": "kariakoo"},
	{"id": "home_plot", "position": Vector2(58, 500), "key": "HUB_PROPERTY_HOME", "icon": "H", "district": "kariakoo"},
	{"id": "workshop_plot", "position": Vector2(470, 652), "key": "HUB_PROPERTY_WORKSHOP", "icon": "W", "district": "kariakoo"},
	{"id": "guest_house_plot", "position": Vector2(155, 500), "key": "HUB_PROPERTY_GUEST", "icon": "G", "district": "kariakoo"},
	{"id": "mwenge_home_plot", "position": Vector2(978, 600), "key": "HUB_PROPERTY_MWENGE", "icon": "H", "district": "mwenge"},
	{"id": "mbezi_yard_plot", "position": Vector2(1518, 600), "key": "HUB_PROPERTY_MBEZI", "icon": "H", "district": "mbezi"},
	{"id": "posta_flat_plot", "position": Vector2(438, 1560), "key": "HUB_PROPERTY_POSTA", "icon": "H", "district": "posta"},
	{"id": "kigamboni_cottage_plot", "position": Vector2(978, 1560), "key": "HUB_PROPERTY_KIGAMBONI", "icon": "H", "district": "kigamboni"},
	{"id": "ubungo_rooms_plot", "position": Vector2(1518, 1560), "key": "HUB_PROPERTY_UBUNGO", "icon": "H", "district": "ubungo"},
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
var _avatar_item := ""
var _placements: Dictionary = {}
var _passport_visited: Array[String] = []
var _passport_jobs: Array[String] = []
var _passport_claimed: Array[String] = []
var _album_found: Array[String] = []
var _npc_bonds: Dictionary = {}
var _phone_button: Button
var _properties: Dictionary = {}
var _rent_claimed_date := ""
var _errand_started := false
var _errand_progress: Array[String] = []
var _errand_completed := false
var _intro_complete := false
var _active_job_id := ""
var _active_job_step := 0
var _jobs_claimed_today := 0
var _jobs_claimed_date := ""
var _election_data: Dictionary = {}
var _election_status := ""
var _election_vote_pending := false
var _election_registration_pending := false
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
var _current_district_id := "kariakoo"
var _travel_tween: Tween
var _arrival_pulse := 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(_layout_hud)
	LocaleManager.locale_changed.connect(_on_locale_changed)
	OnlineService.request_finished.connect(_on_online_request_finished)
	_owned_decor.assign(SaveSystem.get_value("hub_owned_decor", []))
	_avatar_item = String(SaveSystem.get_value("hub_avatar_item", ""))
	_placements = SaveSystem.get_value("hub_decor_placements", {}).duplicate(true)
	_passport_visited.assign(SaveSystem.get_value("hub_passport_visited", []))
	_passport_jobs.assign(SaveSystem.get_value("hub_passport_jobs", []))
	_passport_claimed.assign(SaveSystem.get_value("hub_passport_claimed", []))
	_album_found.assign(SaveSystem.get_value("hub_album_found", []))
	_npc_bonds = SaveSystem.get_value("hub_npc_bonds", {}).duplicate(true)
	_properties = SaveSystem.get_value("hub_properties", {}).duplicate(true)
	_rent_claimed_date = String(SaveSystem.get_value("hub_rent_claimed_date", ""))
	_intro_complete = bool(SaveSystem.get_value("hub_intro_complete", false))
	_active_job_id = String(SaveSystem.get_value("hub_active_job_id", ""))
	_active_job_step = int(SaveSystem.get_value("hub_active_job_step", 0))
	var today := Time.get_date_string_from_system()
	_jobs_claimed_date = String(SaveSystem.get_value("hub_jobs_claimed_date", ""))
	_jobs_claimed_today = int(SaveSystem.get_value("hub_jobs_claimed_count", 0)) if _jobs_claimed_date == today else 0
	_errand_completed = String(SaveSystem.get_value("hub_daily_completed_date", "")) == today
	_errand_started = String(SaveSystem.get_value("hub_daily_started_date", "")) == today
	_errand_progress.assign(SaveSystem.get_value("hub_daily_progress", []) if _errand_started else [])
	if not _errand_started and not SaveSystem.get_value("hub_daily_progress", []).is_empty():
		SaveSystem.set_value("hub_daily_progress", [])
	if _jobs_claimed_date != today:
		_jobs_claimed_date = today
		SaveSystem.begin_batch()
		SaveSystem.set_value("hub_jobs_claimed_date", today)
		SaveSystem.set_value("hub_jobs_claimed_count", 0)
		SaveSystem.end_batch()
	var returning_activity: Dictionary = SaveSystem.get_value("hub_route_activity", {}).duplicate(true)
	var route_reward_paid := _settle_route_activity()
	var saved_activity: Dictionary = returning_activity
	if not saved_activity.is_empty():
		var home_district := String(saved_activity.get("district", "kariakoo"))
		var home := _district_definition(home_district)
		if not home.is_empty():
			_player_position = Vector2(home.origin) + Vector2(270, 760)
			_current_district_id = home_district
	_build_hud()
	_layout_hud()
	_refresh_labels()
	_record_district_visit(_current_district_id)
	if route_reward_paid:
		var route_district := String(saved_activity.get("district", "kariakoo"))
		var route_npc := _npc_for_route(route_district)
		var relationship_before := int(_npc_bonds.get(route_npc, 0))
		var bond_reward := _record_activity_district(route_district, route_npc)
		var payout_message := LocaleManager.t("HUB_ROUTE_PAID_SLOTS").replace("{n}", "25").replace("{left}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today)))
		var relationship_level := int(_npc_bonds.get(route_npc, 0))
		if relationship_level > relationship_before:
			payout_message += "\n" + LocaleManager.t("HUB_NPC_REMEMBER").replace("{name}", LocaleManager.t("HUB_NPC_" + route_npc.to_upper())).replace("{n}", str(relationship_level))
		if bond_reward:
			payout_message += "\n" + LocaleManager.t("HUB_NPC_REWARD").replace("{name}", LocaleManager.t("HUB_NPC_" + route_npc.to_upper()))
		_show_toast(payout_message)
	elif String(saved_activity.get("status", "")) == "success_pending":
		_show_toast(LocaleManager.t("HUB_ROUTE_DEFERRED_SLOTS").replace("{n}", "25").replace("{left}", "0"))
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
		_player_position.x = clampf(_player_position.x, 24.0, WORLD_SIZE.x - 24.0)
		_player_position.y = clampf(_player_position.y, 24.0, WORLD_SIZE.y - 24.0)
		queue_redraw()
	var district_id := _district_at(_player_position)
	if district_id != _current_district_id:
		_current_district_id = district_id
		_refresh_labels()
		_sync_online_presence(true)
		queue_redraw()
		_record_district_visit(district_id)
		_show_toast(LocaleManager.t("HUB_GREETING_" + district_id.to_upper()))
		_play_arrival_feedback(district_id)
	if _arrival_pulse > 0.0:
		_arrival_pulse = maxf(0.0, _arrival_pulse - delta)
		if not bool(SaveSystem.get_value("reduced_effects", false)):
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
	_map_offset = viewport_size * 0.5 - _player_position * _map_scale
	_map_offset.x = clampf(_map_offset.x, viewport_size.x - WORLD_SIZE.x * _map_scale, 0.0)
	_map_offset.y = clampf(_map_offset.y, viewport_size.y - WORLD_SIZE.y * _map_scale, 0.0)
	for district in DISTRICTS:
		var origin: Vector2 = district.origin
		draw_set_transform(_map_offset + origin * _map_scale, 0.0, Vector2.ONE * _map_scale)
		if String(district.id) == "kariakoo":
			_draw_district()
			_draw_ambient_life()
		else:
			_draw_other_district(String(district.id), district.color)
			_draw_other_ambient(String(district.id))
		_draw_property_placements(String(district.id))
		_draw_district_wayfinding(String(district.id))
	draw_set_transform(_map_offset, 0.0, Vector2.ONE * _map_scale)
	_draw_spots()
	_draw_avatar()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_other_district(district_id: String, ground: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, AREA_SIZE), ground)
	draw_rect(Rect2(0, 0, 540, 960), Color(0.0, 0.0, 0.0, 0.025), false, 3.0)
	draw_rect(Rect2(0, 350, 540, 112), Color("#626968"), true)
	draw_rect(Rect2(0, 650, 540, 98), Color("#626968"), true)
	for lane_x in range(16, 540, 76):
		draw_rect(Rect2(lane_x, 401, 34, 5), Color("#f3dda0"), true)
		draw_rect(Rect2(lane_x + 36, 695, 34, 5), Color("#f3dda0"), true)
	for x in [24.0, 204.0, 392.0]:
		var frontage := Color("#d27a52") if int(x) == 24 else (Color("#4d8c83") if int(x) == 204 else Color("#c99d42"))
		_draw_shop(Vector2(x, 255), Vector2(128, 78), frontage, LocaleManager.t(_market_sign_key(district_id)))
	match district_id:
		"mwenge":
			_draw_boda(Vector2(126, 548), Color("#e3a632"))
			_draw_boda(Vector2(188, 556), Color("#388a78"))
			draw_string(ThemeDB.fallback_font, Vector2(74, 536), LocaleManager.t("HUB_LANDMARK_MWENGE"), HORIZONTAL_ALIGNMENT_LEFT, 260, 15, Color("#254743"))
		"mbezi":
			_draw_truck(Vector2(74, 505))
			draw_rect(Rect2(385, 500, 118, 74), Color("#bfcdca"), true)
			draw_rect(Rect2(397, 515, 92, 24), Color("#e5b34e"), true)
			draw_string(ThemeDB.fallback_font, Vector2(388, 531), LocaleManager.t("HUB_LANDMARK_MBEZI"), HORIZONTAL_ALIGNMENT_CENTER, 112, 11, Color("#243438"))
		"posta":
			_draw_shop(Vector2(189, 500), Vector2(164, 122), Color("#bd5646"), LocaleManager.t("HUB_LANDMARK_POSTA"))
			draw_circle(Vector2(270, 488), 38.0, Color("#e7d7ae"))
			draw_circle(Vector2(270, 488), 30.0, Color("#b75b48"))
			draw_circle(Vector2(270, 488), 4.0, Color("#fff1ce"))
		"kigamboni":
			draw_rect(Rect2(0, 0, 540, 184), Color("#72b9c1"), true)
			for wave_x in range(0, 540, 72):
				draw_line(Vector2(wave_x, 126), Vector2(wave_x + 46, 126), Color("#c8eee0"), 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0, 190), Vector2(540, 190), Vector2(540, 280), Vector2(0, 244)]), Color("#d8c59b"))
			draw_rect(Rect2(65, 504, 178, 16), Color("#74513d"), true)
			for pier_x in [82.0, 215.0]:
				draw_rect(Rect2(pier_x, 514, 10, 86), Color("#74513d"), true)
			_draw_boat(Vector2(270, 572))
		"ubungo":
			for platform_x in [22.0, 398.0]:
				draw_rect(Rect2(platform_x, 494, 120, 104), Color("#b8b5a5"), true)
				draw_rect(Rect2(platform_x, 494, 120, 18), Color("#d38c43"), true)
			_draw_small_bus(Vector2(225, 534), Color("#237d86"))
			_draw_small_bus(Vector2(300, 572), Color("#d58b32"))
	_draw_area_landmark_sign(district_id)
	_draw_area_property(district_id)

func _draw_other_ambient(district_id: String) -> void:
	for person in [Vector2(128, 610), Vector2(406, 612), Vector2(278, 292)]:
		_draw_person(person, [Color("#d26c4f"), Color("#e3a63f"), Color("#418c78")][posmod(int(person.x), 3)], "")
	match district_id:
		"mwenge": _draw_boda(Vector2(352, 729), Color("#479376"))
		"mbezi": _draw_truck(Vector2(468, 728))
		"kigamboni": _draw_palm(Vector2(446, 214))
		"ubungo": _draw_small_bus(Vector2(446, 214), Color("#338a87"))

func _draw_boda(point: Vector2, color: Color) -> void:
	draw_circle(point + Vector2(-13, 15), 8, Color("#263137"))
	draw_circle(point + Vector2(20, 15), 8, Color("#263137"))
	draw_line(point + Vector2(-13, 15), point + Vector2(2, 0), color, 5.0)
	draw_line(point + Vector2(2, 0), point + Vector2(20, 15), color, 5.0)
	draw_circle(point + Vector2(3, -7), 7, Color("#d99d6d"))

func _draw_truck(point: Vector2) -> void:
	draw_rect(Rect2(point, Vector2(62, 35)), Color("#b66a43"), true)
	draw_rect(Rect2(point + Vector2(36, 8), Vector2(29, 27)), Color("#396c72"), true)
	draw_circle(point + Vector2(15, 38), 6, Color("#263137"))
	draw_circle(point + Vector2(51, 38), 6, Color("#263137"))

func _draw_boat(point: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([point + Vector2(-55, 0), point + Vector2(58, 0), point + Vector2(39, 22), point + Vector2(-34, 22)]), Color("#985b40"))
	draw_line(point + Vector2(0, -45), point + Vector2(0, 0), Color("#684a37"), 3.0)
	draw_colored_polygon(PackedVector2Array([point + Vector2(2, -42), point + Vector2(2, -4), point + Vector2(34, -8)]), Color("#f0d88e"))

func _draw_small_bus(point: Vector2, color: Color) -> void:
	draw_rect(Rect2(point, Vector2(48, 82)), color, true)
	draw_rect(Rect2(point + Vector2(5, 8), Vector2(38, 24)), Color("#b8d9db"), true)
	draw_rect(Rect2(point + Vector2(5, 42), Vector2(38, 22)), Color("#e6c85e"), true)

func _draw_area_landmark_sign(district_id: String) -> void:
	draw_rect(Rect2(139, 196, 262, 34), Color("#233b3d"), true)
	draw_string(ThemeDB.fallback_font, Vector2(148, 218), LocaleManager.t(_area_key(district_id)), HORIZONTAL_ALIGNMENT_CENTER, 244, 17, Color("#fff0be"))

func _draw_area_cosmetic(district_id: String) -> void:
	var item_by_area := {"mwenge": "mwenge_reflectors", "mbezi": "mbezi_roof_rack", "posta": "posta_placard", "kigamboni": "kigamboni_lamp", "ubungo": "ubungo_flag"}
	if not _owned_decor.has(String(item_by_area.get(district_id, ""))) and not (district_id == "posta" and "posta_relay_stand" in _owned_decor):
		return
	match district_id:
		"mwenge":
			draw_rect(Rect2(30, 772, 42, 30), Color("#e3bb41"), true)
			draw_line(Vector2(33, 786), Vector2(68, 786), Color.WHITE, 3.0)
		"mbezi":
			draw_line(Vector2(230, 751), Vector2(310, 751), Color("#52666a"), 5.0)
			draw_line(Vector2(239, 744), Vector2(239, 758), Color("#52666a"), 4.0)
			draw_line(Vector2(300, 744), Vector2(300, 758), Color("#52666a"), 4.0)
		"posta":
			if "posta_placard" in _owned_decor:
				draw_rect(Rect2(230, 772, 80, 26), Color("#d6b84e"), true)
				draw_string(ThemeDB.fallback_font, Vector2(232, 790), "POSTA", HORIZONTAL_ALIGNMENT_CENTER, 76, 10, Color("#26383c"))
			if "posta_relay_stand" in _owned_decor:
				draw_rect(Rect2(320, 760, 34, 42), Color("#d8c59b"), true)
				draw_rect(Rect2(324, 766, 26, 6), Color("#9c6143"), true)
				draw_rect(Rect2(324, 778, 26, 6), Color("#9c6143"), true)
		"kigamboni":
			draw_line(Vector2(446, 250), Vector2(446, 210), Color("#573d34"), 3.0)
			draw_circle(Vector2(446, 207), 10, Color("#ffc861"))
		"ubungo":
			draw_line(Vector2(456, 264), Vector2(456, 220), Color("#604838"), 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(457, 221), Vector2(492, 230), Vector2(457, 240)]), Color("#d65d45"))

func _draw_area_property(district_id: String) -> void:
	var property_ids := {"mwenge": "mwenge_home", "mbezi": "mbezi_yard", "posta": "posta_flat", "kigamboni": "kigamboni_cottage", "ubungo": "ubungo_rooms"}
	var property_id := String(property_ids.get(district_id, ""))
	if property_id.is_empty():
		return
	var level := int(_properties.get(property_id, 0))
	_draw_house_plot(Vector2(397, 546), level, Color("#bb5644") if district_id != "kigamboni" else Color("#4e8490"), "P")

func _draw_property_placements(district_id: String) -> void:
	var property_districts := {
		"kiosk": "kariakoo", "home": "kariakoo", "guest_house": "kariakoo", "workshop": "kariakoo",
		"mwenge_home": "mwenge", "mbezi_yard": "mbezi", "posta_flat": "posta",
		"kigamboni_cottage": "kigamboni", "ubungo_rooms": "ubungo",
	}
	for property_id in _placements:
		if String(property_districts.get(String(property_id), "")) != district_id:
			continue
		var origin := _property_display_anchor(String(property_id))
		var slots: Array = _placements[property_id]
		for slot in range(mini(3, slots.size())):
			var item_id := String(slots[slot])
			if item_id.is_empty():
				continue
			var definition := _decor_definition(item_id)
			var point := origin + Vector2(float(slot - 1) * 34.0, -4)
			draw_rect(Rect2(point + Vector2(-14, -15), Vector2(28, 31)), Color(0.12, 0.18, 0.18, 0.24), true)
			draw_rect(Rect2(point + Vector2(-16, -18), Vector2(28, 31)), Color("#fff0be"), true)
			draw_rect(Rect2(point + Vector2(-16, -18), Vector2(28, 31)), Color("#25383b"), false, 1.5)
			draw_string(ThemeDB.fallback_font, point + Vector2(-12, 3), String(definition.get("icon", "◆")), HORIZONTAL_ALIGNMENT_CENTER, 20, 17, Color("#25383b"))

func _property_display_anchor(property_id: String) -> Vector2:
	return {
		"kiosk": Vector2(444, 438), "home": Vector2(58, 475), "guest_house": Vector2(155, 475),
		"workshop": Vector2(469, 585), "mwenge_home": Vector2(438, 532), "mbezi_yard": Vector2(438, 532),
		"posta_flat": Vector2(438, 532), "kigamboni_cottage": Vector2(438, 532), "ubungo_rooms": Vector2(438, 532),
	}.get(property_id, Vector2(438, 532))

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
	draw_string(ThemeDB.fallback_font, Vector2(202, 436), LocaleManager.t("HUB_LOUNGE_TITLE"), HORIZONTAL_ALIGNMENT_CENTER, 140, 9, Color("#fff0be"))
	for x in [180.0, 235.0, 290.0, 345.0]:
		draw_rect(Rect2(x, 454, 26, 14), Color("#f2c66d"), true)
	draw_rect(Rect2(206, 500, 128, 86), Color("#d8bf91"), true)
	draw_rect(Rect2(211, 505, 118, 76), Color("#ead8b5"), true)
	for tree in [Vector2(58, 246), Vector2(482, 246), Vector2(58, 615), Vector2(482, 615), Vector2(115, 530), Vector2(425, 530)]:
		_draw_palm(tree)
	# The player's bus remains parked at the dala stand, rendered with the game's chosen skin.
	var display_vehicle := String(SaveSystem.get_value("hub_display_vehicle", ""))
	if display_vehicle.is_empty() or display_vehicle not in SaveSystem.get_value("unlocked_vehicles", []):
		display_vehicle = GameState.selected_vehicle_id
	var vehicle: Dictionary = Vehicles.get_by_id(display_vehicle)
	var texture: Texture2D = SpriteLib.get_tex("vehicle", String(vehicle.get("id", "classic_blue")))
	if texture != null:
		draw_texture_rect(texture, Rect2(223, 765, 94, 126), false)
	else:
		draw_rect(Rect2(230, 768, 80, 117), vehicle.get("body", Color("#1f8fff")), true)
		draw_rect(Rect2(237, 780, 66, 24), Color("#1b2938"), true)
		draw_rect(Rect2(237, 818, 66, 31), vehicle.get("accent", Color("#ffd23f")), true)
	# Owned plot decorations are drawn only in their saved slots below.
	_draw_properties()
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

func _draw_properties() -> void:
	var kiosk_level := int(_properties.get("kiosk", 0))
	if kiosk_level > 0:
		_draw_shop(Vector2(397, 447), Vector2(94, 48), Color("#d5a338") if kiosk_level == 1 else Color("#df7451"), "DUKA %d" % kiosk_level)
	_draw_house_plot(Vector2(18, 435), int(_properties.get("home", 0)), Color("#bb5644"), "H")
	_draw_house_plot(Vector2(115, 435), int(_properties.get("guest_house", 0)), Color("#4e8490"), "G")
	if int(_properties.get("workshop", 0)) > 0:
		var level := int(_properties.workshop)
		draw_rect(Rect2(430, 597, 80, 46), Color("#597f82"), true)
		draw_rect(Rect2(426, 590, 88, 11), Color("#d55e42"), true)
		draw_rect(Rect2(441, 610, 24, 22), Color("#20343a"), true)
		draw_string(ThemeDB.fallback_font, Vector2(470, 625), "★" if level == 2 else "D", HORIZONTAL_ALIGNMENT_LEFT, 18, 12, Color("#ffe18c"))

func _draw_house_plot(origin: Vector2, level: int, roof_color: Color, mark: String) -> void:
	draw_rect(Rect2(origin + Vector2(4, 49), Vector2(78, 10)), Color("#8ea77b"), true)
	for fence_x in range(0, 80, 16):
		draw_line(origin + Vector2(fence_x, 48), origin + Vector2(fence_x, 59), Color("#b7a27b"), 2.0)
	if level <= 0:
		draw_rect(Rect2(origin + Vector2(21, 18), Vector2(42, 28)), Color("#596b55"), true)
		draw_string(ThemeDB.fallback_font, origin + Vector2(27, 36), mark + " • PLOT", HORIZONTAL_ALIGNMENT_CENTER, 42, 9, Color.WHITE)
		return
	var floors := 1 + int(level >= 2) + int(level >= 3)
	var height := 26.0 + float(floors - 1) * 12.0
	var base_y := origin.y + 46.0
	draw_rect(Rect2(origin + Vector2(14, base_y - height), Vector2(54, height)), Color("#e9daba"), true)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(8, base_y - height), origin + Vector2(41, base_y - height - 20),
		origin + Vector2(74, base_y - height),
	]), roof_color)
	for floor in range(floors):
		var floor_y := base_y - 18.0 - float(floor) * 12.0
		draw_rect(Rect2(origin + Vector2(20, floor_y), Vector2(12, 9)), Color("#78a9a5"), true)
		draw_rect(Rect2(origin + Vector2(49, floor_y), Vector2(12, 9)), Color("#78a9a5"), true)
	draw_rect(Rect2(origin + Vector2(34, base_y - 20), Vector2(14, 20)), Color("#805a43"), true)
	draw_string(ThemeDB.fallback_font, origin + Vector2(36, origin.y + 57), str(level), HORIZONTAL_ALIGNMENT_CENTER, 12, 9, Color("#263a35"))

func _draw_spots() -> void:
	var target := _next_target_spot()
	if not target.is_empty():
		var target_point: Vector2 = target.position
		var start := _player_position
		var direction := (target_point - start).normalized()
		var point := start + direction * 34.0
		while point.distance_to(target_point) > 32.0:
			draw_circle(point, 3.2, Color(1.0, 0.88, 0.48, 0.8))
			point += direction * 23.0
	for spot in SPOTS:
		var point: Vector2 = spot.position
		var is_current := String(spot.id) == _nearby_id
		draw_circle(point + Vector2(0, 3), 23.0, Color(0.08, 0.12, 0.12, 0.2))
		draw_circle(point, 21.0, Color("#18272d"))
		draw_circle(point, 17.0, Color("#17a589") if is_current else Color("#ffd166"))
		draw_string(ThemeDB.fallback_font, point + Vector2(-9, 6), String(spot.icon),
			HORIZONTAL_ALIGNMENT_CENTER, 18, 16, Color("#17242a"))
		if String(spot.id) in _errand_progress:
			draw_circle(point + Vector2(15, -14), 7.0, Color("#30c779"))
			draw_line(point + Vector2(11, -14), point + Vector2(14, -10), Color.WHITE, 2.0)
			draw_line(point + Vector2(14, -10), point + Vector2(20, -18), Color.WHITE, 2.0)
		var sign_text := LocaleManager.t(String(spot.key))
		draw_string(ThemeDB.fallback_font, point + Vector2(-42, 34), sign_text,
			HORIZONTAL_ALIGNMENT_CENTER, 84, 10, Color("#17242a"))
	for player in _crowd_players:
		var other_position := Vector2(float(player.x) * AREA_SIZE.x / 1000.0, float(player.y) * AREA_SIZE.y / 1000.0)
		var vehicle: Dictionary = Vehicles.get_by_id(String(player.vehicleId))
		var texture: Texture2D = SpriteLib.get_tex("vehicle", String(player.vehicleId))
		draw_circle(other_position + Vector2(0, 12), 20.0, Color(0.07, 0.11, 0.12, 0.25))
		if texture != null:
			draw_texture_rect(texture, Rect2(other_position + Vector2(-14, -20), Vector2(28, 42)), false)
		else:
			draw_rect(Rect2(other_position + Vector2(-12, -18), Vector2(24, 38)), vehicle.get("body", Color("#388c84")), true)
			draw_rect(Rect2(other_position + Vector2(-11, -17), Vector2(22, 7)), vehicle.get("accent", Color("#ffd166")), true)
		var name_text := String(player.get("displayName", "Dereva")).substr(0, 14)
		draw_rect(Rect2(other_position + Vector2(-36, -38), Vector2(72, 15)), Color(0.08, 0.12, 0.13, 0.86), true)
		draw_string(ThemeDB.fallback_font, other_position + Vector2(-33, -27), name_text,
			HORIZONTAL_ALIGNMENT_CENTER, 66, 9, Color.WHITE)
		if _is_recent_emote(String(player.get("emoteAt", ""))):
			var emote := String(player.get("emote", ""))
			var emote_text: String = {"wave": "👋", "horn": "!", "dance": "♪"}.get(emote, "")
			if emote.begins_with("chat_"):
				emote_text = LocaleManager.t(_chat_phrase_key(emote))
				draw_rect(Rect2(other_position + Vector2(-48, -83), Vector2(112, 38)), Color("#fff3ce"), true)
				draw_colored_polygon(PackedVector2Array([
					other_position + Vector2(4, -48), other_position + Vector2(14, -48),
					other_position + Vector2(6, -40),
				]), Color("#fff3ce"))
				draw_string(ThemeDB.fallback_font, other_position + Vector2(-44, -60), emote_text,
					HORIZONTAL_ALIGNMENT_CENTER, 104, 9, Color("#25343a"))
			if not emote_text.is_empty():
				if not emote.begins_with("chat_"):
					draw_string(ThemeDB.fallback_font, other_position + Vector2(8, -17), emote_text,
						HORIZONTAL_ALIGNMENT_LEFT, 22, 15, Color.WHITE)

func _draw_ambient_life() -> void:
	# Simple local cast keeps the block lively without adding sprite or memory cost.
	_draw_person(Vector2(446, 403), Color("#d26c4f"), "S")
	_draw_person(Vector2(129, 393), Color("#e3a63f"), "D")
	_draw_person(Vector2(244, 704), Color("#418c78"), "")
	_draw_person(Vector2(295, 699), Color("#477ca0"), "")
	draw_rect(Rect2(365, 516, 32, 13), Color("#e8a33f"), true)
	draw_rect(Rect2(371, 508, 18, 10), Color("#b33e35"), true)
	draw_circle(Vector2(371, 531), 5.0, Color("#28343a"))
	draw_circle(Vector2(391, 531), 5.0, Color("#28343a"))
	if not _intro_complete:
		draw_circle(Vector2(270, 684), 18.0, Color("#fff0be"))
		draw_string(ThemeDB.fallback_font, Vector2(263, 691), "!", HORIZONTAL_ALIGNMENT_CENTER, 14, 20, Color("#a34435"))

func _draw_person(center: Vector2, shirt: Color, marker: String) -> void:
	draw_circle(center + Vector2(0, 13), 12.0, Color(0.08, 0.12, 0.12, 0.18))
	draw_circle(center + Vector2(0, -7), 6.5, Color("#d99d6d"))
	draw_rect(Rect2(center + Vector2(-7, 0), Vector2(14, 20)), shirt, true)
	draw_line(center + Vector2(-4, 19), center + Vector2(-6, 25), Color("#344654"), 3.0)
	draw_line(center + Vector2(4, 19), center + Vector2(6, 25), Color("#344654"), 3.0)
	if not marker.is_empty():
		draw_string(ThemeDB.fallback_font, center + Vector2(-7, -16), marker, HORIZONTAL_ALIGNMENT_CENTER, 14, 10, Color.WHITE)

func _next_target_spot() -> Dictionary:
	var target_id := ""
	if _active_job_id != "":
		var job := _job(_active_job_id)
		target_id = String(job.finish) if _active_job_step == 1 else String(job.start)
	elif not SaveSystem.get_value("hub_route_activity", {}).is_empty():
		var activity: Dictionary = SaveSystem.get_value("hub_route_activity", {})
		target_id = _spot_for_district(String(activity.get("district", "")))
	elif not _intro_complete and not _errand_started:
		target_id = "stop"
	elif _errand_started and not _errand_completed:
		for stop in ERRAND_STOPS:
			if stop not in _errand_progress:
				target_id = stop
				break
	return _spot(target_id) if not target_id.is_empty() else {}

func _draw_avatar() -> void:
	draw_set_transform(_map_offset + _player_position * _map_scale, 0.0, Vector2.ONE * _map_scale)
	if _arrival_pulse > 0.0 and not bool(SaveSystem.get_value("reduced_effects", false)):
		var pulse_progress := 1.0 - _arrival_pulse / 0.75
		draw_arc(Vector2(0, 4), 28.0 + pulse_progress * 18.0, 0.0, TAU, 36, Color(1.0, 0.82, 0.35, 1.0 - pulse_progress), 3.0)
	# A friendly top-down conductor avatar follows the player's steering.
	draw_circle(Vector2(2, 4), 18, Color(0.08, 0.10, 0.10, 0.25))
	draw_circle(Vector2(0, -12), 8.0, Color("#ecaa62"))
	draw_rect(Rect2(-10, -2, 20, 22), Color("#178c78"), true)
	if _avatar_item == "conductor_sash":
		draw_rect(Rect2(-10, 5, 20, 5), Color("#f2c34e"), true)
	elif _avatar_item == "coastal_kanga":
		draw_rect(Rect2(-10, 1, 20, 14), Color("#dc7352"), true)
	elif _avatar_item == "dispatcher_badge":
		draw_circle(Vector2(6, 2), 3.5, Color("#ffd166"))
	if _avatar_item in ["konda_cap", "boda_helmet"]:
		draw_rect(Rect2(-10, -22, 20, 6), Color("#e0a933") if _avatar_item == "konda_cap" else Color("#394d67"), true)
	elif _avatar_item == "road_shades":
		draw_rect(Rect2(-8, -14, 16, 3), Color("#253742"), true)
	elif _avatar_item == "juma_scarf":
		draw_rect(Rect2(-10, 3, 20, 5), Color("#d94e3b"), true)
	elif _avatar_item == "musa_spanner_pin":
		draw_circle(Vector2(6, 2), 3.5, Color("#8e9fa2"))
	elif _avatar_item == "rehema_postbag":
		draw_rect(Rect2(8, 4, 7, 13), Color("#bd7541"), true)
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
	var map_button := UIFactory.make_button("⌖", false)
	map_button.custom_minimum_size = Vector2(46, 46)
	map_button.tooltip_text = LocaleManager.t("HUB_MAP_TITLE")
	map_button.pressed.connect(_open_district_map)
	top.add_child(map_button)
	_phone_button = UIFactory.make_button("▣", false)
	_phone_button.custom_minimum_size = Vector2(46, 46)
	_phone_button.tooltip_text = LocaleManager.t("HUB_PHONE_TITLE")
	_phone_button.pressed.connect(_open_phone)
	top.add_child(_phone_button)
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

func _open_district_map() -> void:
	_open_popup(LocaleManager.t("HUB_MAP_TITLE"), func(body: VBoxContainer):
		var help := UIFactory.make_label(LocaleManager.t("HUB_MAP_BODY"), 13, UIFactory.COL_MUTED)
		help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(help)
		var legend := HBoxContainer.new()
		legend.add_child(UIFactory.make_label("● " + LocaleManager.t("HUB_MAP_CURRENT"), 12, Color("#178c78")))
		legend.add_child(UIFactory.make_label("  ◆ " + LocaleManager.t("HUB_MAP_TARGET"), 12, Color("#d29228")))
		body.add_child(legend)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		body.add_child(grid)
		for district in DISTRICTS:
			var district_id := String(district.id)
			var label := LocaleManager.t("HUB_SHORT_" + district_id.to_upper())
			if district_id == _current_district_id:
				label = "● " + label
			var target_area := _district_for_spot(_next_target_spot())
			if district_id == target_area and target_area != _current_district_id:
				label = "◆ " + label
			var travel := UIFactory.make_button(label, district_id == target_area and target_area != _current_district_id)
			travel.custom_minimum_size = Vector2(0, 60)
			travel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			travel.disabled = district_id == _current_district_id
			travel.pressed.connect(func(id: String = district_id): _confirm_travel_to_district(id))
			grid.add_child(travel)
	)

func _travel_to_district(district_id: String) -> void:
	var destination := _district_definition(district_id)
	if destination.is_empty() or district_id == _current_district_id:
		return
	_player_position = Vector2(destination.origin) + Vector2(270, 760)
	_current_district_id = district_id
	_move_vector = Vector2.ZERO
	if is_instance_valid(_popup):
		_popup.queue_free()
	_refresh_labels()
	_sync_online_presence(true)
	queue_redraw()
	_show_toast(LocaleManager.t("HUB_MAP_ARRIVED").replace("{area}", LocaleManager.t(String(destination.key))) + "\n" + LocaleManager.t("HUB_GREETING_" + district_id.to_upper()))
	_record_district_visit(district_id)
	_play_arrival_feedback(district_id)

func _play_arrival_feedback(district_id: String) -> void:
	if not bool(SaveSystem.get_value("reduced_effects", false)):
		_arrival_pulse = 0.75
	var bark_by_district := {"kariakoo": "voice_karibu", "mwenge": "voice_twende", "mbezi": "voice_mafuta", "posta": "voice_kituo", "kigamboni": "voice_karibu", "ubungo": "voice_twende"}
	AudioManager.play_hub_bark(String(bark_by_district.get(district_id, "voice_karibu")))

func _confirm_travel_to_district(district_id: String) -> void:
	var destination := _district_definition(district_id)
	if destination.is_empty():
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("HUB_TRAVEL_TITLE")
	dialog.dialog_text = LocaleManager.t("HUB_TRAVEL_PREVIEW").replace("{area}", LocaleManager.t(String(destination.key)))
	dialog.ok_button_text = LocaleManager.t("HUB_RIDE_FREE")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	dialog.confirmed.connect(func():
		_travel_to_district(district_id)
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(mini(420, int(get_viewport_rect().size.x) - 24), 0))

func _record_district_visit(district_id: String) -> void:
	if district_id not in ["kariakoo", "mwenge", "mbezi", "posta", "kigamboni", "ubungo"]:
		return
	var visited_before := _passport_visited.duplicate()
	var album_before := _album_found.duplicate()
	var claims_before := _passport_claimed.duplicate()
	if district_id not in _passport_visited:
		_passport_visited.append(district_id)
	if district_id not in _album_found:
		_album_found.append(district_id)
	var rewards := 0
	for pair in [[2, 20], [4, 40], [6, 70]]:
		var stamp := str(pair[0])
		if _passport_visited.size() >= int(pair[0]) and stamp not in _passport_claimed:
			_passport_claimed.append(stamp)
			rewards += int(pair[1])
	if visited_before == _passport_visited and album_before == _album_found and claims_before == _passport_claimed:
		return
	var wallet_before := int(SaveSystem.get_value("total_coins", 0))
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_passport_visited", _passport_visited)
	SaveSystem.set_value("hub_album_found", _album_found)
	SaveSystem.set_value("hub_passport_claimed", _passport_claimed)
	if rewards > 0:
		SaveSystem.add_coins(rewards)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_passport_visited = visited_before
		_album_found = album_before
		_passport_claimed = claims_before
		SaveSystem.data["total_coins"] = wallet_before
		SaveSystem.data["hub_passport_visited"] = _passport_visited
		SaveSystem.data["hub_album_found"] = _album_found
		SaveSystem.data["hub_passport_claimed"] = _passport_claimed
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	if rewards > 0:
		_show_toast(LocaleManager.t("HUB_PASSPORT_REWARD").replace("{n}", str(rewards)))
	else:
		_show_toast(LocaleManager.t("HUB_ALBUM_FOUND").replace("{area}", LocaleManager.t(_area_key(district_id))))
	AudioManager.play_sfx("coin" if rewards > 0 else "powerup")

func _record_activity_district(district_id: String, npc_id: String) -> bool:
	var jobs_before := _passport_jobs.duplicate()
	if district_id not in _passport_jobs:
		_passport_jobs.append(district_id)
	var bonds_before := _npc_bonds.duplicate(true)
	var owned_before := _owned_decor.duplicate()
	var level := mini(3, int(_npc_bonds.get(npc_id, 0)) + 1)
	_npc_bonds[npc_id] = level
	var reward_item := String({"juma": "juma_scarf", "musa": "musa_spanner_pin", "rehema": "rehema_postbag"}.get(npc_id, ""))
	var unlocked_reward := level >= 3 and not reward_item.is_empty() and reward_item not in _owned_decor
	if unlocked_reward:
		_owned_decor.append(reward_item)
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_passport_jobs", _passport_jobs)
	SaveSystem.set_value("hub_npc_bonds", _npc_bonds)
	if unlocked_reward:
		SaveSystem.set_value("hub_owned_decor", _owned_decor)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_passport_jobs = jobs_before
		_npc_bonds = bonds_before
		_owned_decor = owned_before
		SaveSystem.data["hub_npc_bonds"] = _npc_bonds
		SaveSystem.data["hub_passport_jobs"] = _passport_jobs
		SaveSystem.data["hub_owned_decor"] = _owned_decor
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return false
	return unlocked_reward

func _npc_for_job(job_id: String) -> String:
	if job_id in ["passenger_escort", "mwenge_boda_delivery", "kiosk_stock"]:
		return "juma"
	if job_id in ["parts_run", "mbezi_fuel_run"]:
		return "musa"
	return "rehema" if job_id in ["posta_courier", "kigamboni_parcel", "ubungo_manifest", "market_delivery"] else ""

func _npc_for_route(district_id: String) -> String:
	return {"kariakoo": "juma", "mwenge": "juma", "mbezi": "musa", "posta": "rehema", "kigamboni": "rehema", "ubungo": "rehema"}.get(district_id, "juma")

func _open_passport() -> void:
	_open_popup(LocaleManager.t("HUB_PASSPORT_TITLE"), func(body: VBoxContainer):
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_PASSPORT_PROGRESS").replace("{visited}", str(_passport_visited.size())).replace("{jobs}", str(_passport_jobs.size())), 14, UIFactory.COL_PRIMARY))
		for district in DISTRICTS:
			var area_id := String(district.id)
			var visited := area_id in _passport_visited
			var served := area_id in _passport_jobs
			var line := LocaleManager.t(String(district.key)) + "  •  " + ("✓" if visited else "○") + "  " + LocaleManager.t("HUB_PASSPORT_VISIT")
			line += "  •  " + ("✓" if served else "○") + "  " + LocaleManager.t("HUB_PASSPORT_ACTIVITY")
			body.add_child(UIFactory.make_label(line, 12, UIFactory.COL_TEXT))
		for milestone in [2, 4, 6]:
			var reward := 20 if milestone == 2 else (40 if milestone == 4 else 70)
			var claimed := str(milestone) in _passport_claimed
			body.add_child(UIFactory.make_label(LocaleManager.t("HUB_PASSPORT_MILESTONE").replace("{n}", str(milestone)).replace("{reward}", str(reward)) + ("  ✓" if claimed else ""), 12, UIFactory.COL_MUTED))
		for npc_id in ["juma", "musa", "rehema"]:
			var level := int(_npc_bonds.get(npc_id, 0))
			body.add_child(UIFactory.make_label(LocaleManager.t("HUB_NPC_BOND").replace("{name}", LocaleManager.t("HUB_NPC_" + npc_id.to_upper())).replace("{n}", str(level)), 12, UIFactory.COL_TEXT))
		var album := UIFactory.make_button(LocaleManager.t("HUB_ALBUM_TITLE"), false)
		album.pressed.connect(_open_album)
		body.add_child(album)
	)

func _open_album() -> void:
	_open_popup(LocaleManager.t("HUB_ALBUM_TITLE"), func(body: VBoxContainer):
		for district in DISTRICTS:
			var area_id := String(district.id)
			var found := area_id in _album_found
			body.add_child(UIFactory.make_label(("▣ " if found else "□ ") + LocaleManager.t("HUB_ALBUM_" + area_id.to_upper()) + "  •  " + LocaleManager.t(String(district.key)), 14, UIFactory.COL_TEXT if found else UIFactory.COL_MUTED))
	)

func _open_phone() -> void:
	if "mtaa_phone" not in _owned_decor:
		_open_popup(LocaleManager.t("HUB_PHONE_TITLE"), func(body: VBoxContainer):
			body.add_child(UIFactory.make_label(LocaleManager.t("HUB_PHONE_LOCKED"), 14, UIFactory.COL_MUTED))
			var buy := UIFactory.make_button(LocaleManager.t("HUB_PHONE_SHOP"), true)
			buy.pressed.connect(func():
				if _current_district_id != "kariakoo":
					_confirm_travel_to_district("kariakoo")
				else:
					_open_market("kariakoo", "mtaa_phone"))
			body.add_child(buy)
		)
		return
	_open_popup(LocaleManager.t("HUB_PHONE_TITLE"), func(body: VBoxContainer):
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_PHONE_HOME"), 13, UIFactory.COL_MUTED))
		for pair in [["HUB_PASSPORT_TITLE", Callable(self, "_open_passport")], ["HUB_ALBUM_TITLE", Callable(self, "_open_album")], ["HUB_EVENT_BOARD", Callable(self, "_open_event_board")], ["HUB_HOME_TITLE", Callable(self, "_open_home")], ["HUB_PHONE_ITEMS", Callable(self, "_open_owned_items")], ["HUB_PHONE_PROPERTIES", Callable(self, "_open_property_portfolio")], ["HUB_GLOBAL_CHAT", Callable(self, "_open_global_chat")], ["HUB_BUS_DISPLAY", Callable(self, "_open_bus_display")], ["HUB_MAP_TITLE", Callable(self, "_open_district_map")]]:
			var action := UIFactory.make_button(LocaleManager.t(String(pair[0])), false)
			action.custom_minimum_size = Vector2(0, 46)
			action.pressed.connect(pair[1])
			body.add_child(action)
	)

func _open_owned_items() -> void:
	_open_popup(LocaleManager.t("HUB_PHONE_ITEMS"), func(body: VBoxContainer):
		var owned_count := 0
		for item in DECOR:
			var item_id := String(item.id)
			if item_id not in _owned_decor:
				continue
			owned_count += 1
			var location := _placement_location_text(item_id)
			var item_name := LocaleManager.t(String(item.key)).replace("{n}", str(item.get("price", 0)))
			var line := UIFactory.make_label(item_name + "\n" + location, 13, UIFactory.COL_TEXT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(line)
			if bool(item.get("avatar", false)):
				var equip := UIFactory.make_button(LocaleManager.t("HUB_EQUIP" if _avatar_item != item_id else "HUB_WORN"), false)
				equip.disabled = _avatar_item == item_id
				equip.pressed.connect(func(id: String = item_id): _equip_avatar_item(id, _current_district_id))
				body.add_child(equip)
			elif _is_placeable_item(item_id):
				var place := UIFactory.make_button(LocaleManager.t("HUB_PLACE_ITEM"), false)
				place.pressed.connect(func(id: String = item_id): _open_placement_properties(id, false))
				body.add_child(place)
			elif bool(item.get("phone", false)):
				var open_phone := UIFactory.make_button(LocaleManager.t("HUB_PHONE_OPEN"), false)
				open_phone.pressed.connect(_open_phone)
				body.add_child(open_phone)
		if owned_count == 0:
			body.add_child(UIFactory.make_label(LocaleManager.t("HUB_OWNED_EMPTY"), 14, UIFactory.COL_MUTED))
	)

func _placement_location_text(decor_id: String) -> String:
	for property_id in _placements:
		var slots: Array = _placements[property_id]
		for slot_index in range(slots.size()):
			if String(slots[slot_index]) != decor_id:
				continue
			var property := _property_definition(String(property_id))
			var property_name := LocaleManager.t(String(property.get("key", "HUB_PROPERTIES_TITLE"))).replace("{0}", str(_properties.get(String(property_id), 0)))
			return LocaleManager.t("HUB_ITEM_LOCATION").replace("{place}", property_name).replace("{n}", str(slot_index + 1))
	return LocaleManager.t("HUB_ITEM_UNPLACED")

func _open_property_portfolio() -> void:
	_open_properties("")

func _open_event_board() -> void:
	_open_popup(LocaleManager.t("HUB_EVENT_BOARD"), func(body: VBoxContainer):
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_EVENT_BODY").replace("{n}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today))), 13, UIFactory.COL_MUTED))
		for district in DISTRICTS:
			var route_id := String(district.route)
			var route := Routes.get_by_id(route_id)
			var contract := RouteContractsData.current(route_id)
			var title := LocaleManager.t(String(route.get("name_key", route_id)))
			if contract.is_empty() or not RouteContractsData.is_available(route_id):
				body.add_child(UIFactory.make_label(title + "  •  " + LocaleManager.t("HUB_EVENT_LOCKED"), 12, UIFactory.COL_MUTED))
				continue
			var done := RouteContractsData.is_completed_today(route_id)
			var line := UIFactory.make_label(title + "  •  " + RouteContractsData.describe(contract) + "  •  +%d" % int(contract.get("reward", 0)) + ("  ✓" if done else ""), 13, UIFactory.COL_TEXT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(line)
			if not done and Routes.is_unlocked(route):
				var start := UIFactory.make_button(LocaleManager.t("HUB_EVENT_START").replace("{route}", title), false)
				start.pressed.connect(func(id: String = route_id):
					GameState.set_route(id)
					TransitionManager.go_to("res://scenes/game.tscn"))
				body.add_child(start)
	)

func _open_home() -> void:
	_open_popup(LocaleManager.t("HUB_HOME_TITLE"), func(body: VBoxContainer):
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_HOME_BODY"), 13, UIFactory.COL_MUTED))
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_RUN_HISTORY").replace("{runs}", str(SaveSystem.get_value("total_runs", 0))).replace("{best}", str(SaveSystem.get_value("best_score", 0))).replace("{distance}", str(int(SaveSystem.get_value("total_distance_ever", 0)))), 14, UIFactory.COL_TEXT))
		for item in DECOR:
			if not bool(item.get("avatar", false)) or String(item.id) not in _owned_decor:
				continue
			var wear := UIFactory.make_button(LocaleManager.t(String(item.key)) + ("  ✓" if _avatar_item == String(item.id) else ""), false)
			wear.pressed.connect(func(id: String = String(item.id)): _equip_avatar_item(id, _current_district_id))
			body.add_child(wear)
	)

func _open_workshop() -> void:
	_open_popup(LocaleManager.t("HUB_PROPERTY_WORKSHOP").replace("{0}", str(int(_properties.get("workshop", 0)))), func(body: VBoxContainer):
		var vehicle := Vehicles.get_by_id(GameState.selected_vehicle_id)
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_WORKSHOP_BODY").replace("{vehicle}", LocaleManager.t(String(vehicle.get("name_key", vehicle.get("id", ""))))).replace("{perk}", "3" if int(_properties.get("workshop", 0)) >= 2 else "0"), 14, UIFactory.COL_TEXT))
		var parts := UIFactory.make_button(LocaleManager.t("HUB_JOB_PARTS"), true)
		parts.disabled = _jobs_claimed_today >= MAX_PAID_JOBS_PER_DAY or int(_properties.get("workshop", 0)) <= 0
		parts.pressed.connect(func(): _start_job("parts_run"))
		body.add_child(parts)
	)

func _open_global_chat() -> void:
	if _current_district_id != "kariakoo":
		var dialog := ConfirmationDialog.new()
		dialog.title = LocaleManager.t("HUB_GLOBAL_CHAT")
		dialog.dialog_text = LocaleManager.t("HUB_GLOBAL_TRAVEL")
		dialog.ok_button_text = LocaleManager.t("HUB_RIDE_FREE")
		dialog.confirmed.connect(func():
			_travel_to_district("kariakoo")
			_open_friends_plaza()
			dialog.queue_free())
		dialog.canceled.connect(func(): dialog.queue_free())
		add_child(dialog)
		dialog.popup_centered()
		return
	_open_friends_plaza()

func _open_bus_display() -> void:
	_open_popup(LocaleManager.t("HUB_BUS_DISPLAY"), func(body: VBoxContainer):
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_BUS_DISPLAY_BODY"), 13, UIFactory.COL_MUTED))
		for vehicle_id in SaveSystem.get_value("unlocked_vehicles", []):
			var vehicle := Vehicles.get_by_id(String(vehicle_id))
			var select := UIFactory.make_button(LocaleManager.t(String(vehicle.get("name_key", vehicle_id))) + ("  ✓" if String(SaveSystem.get_value("hub_display_vehicle", "")) == String(vehicle_id) else ""), false)
			select.pressed.connect(func(id: String = String(vehicle_id)):
				SaveSystem.set_value("hub_display_vehicle", id)
				queue_redraw()
				_open_bus_display())
			body.add_child(select)
	)

func _district_for_spot(spot: Dictionary) -> String:
	if spot.is_empty():
		return ""
	return _district_at(Vector2(spot.get("position", Vector2.ZERO)))

func _district_definition(district_id: String) -> Dictionary:
	for district in DISTRICTS:
		if String(district.id) == district_id:
			return district
	return {}

func _district_at(position: Vector2) -> String:
	var column := clampi(int(floor(position.x / AREA_SIZE.x)), 0, 2)
	var row := clampi(int(floor(position.y / AREA_SIZE.y)), 0, 1)
	return String(DISTRICTS[row * 3 + column].id)

func _area_key(district_id: String) -> String:
	return String(_district_definition(district_id).get("key", "HUB_AREA_KARIAKOO"))

func _market_sign_key(district_id: String) -> String:
	return {"mwenge": "HUB_SHOP_MWENGE", "mbezi": "HUB_SHOP_MBEZI", "posta": "HUB_SHOP_POSTA", "kigamboni": "HUB_SHOP_KIGAMBONI", "ubungo": "HUB_SHOP_UBUNGO"}.get(district_id, "HUB_SHOP_TITLE")

func _draw_district_wayfinding(district_id: String) -> void:
	var index := 0
	for district in DISTRICTS:
		if String(district.id) == district_id:
			break
		index += 1
	var col := index % 3
	var row := int(index / 3)
	var neighbors: Array[Vector2i] = [Vector2i(col + 1, row), Vector2i(col - 1, row), Vector2i(col, row + 1), Vector2i(col, row - 1)]
	for neighbor in neighbors:
		if neighbor.x < 0 or neighbor.x > 2 or neighbor.y < 0 or neighbor.y > 1:
			continue
		var neighbor_id := String(DISTRICTS[neighbor.y * 3 + neighbor.x].id)
		var sign_position := Vector2(270, 940) if neighbor.y > row else (Vector2(270, 20) if neighbor.y < row else (Vector2(480, 476) if neighbor.x > col else Vector2(60, 476)))
		var direction := "↓" if neighbor.y > row else ("↑" if neighbor.y < row else ("→" if neighbor.x > col else "←"))
		draw_rect(Rect2(sign_position - Vector2(60, 19), Vector2(120, 30)), Color("#253a3d"), true)
		draw_string(ThemeDB.fallback_font, sign_position - Vector2(56, 0), direction + " " + LocaleManager.t(_area_key(neighbor_id)), HORIZONTAL_ALIGNMENT_CENTER, 112, 10, Color("#fff0be"))

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

func _refresh_labels() -> void:
	if not is_instance_valid(_action_button):
		return
	_coin_label.text = "🪙 %d" % int(SaveSystem.get_value("total_coins", 0))
	_subtitle_label.text = LocaleManager.t("HUB_MAP_CURRENT") + " • " + LocaleManager.t(_area_key(_current_district_id))
	if not _toast_text.is_empty():
		_status_label.text = _toast_text
	elif _nearby_id.is_empty():
		_status_label.text = LocaleManager.t("HUB_SUBTITLE")
	else:
		var spot := _spot(_nearby_id)
		_status_label.text = LocaleManager.t(String(spot.get("key", "HUB_SUBTITLE")))
	if _active_job_id != "":
		var job := _job(_active_job_id)
		_objective_label.text = LocaleManager.t(String(job.get("key", "HUB_JOB_ACTIVE"))) + "  •  " + (LocaleManager.t("HUB_JOB_GO_TO_FINISH") if _active_job_step == 1 else LocaleManager.t("HUB_JOB_GO_TO_START"))
	elif not _intro_complete:
		_objective_label.text = LocaleManager.t("HUB_GUIDE_FIRST")
	elif _errand_completed:
		_objective_label.text = LocaleManager.t("HUB_DAILY_DONE")
	elif _errand_started:
		var next_spot := _spot(_next_errand_stop())
		_objective_label.text = LocaleManager.t("HUB_DAILY_NEXT").replace("{n}", str(_errand_progress.size())).replace("{spot}", LocaleManager.t(String(next_spot.get("key", "HUB_FIND_MARKET"))))
	else:
		_objective_label.text = LocaleManager.t("HUB_DAILY_START")
	_action_button.text = LocaleManager.t("HUB_ACTION") if _nearby_id.is_empty() else _interaction_label(_nearby_id)
	_action_button.disabled = _nearby_id.is_empty()

func _spot(id: String) -> Dictionary:
	for spot in SPOTS:
		if String(spot.id) == id:
			return spot
	return {}

func _interact() -> void:
	if _nearby_id.is_empty():
		return
	var property_id := _property_from_spot(_nearby_id)
	if not property_id.is_empty():
		_open_property_interaction(property_id)
		return
	if _active_job_id != "":
		_interact_with_job(_nearby_id)
		return
	if not _intro_complete and _nearby_id == "stop":
		_start_errand()
		return
	if _errand_started and not _errand_completed and _nearby_id in ERRAND_STOPS:
		_check_in_errand(_nearby_id)
	match _nearby_id:
		"stop": _open_jobs(_nearby_id)
		"market", "mwenge_market", "mbezi_market", "posta_market", "kigamboni_market", "ubungo_market": _open_market(_current_district_id)
		"garage": TransitionManager.go_to("res://scenes/garage.tscn")
		"plaza": _open_friends_plaza()
		"route_board": _open_route_board()
		"property_board": _open_properties()
		"mwenge_properties", "mbezi_properties", "posta_properties", "kigamboni_properties", "ubungo_properties": _open_properties(_current_district_id)
		"boda_yard", "fuel_depot", "posta_office", "ferry", "terminal": _open_jobs(_nearby_id)

func _interaction_label(spot_id: String) -> String:
	if _active_job_id != "":
		var job := _job(_active_job_id)
		return LocaleManager.t("HUB_JOB_CHECK_IN") if spot_id == (String(job.finish) if _active_job_step == 1 else String(job.start)) else LocaleManager.t("HUB_ACTION")
	if _errand_started and not _errand_completed and spot_id in ERRAND_STOPS and spot_id not in _errand_progress:
		return LocaleManager.t("HUB_CHECK_IN")
	if not _intro_complete and spot_id == "stop":
		return LocaleManager.t("HUB_GUIDE_START")
	return LocaleManager.t({"market": "HUB_SHOP_TITLE", "mwenge_market": "HUB_SHOP_MWENGE", "mbezi_market": "HUB_SHOP_MBEZI", "posta_market": "HUB_SHOP_POSTA", "kigamboni_market": "HUB_SHOP_KIGAMBONI", "ubungo_market": "HUB_SHOP_UBUNGO", "boda_yard": "HUB_ACTIVITY_MWENGE", "fuel_depot": "HUB_ACTIVITY_MBEZI", "posta_office": "HUB_ACTIVITY_POSTA", "ferry": "HUB_ACTIVITY_KIGAMBONI", "terminal": "HUB_ACTIVITY_UBUNGO", "garage": "HUB_FIND_GARAGE", "plaza": "HUB_FIND_PLAZA", "route_board": "HUB_FIND_ROUTE_BOARD", "property_board": "HUB_FIND_PROPERTIES", "mwenge_properties": "HUB_PROPERTY_MWENGE", "mbezi_properties": "HUB_PROPERTY_MBEZI", "posta_properties": "HUB_PROPERTY_POSTA", "kigamboni_properties": "HUB_PROPERTY_KIGAMBONI", "ubungo_properties": "HUB_PROPERTY_UBUNGO", "kiosk_plot": "HUB_PROPERTY_KIOSK", "home_plot": "HUB_PROPERTY_HOME", "workshop_plot": "HUB_PROPERTY_WORKSHOP", "guest_house_plot": "HUB_PROPERTY_GUEST", "mwenge_home_plot": "HUB_PROPERTY_MWENGE", "mbezi_yard_plot": "HUB_PROPERTY_MBEZI", "posta_flat_plot": "HUB_PROPERTY_POSTA", "kigamboni_cottage_plot": "HUB_PROPERTY_KIGAMBONI", "ubungo_rooms_plot": "HUB_PROPERTY_UBUNGO"}.get(spot_id, "HUB_ACTION"))

func _property_from_spot(spot_id: String) -> String:
	return {"kiosk_plot": "kiosk", "home_plot": "home", "workshop_plot": "workshop", "guest_house_plot": "guest_house",
		"mwenge_home_plot": "mwenge_home", "mbezi_yard_plot": "mbezi_yard", "posta_flat_plot": "posta_flat",
		"kigamboni_cottage_plot": "kigamboni_cottage", "ubungo_rooms_plot": "ubungo_rooms"}.get(spot_id, "")

func _open_property_interaction(property_id: String) -> void:
	if int(_properties.get(property_id, 0)) <= 0:
		_open_properties(String(_property_definition(property_id).get("district", _current_district_id)))
		return
	match property_id:
		"home", "guest_house", "mwenge_home", "kigamboni_cottage", "ubungo_rooms": _open_home()
		"workshop": _open_workshop()
		"kiosk": _open_market("kariakoo")
		"posta_flat": _open_market("posta")
		_:
			_open_popup(LocaleManager.t(String(_property_definition(property_id).get("key", "HUB_PROPERTIES_TITLE"))), func(body: VBoxContainer):
				body.add_child(UIFactory.make_label(LocaleManager.t("HUB_PROPERTY_VISIT_BODY"), 13, UIFactory.COL_MUTED))
				var rent := UIFactory.make_button(LocaleManager.t("HUB_RENT_COLLECT").replace("{n}", str(_daily_rent())), true)
				rent.disabled = _daily_rent() <= 0 or _rent_claimed_date == Time.get_date_string_from_system()
				rent.pressed.connect(func(): _collect_rent(_current_district_id))
				body.add_child(rent)
			)

func _check_in_errand(stop: String) -> void:
	if stop in _errand_progress:
		return
	_errand_progress.append(stop)
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_daily_progress", _errand_progress)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_errand_progress.erase(stop)
		SaveSystem.data["hub_daily_progress"] = _errand_progress
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	if _errand_progress.size() >= ERRAND_STOPS.size():
		_finish_errand()
	else:
		var next_spot := _spot(_next_errand_stop())
		_show_toast(LocaleManager.t("HUB_DAILY_NEXT").replace("{n}", str(_errand_progress.size())).replace("{spot}", LocaleManager.t(String(next_spot.get("key", "HUB_FIND_MARKET")))))
	queue_redraw()

func _start_errand() -> void:
	if _errand_completed:
		_show_toast(LocaleManager.t("HUB_DAILY_DONE"))
		return
	_errand_started = true
	_intro_complete = true
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_daily_started_date", Time.get_date_string_from_system())
	SaveSystem.set_value("hub_intro_complete", true)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_errand_started = false
		_intro_complete = false
		SaveSystem.data["hub_daily_started_date"] = ""
		SaveSystem.data["hub_intro_complete"] = false
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	var next_spot := _spot(_next_errand_stop())
	_show_toast(LocaleManager.t("HUB_DAILY_NEXT").replace("{n}", str(_errand_progress.size())).replace("{spot}", LocaleManager.t(String(next_spot.get("key", "HUB_FIND_MARKET")))))
	AudioManager.play_hub_bark("voice_kituo")

func _next_errand_stop() -> String:
	for stop in ERRAND_STOPS:
		if stop not in _errand_progress:
			return stop
	return "plaza"

func _finish_errand() -> void:
	var wallet_before := int(SaveSystem.get_value("total_coins", 0))
	_errand_started = false
	_errand_completed = true
	var today := Time.get_date_string_from_system()
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_daily_completed_date", today)
	SaveSystem.set_value("hub_daily_started_date", "")
	SaveSystem.set_value("hub_daily_progress", [])
	SaveSystem.add_coins(ERRAND_REWARD)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_errand_started = true
		_errand_completed = false
		SaveSystem.data["total_coins"] = wallet_before
		SaveSystem.data["hub_daily_completed_date"] = ""
		SaveSystem.data["hub_daily_started_date"] = today
		SaveSystem.data["hub_daily_progress"] = _errand_progress
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	_show_toast(LocaleManager.t("HUB_DAILY_REWARD").replace("{n}", str(ERRAND_REWARD)))
	AnalyticsService.log_event("hub_errand_completed", {"district": "kariakoo"})

func _open_market(district_id: String = "kariakoo", selected_id: String = "", owned_only: bool = false) -> void:
	var inventory: Array[Dictionary] = []
	for entry in DECOR:
		var item_id := String(entry.id)
		if owned_only:
			if item_id in _owned_decor:
				inventory.append(entry)
		elif String(entry.get("district", "kariakoo")) == district_id:
			var property_id := String(entry.get("property", ""))
			var bond_id := String(entry.get("bond", ""))
			var property_ready := property_id.is_empty() or int(_properties.get(property_id, 0)) >= int(entry.get("level", 1))
			var bond_ready := bond_id.is_empty() or int(_npc_bonds.get(bond_id, 0)) >= int(entry.get("level", 1))
			if property_ready and bond_ready:
				inventory.append(entry)
	if selected_id.is_empty() and not inventory.is_empty():
		selected_id = String(inventory[0].id)
	var selected := _decor_definition(selected_id)
	_open_popup(LocaleManager.t(_market_sign_key(district_id)), func(body: VBoxContainer):
		var owned_toggle := CheckButton.new()
		owned_toggle.text = LocaleManager.t("HUB_MARKET_OWNED")
		owned_toggle.button_pressed = owned_only
		owned_toggle.toggled.connect(func(value: bool): _open_market(district_id, "", value))
		body.add_child(owned_toggle)
		if selected.is_empty():
			body.add_child(UIFactory.make_label(LocaleManager.t("HUB_MARKET_EMPTY"), 14, UIFactory.COL_MUTED))
			return
		var preview := PanelContainer.new()
		var preview_box := VBoxContainer.new()
		preview.add_child(preview_box)
		var icon := UIFactory.make_label(String(selected.get("icon", "◆")), 34, Color("#e4b549"))
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_box.add_child(icon)
		var selected_base_price := int(selected.get("price", 0))
		var preview_name := UIFactory.make_label(LocaleManager.t(String(selected.key)).replace("{n}", str(selected_base_price)), 16, UIFactory.COL_TEXT)
		preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_box.add_child(preview_name)
		body.add_child(preview)
		var selected_item_id := String(selected.id)
		var owned := selected_item_id in _owned_decor
		if bool(selected.get("phone", false)) and owned:
			var open_phone := UIFactory.make_button(LocaleManager.t("HUB_PHONE_OPEN"), true)
			open_phone.pressed.connect(_open_phone)
			body.add_child(open_phone)
		elif bool(selected.get("avatar", false)) and owned:
			var equip := UIFactory.make_button(LocaleManager.t("HUB_EQUIP" if _avatar_item != selected_item_id else "HUB_WORN"), true)
			equip.custom_minimum_size = Vector2(0, 48)
			equip.disabled = _avatar_item == selected_item_id
			equip.pressed.connect(func(): _equip_avatar_item(selected_item_id, district_id))
			body.add_child(equip)
		elif _is_placeable_item(selected_item_id) and owned:
			var location := UIFactory.make_label(_placement_location_text(selected_item_id), 12, UIFactory.COL_MUTED)
			location.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(location)
			var place := UIFactory.make_button(LocaleManager.t("HUB_PLACE_ITEM"), true)
			place.custom_minimum_size = Vector2(0, 48)
			place.pressed.connect(func(): _open_placement_properties(selected_item_id, false))
			body.add_child(place)
		elif not owned:
			var discount := _shop_discount(district_id)
			var price := maxi(1, int(selected.price) * (100 - discount) / 100)
			var buy := UIFactory.make_button(LocaleManager.t("HUB_BUY_FOR").replace("{n}", str(price)) + "  •  " + LocaleManager.t("HUB_COINS_LEFT").replace("{n}", str(maxi(0, int(SaveSystem.get_value("total_coins", 0)) - price))), true)
			buy.custom_minimum_size = Vector2(0, 50)
			buy.disabled = int(SaveSystem.get_value("total_coins", 0)) < price
			if _is_placeable_item(selected_item_id):
				buy.text = LocaleManager.t("HUB_BUY_AND_PLACE").replace("{n}", str(price))
				buy.pressed.connect(func(item_id: String = selected_item_id, area: String = district_id): _open_placement_properties(item_id, true, area))
			else:
				buy.pressed.connect(func(item_id: String = selected_item_id, item_price: int = price, area: String = district_id): _buy_decor(item_id, item_price, area))
			body.add_child(buy)
		else:
			body.add_child(UIFactory.make_label(LocaleManager.t("HUB_OWNED"), 14, Color("#178c78")))
		var list_title := UIFactory.make_label(LocaleManager.t("HUB_MARKET_LIST"), 12, UIFactory.COL_MUTED)
		body.add_child(list_title)
		for entry in inventory:
			var item_id := String(entry.id)
			var item_price := maxi(1, int(entry.price) * (100 - _shop_discount(String(entry.get("district", district_id)))) / 100)
			var item_label := LocaleManager.t(String(entry.key)).replace("{n}", str(item_price))
			if owned_only:
				item_label = LocaleManager.t(_area_key(String(entry.get("district", "kariakoo")))) + " • " + item_label
			var choose := UIFactory.make_button(item_label + ("  •  " + LocaleManager.t("HUB_OWNED") if item_id in _owned_decor else ""), false)
			if item_id in _owned_decor:
				choose.text += "\n" + _placement_location_text(item_id)
			choose.custom_minimum_size = Vector2(0, 44)
			choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choose.pressed.connect(func(id: String = item_id, area: String = district_id, owned_view: bool = owned_only): _open_market(area, id, owned_view))
			body.add_child(choose)
	)

func _decor_definition(decor_id: String) -> Dictionary:
	for item in DECOR:
		if String(item.id) == decor_id:
			return item
	return {}

func _is_placeable_item(decor_id: String) -> bool:
	var item := _decor_definition(decor_id)
	return not item.is_empty() and not bool(item.get("avatar", false)) and not bool(item.get("phone", false)) and String(item.get("bond", "")).is_empty()

func _open_placement_properties(decor_id: String, purchase: bool, shop_district: String = "kariakoo") -> void:
	if _decor_definition(decor_id).is_empty() or (not purchase and decor_id not in _owned_decor):
		return
	_open_popup(LocaleManager.t("HUB_PLACE_TITLE"), func(body: VBoxContainer):
		var item := _decor_definition(decor_id)
		var price := maxi(1, int(item.get("price", 0)) * (100 - _shop_discount(shop_district)) / 100) if purchase else 0
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_PLACE_PREVIEW").replace("{item}", LocaleManager.t(String(item.key))).replace("{cost}", str(price)), 13, UIFactory.COL_MUTED))
		var found_plot := false
		for property in PROPERTIES:
			var property_id := String(property.id)
			var level := int(_properties.get(property_id, 0))
			if level <= 0:
				continue
			found_plot = true
			var slots: Array = _placements.get(property_id, ["", "", ""])
			var occupied := 0
			for item_id in slots:
				if not String(item_id).is_empty(): occupied += 1
			var choose := UIFactory.make_button(LocaleManager.t(String(property.key)).replace("{0}", str(level)) + "  •  %d/3" % occupied, false)
			choose.custom_minimum_size = Vector2(0, 46)
			choose.pressed.connect(func(plot: String = property_id): _open_placement_slots(decor_id, plot, purchase, shop_district))
			body.add_child(choose)
		if not found_plot:
			body.add_child(UIFactory.make_label(LocaleManager.t("HUB_PLACE_NEED_PLOT"), 13, UIFactory.COL_MUTED))
	)

func _open_placement_slots(decor_id: String, property_id: String, purchase: bool, shop_district: String) -> void:
	_open_popup(LocaleManager.t("HUB_PLACE_TITLE"), func(body: VBoxContainer):
		var slots: Array = _placements.get(property_id, ["", "", ""])
		for slot in range(3):
			var occupant := String(slots[slot]) if slot < slots.size() else ""
			var label := LocaleManager.t("HUB_PLACE_SLOT").replace("{n}", str(slot + 1))
			label += "  •  " + (LocaleManager.t(String(_decor_definition(occupant).key)) if not occupant.is_empty() else LocaleManager.t("HUB_PLACE_EMPTY"))
			var pick := UIFactory.make_button(label, occupant.is_empty() or occupant == decor_id)
			pick.custom_minimum_size = Vector2(0, 48)
			pick.pressed.connect(func(index: int = slot): _confirm_placement(decor_id, property_id, index, purchase, shop_district))
			body.add_child(pick)
	)

func _confirm_placement(decor_id: String, property_id: String, slot: int, purchase: bool, shop_district: String) -> void:
	var item := _decor_definition(decor_id)
	var property := _property_definition(property_id)
	if item.is_empty() or property.is_empty() or int(_properties.get(property_id, 0)) <= 0 or slot < 0 or slot >= 3:
		return
	var price := maxi(1, int(item.get("price", 0)) * (100 - _shop_discount(shop_district)) / 100) if purchase else 0
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("HUB_PLACE_CONFIRM_TITLE")
	dialog.dialog_text = LocaleManager.t("HUB_PLACE_CONFIRM_BODY").replace("{item}", LocaleManager.t(String(item.key))).replace("{plot}", LocaleManager.t(String(property.key)).replace("{0}", str(_properties.get(property_id, 0)))).replace("{slot}", str(slot + 1)).replace("{cost}", str(price))
	dialog.ok_button_text = LocaleManager.t("HUB_CONFIRM")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	dialog.confirmed.connect(func():
		_commit_placement(decor_id, property_id, slot, price, purchase)
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(mini(420, int(get_viewport_rect().size.x) - 24), 0))

func _commit_placement(decor_id: String, property_id: String, slot: int, price: int, purchase: bool) -> void:
	if slot < 0 or slot >= 3 or int(_properties.get(property_id, 0)) <= 0:
		return
	if purchase and decor_id in _owned_decor:
		return
	if not purchase and decor_id not in _owned_decor:
		return
	var old_wallet := int(SaveSystem.get_value("total_coins", 0))
	var old_owned := _owned_decor.duplicate()
	var old_placements := _placements.duplicate(true)
	var slots: Array = _placements.get(property_id, ["", "", ""])
	while slots.size() < 3: slots.append("")
	for plot_id in _placements:
		var other_slots: Array = _placements[plot_id]
		for index in range(other_slots.size()):
			if String(other_slots[index]) == decor_id: other_slots[index] = ""
	slots[slot] = decor_id
	_placements[property_id] = slots
	SaveSystem.begin_batch()
	if purchase and not SaveSystem.spend_coins(price):
		SaveSystem.end_batch()
		_placements = old_placements
		_show_toast(LocaleManager.t("HUB_NO_COINS"))
		return
	if purchase:
		_owned_decor.append(decor_id)
		SaveSystem.set_value("hub_owned_decor", _owned_decor)
	SaveSystem.set_value("hub_decor_placements", _placements)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_owned_decor = old_owned
		_placements = old_placements
		SaveSystem.data["total_coins"] = old_wallet
		SaveSystem.data["hub_owned_decor"] = _owned_decor
		SaveSystem.data["hub_decor_placements"] = _placements
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	queue_redraw()
	_show_toast(LocaleManager.t("HUB_PLACED"))
	_open_market(String(_decor_definition(decor_id).get("district", _current_district_id)), decor_id)

func _shop_discount(district_id: String) -> int:
	if district_id == "kariakoo" and int(_properties.get("kiosk", 0)) >= 2:
		return 10
	if district_id == "mbezi" and int(_properties.get("mbezi_yard", 0)) >= 2:
		return 10
	return 0

func _equip_avatar_item(decor_id: String, district_id: String) -> void:
	if decor_id not in _owned_decor or not bool(_decor_definition(decor_id).get("avatar", false)):
		return
	_avatar_item = decor_id
	SaveSystem.set_value("hub_avatar_item", decor_id)
	if SaveSystem.last_save_error != OK:
		_avatar_item = String(SaveSystem.data.get("hub_avatar_item", ""))
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	queue_redraw()
	_show_toast(LocaleManager.t("HUB_EQUIPPED"))
	_open_market(district_id, decor_id, true)

func _buy_decor(decor_id: String, _price: int, district_id: String = "kariakoo") -> void:
	var definition := _decor_definition(decor_id)
	if definition.is_empty() or decor_id in _owned_decor or String(definition.get("district", "kariakoo")) != district_id:
		return
	var property_id := String(definition.get("property", ""))
	if not property_id.is_empty() and int(_properties.get(property_id, 0)) < int(definition.get("level", 1)):
		return
	var final_price := maxi(1, int(definition.price) * (100 - _shop_discount(district_id)) / 100)
	var wallet_before := int(SaveSystem.get_value("total_coins", 0))
	var previous_avatar_item := _avatar_item
	SaveSystem.begin_batch()
	if not SaveSystem.spend_coins(final_price):
		SaveSystem.end_batch()
		_show_toast(LocaleManager.t("HUB_NO_COINS"))
		return
	_owned_decor.append(decor_id)
	SaveSystem.set_value("hub_owned_decor", _owned_decor)
	if bool(definition.get("avatar", false)):
		_avatar_item = decor_id
		SaveSystem.set_value("hub_avatar_item", decor_id)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_avatar_item = previous_avatar_item
		_owned_decor.erase(decor_id)
		SaveSystem.data["total_coins"] = wallet_before
		SaveSystem.data["hub_owned_decor"] = _owned_decor
		SaveSystem.data["hub_avatar_item"] = previous_avatar_item
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	AudioManager.play_sfx("coin")
	_show_toast(LocaleManager.t("HUB_DECOR_BOUGHT"))
	queue_redraw()
	_open_market(district_id, decor_id)

func _open_properties(district_id: String = "kariakoo") -> void:
	_open_popup(LocaleManager.t("HUB_PROPERTIES_TITLE"), func(body: VBoxContainer):
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_PERSONAL_PREVIEW"), 12, UIFactory.COL_MUTED))
		for property in PROPERTIES:
			if not district_id.is_empty() and String(property.get("district", "kariakoo")) != district_id:
				continue
			var id := String(property.id)
			var level := int(_properties.get(id, 0))
			var max_level := int(property.get("max_level", 2))
			var cost := int(property.price) if level == 0 else int(property.upgrade_price)
			var item := UIFactory.make_label(LocaleManager.t(String(property.key)).replace("{0}", str(level)), 14, UIFactory.COL_TEXT)
			if bool(property.get("rental", false)):
				item.text += "  •  " + LocaleManager.t("HUB_RENTING_PROPERTY")
			if not String(property.get("perk", "")).is_empty():
				item.text += "\n" + LocaleManager.t(String(property.perk))
			item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(item)
			var buy := UIFactory.make_button(LocaleManager.t("HUB_PROPERTY_BUY").replace("{n}", str(cost)) if level == 0 else LocaleManager.t("HUB_PROPERTY_UPGRADE").replace("{n}", str(cost)), false)
			buy.text += "  •  " + LocaleManager.t("HUB_COINS_LEFT").replace("{n}", str(maxi(0, int(SaveSystem.get_value("total_coins", 0)) - cost)))
			buy.custom_minimum_size = Vector2(0, 48)
			buy.disabled = level >= max_level
			buy.pressed.connect(func(property_id: String = id, price: int = cost, area: String = district_id): _buy_property(property_id, price, area))
			body.add_child(buy)
			if level > 0:
				var visit := UIFactory.make_button(LocaleManager.t("HUB_PROPERTY_VISIT"), true)
				visit.custom_minimum_size = Vector2(0, 42)
				visit.pressed.connect(func(property_id: String = id): _open_property_interaction(property_id))
				body.add_child(visit)
		var rent := _daily_rent()
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_RENT_INFO").replace("{n}", str(rent)), 12, UIFactory.COL_MUTED))
		var collect := UIFactory.make_button(LocaleManager.t("HUB_RENT_COLLECT").replace("{n}", str(rent)), true)
		collect.custom_minimum_size = Vector2(0, 50)
		collect.disabled = rent <= 0 or _rent_claimed_date == Time.get_date_string_from_system()
		collect.pressed.connect(func(area: String = district_id): _collect_rent(area))
		body.add_child(collect)
	)

func _buy_property(property_id: String, price: int, district_id: String = "kariakoo") -> void:
	var definition := _property_definition(property_id)
	if definition.is_empty():
		return
	var level := int(_properties.get(property_id, 0))
	if level >= int(definition.get("max_level", 2)):
		return
	var wallet_before := int(SaveSystem.get_value("total_coins", 0))
	var previous := _properties.duplicate(true)
	SaveSystem.begin_batch()
	if not SaveSystem.spend_coins(price):
		SaveSystem.end_batch()
		_show_toast(LocaleManager.t("HUB_NO_COINS"))
		return
	_properties[property_id] = level + 1
	SaveSystem.set_value("hub_properties", _properties)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_properties = previous
		SaveSystem.data["total_coins"] = wallet_before
		SaveSystem.data["hub_properties"] = _properties
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	AudioManager.play_sfx("coin")
	AnalyticsService.log_event("hub_property_bought", {"property": property_id, "level": level + 1})
	_refresh_labels()
	queue_redraw()
	_open_properties(district_id)

func _property_definition(property_id: String) -> Dictionary:
	for property in PROPERTIES:
		if String(property.id) == property_id:
			return property
	return {}

func _daily_rent() -> int:
	var rent := 0
	for property in PROPERTIES:
		if bool(property.get("rental", false)):
			rent += int(_properties.get(String(property.id), 0)) * int(property.get("rent_per_level", 0))
	return mini(40, rent)

func _collect_rent(district_id: String = "kariakoo") -> void:
	var today := Time.get_date_string_from_system()
	var reward := _daily_rent()
	if reward <= 0 or _rent_claimed_date == today:
		return
	var wallet_before := int(SaveSystem.get_value("total_coins", 0))
	var date_before := _rent_claimed_date
	_rent_claimed_date = today
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_rent_claimed_date", today)
	SaveSystem.add_coins(reward)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_rent_claimed_date = date_before
		SaveSystem.data["hub_rent_claimed_date"] = _rent_claimed_date
		SaveSystem.data["total_coins"] = wallet_before
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	AudioManager.play_sfx("coin")
	AnalyticsService.log_event("hub_rent_collected", {"coins": reward})
	_show_toast(LocaleManager.t("HUB_RENT_PAID").replace("{n}", str(reward)))
	_refresh_labels()
	_open_properties(district_id)

func _open_route_board() -> void:
	var route_id := String(GameState.selected_route_id)
	var route: Dictionary = Routes.get_by_id(route_id)
	_open_popup(LocaleManager.t("HUB_ROUTE_BOARD"), func(body: VBoxContainer):
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_ROUTE_CURRENT").replace("{route}", LocaleManager.t(String(route.get("name_key", route_id)))), 16, UIFactory.COL_TEXT))
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_ROUTE_BOARD_BODY"), 13, UIFactory.COL_MUTED))
		var play := UIFactory.make_button(LocaleManager.t("PLAY"), true)
		play.custom_minimum_size = Vector2(0, 54)
		play.pressed.connect(func(): TransitionManager.go_to("res://scenes/game.tscn"))
		body.add_child(play)
		var routes := UIFactory.make_button(LocaleManager.t("ROUTES"), false)
		routes.custom_minimum_size = Vector2(0, 48)
		routes.pressed.connect(func(): TransitionManager.go_to("res://scenes/routes.tscn"))
		body.add_child(routes)
		var jobs := UIFactory.make_button(LocaleManager.t("HUB_JOBS_TITLE"), false)
		jobs.custom_minimum_size = Vector2(0, 48)
		jobs.pressed.connect(_open_jobs)
		body.add_child(jobs)
	)

func _open_jobs(focus_spot: String = "") -> void:
	_open_popup(LocaleManager.t("HUB_JOBS_TITLE"), func(body: VBoxContainer):
		body.add_child(UIFactory.make_label(LocaleManager.t("HUB_JOBS_REMAINING").replace("{n}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today))), 13, UIFactory.COL_MUTED))
		var district_id := _district_for_job_spot(focus_spot)
		var activity: Dictionary = SaveSystem.get_value("hub_route_activity", {})
		if not activity.is_empty():
			var activity_route := String(activity.get("route", ""))
			var route_info := Routes.get_by_id(activity_route)
			body.add_child(UIFactory.make_label(LocaleManager.t("HUB_ROUTE_ACTIVITY_STATUS").replace("{route}", LocaleManager.t(String(route_info.get("name_key", activity_route)))), 14, UIFactory.COL_PRIMARY))
			if String(activity.get("status", "")) == "success_pending":
				body.add_child(UIFactory.make_label(LocaleManager.t("HUB_ROUTE_ACTIVITY_PENDING").replace("{reward}", str(activity.get("reward", 25))).replace("{slots}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today))), 13, UIFactory.COL_MUTED))
			else:
				var contract := RouteContractsData.current(activity_route)
				var detail := LocaleManager.t("HUB_DRIVE_DETAIL").replace("{goal}", RouteContractsData.describe(contract)).replace("{reward}", str(activity.get("reward", 25))).replace("{slots}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today)))
				var detail_label := UIFactory.make_label(detail, 12, UIFactory.COL_MUTED)
				detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				body.add_child(detail_label)
			if String(activity.get("status", "")) == "active":
				var resume := UIFactory.make_button(LocaleManager.t("HUB_ROUTE_RESUME"), true)
				resume.custom_minimum_size = Vector2(0, 48)
				resume.pressed.connect(func(route: String = activity_route):
					GameState.set_route(route)
					TransitionManager.go_to("res://scenes/game.tscn")
				)
				body.add_child(resume)
				var cancel := UIFactory.make_button(LocaleManager.t("HUB_ROUTE_CANCEL"), false)
				cancel.pressed.connect(_cancel_route_activity)
				body.add_child(cancel)
			return
		if _active_job_id != "":
			var active_job := _job(_active_job_id)
			var target_spot := String(active_job.finish) if _active_job_step == 1 else String(active_job.start)
			var target := _spot(target_spot)
			var payout := int(active_job.reward) + (3 if _active_job_id == "parts_run" and int(_properties.get("workshop", 0)) >= 2 else 0)
			body.add_child(UIFactory.make_label(LocaleManager.t(String(active_job.key)), 16, UIFactory.COL_TEXT))
			var detail := LocaleManager.t("HUB_JOB_ACTIVE_DETAIL").replace("{action}", LocaleManager.t(String(target.get("key", "HUB_JOB_GO_TO_START")))).replace("{reward}", str(payout)).replace("{slots}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today)))
			var detail_label := UIFactory.make_label(detail, 12, UIFactory.COL_MUTED)
			detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(detail_label)
			return
		for entry in JOBS:
			if not focus_spot.is_empty() and String(entry.get("start", "")) != focus_spot:
				continue
			var property_id := String(entry.get("property", ""))
			if not property_id.is_empty() and int(_properties.get(property_id, 0)) < int(entry.get("level", 1)):
				continue
			var pickup := _spot(String(entry.get("start", "")))
			var delivery := _spot(String(entry.get("finish", "")))
			var detail := LocaleManager.t("HUB_JOB_DETAIL").replace("{start}", LocaleManager.t(String(pickup.get("key", "HUB_JOB_GO_TO_START")))).replace("{finish}", LocaleManager.t(String(delivery.get("key", "HUB_JOB_GO_TO_FINISH")))).replace("{reward}", str(entry.reward)).replace("{slots}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today)))
			var detail_label := UIFactory.make_label(detail, 12, UIFactory.COL_MUTED)
			detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(detail_label)
			var task := UIFactory.make_button(LocaleManager.t(String(entry.key)) + "  •  +%d" % int(entry.reward), false)
			task.custom_minimum_size = Vector2(0, 48)
			task.disabled = _jobs_claimed_today >= MAX_PAID_JOBS_PER_DAY
			task.pressed.connect(func(job_id: String = String(entry.id)): _start_job(job_id))
			body.add_child(task)
		if not district_id.is_empty():
			var district := _district_definition(district_id)
			var route_id := String(district.get("route", ""))
			var route := Routes.get_by_id(route_id)
			var drive_label := LocaleManager.t("HUB_DRIVE_CONTRACT").replace("{route}", LocaleManager.t(String(route.get("name_key", route_id)))).replace("{n}", "25")
			var route_contract := RouteContractsData.current(route_id)
			var route_preview := LocaleManager.t("HUB_DRIVE_DETAIL").replace("{goal}", RouteContractsData.describe(route_contract)).replace("{reward}", "25").replace("{slots}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today)))
			var route_preview_label := UIFactory.make_label(route_preview, 12, UIFactory.COL_MUTED)
			route_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(route_preview_label)
			var drive := UIFactory.make_button(drive_label, true)
			drive.custom_minimum_size = Vector2(0, 52)
			var route_locked := not Routes.is_unlocked(route)
			drive.disabled = route_locked or _jobs_claimed_today >= MAX_PAID_JOBS_PER_DAY or not _active_job_id.is_empty()
			if route_locked:
				drive.tooltip_text = LocaleManager.t("HUB_ROUTE_LOCKED")
			drive.pressed.connect(func(area: String = district_id): _start_route_activity(area))
			body.add_child(drive)
	)

func _district_for_job_spot(spot_id: String) -> String:
	for spot in SPOTS:
		if String(spot.id) == spot_id:
			return String(spot.get("district", "kariakoo"))
	return ""

func _start_route_activity(district_id: String) -> void:
	var district := _district_definition(district_id)
	if district.is_empty() or not Routes.is_unlocked(Routes.get_by_id(String(district.get("route", "")))) \
		or _jobs_claimed_today >= MAX_PAID_JOBS_PER_DAY or _active_job_id != "" \
		or not SaveSystem.get_value("hub_route_activity", {}).is_empty():
		return
	var activity := {"district": district_id, "route": String(district.route), "status": "active", "reward": 25}
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_route_activity", activity)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		SaveSystem.data["hub_route_activity"] = {}
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	GameState.set_route(String(district.route))
	AnalyticsService.log_event("hub_route_contract_started", {"district": district_id, "route": String(district.route)})
	TransitionManager.go_to("res://scenes/game.tscn")

func _cancel_route_activity() -> void:
	var activity: Dictionary = SaveSystem.get_value("hub_route_activity", {})
	if String(activity.get("status", "")) != "active":
		return
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_route_activity", {})
	SaveSystem.end_batch()
	_open_jobs(String(_spot_for_district(String(activity.district))))

func _spot_for_district(district_id: String) -> String:
	for spot in SPOTS:
		if String(spot.get("district", "kariakoo")) == district_id and String(spot.id) in ["boda_yard", "fuel_depot", "posta_office", "ferry", "terminal"]:
			return String(spot.id)
	return ""

func _settle_route_activity() -> bool:
	var activity: Dictionary = SaveSystem.get_value("hub_route_activity", {})
	if String(activity.get("status", "")) != "success_pending":
		return false
	if _jobs_claimed_today >= MAX_PAID_JOBS_PER_DAY:
		return false
	var reward := clampi(int(activity.get("reward", 25)), 1, 25)
	var wallet_before := int(SaveSystem.get_value("total_coins", 0))
	var previous_count := _jobs_claimed_today
	_jobs_claimed_today += 1
	SaveSystem.begin_batch()
	SaveSystem.add_coins(reward)
	SaveSystem.set_value("hub_jobs_claimed_date", Time.get_date_string_from_system())
	SaveSystem.set_value("hub_jobs_claimed_count", _jobs_claimed_today)
	SaveSystem.set_value("hub_route_activity", {})
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_jobs_claimed_today = previous_count
		SaveSystem.data["total_coins"] = wallet_before
		SaveSystem.data["hub_jobs_claimed_count"] = previous_count
		SaveSystem.data["hub_route_activity"] = activity
		return false
	AnalyticsService.log_event("hub_route_contract_completed", {"district": String(activity.get("district", "")), "route": String(activity.get("route", "")), "reward": reward})
	return true

func _start_job(job_id: String) -> void:
	if _jobs_claimed_today >= MAX_PAID_JOBS_PER_DAY or _active_job_id != "" or _job(job_id).is_empty():
		return
	_active_job_id = job_id
	_active_job_step = 0
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_active_job_id", job_id)
	SaveSystem.set_value("hub_active_job_step", 0)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_active_job_id = ""
		SaveSystem.data["hub_active_job_id"] = ""
		SaveSystem.data["hub_active_job_step"] = 0
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	_show_toast(LocaleManager.t("HUB_JOB_STARTED"))
	AudioManager.play_hub_bark("voice_twende")
	_open_jobs()

func _interact_with_job(spot_id: String) -> void:
	if _active_job_id.is_empty():
		return
	var job := _job(_active_job_id)
	var expected := String(job.finish) if _active_job_step == 1 else String(job.start)
	if spot_id != expected:
		return
	if _active_job_step == 0:
		_active_job_step = 1
		SaveSystem.begin_batch()
		SaveSystem.set_value("hub_active_job_step", 1)
		SaveSystem.end_batch()
		if SaveSystem.last_save_error != OK:
			_active_job_step = 0
			SaveSystem.data["hub_active_job_step"] = 0
			_show_toast(LocaleManager.t("SAVE_ERROR"))
			return
		_show_toast(LocaleManager.t("HUB_JOB_PICKED_UP"))
		return
	var wallet_before := int(SaveSystem.get_value("total_coins", 0))
	var job_id := _active_job_id
	var reward := int(job.reward)
	if job_id == "parts_run" and int(_properties.get("workshop", 0)) >= 2:
		reward += 3
	_jobs_claimed_today += 1
	_active_job_id = ""
	_active_job_step = 0
	SaveSystem.begin_batch()
	SaveSystem.set_value("hub_active_job_id", "")
	SaveSystem.set_value("hub_active_job_step", 0)
	SaveSystem.set_value("hub_jobs_claimed_date", Time.get_date_string_from_system())
	SaveSystem.set_value("hub_jobs_claimed_count", _jobs_claimed_today)
	SaveSystem.add_coins(reward)
	SaveSystem.end_batch()
	if SaveSystem.last_save_error != OK:
		_jobs_claimed_today -= 1
		_active_job_id = job_id
		_active_job_step = 1
		SaveSystem.data["total_coins"] = wallet_before
		SaveSystem.data["hub_active_job_id"] = job_id
		SaveSystem.data["hub_active_job_step"] = 1
		SaveSystem.data["hub_jobs_claimed_count"] = _jobs_claimed_today
		_show_toast(LocaleManager.t("SAVE_ERROR"))
		return
	AnalyticsService.log_event("hub_job_completed", {"job": job_id, "reward": reward})
	var reaction_key := "HUB_REACTION_JOB_" + _current_district_id.to_upper()
	var bond_npc := _npc_for_job(job_id)
	var relationship_before := int(_npc_bonds.get(bond_npc, 0)) if not bond_npc.is_empty() else 0
	var bond_reward := _record_activity_district(_district_at(_spot(String(job.finish)).get("position", _player_position)), bond_npc) if not bond_npc.is_empty() else false
	var job_message := LocaleManager.t("HUB_JOB_PAID_SLOTS").replace("{n}", str(reward)).replace("{left}", str(maxi(0, MAX_PAID_JOBS_PER_DAY - _jobs_claimed_today))) + "\n" + LocaleManager.t(reaction_key)
	var relationship_level := int(_npc_bonds.get(bond_npc, 0)) if not bond_npc.is_empty() else 0
	if relationship_level > relationship_before:
		job_message += "\n" + LocaleManager.t("HUB_NPC_REMEMBER").replace("{name}", LocaleManager.t("HUB_NPC_" + bond_npc.to_upper())).replace("{n}", str(relationship_level))
	if bond_reward:
		job_message += "\n" + LocaleManager.t("HUB_NPC_REWARD").replace("{name}", LocaleManager.t("HUB_NPC_" + bond_npc.to_upper()))
	_show_toast(job_message)
	AudioManager.play_hub_bark("voice_twende")
	queue_redraw()

func _job(job_id: String) -> Dictionary:
	for entry in JOBS:
		if String(entry.id) == job_id:
			return entry
	return {}

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
		var lounge_title := UIFactory.make_label(LocaleManager.t("HUB_LOUNGE_TITLE"), 17, UIFactory.COL_ACCENT)
		body.add_child(lounge_title)
		var lounge_copy := UIFactory.make_label(LocaleManager.t("HUB_CHAT_BODY"), 12, UIFactory.COL_MUTED)
		lounge_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(lounge_copy)
		if bool(SaveSystem.get_value("hub_presence_opt_in", false)):
			for phrase in CHAT_PHRASES:
				var chat_button := UIFactory.make_button(LocaleManager.t(String(phrase.key)), false)
				chat_button.custom_minimum_size = Vector2(0, 42)
				chat_button.pressed.connect(func(phrase_id: String = String(phrase.id)): _send_emote(phrase_id))
				body.add_child(chat_button)
		else:
			var opt_in_hint := UIFactory.make_label(LocaleManager.t("HUB_CHAT_ENABLE_PRESENCE"), 12, UIFactory.COL_MUTED)
			opt_in_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(opt_in_hint)
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
		var election := UIFactory.make_button(LocaleManager.t("ELECTION_MENU"), true)
		election.custom_minimum_size = Vector2(0, 52)
		election.pressed.connect(func():
			if not OnlineService.has_identity():
				_election_status = LocaleManager.t("ELECTION_NEEDS_CONNECTION")
				_open_election()
			else:
				_election_status = LocaleManager.t("ELECTION_LOADING")
				OnlineService.fetch_hub_election()
				_open_election())
		body.add_child(election)
	)

func _sync_online_presence(fetch_crowd: bool) -> void:
	if not bool(SaveSystem.get_value("hub_presence_opt_in", false)):
		return
	if _current_district_id != "kariakoo":
		if OnlineService.has_identity():
			OnlineService.leave_hub_presence()
		_crowd_players.clear()
		return
	if not OnlineService.has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		return
	var x := int(roundf(_player_position.x / AREA_SIZE.x * 1000.0))
	var y := int(roundf(_player_position.y / AREA_SIZE.y * 1000.0))
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
	if _current_district_id != "kariakoo":
		return
	var x := int(roundf(_player_position.x / AREA_SIZE.x * 1000.0))
	var y := int(roundf(_player_position.y / AREA_SIZE.y * 1000.0))
	if emote.begins_with("chat_"):
		OnlineService.send_hub_lounge_phrase(x, y, GameState.selected_vehicle_id, emote)
		AudioManager.play_sfx("click")
		return
	OnlineService.update_hub_presence(x, y, GameState.selected_vehicle_id, emote)
	AudioManager.play_sfx("horn" if emote == "horn" else "click")
	_show_toast(LocaleManager.t("HUB_EMOTE_SENT"))

func _chat_phrase_key(phrase_id: String) -> String:
	for phrase in CHAT_PHRASES:
		if String(phrase.id) == phrase_id:
			return String(phrase.key)
	return "HUB_CHAT_HELLO"

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
	if operation == "hub_lounge":
		_show_toast(LocaleManager.t(_chat_phrase_key(String(payload.get("phrase_id", "chat_hello")))) if success else LocaleManager.t("HUB_CHAT_FAILED"))
		return
	if operation == "registration" and _election_registration_pending:
		_election_registration_pending = false
		if success:
			_election_status = LocaleManager.t("ELECTION_LOADING")
			OnlineService.fetch_hub_election()
		else:
			_election_status = LocaleManager.t("ELECTION_UNAVAILABLE")
			_open_election()
		return
	if operation == "hub_election" or operation == "hub_election_vote":
		if operation == "hub_election_vote":
			_election_vote_pending = false
		if success:
			_election_data = payload.duplicate(true)
			_election_status = ""
		else:
			_election_status = LocaleManager.t("ELECTION_UNAVAILABLE")
			if operation == "hub_election_vote":
				OnlineService.fetch_hub_election()
		if is_instance_valid(_popup):
			_open_election()
		return
	if operation == "hub_crowd" and success:
		_crowd_players.clear()
		for entry in payload.get("players", []):
			_crowd_players.append(entry)
		queue_redraw()
		_populate_crowd_list()
		_refresh_labels()

func _open_election() -> void:
	_open_popup(LocaleManager.t("ELECTION_TITLE_S1"), func(body: VBoxContainer):
		var intro := UIFactory.make_label(LocaleManager.t("ELECTION_RULES"), 13, UIFactory.COL_MUTED)
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(intro)
		if not _election_status.is_empty():
			var status := UIFactory.make_label(_election_status, 14, UIFactory.COL_TEXT)
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(status)
		if _election_data.is_empty():
			if OnlineService.has_identity():
				var retry := UIFactory.make_button(LocaleManager.t("RETRY"), false)
				retry.pressed.connect(func():
					_election_status = LocaleManager.t("ELECTION_LOADING")
					OnlineService.fetch_hub_election()
					_open_election())
				body.add_child(retry)
			else:
				var register_note := UIFactory.make_label(LocaleManager.t("ELECTION_REGISTER_NOTE"), 12, UIFactory.COL_MUTED)
				register_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				body.add_child(register_note)
				var register := UIFactory.make_button(LocaleManager.t("ELECTION_REGISTER"), true)
				register.custom_minimum_size = Vector2(0, 50)
				register.disabled = _election_registration_pending
				register.pressed.connect(func():
					_election_registration_pending = true
					_election_status = LocaleManager.t("ELECTION_LOADING")
					OnlineService.register_installation()
					_open_election())
				body.add_child(register)
			return
		var is_open := bool(_election_data.get("isOpen", false))
		var has_voted := bool(_election_data.get("hasVoted", false)) or not is_open
		if not is_open:
			body.add_child(UIFactory.make_label(LocaleManager.t("ELECTION_CLOSED"), 15, UIFactory.COL_ACCENT))
			var winner := _election_winner()
			if winner.is_empty():
				body.add_child(UIFactory.make_label(LocaleManager.t("ELECTION_NO_WINNER"), 13, UIFactory.COL_MUTED))
			else:
				body.add_child(UIFactory.make_label(LocaleManager.t("ELECTION_WINNER").replace("{name}", winner), 15, UIFactory.COL_TEXT))
		if has_voted:
			body.add_child(UIFactory.make_label(LocaleManager.t("ELECTION_VOTED"), 15, UIFactory.COL_ACCENT))
		for candidate in _election_data.get("candidates", []):
			var id := String(candidate.get("id", ""))
			var name := LocaleManager.t(String(candidate.get("nameKey", "")))
			var role := LocaleManager.t(String(candidate.get("roleKey", "")))
			var votes := _election_votes(id)
			var card := VBoxContainer.new()
			var heading := UIFactory.make_label(name + "  •  " + role, 15, UIFactory.COL_TEXT)
			heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(heading)
			card.add_child(UIFactory.make_label(LocaleManager.t("ELECTION_VOTES").replace("{n}", str(votes)), 12, UIFactory.COL_MUTED))
			var choose := UIFactory.make_button(LocaleManager.t("ELECTION_VOTE"), false)
			choose.custom_minimum_size = Vector2(0, 44)
			choose.disabled = has_voted or _election_vote_pending
			choose.pressed.connect(func(candidate_id: String = id): _confirm_election_vote(candidate_id))
			card.add_child(choose)
			body.add_child(card)
	)

func _election_votes(candidate_id: String) -> int:
	for result in _election_data.get("results", []):
		if String(result.get("candidateId", "")) == candidate_id:
			return int(result.get("votes", 0))
	return 0

func _election_winner() -> String:
	var best := -1
	var winner_id := ""
	var tied := false
	for candidate in _election_data.get("candidates", []):
		var id := String(candidate.get("id", ""))
		var count := _election_votes(id)
		if count > best:
			best = count
			winner_id = id
			tied = false
		elif count == best:
			tied = true
	if best <= 0 or tied:
		return ""
	for candidate in _election_data.get("candidates", []):
		if String(candidate.get("id", "")) == winner_id:
			return LocaleManager.t(String(candidate.get("nameKey", "")))
	return ""

func _confirm_election_vote(candidate_id: String) -> void:
	if _election_vote_pending or bool(_election_data.get("hasVoted", false)):
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = LocaleManager.t("ELECTION_CONFIRM_TITLE")
	dialog.dialog_text = LocaleManager.t("ELECTION_CONFIRM_BODY")
	dialog.ok_button_text = LocaleManager.t("ELECTION_VOTE")
	dialog.cancel_button_text = LocaleManager.t("CANCEL")
	dialog.confirmed.connect(func():
		_election_vote_pending = true
		_election_status = LocaleManager.t("ELECTION_LOADING")
		OnlineService.vote_hub_election(String(_election_data.get("electionId", "")), candidate_id)
		_open_election()
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(mini(420, int(get_viewport_rect().size.x) - 24), 0))

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
	return parsed > 0.0 and Time.get_unix_time_from_system() - parsed <= 12.0

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
