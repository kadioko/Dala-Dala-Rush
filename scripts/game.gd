extends Node2D
## Main game loop — full feature set:
##   3-2-1-GO countdown  •  Horn mechanic (3 charges)  •  Lane warning arrows
##   Camera shake  •  Floating labels  •  Speed lines  •  Fuel meter
##   Combo multiplier  •  Power-up HUD bars  •  Achievement triggers

const PlayerCls     := preload("res://scripts/entities/player.gd")
const KituoCls      := preload("res://scripts/entities/kituo.gd")
const ObstacleCls   := preload("res://scripts/entities/obstacle.gd")
const CollectCls    := preload("res://scripts/entities/collectible.gd")
const RoadCls       := preload("res://scripts/entities/road.gd")
const SpeedLinesCls := preload("res://scripts/effects/speed_lines.gd")
const Vehicles      := preload("res://data/vehicles.gd")
const Routes        := preload("res://data/routes.gd")
const UIFactory     := preload("res://ui/ui_factory.gd")

# ── World ─────────────────────────────────────────────────────────
var view_size: Vector2
var lanes: Array = []
var num_lanes: int = 3
var road: Road
var player: Player
var entity_layer: Node2D
var speed_lines: SpeedLines
var camera: Camera2D
var hud_layer: CanvasLayer

# ── Pools ─────────────────────────────────────────────────────────
var obstacles_active: Array = []
var collectibles_active: Array = []
var obstacles_free: Array = []
var collectibles_free: Array = []
const POOL_OBS := 24
const POOL_COL := 28

# ── Run state ─────────────────────────────────────────────────────
var base_speed: float = 340.0
var speed: float = 340.0
var distance: float = 0.0
var bonus_score: int = 0
var coins: int = 0
var passengers: int = 0
var elapsed: float = 0.0
var spawn_timer: float = 0.0
var passenger_timer: float = 0.0
var _last_safe_lane: int = 1
var difficulty_mult: float = 1.0
var current_route: Dictionary = {}
var current_vehicle: Dictionary = {}
var spawn_interval_mult: float = 1.0
var fuel_drain_mult: float = 1.0
var coin_mult: float = 1.0
var paused: bool = false
var game_over: bool = false
var near_miss_done: Dictionary = {}
var reduced_effects: bool = false

# ── Career upgrades (permanent, read at run start) ───────────────
var _upg_engine: int = 0     # +4% score per level
var _upg_brakes: int = 0     # +1s slow-motion per level
var _upg_sound: int = 0      # +2 coins per served kituo per level
var slow_max: float = 4.0

# ── Living city: per-run conditions ──────────────────────────────
var condition: String = "day"        # day | dusk | night | rain
var rush_hour: bool = false
var _headlights: Node2D = null
var _rain: CPUParticles2D = null
var _fuel_warned: bool = false
var _fuel_visual_state: int = -1

# ── Ghost racing ──────────────────────────────────────────────────
# Records the lane timeline of every fresh run; best run is saved and
# replayed as a translucent bus. Friend ghosts import via codes (leaderboard).
var _ghost_events: Array = []        # [[elapsed, lane], ...]
var _ghost_data: Dictionary = {}     # ghost being raced (events/end/score/name)
var _ghost_node: Node2D = null
var _ghost_idx: int = 0
var _ghost_beaten: bool = false
var _was_continued: bool = false

# ── Boss moment: traffic police chase ────────────────────────────
var chase_active: bool = false
var chase_time: float = 0.0
var chase_danger: float = 0.0
var chase_check_timer: float = 40.0
var _chase_cop: Node2D = null
const CHASE_DURATION := 10.0
const CHASE_CATCH_TIME := 2.2     # seconds in the cop's lane before fined
const CHASE_FINE := 15
const CHASE_REWARD := 25

# ── Daladala passenger loop (vituo) ──────────────────────────────
var onboard: int = 0                 # passengers currently in the bus
var dropoffs: int = 0                # total delivered this run
var fares_earned: int = 0            # coins earned from fares
const CAPACITY := 8                  # comfortable seats
const OVERLOAD_MAX := 4              # extra squeezed-in passengers
const FARE_NORMAL := 2               # coins per normal passenger dropped
const FARE_OVERLOAD := 3             # overload passengers pay extra
const OVERLOAD_HANDLING := 0.07      # lane-switch penalty per excess passenger
const OVERLOAD_FUEL := 0.04          # fuel drain penalty per excess passenger
const POLICE_FINE_PER_EXCESS := 5    # coins lost per excess at a checkpoint
var kituo: Kituo = null
var kituo_timer: float = 9.0         # first kituo arrives early to teach the mechanic
var _kituo_warned: bool = false
var _kituo_hint_time: float = 0.0
var _kituo_hint_key: String = "KITUO_AHEAD"
var _base_lane_time: float = 0.14

# ── Power-ups ─────────────────────────────────────────────────────
var shield_active: bool = false
var magnet_time: float = 0.0
var slow_time: float = 0.0
var boost_time: float = 0.0
var grace_time: float = 0.0          # post-continue invulnerability
const MAGNET_MAX := 6.0
const SLOW_MAX   := 4.0
const BOOST_MAX  := 3.0
const BOOST_SPEED_MULT := 1.45
const GRACE_TIME := 2.5
const STARTER_WINDOW := 12.0
const START_HINT_DURATION := 4.0
const MAX_SPEED_RAMPS := 7
const MIN_SPAWN_INTERVAL := 0.52
var _total_boost_uses: int = 0
var starter_hint_time: float = 0.0

# ── Fuel ──────────────────────────────────────────────────────────
var fuel: float = 1.0
const FUEL_DRAIN := 0.0115
const FUEL_RESTORE := 0.42
const FUEL_LOW_THRESHOLD := 0.28

# ── Combo ─────────────────────────────────────────────────────────
var combo: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW := 2.8

# ── Horn ──────────────────────────────────────────────────────────
var horn_charges: int = 3
var horn_regen_timer: float = 0.0
const HORN_REGEN_TIME := 14.0
var max_horn_charges: int = 3
var _horn_btn: Button
var _total_horn_uses: int = 0

# ── Lane warnings ─────────────────────────────────────────────────
var _lane_warnings: Array = []

# ── Countdown ─────────────────────────────────────────────────────
var _counting_down: bool = true
var _countdown_layer: CanvasLayer
var _countdown_label: Label
var _countdown_bg: ColorRect

# ── Achievement triggers (prevent double-fire) ────────────────────
var _ach_1km_done: bool = false
var _ach_s1000_done: bool = false
var _ach_s5000_done: bool = false
var _run_near_misses: int = 0

# ── Input ─────────────────────────────────────────────────────────
var swipe_start: Vector2 = Vector2.ZERO
var swipe_threshold: float = 40.0
var swipe_active_id: int = -1
var swipe_consumed: bool = false
var mouse_swipe_active: bool = false

# ── HUD nodes ─────────────────────────────────────────────────────
var score_label: Label
var coins_label: Label
var pass_label: Label
var status_label: Label
var combo_label: Label
var pause_btn: Button
var btn_left: Button
var btn_right: Button
var fuel_bar: ProgressBar
var magnet_bar: ProgressBar
var slow_bar: ProgressBar
var boost_bar: ProgressBar
var shield_icon: Control
var pause_overlay: Control
var near_miss_flash: ColorRect

const OBSTACLE_TYPES := [
	"bodaboda","bajaji","car","pothole","cone",
	"police","barrier","truck","pedestrian","tire","mbuzi"
]
const BASE_COLLECTIBLE_TYPES := ["coin", "fuel", "shield", "magnet", "speed_boost", "slow"]
const SCORE_FIRE := 800
const SCORE_JAM  := 1500

# ═════════════════════════ READY ══════════════════════════════════

