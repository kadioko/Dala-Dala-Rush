extends Node

const Atomic := preload("res://scripts/atomic_json.gd")
const Online := preload("res://autoload/online_service.gd")
const Save := preload("res://autoload/save_system.gd")
const PlayerScript := preload("res://scripts/entities/player.gd")
const Ads := preload("res://autoload/ad_service.gd")
const CollisionChecks := preload("res://data/collision_math.gd")
const Game := preload("res://scripts/game.gd")
const Ids := preload("res://data/operation_ids.gd")
var _failures: Array[String] = []
var _profile: Dictionary
var _depth: int
var _dirty: bool
var _events: Array

class FakeAd extends RefCounted:
	var full_screen_content_callback: Variant
	func destroy() -> void:
		pass

class FakeAdService extends Ads:
	var reload_count: int = 0
	func _plugin_load_rewarded() -> void:
		reload_count += 1

class CollisionGame extends Game:
	var contacts: int = 0
	var pickups: int = 0
	func _on_hit(obstacle: Obstacle) -> void:
		contacts += 1
		_despawn_obstacle(obstacle)
	func _on_collect(collectible: Collectible) -> void:
		pickups += 1
		_despawn_collectible(collectible)

func _ready() -> void:
	_profile = SaveSystem.data.duplicate(true)
	_depth = SaveSystem._batch_depth
	_dirty = SaveSystem._batch_dirty
	_events = AnalyticsService._queue.duplicate(true)
	SaveSystem.data = Save.DEFAULTS.duplicate(true)
	SaveSystem._batch_depth += 1
	_run.call_deferred()

func _run() -> void:
	_check_atomic_storage()
	_check_cloud_retries()
	_check_tutorial_attempts()
	_check_sweeps()
	_check_prior_saves()
	await _check_crossed_entities()
	await _check_ads()
	await _check_steering()
	SaveSystem.data = _profile
	SaveSystem._batch_depth = _depth
	SaveSystem._batch_dirty = _dirty
	AnalyticsService._queue = _events
	AnalyticsService._save_log()
	for failure in _failures:
		push_error("RECOVERY: " + failure)
	print("RECOVERY CONTRACTS: " + ("PASS" if _failures.is_empty() else "FAIL"))
	get_tree().quit(0 if _failures.is_empty() else 1)

func _check(value: bool, message: String) -> void:
	if not value:
		_failures.append(message)

func _read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _check_atomic_storage() -> void:
	var directory := "user://recovery_contracts"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var primary := directory + "/save.json"
	var backup := directory + "/save.bak"
	_check(Atomic.write(primary, {"coins": 10}) == OK, "First save must be complete")
	_check(Atomic.write(primary, {"coins": 20}, backup) == OK, "Replacement must succeed")
	_check(int(_read_json(primary).coins) == 20 and int(_read_json(backup).coins) == 10,
		"Primary and last good backup must retain different generations")
	var failed: Error = Atomic.write(primary, {"coins": 30}, directory + "/missing/backup.json")
	_check(failed != OK and int(_read_json(primary).coins) == 20,
		"A failed backup copy must preserve the complete primary")
	for filename in [primary, primary + ".tmp", backup, backup + ".tmp"]:
		if FileAccess.file_exists(filename):
			DirAccess.remove_absolute(filename)

