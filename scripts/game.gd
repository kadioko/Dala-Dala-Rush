extends Node2D
## Main game loop — full feature set:
##   3-2-1-GO countdown  •  Horn mechanic (3 charges)  •  Lane warning arrows
##   Camera shake  •  Floating labels  •  Speed lines  •  Fuel meter
##   Combo multiplier  •  Power-up HUD bars  •  Achievement triggers

const PlayerCls     := preload("res://scripts/entities/player.gd")
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
const POOL_COL := 16

# ── Run state ─────────────────────────────────────────────────────
var base_speed: float = 340.0
var speed: float = 340.0
var distance: float = 0.0
var coins: int = 0
var passengers: int = 0
var elapsed: float = 0.0
var spawn_timer: float = 0.0
var passenger_timer: float = 0.0
var difficulty_mult: float = 1.0
var current_route: Dictionary = {}
var current_vehicle: Dictionary = {}
var spawn_interval_mult: float = 1.0
var fuel_drain_mult: float = 1.0
var coin_mult: float = 1.0
var paused: bool = false
var game_over: bool = false
var near_miss_done: Dictionary = {}

# ── Power-ups ─────────────────────────────────────────────────────
var shield_active: bool = false
var magnet_time: float = 0.0
var slow_time: float = 0.0
const MAGNET_MAX := 6.0
const SLOW_MAX   := 4.0

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
var _horn_dots: Array = []
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
var shield_icon: Label
var pause_overlay: Control
var near_miss_flash: ColorRect