func _ready() -> void:
	view_size = get_viewport_rect().size
	_compute_lanes()

	current_route = Routes.get_by_id(GameState.selected_route_id)
	difficulty_mult = float(current_route.difficulty)
	spawn_interval_mult = float(current_route.get("spawn_interval_mult", 1.0))
	reduced_effects = bool(SaveSystem.get_value("reduced_effects", false))
	var resume_state: Dictionary = {}
	if GameState.continue_pending:
		resume_state = GameState.continue_state.duplicate(true)
	var is_continuing: bool = GameState.continue_pending and not resume_state.is_empty()

	# Give new drivers two clear runs before introducing weather and rush hour.
	var completed_runs: int = int(SaveSystem.get_value("total_runs", 0))
	if is_continuing:
		condition = String(resume_state.get("condition", "day"))
		rush_hour = bool(resume_state.get("rush_hour", false))
	elif completed_runs < 2:
		condition = "day"
		rush_hour = false
	else:
		var roll: float = randf()
		if roll < 0.40:   condition = "day"
		elif roll < 0.60: condition = "dusk"
		elif roll < 0.80: condition = "night"
		else:             condition = "rain"
		rush_hour = randf() < 0.25
	if rush_hour:
		spawn_interval_mult *= 0.85

	camera = Camera2D.new()
	camera.position = view_size * 0.5
	add_child(camera)
	camera.make_current()

	var sky_col: Color = current_route.sky
	var road_col: Color = current_route.road
	match condition:
		"dusk":
			sky_col = sky_col.lerp(Color("#e17055"), 0.45)
		"night":
			sky_col = sky_col.lerp(Color("#10131c"), 0.85)
			road_col = road_col.darkened(0.25)
		"rain":
			sky_col = sky_col.lerp(Color("#5d6d7e"), 0.6)
			road_col = road_col.lerp(Color("#1c2833"), 0.3)

	road = RoadCls.new()
	road.setup(view_size, sky_col, road_col, current_route.id)
	add_child(road)
	if condition == "night":
		road.modulate = Color(0.62, 0.66, 0.85)
	elif condition == "dusk":
		road.modulate = Color(1.0, 0.88, 0.78)

	entity_layer = Node2D.new()
	add_child(entity_layer)

	speed_lines = SpeedLinesCls.new()
	speed_lines.setup(view_size, reduced_effects)
	entity_layer.add_child(speed_lines)

	_upg_engine = Career.upgrade_level("upg_engine")
	_upg_brakes = Career.upgrade_level("upg_brakes")
	_upg_sound = Career.upgrade_level("upg_sound")
	slow_max = SLOW_MAX + float(_upg_brakes)

	current_vehicle = Vehicles.get_by_id(GameState.selected_vehicle_id)
	fuel_drain_mult = float(current_vehicle.get("fuel_drain_mult", 1.0))
	coin_mult = float(current_vehicle.get("coin_mult", 1.0))
	max_horn_charges = int(current_vehicle.get("horn_charges", 3))
	horn_charges = max_horn_charges

	player = PlayerCls.new()
	player.reduced_motion = reduced_effects
	entity_layer.add_child(player)
	player.setup(lanes, current_vehicle)
	# The bus needs its own clear road space above the driving dock.
	# Include gesture-navigation clearance so Android devices keep the same gap.
	var gameplay_bottom_inset: float = UIFactory.safe_bottom_inset(view_size.y)
	player.position.y = view_size.y - 246 - gameplay_bottom_inset
	_base_lane_time = player.lane_switch_time
	if condition == "rain":
		_base_lane_time *= 1.18  # wet road: heavier steering
		player.lane_switch_time = _base_lane_time

	# Night: headlight cones in front of the bus
	if condition == "night":
		_headlights = _Headlights.new()
		player.add_child(_headlights)

	# Rain: streaking particles across the screen
	if condition == "rain":
		_rain = CPUParticles2D.new()
		_rain.amount = 36 if reduced_effects else 90
		_rain.lifetime = 0.7
		_rain.preprocess = 0.7
		_rain.position = Vector2(view_size.x * 0.5, -20)
		_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_rain.emission_rect_extents = Vector2(view_size.x * 0.6, 10)
		_rain.direction = Vector2(-0.18, 1.0)
		_rain.spread = 4.0
		_rain.initial_velocity_min = 1500.0
		_rain.initial_velocity_max = 1900.0
		_rain.scale_amount_min = 1.4
		_rain.scale_amount_max = 2.2
		_rain.color = Color(0.75, 0.85, 1.0, 0.42)
		add_child(_rain)
		_rain.emitting = true

	kituo = KituoCls.new()
	kituo.visible = false
	entity_layer.add_child(kituo)

	# Ghost setup: race the imported rival ghost if present, else own best.
	if bool(SaveSystem.get_value("ghost_on", true)):
		var rival: Variant = SaveSystem.get_value("ghost_rival", null)
		var own: Variant = SaveSystem.get_value("ghost_best", null)
		var g: Variant = rival if typeof(rival) == TYPE_DICTIONARY else own
		if typeof(g) == TYPE_DICTIONARY and (g as Dictionary).has("events"):
			_ghost_data = g
			_ghost_node = _GhostBus.new()
			_ghost_node.modulate = Color(1, 1, 1, 0.38)
			entity_layer.add_child(_ghost_node)
			_ghost_node.position = Vector2(lanes[1], player.position.y - 94.0)
	_ghost_events = [[0.0, 1]]

	# Ad-continue: restore the crashed run's progress, else start fresh.
	if is_continuing:
		distance         = float(resume_state.get("distance", 0.0))
		bonus_score      = int(resume_state.get("bonus_score", 0))
		coins            = int(resume_state.get("coins", 0))
		passengers       = int(resume_state.get("passengers", 0))
		onboard          = clampi(int(resume_state.get("onboard", 0)), 0, CAPACITY + OVERLOAD_MAX)
		_run_near_misses = int(resume_state.get("near_misses", 0))
		dropoffs         = int(resume_state.get("dropoffs", 0))
		fares_earned     = int(resume_state.get("fares", 0))
		elapsed          = maxf(0.0, float(resume_state.get("elapsed", 0.0)))
		fuel             = clampf(maxf(float(resume_state.get("fuel", 0.0)), 0.6), 0.0, 1.0)
		_total_horn_uses = int(resume_state.get("horn_uses", 0))
		_total_boost_uses = int(resume_state.get("boosts", 0))
		max_horn_charges = maxi(1, int(resume_state.get("max_horn_charges", max_horn_charges)))
		horn_charges     = clampi(int(resume_state.get("horn_charges", 0)), 0, max_horn_charges)
		horn_regen_timer = clampf(float(resume_state.get("horn_regen_timer", HORN_REGEN_TIME)), 0.0, HORN_REGEN_TIME)
		fuel_drain_mult  = maxf(0.1, float(resume_state.get("fuel_drain_mult", fuel_drain_mult)))
		_update_handling()
		grace_time      = GRACE_TIME
		_was_continued  = true
		GameState.continue_pending = false
		GameState.continue_state = {}
	else:
		GameState.begin_run()
		_apply_consumables()

	_build_pools()
	_build_hud()
	_build_pause_overlay()
	_build_countdown()

	# Tell the player which consumables kicked in
	for i in range(_used_items.size()):
		_spawn_float_label(
			"✓ " + LocaleManager.t(_used_items[i]),
			player.position + Vector2(0, -60.0 - i * 34.0),
			UIFactory.COL_PRIMARY)

	speed = base_speed * difficulty_mult
	set_process(true)
	set_process_input(true)

## Auto-use one of each owned consumable at the start of a fresh run.
var _used_items: Array = []

func _apply_consumables() -> void:
	SaveSystem.begin_batch()
	if SaveSystem.use_consumable("head_start_shield"):
		shield_active = true
		_used_items.append("ITEM_SHIELD")
	if SaveSystem.use_consumable("horn_pack"):
		max_horn_charges += 1
		horn_charges = max_horn_charges
		_used_items.append("ITEM_HORN")
	if SaveSystem.use_consumable("fuel_saver"):
		fuel_drain_mult *= 0.8
		_used_items.append("ITEM_FUEL")
	SaveSystem.end_batch()

func _compute_lanes() -> void:
	var road_w: float = view_size.x * 0.8
	var road_x: float = (view_size.x - road_w) * 0.5
	var lane_w: float = road_w / num_lanes
	lanes.clear()
	for i in range(num_lanes):
		lanes.append(road_x + lane_w * 0.5 + lane_w * i)

func _build_pools() -> void:
	for _i in range(POOL_OBS):
		var o := ObstacleCls.new()
		o.visible = false
		entity_layer.add_child(o)
		obstacles_free.append(o)
	for _i in range(POOL_COL):
		var c := CollectCls.new()
		c.visible = false
		entity_layer.add_child(c)
		collectibles_free.append(c)

# ═════════════════════════ COUNTDOWN ══════════════════════════════

func _build_countdown() -> void:
	_countdown_layer = CanvasLayer.new()
	add_child(_countdown_layer)

	_countdown_bg = ColorRect.new()
	_countdown_bg.color = Color(0.02, 0.04, 0.07, 0.42)
	_countdown_bg.anchor_right = 1.0
	_countdown_bg.anchor_bottom = 1.0
	_countdown_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_layer.add_child(_countdown_bg)

	_countdown_label = Label.new()
	_countdown_label.anchor_left = 0.5
	_countdown_label.anchor_top = 0.5
	_countdown_label.anchor_right = 0.5
	_countdown_label.anchor_bottom = 0.5
	_countdown_label.offset_left = -120
	_countdown_label.offset_right = 120
	_countdown_label.offset_top = -100
	_countdown_label.offset_bottom = 100
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 110)
	_countdown_label.add_theme_color_override("font_color", UIFactory.COL_ACCENT)
	_countdown_layer.add_child(_countdown_label)

	# Route card: establish where this particular run is happening before launch.
	var route_title := UIFactory.make_title(
		LocaleManager.t(String(current_route.get("name_key", "ROUTE_KARIAKOO"))), 30)
	route_title.anchor_left = 0.5
	route_title.anchor_right = 0.5
	route_title.anchor_top = 0.5
	route_title.anchor_bottom = 0.5
	route_title.offset_left = -210
	route_title.offset_right = 210
	route_title.offset_top = -230
	route_title.offset_bottom = -185
	route_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_countdown_layer.add_child(route_title)

	var route_detail := UIFactory.make_label(
		LocaleManager.t(String(current_route.get("flavor_key", "ROUTE_KARIAKOO_D"))), 16, UIFactory.COL_TEXT)
	route_detail.anchor_left = 0.5
	route_detail.anchor_right = 0.5
	route_detail.anchor_top = 0.5
	route_detail.anchor_bottom = 0.5
	route_detail.offset_left = -210
	route_detail.offset_right = 210
	route_detail.offset_top = -182
	route_detail.offset_bottom = -138
	route_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_countdown_layer.add_child(route_detail)

	# Condition banner ("Usiku" / "Mvua" / "Rush Hour"...)
	var cond_parts: Array = []
	if condition != "day":
		cond_parts.append(LocaleManager.t("COND_" + condition.to_upper()))
	if rush_hour:
		cond_parts.append(LocaleManager.t("COND_RUSH"))
	if not cond_parts.is_empty():
		var cond_lbl := UIFactory.make_label(" • ".join(cond_parts), 24, UIFactory.COL_ACCENT)
		cond_lbl.anchor_left = 0.5
		cond_lbl.anchor_right = 0.5
		cond_lbl.anchor_top = 0.5
		cond_lbl.anchor_bottom = 0.5
		cond_lbl.offset_left = -180
		cond_lbl.offset_right = 180
		cond_lbl.offset_top = -134
		cond_lbl.offset_bottom = -96
		_countdown_layer.add_child(cond_lbl)

	# The dala dala rolls into its starting position while the route is introduced.
	var launch_y: float = player.position.y
	player.position.y = launch_y + 34.0
	player.modulate.a = 0.55
	var bus_intro := player.create_tween()
	bus_intro.set_parallel(true)
	bus_intro.tween_property(player, "position:y", launch_y, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bus_intro.tween_property(player, "modulate:a", 1.0, 0.34)

	_show_countdown_num(3)

func _show_countdown_num(n: int) -> void:
	if n <= 0:
		# Give new players a moment to orient themselves before traffic arrives.
		spawn_timer = maxf(spawn_timer, 1.25)
		passenger_timer = maxf(passenger_timer, 1.0)
		starter_hint_time = START_HINT_DURATION
		_countdown_label.text = LocaleManager.t("GO_TEXT")
		AudioManager.play_sfx("voice_twende")
		_countdown_label.add_theme_color_override("font_color", Color("#2ecc71"))
		_countdown_label.scale = Vector2(0.4, 0.4)
		_countdown_label.modulate.a = 1.0
		var tw := _countdown_label.create_tween()
		tw.tween_property(_countdown_label, "scale", Vector2(1.3, 1.3), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.22)
		tw.tween_property(_countdown_label, "modulate:a", 0.0, 0.22)
		tw.tween_callback(func():
			_countdown_layer.queue_free()
			_counting_down = false
		)
		return

	_countdown_label.text = str(n)
	_countdown_label.add_theme_color_override("font_color", UIFactory.COL_ACCENT)
	_countdown_label.scale = Vector2(1.8, 1.8)
	_countdown_label.modulate.a = 1.0
	var tw := _countdown_label.create_tween()
	tw.tween_property(_countdown_label, "scale", Vector2(1.0, 1.0), 0.30).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.42)
	tw.tween_property(_countdown_label, "modulate:a", 0.0, 0.20)
	tw.tween_callback(func(): _show_countdown_num(n - 1))