func _check_cloud_retries() -> void:
	var pending := Online.prepare_cloud_upload({"total_coins": 10}, {}, 4)
	var retry := Online.prepare_cloud_upload({"total_coins": 20}, pending, 4)
	_check(retry == pending and Ids.is_valid(retry.operationId), "An interrupted upload must retain its ID and immutable body")
	_check(int(retry.baseRevision) == 4 and int(retry.revision) == 5, "Cloud writes must carry an explicit base revision")
	_check(not Online.valid_response("registration", {}) and not Online.valid_response("cloud_download", {"revision": 1}),
		"Malformed successful responses must not alter local identity or progress")
	_check(not Online.valid_response("account_delete", {"deleted": false}), "Deletion must require an explicit acknowledgement")
	var service := Online.new()
	var snapshot: Dictionary = service.cloud_snapshot({"total_coins": 100, "upg_engine": 2,
		"season_xp": 1200, "ghost_on": false, "livery_classic_blue": {"body": "123456"},
		"online_pending_cloud_upload": pending, "unknown_secret": "private"})
	_check(snapshot.has("upg_engine") and snapshot.has("season_xp") and snapshot.get("ghost_on") == false and snapshot.has("livery_classic_blue")
		and not snapshot.has("online_pending_cloud_upload") and not snapshot.has("unknown_secret"),
		"Cloud backups must preserve career/livery progress and exclude pending/private values")
	SaveSystem.data["online_pending_cloud_upload"] = {"conflict_revision": 6}
	_check(service.apply_cloud_snapshot({"revision": 6, "save": {"total_coins": 145,
		"upg_engine": 2, "ghost_on": false}})
		and SaveSystem.get_value("online_pending_cloud_upload", {}).is_empty()
		and SaveSystem.get_value("upg_engine", 0) == 2
		and SaveSystem.get_value("ghost_on", true) == false,
		"Confirmed restoration must clear the obsolete pending conflict and restore upgrades/preferences")
	service.free()

func _check_crossed_entities() -> void:
	var game := CollisionGame.new()
	add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.grace_time = 0.0
	game.boost_time = 0.0
	var barrier: Obstacle = game.obstacles_free.pop_back()
	barrier.setup("barrier", game.player.position.x, game.player.position.y - 200.0)
	barrier.warning_announced = true
	game.obstacles_active.append(barrier)
	var coin: Collectible = game.collectibles_free.pop_back()
	coin.setup("coin", game.player.position.x, game.player.position.y - 100.0)
	game.collectibles_active.append(coin)
	game._previous_entity_rects[barrier.get_instance_id()] = barrier.get_collision_aabb()
	game._previous_entity_rects[coin.get_instance_id()] = coin.get_aabb()
	game._previous_player_rect = game.player.get_collision_aabb()
	game._move_entities(1500.0, 0.5)
	_check(barrier in game.obstacles_active and coin in game.collectibles_active,
		"Offscreen objects must stay active until their crossed paths have been checked")
	game._check_collisions()
	game._check_collisions()
	game._cleanup_passed_entities()
	_check(game.contacts == 1 and game.pickups == 1,
		"The live entity pipeline must detect one crossed barrier and collect one crossed coin")
	game.queue_free()
	await get_tree().process_frame

func _check_tutorial_attempts() -> void:
	SaveSystem.data["first_session_stage"] = 0
	SaveSystem.data["regular_runs"] = 1
	SaveSystem.data["tutorial_started"] = true
	GameState.complete_tutorial_stage(1, 0)
	_check(GameState.tutorial_stage_for_run() == 1, "Crashing before the lesson is complete must repeat it")
	GameState.complete_tutorial_stage(1, 1)
	_check(GameState.tutorial_stage_for_run() == 1, "A partial lesson must not unlock the next stage")
	GameState.complete_tutorial_stage(1, 2)
	_check(GameState.tutorial_stage_for_run() == 2, "Performing both lesson steps must unlock the next stage")
	GameState.skip_tutorials()
	_check(GameState.tutorial_stage_for_run() == 0, "An explicit skip must persist")

func _check_sweeps() -> void:
	var player_rect := Rect2(100, 200, 56, 92)
	var before := Rect2(100, 0, 50, 15)
	var after := Rect2(100, 400, 50, 15)
	_check(CollisionChecks.swept_intersects(player_rect, player_rect, before, after),
		"A thin barrier must not pass through the player during a stalled frame")
	_check(not CollisionChecks.swept_intersects(player_rect, player_rect,
		Rect2(200, 0, 50, 15), Rect2(200, 400, 50, 15)), "A clear adjacent lane must stay safe")
	_check(CollisionChecks.swept_intersects(Rect2(0, 200, 56, 92), Rect2(300, 200, 56, 92),
		Rect2(150, 210, 50, 80), Rect2(150, 210, 50, 80)), "Steering across traffic must use continuous collision")
	_check(Game.bus_stop_service_window(100.0, 500.0, 300.0)
		and not Game.bus_stop_service_window(500.0, 600.0, 300.0),
		"A stop's service window must survive a large movement without serving an already missed stop")