const OBSTACLE_TYPES := [
	"bodaboda","bajaji","car","pothole","cone",
	"police","barrier","truck","pedestrian","tire"
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

	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	road = RoadCls.new()
	road.setup(view_size, current_route.sky, current_route.road, current_route.id)
	add_child(road)

	entity_layer = Node2D.new()
	add_child(entity_layer)

	speed_lines = SpeedLinesCls.new()
	speed_lines.setup(view_size)
	entity_layer.add_child(speed_lines)

	current_vehicle = Vehicles.get_by_id(GameState.selected_vehicle_id)
	fuel_drain_mult = float(current_vehicle.get("fuel_drain_mult", 1.0))
	coin_mult = float(current_vehicle.get("coin_mult", 1.0))
	max_horn_charges = int(current_vehicle.get("horn_charges", 3))
	horn_charges = max_horn_charges

	player = PlayerCls.new()
	entity_layer.add_child(player)
	player.setup(lanes, current_vehicle)
	player.position.y = view_size.y - 160

	_build_pools()
	_build_hud()
	_build_pause_overlay()
	_build_countdown()

	speed = base_speed * difficulty_mult
	set_process(true)
	set_process_input(true)

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
	_countdown_bg.color = Color(0, 0, 0, 0.55)
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

	_show_countdown_num(3)

func _show_countdown_num(n: int) -> void:
	if n <= 0:
		_countdown_label.text = LocaleManager.t("GO_TEXT")
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
	var top := HBoxContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 60
	top.offset_top = 12
	top.offset_right = -12
	top.add_theme_constant_override("separation", 10)
	hud_layer.add_child(top)

	score_label = UIFactory.make_label("0", 30, UIFactory.COL_ACCENT)
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(score_label)

	coins_label = UIFactory.make_label("", 18, UIFactory.COL_ACCENT)
	top.add_child(coins_label)
	pass_label = UIFactory.make_label("", 18, UIFactory.COL_TEXT)
	top.add_child(pass_label)

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
	status_label.offset_top = 70
	hud_layer.add_child(status_label)

	# Combo label
	combo_label = UIFactory.make_label("", 28, UIFactory.COL_ACCENT)
	combo_label.anchor_left = 0.5
	combo_label.anchor_right = 0.5
	combo_label.offset_left = -120
	combo_label.offset_right = 120
	combo_label.offset_top = 100
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

	var fuel_icon := UIFactory.make_label("⛽", 14, UIFactory.COL_MUTED)
	fuel_icon.anchor_top = 0.74
	fuel_icon.offset_left = 4
	fuel_icon.offset_right = 36
	fuel_icon.offset_top = 3
	hud_layer.add_child(fuel_icon)

	# Power-up row (above horn/lane buttons)
	var powerup_row := HBoxContainer.new()
	powerup_row.anchor_left = 0.5
	powerup_row.anchor_right = 0.5
	powerup_row.anchor_top = 1.0
	powerup_row.anchor_bottom = 1.0
	powerup_row.offset_left = -140
	powerup_row.offset_right = 140
	powerup_row.offset_top = -190
	powerup_row.offset_bottom = -155
	powerup_row.add_theme_constant_override("separation", 8)
	hud_layer.add_child(powerup_row)

	shield_icon = _make_powerup_badge("★ ", UIFactory.COL_MUTED)
	powerup_row.add_child(shield_icon)

	var mc := _powerup_col("🧲", Color("#a55eea"))
	magnet_bar = mc[1] as ProgressBar
	powerup_row.add_child(mc[0])

	var sc := _powerup_col("❄", Color("#74b9ff"))
	slow_bar = sc[1] as ProgressBar
	powerup_row.add_child(sc[0])

	# ── Horn charges row ──────────────────────────────────────────
	var horn_row := HBoxContainer.new()
	horn_row.anchor_left = 0.5
	horn_row.anchor_right = 0.5
	horn_row.anchor_top = 1.0
	horn_row.anchor_bottom = 1.0
	horn_row.offset_left = -56
	horn_row.offset_right = 56
	horn_row.offset_top = -148
	horn_row.offset_bottom = -120
	horn_row.add_theme_constant_override("separation", 6)
	hud_layer.add_child(horn_row)

	for i in range(max_horn_charges):
		var dot := _HornDot.new()
		dot.custom_minimum_size = Vector2(22, 22)
		horn_row.add_child(dot)
		_horn_dots.append(dot)

	# ── Lane warning triangles ─────────────────────────────────────
	for i in range(num_lanes):
		var w := _LaneWarning.new()
		w.custom_minimum_size = Vector2(40, 40)
		w.position = Vector2(lanes[i] - 20, 124)
		hud_layer.add_child(w)
		_lane_warnings.append(w)

	# ── Lane tap buttons ──────────────────────────────────────────
	btn_left = UIFactory.make_button("◀", false)
	btn_left.anchor_left = 0.0;   btn_left.anchor_right = 0.0
	btn_left.anchor_top = 1.0;    btn_left.anchor_bottom = 1.0
	btn_left.offset_left = 16;    btn_left.offset_right = 116
	btn_left.offset_top = -110;   btn_left.offset_bottom = -32
	btn_left.modulate.a = 0.65
	btn_left.pressed.connect(_move_left)
	hud_layer.add_child(btn_left)

	# Horn button (centre)
	_horn_btn = UIFactory.make_button(LocaleManager.t("HORN_BTN"), false)
	_horn_btn.anchor_left = 0.5;  _horn_btn.anchor_right = 0.5
	_horn_btn.anchor_top = 1.0;   _horn_btn.anchor_bottom = 1.0
	_horn_btn.offset_left = -44;  _horn_btn.offset_right = 44
	_horn_btn.offset_top = -110;  _horn_btn.offset_bottom = -32
	_horn_btn.modulate.a = 0.7
	_horn_btn.pressed.connect(_use_horn)
	hud_layer.add_child(_horn_btn)

	btn_right = UIFactory.make_button("▶", false)
	btn_right.anchor_left = 1.0;  btn_right.anchor_right = 1.0
	btn_right.anchor_top = 1.0;   btn_right.anchor_bottom = 1.0
	btn_right.offset_left = -116; btn_right.offset_right = -16
	btn_right.offset_top = -110;  btn_right.offset_bottom = -32
	btn_right.modulate.a = 0.65
	btn_right.pressed.connect(_move_right)
	hud_layer.add_child(btn_right)

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

func _make_powerup_badge(text: String, col: Color) -> Label:
	var l := UIFactory.make_label(text, 20, col)
	l.custom_minimum_size = Vector2(40, 32)
	return l

func _powerup_col(icon: String, col: Color) -> Array:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.custom_minimum_size = Vector2(58, 0)
	var lbl := UIFactory.make_label(icon, 16, col)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lbl)
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

	var mb := UIFactory.make_button(LocaleManager.t("MAIN_MENU"), false)
	mb.pressed.connect(func(): TransitionManager.go_to("res://scenes/main_menu.tscn"))
	v.add_child(mb)

func _toggle_pause() -> void:
	if game_over or _counting_down: return
	paused = not paused
	pause_overlay.visible = paused
	AudioManager.play_sfx("click")

# ═════════════════════════ HUD UPDATE ═════════════════════════════

func _update_hud() -> void:
	score_label.text = "%d" % int(distance * 0.1)
	coins_label.text = "🪙 %d" % coins
	pass_label.text  = "👤 %d" % passengers

	fuel_bar.value = fuel
	if fuel < FUEL_LOW_THRESHOLD * 0.5:
		_style_bar(fuel_bar, Color("#e74c3c"))
	elif fuel < FUEL_LOW_THRESHOLD:
		_style_bar(fuel_bar, Color("#f1c40f"))
	else:
		_style_bar(fuel_bar, Color("#2ecc71"))

	shield_icon.modulate = UIFactory.COL_ACCENT if shield_active else UIFactory.COL_MUTED
	shield_icon.text = "★ %s" % (LocaleManager.t("SHIELD_ON") if shield_active else "  ")
	magnet_bar.value = magnet_time / MAGNET_MAX
	slow_bar.value   = slow_time   / SLOW_MAX

	if combo >= 2:
		combo_label.text = "x%d!" % combo
		combo_label.visible = true
	else:
		combo_label.visible = false

	# Horn dots
	for i in range(_horn_dots.size()):
		(_horn_dots[i] as _HornDot).filled = (i < horn_charges)
		(_horn_dots[i] as _HornDot).queue_redraw()