# ═════════════════════════ HUD BUILD ══════════════════════════════

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	# Near-miss edge flash
	near_miss_flash = ColorRect.new()
	near_miss_flash.color = Color(1, 0.9, 0, 0)
	near_miss_flash.anchor_right = 1.0
	near_miss_flash.anchor_bottom = 1.0
	near_miss_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(near_miss_flash)

	# Top bar
	var safe_top := UIFactory.safe_top_inset(view_size.y)
	var safe_bottom := UIFactory.safe_bottom_inset(view_size.y)
	var top := HBoxContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 60
	top.offset_top = 12 + safe_top
	top.offset_right = -12
	top.add_theme_constant_override("separation", 10)
	hud_layer.add_child(top)

	score_label = UIFactory.make_label("0", 30, UIFactory.COL_ACCENT)
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(score_label)

	var coin_stat := HBoxContainer.new()
	coin_stat.add_theme_constant_override("separation", 5)
	coin_stat.add_child(_make_game_icon(_GameIcon.IconKind.COIN, UIFactory.COL_ACCENT, Vector2(22, 22)))
	coins_label = UIFactory.make_label("", 18, UIFactory.COL_ACCENT)
	coin_stat.add_child(coins_label)
	top.add_child(coin_stat)

	var passenger_stat := HBoxContainer.new()
	passenger_stat.add_theme_constant_override("separation", 5)
	passenger_stat.add_child(_make_game_icon(_GameIcon.IconKind.PASSENGER, UIFactory.COL_TEXT, Vector2(22, 22)))
	pass_label = UIFactory.make_label("", 18, UIFactory.COL_TEXT)
	passenger_stat.add_child(pass_label)
	top.add_child(passenger_stat)

	pause_btn = UIFactory.make_button("II", false)
	pause_btn.custom_minimum_size = Vector2(56, 48)
	pause_btn.pressed.connect(_toggle_pause)
	top.add_child(pause_btn)

	# Status phrase
	status_label = UIFactory.make_label("", 22, UIFactory.COL_DANGER)
	status_label.anchor_left = 0.5
	status_label.anchor_right = 0.5
	status_label.offset_left = -160
	status_label.offset_right = 160
	status_label.offset_top = 70 + safe_top
	hud_layer.add_child(status_label)

	# Combo label
	combo_label = UIFactory.make_label("", 28, UIFactory.COL_ACCENT)
	combo_label.anchor_left = 0.5
	combo_label.anchor_right = 0.5
	combo_label.offset_left = -120
	combo_label.offset_right = 120
	combo_label.offset_top = 100 + safe_top
	combo_label.visible = false
	hud_layer.add_child(combo_label)

	# Fuel bar (left edge, vertical)
	fuel_bar = ProgressBar.new()
	fuel_bar.anchor_top = 0.14
	fuel_bar.anchor_bottom = 0.74
	fuel_bar.offset_left = 8
	fuel_bar.offset_right = 28
	fuel_bar.min_value = 0.0
	fuel_bar.max_value = 1.0
	fuel_bar.value = 1.0
	fuel_bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	fuel_bar.show_percentage = false
	_style_bar(fuel_bar, Color("#2ecc71"))
	hud_layer.add_child(fuel_bar)

	var fuel_icon := _make_game_icon(_GameIcon.IconKind.FUEL, Color("#e74c3c"), Vector2(28, 28))
	fuel_icon.anchor_top = 0.74
	fuel_icon.offset_left = 4
	fuel_icon.offset_right = 32
	fuel_icon.offset_top = 3
	fuel_icon.offset_bottom = 31
	hud_layer.add_child(fuel_icon)

	# Power-ups sit in the deliberate gap between the bus and control dock.
	var powerup_row := HBoxContainer.new()
	powerup_row.anchor_left = 0.5
	powerup_row.anchor_right = 0.5
	powerup_row.anchor_top = 1.0
	powerup_row.anchor_bottom = 1.0
	powerup_row.offset_left = -140
	powerup_row.offset_right = 140
	powerup_row.offset_top = -183 - safe_bottom
	powerup_row.offset_bottom = -148 - safe_bottom
	powerup_row.add_theme_constant_override("separation", 8)
	hud_layer.add_child(powerup_row)

	shield_icon = _make_game_icon(_GameIcon.IconKind.SHIELD, Color("#1f8fff"), Vector2(58, 24))
	powerup_row.add_child(shield_icon)

	var mc := _powerup_col(_GameIcon.IconKind.MAGNET, Color("#a55eea"))
	magnet_bar = mc[1] as ProgressBar
	powerup_row.add_child(mc[0])

	var sc := _powerup_col(_GameIcon.IconKind.SLOW, Color("#74b9ff"))
	slow_bar = sc[1] as ProgressBar
	powerup_row.add_child(sc[0])

	var bc := _powerup_col(_GameIcon.IconKind.BOOST, Color("#2ecc71"))
	boost_bar = bc[1] as ProgressBar
	powerup_row.add_child(bc[0])

	# ── Horn charges row ──────────────────────────────────────────
	# ── Lane warning triangles ─────────────────────────────────────
	for i in range(num_lanes):
		var w := _LaneWarning.new()
		w.custom_minimum_size = Vector2(40, 40)
		w.position = Vector2(lanes[i] - 20, 124)
		hud_layer.add_child(w)
		_lane_warnings.append(w)

	# One stable driving dock keeps controls clear of the bus on portrait phones.
	var drive_dock := PanelContainer.new()
	drive_dock.anchor_left = 0.5; drive_dock.anchor_right = 0.5
	drive_dock.anchor_top = 1.0; drive_dock.anchor_bottom = 1.0
	drive_dock.offset_left = -204; drive_dock.offset_right = 204
	drive_dock.offset_top = -130 - safe_bottom; drive_dock.offset_bottom = -18 - safe_bottom
	drive_dock.mouse_filter = Control.MOUSE_FILTER_PASS
	var dock_style := StyleBoxFlat.new()
	dock_style.bg_color = Color(0.035, 0.055, 0.078, 0.94)
	dock_style.border_color = Color(0.45, 0.64, 0.76, 0.42)
	dock_style.border_width_top = 1; dock_style.border_width_bottom = 1
	dock_style.border_width_left = 1; dock_style.border_width_right = 1
	dock_style.corner_radius_top_left = 8; dock_style.corner_radius_top_right = 8
	dock_style.corner_radius_bottom_left = 8; dock_style.corner_radius_bottom_right = 8
	dock_style.content_margin_left = 12.0; dock_style.content_margin_right = 12.0
	dock_style.content_margin_top = 12.0; dock_style.content_margin_bottom = 12.0
	drive_dock.add_theme_stylebox_override("panel", dock_style)
	hud_layer.add_child(drive_dock)

	var drive_row := HBoxContainer.new()
	drive_row.alignment = BoxContainer.ALIGNMENT_CENTER
	drive_row.add_theme_constant_override("separation", 12)
	drive_row.mouse_filter = Control.MOUSE_FILTER_PASS
	drive_dock.add_child(drive_row)

	# ── Lane tap buttons ──────────────────────────────────────────
	btn_left = _DriveButton.new()
	(btn_left as _DriveButton).icon_kind = _DriveButton.IconKind.LEFT
	btn_left.custom_minimum_size = Vector2(104, 82)
	btn_left.tooltip_text = LocaleManager.t("CTRL_SWIPE")
	_style_drive_button(btn_left, Color("#1f78bd"))
	btn_left.pressed.connect(_move_left)
	drive_row.add_child(btn_left)

	# Horn button (centre)
	_horn_btn = _DriveButton.new()
	var horn_control := _horn_btn as _DriveButton
	horn_control.icon_kind = _DriveButton.IconKind.HORN
	horn_control.charge_capacity = max_horn_charges
	_horn_btn.custom_minimum_size = Vector2(128, 82)
	_horn_btn.tooltip_text = LocaleManager.t("HORN_CHARGES")
	_style_drive_button(_horn_btn, Color("#d98218"))
	_horn_btn.pressed.connect(_use_horn)
	drive_row.add_child(_horn_btn)

	btn_right = _DriveButton.new()
	(btn_right as _DriveButton).icon_kind = _DriveButton.IconKind.RIGHT
	btn_right.custom_minimum_size = Vector2(104, 82)
	btn_right.tooltip_text = LocaleManager.t("CTRL_SWIPE")
	_style_drive_button(btn_right, Color("#1f78bd"))
	btn_right.pressed.connect(_move_right)
	drive_row.add_child(btn_right)

	_update_hud()