func _check_prior_saves() -> void:
	for version in [2, 8, 16]:
		var fixture := "res://tests/fixtures/save_schema_%d.json" % version
		var original: Dictionary = _read_json(fixture)
		var reader := Save.new()
		reader.data = Save.DEFAULTS.duplicate(true)
		_check(reader._load_from(fixture), "Prior save fixture must load")
		_check(int(reader.data.schema_version) == int(Save.DEFAULTS.schema_version)
			and reader.data.total_coins == original.total_coins
			and reader.data.selected_vehicle == original.selected_vehicle,
			"Migration must preserve prior currency and selected buses")
		reader.free()

func _check_ads() -> void:
	var service := FakeAdService.new()
	add_child(service)
	service._plugin = RefCounted.new()
	service._sdk_initialized = true
	service._consent_allowed = true
	service._on_rewarded_failed_to_load("expected test failure")
	service._on_rewarded_failed_to_load("expected duplicate callback")
	_check(service._retry_timers.size() == 1, "Ad load failures must schedule only one retry")
	_check(Ads.retry_delay(0) == 2.0 and Ads.retry_delay(20) == 60.0, "Ad retry delay must be bounded")
	var notifications: Array = []
	service.rewarded_availability_changed.connect(func(available: bool): notifications.append(available))
	service._on_rewarded_loaded(FakeAd.new())
	_check(service._rewarded_loaded and service._retry_timers.is_empty() and notifications == [true],
		"A late loaded ad must publish availability and cancel its retry")
	var rewards: Array = []
	service.rewarded_result.connect(func(placement: String, success: bool): rewards.append([placement, success]))
	service._pending_placement = Ads.PLACEMENT_DOUBLE_COINS
	service._on_user_earned_reward(null)
	service._on_user_earned_reward(null)
	service._on_rewarded_dismissed()
	_check(rewards == [[Ads.PLACEMENT_DOUBLE_COINS, true]] and service.reload_count == 1,
		"Duplicate SDK reward callbacks and dismissal must deliver exactly one reward")
	service.queue_free()
	await get_tree().process_frame

func _check_steering() -> void:
	var bus := PlayerScript.new()
	add_child(bus)
	bus.setup([60.0, 160.0, 260.0], preload("res://data/vehicles.gd").LIST[0])
	bus.current_lane = 0
	bus.position.x = 60.0
	bus.move_right()
	bus.move_right()
	_check(not bus.aligned_with_lane(1), "A target lane must not count as an arrived bus")
	for frame in range(40):
		await get_tree().physics_frame
	_check(bus.current_lane == 2 and bus.aligned_with_lane(2), "Two quick taps must execute two lane changes (lane=%d, x=%.1f, moving=%s)" % [bus.current_lane, bus.position.x, bus.is_lane_switching()])
	bus.current_lane = 0
	bus.position.x = 60.0
	bus.move_right()
	bus.move_right()
	await get_tree().create_timer(0.04).timeout
	bus.set_steering_paused(true)
	var stopped_x: float = bus.position.x
	await get_tree().create_timer(0.18).timeout
	_check(is_equal_approx(stopped_x, bus.position.x), "Pause must stop the steering tween")
	bus.set_steering_paused(false)
	await get_tree().create_timer(0.25).timeout
	_check(bus.current_lane == 1 and bus.aligned_with_lane(1), "Resume must complete the move without a stale buffered tap")
	bus.move_left()
	bus.move_right()
	await get_tree().create_timer(0.4).timeout
	_check(bus.current_lane == 1 and bus.aligned_with_lane(1), "A buffered opposite turn must return exactly one lane")
	bus.queue_free()
	await get_tree().process_frame