func _update_status() -> void:
	var sc: int = int(distance * 0.1)
	if fuel < FUEL_LOW_THRESHOLD * 0.5:
		status_label.text = LocaleManager.t("FUEL_LOW")
		status_label.add_theme_color_override("font_color", Color("#e74c3c"))
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
	if _counting_down or paused or game_over:
		return

	elapsed += delta
	var ramps: int = int(elapsed / 20.0)
	speed = base_speed * difficulty_mult * (1.0 + 0.15 * ramps)
	speed_lines.speed_ref = speed

	if magnet_time > 0: magnet_time = max(0.0, magnet_time - delta)
	if slow_time  > 0: slow_time   = max(0.0, slow_time  - delta)

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

	# Fuel
	fuel -= FUEL_DRAIN * fuel_drain_mult * delta * (0.65 if slow_time > 0.0 else 1.0)
	fuel = max(0.0, fuel)
	if fuel <= 0.0:
		_spawn_float_label(LocaleManager.t("FUEL_EMPTY"), player.position, Color("#e74c3c"))
		_end_run()
		return

	var move: float = speed * delta * (0.5 if slow_time > 0.0 else 1.0)
	distance += move

	road.advance(move)
	speed_lines.advance(move)
	_move_entities(move, delta)
	_check_collisions()
	_update_status()
	_update_hud()

	# Shield pulse
	player.modulate.a = 0.62 + 0.38 * abs(sin(elapsed * 9.0)) if shield_active else 1.0

	# Achievement distance / score checks
	if distance >= 1000.0 and not _ach_1km_done:
		_ach_1km_done = true
		AchievementManager.try_unlock("dist_1km")
	var sc: int = int(distance * 0.1)
	if sc >= 1000 and not _ach_s1000_done:
		_ach_s1000_done = true
		AchievementManager.try_unlock("score_1000")
	if sc >= 5000 and not _ach_s5000_done:
		_ach_s5000_done = true
		AchievementManager.try_unlock("score_5000")

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var interval: float = max(0.55, 1.75 - elapsed * 0.014) * spawn_interval_mult / difficulty_mult
		spawn_timer = interval
		_spawn_wave()

	passenger_timer -= delta
	if passenger_timer <= 0.0:
		passenger_timer = randf_range(4.2, 7.2)
		_spawn_collectible(_pick_collectible_type(true))

# ═════════════════════════ ENTITIES ═══════════════════════════════

func _move_entities(move: float, delta: float) -> void:
	for o in obstacles_active.duplicate():
		o.position.y += move
		if o.position.y > view_size.y + 140:
			_despawn_obstacle(o)
	for c in collectibles_active.duplicate():
		c.position.y += move
		if magnet_time > 0.0:
			var dx: float = player.position.x - c.position.x
			c.position.x += sign(dx) * min(abs(dx), 380.0 * delta)
		if c.position.y > view_size.y + 140:
			_despawn_collectible(c)

func _check_collisions() -> void:
	var prect: Rect2 = player.get_aabb()
	for o in obstacles_active.duplicate():
		var orect: Rect2 = o.get_aabb()
		if not near_miss_done.get(o.get_instance_id(), false) and o.position.y > player.position.y + 20:
			var h_gap: float = abs(o.position.x - player.position.x)
			if h_gap < 92.0 and not prect.intersects(orect):
				near_miss_done[o.get_instance_id()] = true
				distance += 80.0
				_on_near_miss(o.position)
		if prect.intersects(orect):
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
			if coins >= 50: AchievementManager.try_unlock("coins_50")
			if combo >= 5:  AchievementManager.try_unlock("combo_5")
		"passenger":
			passengers += 1
			distance += 200.0
			bonus_text = "+200"
			label_col = Color("#fab1a0")
			AudioManager.play_sfx("passenger")
			FeedbackManager.collect()
			if passengers >= 10: AchievementManager.try_unlock("pass_10")
		"fuel":
			fuel = min(1.0, fuel + FUEL_RESTORE)
			distance += 300.0
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
			distance += 400.0
			bonus_text = "+400"
			label_col = Color("#2ecc71")
			AudioManager.play_sfx("powerup")
			FeedbackManager.powerup()
		"slow":
			slow_time = SLOW_MAX
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
		near_miss_flash.color = Color(1.0, 0.9, 0.1, 0.38)
		var tw := near_miss_flash.create_tween()
		tw.tween_property(near_miss_flash, "color:a", 0.0, 0.30)
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
		_spawn_float_label("PEMBE! 📯", nearest.position, Color("#ffd23f"))
		# Shrink-out animation
		var tw := nearest.create_tween()
		tw.tween_property(nearest, "scale", Vector2(0.0, 0.0), 0.22).set_trans(Tween.TRANS_BACK)
		tw.tween_callback(func():
			if is_instance_valid(nearest):
				nearest.scale = Vector2.ONE
				_despawn_obstacle(nearest)
		)