func _style_bar(bar: ProgressBar, col: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.08, 0.75)
	bg.corner_radius_top_left = 4; bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4; bg.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.corner_radius_top_left = 4; fg.corner_radius_top_right = 4
	fg.corner_radius_bottom_left = 4; fg.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fg)

func _style_drive_button(button: Button, color: Color) -> void:
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.085, 0.12, 0.98)
	normal.border_color = color
	normal.border_width_top = 2; normal.border_width_bottom = 2
	normal.border_width_left = 2; normal.border_width_right = 2
	normal.corner_radius_top_left = 8; normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8; normal.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.13, 0.18, 1.0)
	hover.border_color = color.lightened(0.16)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.38)
	pressed.border_color = color.lightened(0.26)
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled_style := normal.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.045, 0.055, 0.07, 0.86)
	disabled_style.border_color = Color(0.28, 0.34, 0.39, 0.72)
	button.add_theme_stylebox_override("disabled", disabled_style)

func _make_game_icon(kind: _GameIcon.IconKind, col: Color, icon_size: Vector2) -> _GameIcon:
	var icon := _GameIcon.new()
	icon.icon_kind = kind
	icon.tint = col
	icon.custom_minimum_size = icon_size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _powerup_col(kind: _GameIcon.IconKind, col: Color) -> Array:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.custom_minimum_size = Vector2(58, 0)
	vb.add_child(_make_game_icon(kind, col, Vector2(58, 24)))
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(58, 8)
	bar.min_value = 0.0; bar.max_value = 1.0; bar.value = 0.0
	bar.show_percentage = false
	_style_bar(bar, col)
	vb.add_child(bar)
	return [vb, bar]

func _build_pause_overlay() -> void:
	pause_overlay = Control.new()
	pause_overlay.anchor_right = 1.0; pause_overlay.anchor_bottom = 1.0
	pause_overlay.visible = false
	hud_layer.add_child(pause_overlay)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.68)
	bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	pause_overlay.add_child(bg)

	var v := VBoxContainer.new()
	v.anchor_left = 0.5; v.anchor_top = 0.5
	v.anchor_right = 0.5; v.anchor_bottom = 0.5
	v.offset_left = -165; v.offset_right = 165
	v.offset_top = -145; v.offset_bottom = 145
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	pause_overlay.add_child(v)

	v.add_child(UIFactory.make_title(LocaleManager.t("PAUSE"), 38))

	var rs := UIFactory.make_button(LocaleManager.t("RESUME"))
	rs.pressed.connect(_toggle_pause)
	v.add_child(rs)

	var restart := UIFactory.make_button(LocaleManager.t("RESTART"), false)
	restart.pressed.connect(func():
		AudioManager.play_sfx("click")
		TransitionManager.go_to("res://scenes/game.tscn")
	)
	v.add_child(restart)

	var mb := UIFactory.make_button(LocaleManager.t("MAIN_MENU"), false)
	mb.pressed.connect(func(): TransitionManager.go_to("res://scenes/main_menu.tscn"))
	v.add_child(mb)

func _toggle_pause() -> void:
	if game_over or _counting_down: return
	paused = not paused
	pause_overlay.visible = paused
	AudioManager.play_sfx("click")

func _notification(what: int) -> void:
	if what not in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		return
	if game_over or _counting_down or paused or not is_instance_valid(pause_overlay):
		return
	paused = true
	pause_overlay.visible = true

# ═════════════════════════ HUD UPDATE ═════════════════════════════

func _update_hud() -> void:
	score_label.text = "%d" % _current_score()
	coins_label.text = "%d" % coins
	pass_label.text  = "%d/%d" % [onboard, CAPACITY + OVERLOAD_MAX]
	pass_label.add_theme_color_override("font_color",
		UIFactory.COL_DANGER if onboard > CAPACITY else UIFactory.COL_TEXT)

	fuel_bar.value = fuel
	var fuel_state: int = 2
	if fuel < FUEL_LOW_THRESHOLD * 0.5:
		fuel_state = 0
	elif fuel < FUEL_LOW_THRESHOLD:
		fuel_state = 1
	if fuel_state != _fuel_visual_state:
		_fuel_visual_state = fuel_state
		var fuel_color: Color = Color("#e74c3c") if fuel_state == 0 else (Color("#f1c40f") if fuel_state == 1 else Color("#2ecc71"))
		_style_bar(fuel_bar, fuel_color)

	var shield_badge := shield_icon as _GameIcon
	shield_badge.active = shield_active
	shield_badge.queue_redraw()
	magnet_bar.value = magnet_time / MAGNET_MAX
	slow_bar.value   = slow_time   / slow_max
	boost_bar.value  = boost_time  / BOOST_MAX

	if combo >= 2:
		combo_label.text = "x%d!" % combo
		combo_label.visible = true
	else:
		combo_label.visible = false

	var horn_control := _horn_btn as _DriveButton
	horn_control.charge_count = horn_charges
	horn_control.queue_redraw()
	_horn_btn.disabled = horn_charges <= 0

	# Dim unavailable lane buttons so touch controls communicate their limits.
	var can_move_left: bool = player.current_lane > 0
	var can_move_right: bool = player.current_lane < num_lanes - 1
	btn_left.disabled = not can_move_left
	btn_right.disabled = not can_move_right
	btn_left.queue_redraw()
	btn_right.queue_redraw()

func _update_status() -> void:
	var sc: int = _current_score()
	if fuel < FUEL_LOW_THRESHOLD * 0.5:
		status_label.text = LocaleManager.t("FUEL_LOW")
		status_label.add_theme_color_override("font_color", Color("#e74c3c"))
	elif _kituo_hint_time > 0.0:
		status_label.text = LocaleManager.t(_kituo_hint_key)
		status_label.add_theme_color_override("font_color", UIFactory.COL_PRIMARY)
	elif starter_hint_time > 0.0:
		status_label.text = LocaleManager.t("START_HINT")
		status_label.add_theme_color_override("font_color", UIFactory.COL_ACCENT)
	elif sc > SCORE_JAM:
		status_label.text = LocaleManager.t("TRAFFIC_JAM")
		status_label.add_theme_color_override("font_color", UIFactory.COL_DANGER)
	elif sc > SCORE_FIRE:
		status_label.text = LocaleManager.t("ON_FIRE")
		status_label.add_theme_color_override("font_color", UIFactory.COL_ACCENT)
	else:
		status_label.text = ""

# ═════════════════════════ MAIN LOOP ══════════════════════════════

func _process(delta: float) -> void:
	if _counting_down:
		# Keep the city alive behind the route intro without spawning danger yet.
		road.advance(72.0 * delta)
		speed_lines.advance(72.0 * delta)
		return
	if paused or game_over:
		return

	elapsed += delta
	# Escalate every 20 seconds, then hold a demanding but readable end-game pace.
	var ramps: int = mini(int(elapsed / 20.0), MAX_SPEED_RAMPS)
	speed = base_speed * difficulty_mult * (1.0 + 0.15 * ramps)
	speed_lines.speed_ref = speed
	AudioManager.set_music_intensity(clampf(elapsed / 160.0, 0.0, 1.0))

	if magnet_time > 0: magnet_time = max(0.0, magnet_time - delta)
	if slow_time  > 0: slow_time   = max(0.0, slow_time  - delta)
	if boost_time > 0: boost_time  = max(0.0, boost_time - delta)
	if grace_time > 0: grace_time  = max(0.0, grace_time - delta)
	if starter_hint_time > 0: starter_hint_time = maxf(0.0, starter_hint_time - delta)
	if _kituo_hint_time > 0: _kituo_hint_time = maxf(0.0, _kituo_hint_time - delta)

	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

	# Horn regen
	if horn_charges < max_horn_charges:
		horn_regen_timer -= delta
		if horn_regen_timer <= 0.0:
			horn_charges = min(max_horn_charges, horn_charges + 1)
			horn_regen_timer = HORN_REGEN_TIME

	# Fuel (overloaded bus drinks more)
	var overload_fuel: float = 1.0 + OVERLOAD_FUEL * _overload_excess()
	fuel -= FUEL_DRAIN * fuel_drain_mult * overload_fuel * delta * (0.65 if slow_time > 0.0 else 1.0)
	fuel = max(0.0, fuel)
	if fuel < FUEL_LOW_THRESHOLD and not _fuel_warned:
		_fuel_warned = true
		AudioManager.play_sfx("voice_mafuta")
	elif fuel >= FUEL_LOW_THRESHOLD:
		_fuel_warned = false
	if fuel <= 0.0:
		_spawn_float_label(LocaleManager.t("FUEL_EMPTY"), player.position, Color("#e74c3c"))
		_end_run()
		return

	var move: float = speed * delta * (0.5 if slow_time > 0.0 else 1.0)
	if boost_time > 0.0:
		move *= BOOST_SPEED_MULT
	distance += move * (1.0 + 0.04 * _upg_engine)

	road.advance(move)
	speed_lines.advance(move)
	_move_entities(move, delta)
	_check_collisions()
	_update_status()
	_update_hud()

	# Shield pulse / grace flicker
	if grace_time > 0.0:
		player.modulate.a = 0.35 + 0.55 * abs(sin(elapsed * 14.0))
	elif shield_active:
		player.modulate.a = 0.62 + 0.38 * abs(sin(elapsed * 9.0))
	else:
		player.modulate.a = 1.0

	# Achievement distance / score checks
	if distance >= 1000.0 and not _ach_1km_done:
		_ach_1km_done = true
		AchievementManager.try_unlock("dist_1km")
	var sc: int = _current_score()
	if sc >= 1000 and not _ach_s1000_done:
		_ach_s1000_done = true
		AchievementManager.try_unlock("score_1000")
	if sc >= 5000 and not _ach_s5000_done:
		_ach_s5000_done = true
		AchievementManager.try_unlock("score_5000")

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var scaled_interval: float = (1.75 - elapsed * 0.014) * spawn_interval_mult / difficulty_mult
		var interval: float = maxf(MIN_SPAWN_INTERVAL, scaled_interval)
		spawn_timer = interval
		_spawn_wave()

	passenger_timer -= delta
	if passenger_timer <= 0.0:
		passenger_timer = randf_range(4.2, 7.2)
		_spawn_collectible(_pick_collectible_type(true))

	# ── Ghost playback ────────────────────────────────────────────
	if _ghost_node != null and not _ghost_data.is_empty():
		var g_end: float = float(_ghost_data.get("end", 0.0))
		if elapsed >= g_end and not _ghost_beaten:
			_ghost_beaten = true
			bonus_score += 150
			_spawn_float_label(LocaleManager.t("GHOST_BEATEN"),
				_ghost_node.position, Color("#2ecc71"))
			AudioManager.play_sfx("powerup")
			var tw := _ghost_node.create_tween()
			tw.tween_property(_ghost_node, "modulate:a", 0.0, 0.6)
		elif not _ghost_beaten:
			var events: Array = _ghost_data.get("events", [])
			while _ghost_idx + 1 < events.size() and float(events[_ghost_idx + 1][0]) <= elapsed:
				_ghost_idx += 1
			if _ghost_idx < events.size():
				var lane_i: int = clampi(int(events[_ghost_idx][1]), 0, num_lanes - 1)
				_ghost_node.position.x = lerpf(_ghost_node.position.x, lanes[lane_i], 10.0 * delta)

	# ── Police chase event ────────────────────────────────────────
	if not chase_active:
		chase_check_timer -= delta
		if chase_check_timer <= 0.0:
			chase_check_timer = randf_range(35.0, 55.0)
			if randf() < 0.5:
				_start_chase()
	else:
		_update_chase(delta)

	# ── Kituo (bus stop) cycle ────────────────────────────────────
	if not kituo.active:
		kituo_timer -= delta
		if kituo_timer <= 0.0:
			_spawn_kituo()
	else:
		kituo.position.y += move
		# Approach warning once it's getting close
		if not _kituo_warned and kituo.position.y > player.position.y - 420.0:
			_kituo_warned = true
			_kituo_hint_time = 3.0
			_kituo_hint_key = "KITUO_LEFT" if kituo.lane_idx == 0 else "KITUO_RIGHT"
			if kituo.lane_idx < _lane_warnings.size():
				(_lane_warnings[kituo.lane_idx] as _LaneWarning).flash(1.20)
			_spawn_float_label("🚏 " + LocaleManager.t(_kituo_hint_key),
				Vector2(kituo.position.x, kituo.position.y + 80), UIFactory.COL_ACCENT)
			AudioManager.play_sfx("voice_kituo")
		# Serve: player in the adjacent lane as the kituo passes
		if not kituo.served and not kituo.missed \
		and abs(kituo.position.y - player.position.y) < 80.0 \
		and player.current_lane == kituo.lane_idx:
			_serve_kituo()
		# Missed it
		if not kituo.served and not kituo.missed and kituo.position.y > player.position.y + 130.0:
			kituo.missed = true
			_kituo_hint_time = 0.0
			if onboard > 0:
				_spawn_float_label(LocaleManager.t("KITUO_MISSED"),
					player.position + Vector2(0, -50), UIFactory.COL_MUTED)
		if kituo.position.y > view_size.y + 170.0:
			kituo.deactivate()
			kituo_timer = randf_range(20.0, 32.0)
			_kituo_warned = false

# ═════════════════════════ ENTITIES ═══════════════════════════════

func _move_entities(move: float, delta: float) -> void:
	var road_left: float = lanes[0] - 40.0
	var road_right: float = lanes[num_lanes - 1] + 40.0
	for o in obstacles_active.duplicate():
		o.position.y += move
		# Type-specific horizontal behaviour
		match o.type_id:
			"bodaboda":
				# Weaves around its lane like a real bodaboda
				o.position.x = o.base_x + sin(o.position.y * 0.012 + o.drift_phase) * 26.0
			"mbuzi":
				# Goat slowly wanders across the road, turning at the edges
				o.position.x += o.walk_dir * 42.0 * delta
				if o.position.x < road_left:
					o.position.x = road_left
					o.walk_dir = 1
				elif o.position.x > road_right:
					o.position.x = road_right
					o.walk_dir = -1
		# Telegraph the lane as the obstacle reaches the visible road, rather
		# than flashing while it is still above the screen.
		if not o.warning_announced and o.position.y >= 118.0:
			o.warning_announced = true
			var warning_lane: int = _nearest_lane_index(o.position.x)
			if warning_lane < _lane_warnings.size():
				(_lane_warnings[warning_lane] as _LaneWarning).flash(0.82)
		if o.position.y > view_size.y + 140:
			_despawn_obstacle(o)
	for c in collectibles_active.duplicate():
		c.position.y += move
		if magnet_time > 0.0 and c.type_id == "coin":
			var dx: float = player.position.x - c.position.x
			c.position.x += sign(dx) * min(abs(dx), 380.0 * delta)
		if c.position.y > view_size.y + 140:
			_despawn_collectible(c)

func _check_collisions() -> void:
	var prect: Rect2 = player.get_collision_aabb()
	for o in obstacles_active.duplicate():
		var orect: Rect2 = o.get_collision_aabb()
		if not near_miss_done.get(o.get_instance_id(), false) and o.position.y > player.position.y + 20:
			var h_gap: float = abs(o.position.x - player.position.x)
			if h_gap < 92.0 and not prect.intersects(orect):
				near_miss_done[o.get_instance_id()] = true
				# Passing a police checkpoint while overloaded = fine!
				if o.type_id == "police" and _overload_excess() > 0:
					var fine: int = _overload_excess() * POLICE_FINE_PER_EXCESS
					coins = max(0, coins - fine)
					_spawn_float_label("%s -%d 🪙" % [LocaleManager.t("FINE"), fine],
						player.position + Vector2(0, -50), UIFactory.COL_DANGER)
					_screen_shake(6.0, 0.2)
					AudioManager.play_sfx("crash")
					FeedbackManager.crash()
				else:
					bonus_score += 80
					_on_near_miss(o.position)
		if prect.intersects(orect):
			if grace_time > 0.0:
				continue
			if boost_time > 0.0:
				# Boosting: smash through the obstacle.
				bonus_score += 50
				_burst(o.position, Color("#2ecc71"), 10)
				_spawn_float_label("+50", o.position, Color("#2ecc71"))
				_screen_shake(5.0, 0.15)
				AudioManager.play_sfx("powerup")
				_despawn_obstacle(o)
				continue
			_on_hit(o)
			return
	for c in collectibles_active.duplicate():
		if prect.intersects(c.get_aabb()):
			_on_collect(c)

# ═════════════════════════ EVENTS ════════════════════════════════

func _on_hit(o: Obstacle) -> void:
	if shield_active:
		shield_active = false
		FeedbackManager.powerup()
		_screen_shake(7.0, 0.25)
		AudioManager.play_sfx("powerup")
		_spawn_float_label(LocaleManager.t("SHIELD_HIT"), player.position, UIFactory.COL_PRIMARY)
		AchievementManager.try_unlock("shield_use")
		_despawn_obstacle(o)
		return
	FeedbackManager.crash()
	AudioManager.play_sfx("voice_mwisho")
	_burst(player.position, Color("#e74c3c"), 18)
	_burst(player.position, Color("#f1c40f"), 10)
	_hit_stop()
	_screen_shake(16.0, 0.45)
	AudioManager.play_sfx("crash")
	_end_run()

func _on_collect(c: Collectible) -> void:
	var bonus_text: String = ""
	var label_col: Color = UIFactory.COL_ACCENT
	match c.type_id:
		"coin":
			combo += 1
			combo_timer = COMBO_WINDOW
			var base_value: int = 1 + int(max(0, combo - 1) * 0.5)
			var value: int = max(1, int(ceil(float(base_value) * coin_mult)))
			coins += value
			bonus_text = "+%d" % value
			label_col = UIFactory.COL_ACCENT
			AudioManager.play_sfx("coin")
			FeedbackManager.collect()
			_burst(c.position, UIFactory.COL_ACCENT, 6)
			if combo >= 2:
				_punch_combo_label()
			if coins >= 50: AchievementManager.try_unlock("coins_50")
			if combo >= 5:  AchievementManager.try_unlock("combo_5")
		"passenger":
			if onboard < CAPACITY + OVERLOAD_MAX:
				onboard += 1
				passengers += 1
				bonus_score += 200
				_update_handling()
				if onboard > CAPACITY:
					bonus_text = LocaleManager.t("OVERLOAD")
					label_col = UIFactory.COL_DANGER
				else:
					bonus_text = "+1 👤"
					label_col = Color("#fab1a0")
			else:
				# Bus completely full — they wave you past
				bonus_score += 50
				bonus_text = LocaleManager.t("BUS_FULL")
				label_col = UIFactory.COL_MUTED
			AudioManager.play_sfx("passenger")
			FeedbackManager.collect()
			if passengers >= 10: AchievementManager.try_unlock("pass_10")
		"fuel":
			fuel = min(1.0, fuel + FUEL_RESTORE)
			bonus_score += 300
			bonus_text = "+300"
			label_col = Color("#e74c3c")
			AudioManager.play_sfx("powerup")
			FeedbackManager.powerup()
		"shield":
			shield_active = true
			bonus_text = LocaleManager.t("SHIELD_ON")
			label_col = UIFactory.COL_PRIMARY
			AudioManager.play_sfx("powerup")
			FeedbackManager.powerup()
		"magnet":
			magnet_time = MAGNET_MAX
			bonus_text = LocaleManager.t("MAGNET_ON")
			label_col = Color("#a55eea")
			AudioManager.play_sfx("powerup")
			FeedbackManager.powerup()
		"speed_boost":
			boost_time = BOOST_MAX
			bonus_score += 150
			bonus_text = "+150  " + LocaleManager.t("BOOST_ON")
			label_col = Color("#2ecc71")
			AudioManager.play_sfx("powerup")
			FeedbackManager.powerup()
			_total_boost_uses += 1
			if _total_boost_uses == 1:
				AchievementManager.try_unlock("boost_use")
		"slow":
			slow_time = slow_max
			bonus_text = LocaleManager.t("SLOW_ON")
			label_col = Color("#74b9ff")
			AudioManager.play_sfx("powerup")
			FeedbackManager.powerup()
	if bonus_text != "":
		_spawn_float_label(bonus_text, c.position, label_col)
	_despawn_collectible(c)