# ═════════════════════════ SPAWN ══════════════════════════════════

func _spawn_wave() -> void:
	var max_blocked: int = clamp(int(1 + elapsed / 30.0), 1, num_lanes - 1)
	var to_block: int = randi_range(1, max_blocked)
	var indices: Array = range(num_lanes)
	indices.shuffle()
	for i in range(to_block):
		_spawn_obstacle_in_lane(indices[i])
	if to_block < num_lanes and randf() < 0.65:
		_spawn_collectible_in_lane(indices[to_block], _pick_collectible_type(false))

func _spawn_obstacle_in_lane(lane_idx: int) -> void:
	if obstacles_free.is_empty(): return
	var o: Obstacle = obstacles_free.pop_back()
	var t: String = _pick_obstacle_type()
	o.setup(t, lanes[lane_idx], -130.0)
	obstacles_active.append(o)
	# Flash lane warning
	if lane_idx < _lane_warnings.size():
		(_lane_warnings[lane_idx] as _LaneWarning).flash()

func _spawn_collectible(t: String) -> void:
	_spawn_collectible_in_lane(randi() % num_lanes, t)

func _spawn_collectible_in_lane(lane_idx: int, t: String) -> void:
	if collectibles_free.is_empty(): return
	var c: Collectible = collectibles_free.pop_back()
	c.setup(t, lanes[lane_idx], -90.0)
	collectibles_active.append(c)

func _pick_collectible_type(passenger_allowed: bool) -> String:
	var allowed := BASE_COLLECTIBLE_TYPES.duplicate()
	if passenger_allowed:
		allowed.append("passenger")
	var weights: Dictionary = current_route.get("collectible_weights", {})
	return Routes.weighted_pick(weights, allowed, "coin")

func _pick_obstacle_type() -> String:
	var weights: Dictionary = current_route.get("obstacle_weights", {})
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

func _screen_shake(strength: float, duration: float) -> void:
	var tw := create_tween()
	var steps: int = int(duration / 0.038)
	for _i in range(steps):
		var off := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tw.tween_property(camera, "offset", off, 0.038)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.06)

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
			swipe_start = event.position
			swipe_active_id = event.index
		elif event.index == swipe_active_id:
			swipe_active_id = -1
	elif event is InputEventScreenDrag and event.index == swipe_active_id:
		var dx: float = event.position.x - swipe_start.x
		if abs(dx) > swipe_threshold:
			if dx > 0: _move_right()
			else: _move_left()
			swipe_start = event.position
	elif event is InputEventMouseButton:
		if event.pressed: swipe_start = event.position
		else:
			var dx2: float = event.position.x - swipe_start.x
			if abs(dx2) > swipe_threshold:
				if dx2 > 0: _move_right()
				else: _move_left()
	elif event.is_action_pressed("ui_left"):        _move_left()
	elif event.is_action_pressed("ui_right"):       _move_right()
	elif event.is_action_pressed("pause_action"):   _toggle_pause()

func _move_left() -> void:
	player.move_left()
	AudioManager.play_sfx("click")
	FeedbackManager.tap()

func _move_right() -> void:
	player.move_right()
	AudioManager.play_sfx("click")
	FeedbackManager.tap()

# ═════════════════════════ END RUN ════════════════════════════════

func _end_run() -> void:
	if game_over: return
	game_over = true
	AchievementManager.try_unlock("first_run")
	GameState.record_run(int(distance * 0.1), coins, passengers, distance, _run_near_misses)
	await get_tree().create_timer(0.55).timeout
	TransitionManager.go_to("res://scenes/game_over.tscn")

# ══════════════════════ Inner draw helpers ═════════════════════════

## Coloured dot representing one horn charge.
class _HornDot extends Control:
	var filled: bool = true
	func _draw() -> void:
		var r: float = min(size.x, size.y) * 0.44
		var c: Vector2 = size * 0.5
		draw_circle(c, r, Color("#e67e22") if filled else Color(0.3, 0.3, 0.3, 0.5))

## Flashing downward triangle shown at top of lane when obstacle is spawning.
class _LaneWarning extends Control:
	var _t: float = 0.0
	var _on: bool = false
	func flash() -> void:
		_t = 0.52
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