func _on_near_miss(world_pos: Vector2) -> void:
	_run_near_misses += 1
	_spawn_float_label(LocaleManager.t("NEAR_MISS"), world_pos, Color("#f1c40f"))
	if near_miss_flash:
		near_miss_flash.color = Color(1.0, 0.9, 0.1, 0.16 if reduced_effects else 0.38)
		var tw := near_miss_flash.create_tween()
		tw.tween_property(near_miss_flash, "color:a", 0.0, 0.18 if reduced_effects else 0.30)
	if _run_near_misses >= 5:
		AchievementManager.try_unlock("near_miss_5")

# ─── Horn ────────────────────────────────────────────────────────

func _use_horn() -> void:
	if _counting_down or paused or game_over: return
	if horn_charges <= 0:
		_spawn_float_label(LocaleManager.t("HORN_EMPTY"),
			player.position + Vector2(0, -40), UIFactory.COL_DANGER)
		return
	horn_charges -= 1
	horn_regen_timer = HORN_REGEN_TIME
	_total_horn_uses += 1
	AudioManager.play_sfx("horn")
	FeedbackManager.powerup()
	if _total_horn_uses >= 3:
		AchievementManager.try_unlock("horn_3")
	# Clear nearest obstacle in current lane ahead of player
	var lane_x: float = lanes[player.current_lane]
	var nearest: Obstacle = null
	var nearest_d: float = INF
	for o in obstacles_active:
		if abs(o.position.x - lane_x) < 50 and o.position.y < player.position.y:
			var d: float = player.position.y - o.position.y
			if d < nearest_d:
				nearest_d = d
				nearest = o
	if nearest:
		_spawn_float_label(LocaleManager.t("HORN_BLAST"), nearest.position, Color("#ffd23f"))
		# Stop collision immediately; return the visual to the pool after it exits.
		obstacles_active.erase(nearest)
		near_miss_done.erase(nearest.get_instance_id())
		var tw := nearest.create_tween()
		tw.tween_property(nearest, "scale", Vector2(0.0, 0.0), 0.22).set_trans(Tween.TRANS_BACK)
		tw.tween_callback(func():
			if is_instance_valid(nearest):
				nearest.scale = Vector2.ONE
				_despawn_obstacle(nearest)
		)

# ─── Police chase ────────────────────────────────────────────────

func _start_chase() -> void:
	chase_active = true
	chase_time = 0.0
	chase_danger = 0.0
	_chase_cop = _ChaseCop.new()
	_chase_cop.position = Vector2(lanes[randi() % num_lanes], view_size.y + 80)
	entity_layer.add_child(_chase_cop)
	_spawn_float_label("🚨 " + LocaleManager.t("CHASE_START"),
		player.position + Vector2(0, -70), UIFactory.COL_DANGER)
	AudioManager.play_sfx("horn")
	FeedbackManager.crash()
	_screen_shake(5.0, 0.2)

func _update_chase(delta: float) -> void:
	chase_time += delta
	# Cop slides up into view, then tracks the player's lane
	var target_y: float = player.position.y + 150.0
	_chase_cop.position.y = move_toward(_chase_cop.position.y, target_y, 220.0 * delta)
	_chase_cop.position.x = move_toward(_chase_cop.position.x, player.position.x, 150.0 * delta)

	# Danger builds while the cop is lined up behind you
	if abs(_chase_cop.position.x - player.position.x) < 55.0:
		chase_danger += delta
		if chase_danger >= CHASE_CATCH_TIME:
			_end_chase(false)
			return
	else:
		chase_danger = max(0.0, chase_danger - delta * 1.5)

	if chase_time >= CHASE_DURATION:
		_end_chase(true)

func _end_chase(escaped: bool) -> void:
	chase_active = false
	if escaped:
		coins += CHASE_REWARD
		_spawn_float_label("%s +%d 🪙" % [LocaleManager.t("CHASE_ESCAPED"), CHASE_REWARD],
			player.position + Vector2(0, -60), Color("#2ecc71"))
		AudioManager.play_sfx("powerup")
		AchievementManager.try_unlock("chase_escape")
	else:
		var fine: int = CHASE_FINE + _overload_excess() * POLICE_FINE_PER_EXCESS
		coins = max(0, coins - fine)
		_spawn_float_label("%s -%d 🪙" % [LocaleManager.t("FINE"), fine],
			player.position + Vector2(0, -60), UIFactory.COL_DANGER)
		AudioManager.play_sfx("crash")
		FeedbackManager.crash()
		_screen_shake(10.0, 0.3)
	# Cop drives off
	if _chase_cop:
		var cop := _chase_cop
		_chase_cop = null
		var tw := cop.create_tween()
		tw.tween_property(cop, "position:y", view_size.y + 160.0, 0.8)
		tw.tween_callback(cop.queue_free)

# ─── Vituo (bus stops) ───────────────────────────────────────────

func _spawn_kituo() -> void:
	var side: int = -1 if randf() < 0.5 else 1
	var lane_idx: int = 0 if side < 0 else num_lanes - 1
	var road_w: float = view_size.x * 0.8
	var lane_w: float = road_w / num_lanes
	var shoulder_x: float = lanes[lane_idx] + side * lane_w * 0.72
	kituo.setup(lane_idx, side, shoulder_x, -140.0, randi_range(2, 5))
	_kituo_warned = false

func _serve_kituo() -> void:
	kituo.served = true
	_kituo_hint_time = 0.0
	var excess: int = max(0, onboard - CAPACITY)
	var normal: int = onboard - excess
	var fare: int = normal * FARE_NORMAL + excess * FARE_OVERLOAD + 2 * _upg_sound
	if onboard > 0:
		coins += fare
		fares_earned += fare
		dropoffs += onboard
		bonus_score += onboard * 60
		_spawn_float_label("%s +%d 🪙" % [LocaleManager.t("FARE"), fare],
			player.position + Vector2(0, -56), UIFactory.COL_ACCENT)
		_burst(kituo.position, UIFactory.COL_ACCENT, 8)
	# Waiting passengers board (only up to comfortable capacity —
	# overloading is the player's own roadside choice)
	var boarded: int = mini(kituo.waiting, CAPACITY)
	onboard = boarded
	passengers += boarded
	if boarded > 0:
		_spawn_float_label("+%d 👤" % boarded,
			kituo.position + Vector2(0, -40), Color("#fab1a0"))
	AudioManager.play_sfx("passenger")
	FeedbackManager.collect()
	_update_handling()
	if dropoffs >= 20:
		AchievementManager.try_unlock("dropoff_20")

## Overload makes the bus heavier to steer and thirstier.
func _update_handling() -> void:
	var excess: int = max(0, onboard - CAPACITY)
	player.lane_switch_time = _base_lane_time * (1.0 + OVERLOAD_HANDLING * excess)

func _overload_excess() -> int:
	return max(0, onboard - CAPACITY)

# ═════════════════════════ SPAWN ══════════════════════════════════

func _spawn_wave() -> void:
	var max_blocked: int = clamp(int(1 + elapsed / 30.0), 1, num_lanes - 1)
	var to_block: int = randi_range(1, max_blocked)
	var blocked_lanes: Array = []
	var free_lane: int = -1
	if to_block == num_lanes - 1:
		# A touch player should never need to cross two lanes between consecutive
		# forced-choice waves. Keep the next safe lane current or adjacent.
		var safe_choices: Array = [_last_safe_lane]
		if _last_safe_lane > 0:
			safe_choices.append(_last_safe_lane - 1)
		if _last_safe_lane < num_lanes - 1:
			safe_choices.append(_last_safe_lane + 1)
		safe_choices.shuffle()
		free_lane = int(safe_choices[0])
		_last_safe_lane = free_lane
		for lane_idx in range(num_lanes):
			if lane_idx != free_lane:
				blocked_lanes.append(lane_idx)
		blocked_lanes.shuffle()
	else:
		var indices: Array = range(num_lanes)
		indices.shuffle()
		for i in range(to_block):
			blocked_lanes.append(indices[i])
		free_lane = int(indices[to_block])

	for lane_idx in blocked_lanes:
		_spawn_obstacle_in_lane(int(lane_idx))
	if free_lane >= 0 and randf() < 0.65:
		# 35% of pickups become a satisfying coin trail down the lane
		if randf() < 0.35:
			_spawn_coin_trail(free_lane)
		else:
			_spawn_collectible_in_lane(free_lane, _pick_collectible_type(false))

func _spawn_coin_trail(lane_idx: int) -> void:
	if not _pickup_corridor_clear(lane_idx, -500.0, -50.0):
		return
	var count: int = randi_range(4, 6)
	for i in range(count):
		if collectibles_free.is_empty():
			return
		var c: Collectible = collectibles_free.pop_back()
		c.setup("coin", lanes[lane_idx], -90.0 - i * 78.0)
		collectibles_active.append(c)

func _spawn_obstacle_in_lane(lane_idx: int) -> void:
	if obstacles_free.is_empty(): return
	var o: Obstacle = obstacles_free.pop_back()
	var t: String = _pick_obstacle_type()
	o.setup(t, lanes[lane_idx], -130.0)
	obstacles_active.append(o)

func _nearest_lane_index(world_x: float) -> int:
	var closest_index: int = 0
	var closest_distance: float = INF
	for i in range(lanes.size()):
		var lane_distance: float = absf(float(lanes[i]) - world_x)
		if lane_distance < closest_distance:
			closest_distance = lane_distance
			closest_index = i
	return closest_index

func _spawn_collectible(t: String) -> void:
	var lane_idx: int = _pick_collectible_lane()
	if lane_idx >= 0:
		_spawn_collectible_in_lane(lane_idx, t)

func _pick_collectible_lane() -> int:
	# A pickup should always look attainable when it enters the road.
	var clear_lanes: Array = []
	const spawn_y := -90.0
	for lane_idx in range(num_lanes):
		var blocked := false
		for candidate in obstacles_active:
			var obstacle: Obstacle = candidate as Obstacle
			if _nearest_lane_index(obstacle.position.x) == lane_idx \
			and absf(obstacle.position.y - spawn_y) < 130.0:
				blocked = true
				break
		if not blocked:
			clear_lanes.append(lane_idx)
	if clear_lanes.is_empty():
		return -1
	return int(clear_lanes[randi() % clear_lanes.size()])

func _spawn_collectible_in_lane(lane_idx: int, t: String) -> void:
	if lane_idx < 0 or lane_idx >= num_lanes or collectibles_free.is_empty():
		return
	if not _pickup_corridor_clear(lane_idx, -150.0, -30.0):
		return
	var c: Collectible = collectibles_free.pop_back()
	c.setup(t, lanes[lane_idx], -90.0)
	collectibles_active.append(c)

func _pickup_corridor_clear(lane_idx: int, top_y: float, bottom_y: float) -> bool:
	for candidate in obstacles_active:
		var obstacle := candidate as Obstacle
		if _nearest_lane_index(obstacle.position.x) != lane_idx:
			continue
		var half_height: float = obstacle.size.y * 0.5 + 36.0
		if obstacle.position.y + half_height >= top_y \
		and obstacle.position.y - half_height <= bottom_y:
			return false
	return true

func _pick_collectible_type(passenger_allowed: bool) -> String:
	var allowed := BASE_COLLECTIBLE_TYPES.duplicate()
	if passenger_allowed:
		allowed.append("passenger")
	var weights: Dictionary = current_route.get("collectible_weights", {})
	return Routes.weighted_pick(weights, allowed, "coin")

func _pick_obstacle_type() -> String:
	var weights: Dictionary = current_route.get("obstacle_weights", {})
	if elapsed < STARTER_WINDOW:
		var starter_types: Array = ["bodaboda", "bajaji", "car", "pothole", "cone", "tire"]
		return Routes.weighted_pick(weights, starter_types, "car")
	return Routes.weighted_pick(weights, OBSTACLE_TYPES, "car")

func _despawn_obstacle(o: Obstacle) -> void:
	o.deactivate()
	obstacles_active.erase(o)
	obstacles_free.append(o)
	near_miss_done.erase(o.get_instance_id())

func _despawn_collectible(c: Collectible) -> void:
	c.deactivate()
	collectibles_active.erase(c)
	collectibles_free.append(c)

# ═════════════════════════ EFFECTS ════════════════════════════════

var _shake_tween: Tween

func _screen_shake(strength: float, duration: float) -> void:
	if reduced_effects:
		return
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	camera.offset = Vector2.ZERO
	_shake_tween = create_tween()
	var steps: int = int(duration / 0.038)
	for _i in range(steps):
		var off := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		_shake_tween.tween_property(camera, "offset", off, 0.038)
	_shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.06)

## Brief slow-motion freeze on crash for impact feel.
func _hit_stop() -> void:
	if reduced_effects:
		return
	Engine.time_scale = 0.2
	var t := get_tree().create_timer(0.09, true, false, true)  # ignores time_scale
	t.timeout.connect(func(): Engine.time_scale = 1.0)

## One-shot particle burst at a world position.
func _burst(world_pos: Vector2, col: Color, amount: int) -> void:
	if reduced_effects:
		amount = mini(amount, 5)
	var p := CPUParticles2D.new()
	p.position = world_pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.45
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 240.0
	p.gravity = Vector2(0, 480)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = col
	entity_layer.add_child(p)
	p.emitting = true
	var t := get_tree().create_timer(0.9)
	t.timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)

func _punch_combo_label() -> void:
	if not combo_label: return
	combo_label.pivot_offset = combo_label.size * 0.5
	combo_label.scale = Vector2(1.35, 1.35)
	var tw := combo_label.create_tween()
	tw.tween_property(combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _spawn_float_label(text: String, world_pos: Vector2, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", col)
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * world_pos
	lbl.position = screen_pos - Vector2(52, 24)
	hud_layer.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 95.0, 0.80)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.80)
	tw.tween_callback(lbl.queue_free)

# ═════════════════════════ INPUT ══════════════════════════════════

func _input(event: InputEvent) -> void:
	if _counting_down or paused or game_over: return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_hud_interaction(event.position):
				swipe_active_id = -1
				return
			swipe_start = event.position
			swipe_active_id = event.index
			swipe_consumed = false
		elif event.index == swipe_active_id:
			swipe_active_id = -1
			swipe_consumed = false
	elif event is InputEventScreenDrag and event.index == swipe_active_id and not swipe_consumed:
		var dx: float = event.position.x - swipe_start.x
		if abs(dx) > swipe_threshold:
			if dx > 0: _move_right()
			else: _move_left()
			swipe_consumed = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_hud_interaction(event.position):
				mouse_swipe_active = false
				return
			swipe_start = event.position
			mouse_swipe_active = true
		else:
			if not mouse_swipe_active:
				return
			mouse_swipe_active = false
			var dx2: float = event.position.x - swipe_start.x
			if abs(dx2) > swipe_threshold:
				if dx2 > 0: _move_right()
				else: _move_left()
	elif event is InputEventKey and not event.echo:
		if event.is_action_pressed("ui_left"):
			_move_left()
		elif event.is_action_pressed("ui_right"):
			_move_right()
		elif event.is_action_pressed("pause_action"):
			_toggle_pause()
		elif event.is_action_pressed("horn_action"):
			_use_horn()

func _is_hud_interaction(screen_position: Vector2) -> bool:
	for control in [pause_btn, btn_left, btn_right, _horn_btn]:
		if is_instance_valid(control) and control.visible and control.get_global_rect().has_point(screen_position):
			return true
	return false

func _move_left() -> void:
	var previous_lane: int = player.current_lane
	player.move_left()
	if player.current_lane == previous_lane:
		return
	_ghost_events.append([elapsed, player.current_lane])
	AudioManager.play_sfx("click")
	FeedbackManager.tap()

func _move_right() -> void:
	var previous_lane: int = player.current_lane
	player.move_right()
	if player.current_lane == previous_lane:
		return
	_ghost_events.append([elapsed, player.current_lane])
	AudioManager.play_sfx("click")
	FeedbackManager.tap()

func _current_score() -> int:
	return int(distance * 0.1) + bonus_score

## Android hardware back button → pause (called by TransitionManager).
func handle_back() -> void:
	if not paused and not game_over and not _counting_down:
		_toggle_pause()
	elif paused:
		_toggle_pause()

# ═════════════════════════ END RUN ════════════════════════════════

func _end_run() -> void:
	if game_over: return
	game_over = true
	AchievementManager.try_unlock("first_run")
	AnalyticsService.log_event("run_end", {
		"score": _current_score(),
		"coins": coins,
		"dropoffs": dropoffs,
		"route": String(current_route.id),
		"condition": condition,
		"continued": _was_continued,
	})
	# Save ghost of best fresh (non-continued) run
	if not _was_continued:
		var score_now: int = _current_score()
		var best: Variant = SaveSystem.get_value("ghost_best", null)
		if typeof(best) != TYPE_DICTIONARY or score_now > int((best as Dictionary).get("score", 0)):
			SaveSystem.set_value("ghost_best", {
				"events": _ghost_events,
				"end": elapsed,
				"score": score_now,
				"name": "MIMI",
			})
	GameState.record_run(_current_score(), coins, passengers, distance, _run_near_misses, {
		"dropoffs": dropoffs,
		"fares": fares_earned,
		"onboard": onboard,
		"fuel": fuel,
		"elapsed": elapsed,
		"horn_uses": _total_horn_uses,
		"boosts": _total_boost_uses,
		"horn_charges": horn_charges,
		"max_horn_charges": max_horn_charges,
		"horn_regen_timer": horn_regen_timer,
		"fuel_drain_mult": fuel_drain_mult,
		"condition": condition,
		"rush_hour": rush_hour,
	})
	await get_tree().create_timer(0.55).timeout
	TransitionManager.go_to("res://scenes/game_over.tscn")

# ══════════════════════ Inner draw helpers ═════════════════════════

## Translucent rival/own-best ghost bus.
class _GhostBus extends Node2D:
	func _draw() -> void:
		var s := Vector2(72, 110)
		LiveryLib.draw_bus(self, -s * 0.5, s,
			Color("#9aa3b2"), Color("#dfe6e9"), "none", "")

## Pursuing traffic-police car shown during chase events.
class _ChaseCop extends Node2D:
	var _t: float = 0.0
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var s := Vector2(72, 104)
		var tl := -s * 0.5
		draw_rect(Rect2(tl + Vector2(4, 7), s), Color(0.02, 0.03, 0.04, 0.30), true)
		for wheel_y in [tl.y + 17.0, tl.y + s.y - 37.0]:
			draw_rect(Rect2(Vector2(tl.x - 4, wheel_y), Vector2(8, 21)), Color("#15191d"), true)
			draw_rect(Rect2(Vector2(tl.x + s.x - 4, wheel_y), Vector2(8, 21)), Color("#15191d"), true)
		var shell := PackedVector2Array([
			Vector2(tl.x + 8, tl.y), Vector2(tl.x + s.x - 8, tl.y),
			Vector2(tl.x + s.x, tl.y + 10), Vector2(tl.x + s.x, tl.y + s.y - 11),
			Vector2(tl.x + s.x - 8, tl.y + s.y), Vector2(tl.x + 8, tl.y + s.y),
			Vector2(tl.x, tl.y + s.y - 11), Vector2(tl.x, tl.y + 10),
		])
		draw_colored_polygon(shell, Color("#1f4e79"))
		draw_rect(Rect2(tl + Vector2(10, 18), Vector2(s.x - 20, 20)), Color("#8fd3e8"), true)
		draw_rect(Rect2(tl + Vector2(10, 51), Vector2(s.x - 20, 20)), Color("#8fd3e8"), true)
		draw_line(Vector2(0, tl.y + 19), Vector2(0, tl.y + 70), Color("#405f75"), 2.0)
		draw_rect(Rect2(Vector2(tl.x + 1, tl.y + 43), Vector2(s.x - 2, 10)), Color.WHITE, true)
		# Flashing light bar
		var phase: bool = fmod(_t * 5.0, 1.0) > 0.5
		draw_rect(Rect2(tl + Vector2(s.x * 0.18, 40), Vector2(s.x * 0.3, 8)),
			Color("#e74c3c") if phase else Color("#7f1d1d"))
		draw_rect(Rect2(tl + Vector2(s.x * 0.52, 40), Vector2(s.x * 0.3, 8)),
			Color("#1f8fff") if phase else Color("#0a3d62"))
		for light_x in [tl.x + 9.0, tl.x + s.x - 17.0]:
			draw_rect(Rect2(Vector2(light_x, tl.y + s.y - 8), Vector2(8, 5)), Color("#fff3a6"), true)

## Headlight cones drawn in front of the player's bus on night runs.
class _Headlights extends Node2D:
	func _ready() -> void:
		z_index = -1  # behind the bus body
	func _draw() -> void:
		for hx in [-22.0, 22.0]:
			var pts := PackedVector2Array([
				Vector2(hx, -50),
				Vector2(hx - 26, -240),
				Vector2(hx + 26, -240),
			])
			draw_polygon(pts, PackedColorArray([
				Color(1.0, 0.97, 0.75, 0.30),
				Color(1.0, 0.97, 0.75, 0.0),
				Color(1.0, 0.97, 0.75, 0.0),
			]))

## Consistent vector icons for HUD stats and active power-ups.
class _GameIcon extends Control:
	enum IconKind { COIN, PASSENGER, FUEL, SHIELD, MAGNET, SLOW, BOOST }
	var icon_kind: IconKind = IconKind.COIN
	var tint: Color = Color.WHITE
	var active: bool = true

	func _draw() -> void:
		var color := tint if active else Color(0.38, 0.44, 0.49, 0.72)
		var c := size * 0.5
		var scale_factor: float = minf(size.x, size.y) / 24.0
		match icon_kind:
			IconKind.COIN:
				draw_circle(c, 9.0 * scale_factor, color)
				draw_arc(c, 6.0 * scale_factor, 0.0, TAU, 20, color.darkened(0.32), 2.0 * scale_factor, true)
				draw_line(c + Vector2(0, -4) * scale_factor, c + Vector2(0, 4) * scale_factor,
					color.lightened(0.36), 1.6 * scale_factor, true)
			IconKind.PASSENGER:
				draw_circle(c + Vector2(0, -5) * scale_factor, 4.2 * scale_factor, color)
				draw_arc(c + Vector2(0, 8) * scale_factor, 8.0 * scale_factor, PI, TAU,
					18, color, 5.0 * scale_factor, true)
			IconKind.FUEL:
				draw_rect(Rect2(c + Vector2(-7, -8) * scale_factor, Vector2(13, 17) * scale_factor), color, true)
				draw_rect(Rect2(c + Vector2(-3, -5) * scale_factor, Vector2(6, 4) * scale_factor),
					Color(0.95, 0.97, 0.98, 0.9), true)
				draw_line(c + Vector2(6, -5) * scale_factor, c + Vector2(9, -2) * scale_factor,
					color, 2.5 * scale_factor, true)
			IconKind.SHIELD:
				var shield := PackedVector2Array([
					c + Vector2(0, -10) * scale_factor, c + Vector2(9, -6) * scale_factor,
					c + Vector2(7, 5) * scale_factor, c + Vector2(0, 11) * scale_factor,
					c + Vector2(-7, 5) * scale_factor, c + Vector2(-9, -6) * scale_factor,
				])
				draw_colored_polygon(shield, color)
				draw_polyline(PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[5], shield[0]]),
					color.lightened(0.35), 1.5 * scale_factor, true)
			IconKind.MAGNET:
				draw_arc(c + Vector2(0, 1) * scale_factor, 8.0 * scale_factor, 0.0, PI,
					20, color, 5.0 * scale_factor, true)
				draw_line(c + Vector2(-8, 1) * scale_factor, c + Vector2(-8, -8) * scale_factor,
					color, 5.0 * scale_factor, true)
				draw_line(c + Vector2(8, 1) * scale_factor, c + Vector2(8, -8) * scale_factor,
					color, 5.0 * scale_factor, true)
				draw_line(c + Vector2(-10, -8) * scale_factor, c + Vector2(-6, -8) * scale_factor,
					Color.WHITE, 3.0 * scale_factor, true)
				draw_line(c + Vector2(6, -8) * scale_factor, c + Vector2(10, -8) * scale_factor,
					Color.WHITE, 3.0 * scale_factor, true)
			IconKind.SLOW:
				for angle in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
					var arm := Vector2(cos(angle), sin(angle)) * 10.0 * scale_factor
					draw_line(c - arm, c + arm, color, 2.2 * scale_factor, true)
				draw_circle(c, 2.8 * scale_factor, Color.WHITE)
			IconKind.BOOST:
				var bolt := PackedVector2Array([
					c + Vector2(2, -11) * scale_factor, c + Vector2(-8, 2) * scale_factor,
					c + Vector2(-1, 2) * scale_factor, c + Vector2(-4, 11) * scale_factor,
					c + Vector2(9, -4) * scale_factor, c + Vector2(2, -4) * scale_factor,
				])
				draw_colored_polygon(bolt, color)

## Font-independent driving control with built-in horn charge display.
class _DriveButton extends Button:
	enum IconKind { LEFT, HORN, RIGHT }
	var icon_kind: IconKind = IconKind.LEFT
	var charge_count: int = 0
	var charge_capacity: int = 0

	func _draw() -> void:
		var icon_color := Color("#f4f8fb") if not disabled else Color(0.56, 0.61, 0.66, 0.78)
		var center := Vector2(size.x * 0.5, size.y * 0.45)
		if icon_kind == IconKind.HORN:
			_draw_horn(center, icon_color)
			_draw_charges(icon_color)
		else:
			_draw_arrow(center, -1.0 if icon_kind == IconKind.LEFT else 1.0, icon_color)

	func _draw_arrow(center: Vector2, direction: float, color: Color) -> void:
		var tip := center + Vector2(25.0 * direction, 0.0)
		var inner_x := center.x - 2.0 * direction
		var points := PackedVector2Array([
			tip,
			Vector2(inner_x, center.y - 23.0),
			Vector2(inner_x, center.y - 9.0),
			Vector2(center.x - 27.0 * direction, center.y - 9.0),
			Vector2(center.x - 27.0 * direction, center.y + 9.0),
			Vector2(inner_x, center.y + 9.0),
			Vector2(inner_x, center.y + 23.0),
		])
		draw_colored_polygon(points, color)

	func _draw_horn(center: Vector2, color: Color) -> void:
		var c := center + Vector2(-3.0, -2.0)
		var body := PackedVector2Array([
			c + Vector2(-27.0, -8.0),
			c + Vector2(-10.0, -8.0),
			c + Vector2(12.0, -22.0),
			c + Vector2(12.0, 22.0),
			c + Vector2(-10.0, 8.0),
			c + Vector2(-27.0, 8.0),
		])
		draw_colored_polygon(body, color)
		draw_line(c + Vector2(-12.0, 9.0), c + Vector2(-7.0, 23.0), color, 6.0, true)
		draw_arc(c + Vector2(12.0, 0.0), 13.0, -0.72, 0.72, 12, color, 3.0, true)
		draw_arc(c + Vector2(12.0, 0.0), 22.0, -0.62, 0.62, 12, color, 3.0, true)

	func _draw_charges(color: Color) -> void:
		if charge_capacity <= 0:
			return
		var spacing := 13.0
		var start_x := size.x * 0.5 - spacing * float(charge_capacity - 1) * 0.5
		for i in range(charge_capacity):
			var dot_color := color if i < charge_count else Color(0.28, 0.32, 0.36, 0.92)
			draw_circle(Vector2(start_x + float(i) * spacing, size.y - 10.0), 3.5, dot_color)

## Flashing downward triangle shown at top of lane when obstacle is spawning.
class _LaneWarning extends Control:
	var _t: float = 0.0
	var _on: bool = false
	func flash(duration: float = 0.52) -> void:
		_t = duration
		_on = true
		queue_redraw()
	func _process(delta: float) -> void:
		if _t <= 0.0: return
		_t -= delta
		_on = fmod(_t * 7.0, 1.0) > 0.45
		queue_redraw()
		if _t <= 0.0:
			_on = false
			queue_redraw()
	func _draw() -> void:
		if not _on: return
		var pts := PackedVector2Array([
			Vector2(size.x * 0.5, size.y),
			Vector2(0, 0),
			Vector2(size.x, 0),
		])
		draw_polygon(pts, PackedColorArray([Color("#e74c3c"), Color("#e74c3c"), Color("#e74c3c")]))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color.WHITE, 1.5)
