extends Node

const Save := preload("res://autoload/save_system.gd")
const Ghost := preload("res://data/ghost_data.gd")
const Game := preload("res://scripts/game.gd")
const Results := preload("res://scripts/game_over.gd")
const Ads := preload("res://autoload/ad_service.gd")
const Frames := preload("res://data/frame_pacing.gd")

class FakeAd extends RefCounted:
	var destroyed: bool = false
	var full_screen_content_callback: Variant
	var listener: Variant
	func destroy() -> void: destroyed = true
	func show(reward_listener: Variant) -> void: listener = reward_listener
var failures: Array[String] = []
var original: Dictionary
var events: Array
var depth: int
var dirty: bool

func _ready() -> void:
	original = SaveSystem.data.duplicate(true)
	events = AnalyticsService._queue.duplicate(true)
	depth = SaveSystem._batch_depth
	dirty = SaveSystem._batch_dirty
	SaveSystem._batch_depth += 1
	SaveSystem.data = Save.DEFAULTS.duplicate(true)
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _run() -> void:
	_check_save_validation()
	_check_replay_budget()
	_check_receipt()
	_check_consent_epochs()
	_check_frame_capture()
	_check_audio_assets()
	await _check_gui_buffer()
	await _check_reward_navigation()
	SaveSystem.data = original
	SaveSystem._batch_depth = depth
	SaveSystem._batch_dirty = dirty
	AnalyticsService._queue = events
	AnalyticsService._save_log()
	for failure in failures: push_error("TRUST: " + failure)
	print("TRUST CONTRACTS: " + ("PASS" if failures.is_empty() else "FAIL"))
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_audio_assets() -> void:
	var total_bytes: int = 0
	for key in AudioManager.VOICE_KEYS:
		var path: String = "res://audio/%s.wav" % key
		check(ResourceLoader.exists(path), "Missing synthetic voice: " + key)
		if not ResourceLoader.exists(path): continue
		var voice := load(path) as AudioStreamWAV
		check(voice != null, "Voice must import as PCM WAV: " + key)
		if voice == null: continue
		check(not voice.stereo and voice.mix_rate == 22050 and voice.get_length() >= 0.15
			and voice.get_length() < 3.0 and voice.data.size() > 100,
			"Voice must be bounded, mono and nonempty: " + key)
		total_bytes += voice.data.size()
	check(total_bytes > 0 and total_bytes < 512000, "Voice placeholders must remain under 500 KB combined")

func _check_save_validation() -> void:
	check(not Save.valid_envelope({}) and not Save.valid_envelope({"unknown": 12}), "Empty/unrecognized primaries must trigger recovery")
	var reader := Save.new()
	reader.storage_path = "user://trust_damaged_save.json"
	reader.backup_storage_path = "user://trust_damaged_save.json.bak"
	AtomicJson.write(reader.storage_path, {})
	AtomicJson.write(reader.backup_storage_path, {"schema_version": 5, "total_coins": 123, "best_score": 45})
	reader.load_data()
	check(int(reader.data.total_coins) == 123 and int(reader.data.best_score) == 45,
		"An actual empty primary must restore real backup progress")
	var restored: Variant = JSON.parse_string(FileAccess.get_file_as_string(reader.storage_path))
	check(restored is Dictionary and restored.total_coins == 123, "Recovered primary must be repaired without rotating damaged data over backup")
	var parent := DirAccess.open("user://")
	for file in parent.get_files():
		if file.begins_with("trust_damaged_save.json"): parent.remove(file)
	reader.data = Save.DEFAULTS.duplicate(true)
	reader.data.missions_active = ["broken", {"progress": "invalid"}, {"tid": "m_coins_40", "progress": 5}, {"tid": "m_coins_40", "progress": 5}]
	reader.data["livery_classic_blue"] = {"body": "invalid", "pattern": "surprise", "slogan": "line\nbreak"}
	reader._normalize_core_data()
	check(reader.data.missions_active == [{"tid": "m_coins_40", "progress": 5}], "Nested mission rows must be structurally repaired")
	check(not reader.data.livery_classic_blue.has("body") and not reader.data.livery_classic_blue.has("pattern"), "Untrusted livery colors/patterns must be rejected")
	var damaged_receipt := reader.clean_reward_receipt({"run_ref": preload("res://data/operation_ids.gd").create(),
		"summary": [], "components": "broken", "segments": ["invalid"], "choice": "double_coins"})
	check(damaged_receipt.summary.is_empty() and damaged_receipt.components.is_empty()
		and damaged_receipt.choice == "double_coins", "Malformed receipt data must be safe without forgetting an already-used reward choice")
	var fixture := "user://trust_future_save.json"
	AtomicJson.write(fixture, {"schema_version": 999, "total_coins": 123})
	check(not reader._load_from(fixture) and reader.recovery_read_only and not reader.save(), "Newer-schema progress must never be downgraded or overwritten")
	DirAccess.remove_absolute(fixture)
	reader.free()

func _check_consent_epochs() -> void:
	var ads := Ads.new()
	ads._plugin_load_rewarded()
	check(not ads._rewarded_loading and not ads._rewarded_loaded, "No native request before SDK consent")
	ads._consent_allowed = true
	var old_rewarded: Variant = ads._rewarded_callbacks(ads._consent_epoch)
	var old_interstitial: Variant = ads._interstitial_callbacks(ads._consent_epoch)
	ads._clear_consent_ads()
	ads._consent_allowed = true
	ads._rewarded_loading = true
	ads._interstitial_loading = true
	var reward := FakeAd.new()
	var interstitial := FakeAd.new()
	old_rewarded.on_ad_loaded.call(reward)
	old_interstitial.on_ad_loaded.call(interstitial)
	old_rewarded.on_ad_failed_to_load.call("old error")
	check(reward.destroyed and interstitial.destroyed and not ads._rewarded_loaded
		and ads._rewarded_loading and ads._interstitial_loading,
		"Old consent callbacks must destroy ads without changing a new request's state")
	ads._rewarded_ad = FakeAd.new()
	var previous: FakeAd = ads._rewarded_ad
	ads._plugin_show_rewarded()
	ads._consent_allowed = false
	previous.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	ads._rewarded_ad = FakeAd.new()
	ads._plugin_show_rewarded()
	previous.listener.on_user_earned_reward.call(null)
	check(not ads._rewarded_earned, "A late reward from the previous ad must not credit a new ad request")
	ads._rewarded_ad.listener.on_user_earned_reward.call(null)
	check(ads._rewarded_earned, "The current ad retains its own earned reward")
	ads._full_screen_active = false
	ads._rewarded_ad = null
	ads.free()

func _check_frame_capture() -> void:
	var capture := Frames.new(60)
	for i in range(995): capture.add_frame(0.016)
	for i in range(5): capture.add_frame(0.120)
	capture.add_frame(NAN)
	var result := capture.report()
	check(result.frames == 1000 and result.p95_ms_upper == 16 and result.worst_ms == 120.0
		and result.over_1_5_budget_frames == 5 and capture.buckets.size() == 501,
		"Frame capture must be bounded and report frame stalls without storing per-frame data")

func _check_replay_budget() -> void:
	var moves: Array = []
	var truncated: bool = false
	for i in range(4096):
		truncated = Ghost.record_event(moves, float(i) * 0.2, i % 3) or truncated
	var clip := Ghost.sanitize({"events": moves, "end": 900.0, "score": 4500,
		"route": "kariakoo", "vehicle_id": "classic_blue", "window_start": moves[0][0]})
	check(truncated and moves.size() == Ghost.MAX_EVENTS and not clip.is_empty(), "Long runs must retain a bounded nonempty replay window")
	check(not Ghost.decode(Ghost.encode(clip)).is_empty(), "Maximum bounded clip must round-trip within the code-size budget")
	var source: Dictionary = Save.DEFAULTS.duplicate(true)
	for key in ["ghost_best", "ghost_rival", "latest_replay", "daily_replay_best"]: source[key] = clip
	var snapshot := OnlineService.cloud_snapshot(source)
	check(snapshot.has("total_coins") and not snapshot.has("ghost_best")
		and JSON.stringify(snapshot).to_utf8_buffer().size() < OnlineService.MAX_SNAPSHOT_BYTES,
		"Optional replays must not prevent essential-progress backup")

func _check_receipt() -> void:
	SaveSystem.data = Save.DEFAULTS.duplicate(true)
	SaveSystem.data.season_xp = 119
	GameState.finish_daily_route_challenge()
	GameState.begin_run()
	var wallet_before: int = int(SaveSystem.data.total_coins)
	var extra: Dictionary = {"elapsed": 20.0, "fares": 20, "fines_paid": 5, "chase_coins": 10, "end_reason": "car"}
	GameState.record_run(200, 100, 0, 100.0, 0, extra)
	var receipt := GameState.reward_receipt()
	check(int(receipt.total) == int(SaveSystem.data.total_coins) - wallet_before, "Receipt total must exactly equal wallet credit, including mission/season payouts")
	var credited: int = int(SaveSystem.data.total_coins)
	GameState.record_run(200, 100, 0, 100.0, 0, extra)
	check(int(SaveSystem.data.total_coins) == credited, "A repeated segment settlement must not pay twice")
	check(GameState.request_continue(), "A single revive must remain available")
	extra.fines_paid = 25
	extra.elapsed = 30.0
	GameState.record_run(210, 80, 0, 110.0, 0, extra)
	receipt = GameState.reward_receipt()
	check(int(receipt.total) == int(SaveSystem.data.total_coins) - wallet_before
		and int(SaveSystem.data.total_runs) == 1, "Continued fines and reward deltas must reconcile without counting another run")
	check(GameState.claim_double_coins() == 0, "A revived run cannot also double coins")
	GameState.begin_run()
	GameState.last_coins = 12
	check(GameState.claim_double_coins() == 12 and GameState.claim_double_coins() == 0, "Ad reward receipt must be exactly-once")

func _click(viewport: SubViewport, button: Button) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.global_position = event.position
	event.pressed = true
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	viewport.push_input(event)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	release.button_mask = 0
	viewport.push_input(release)

func _check_gui_buffer() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(360, 640)
	add_child(viewport)
	var game := Game.new()
	viewport.add_child(game)
	game.set_physics_process(false)
	game._counting_down = false
	game._countdown_layer.visible = false
	game.hud_layer.visible = true
	game.player.current_lane = 0
	game.player.position.x = game.lanes[0]
	for i in range(4): await get_tree().process_frame
	game._update_hud()
	_click(viewport, game.btn_right)
	game._update_hud()
	check(game.player.is_lane_switching() and not game.btn_right.disabled, "Real HUD button must accept a second turn while moving")
	_click(viewport, game.btn_right)
	check(game.player._queued_direction == 1, "Second real GUI click must reach the player buffer")
	for i in range(35): await get_tree().physics_frame
	check(game.player.current_lane == 2 and game.player.aligned_with_lane(2), "Two real GUI taps must complete two lane changes")
	game.queue_free()
	viewport.queue_free()
	await get_tree().process_frame

func _check_reward_navigation() -> void:
	GameState.begin_run()
	GameState.last_coins = 30
	var screen := Results.new()
	add_child(screen)
	screen._on_double_coins_ad()
	check(screen._reward_in_progress and screen._play_btn.disabled and screen._menu_btn.disabled,
		"Results navigation must lock before requesting an ad")
	screen._on_play_again()
	screen.handle_back()
	check(not screen._navigation_in_progress, "Direct navigation and hardware Back must not race an ad")
	screen._on_rewarded_result(AdService.PLACEMENT_CONTINUE, true)
	check(screen._reward_in_progress, "A callback for the wrong placement must not consume the pending reward")
	screen._on_rewarded_result(AdService.PLACEMENT_DOUBLE_COINS, false)
	check(not screen._reward_in_progress and not screen._play_btn.disabled, "Failed ads must release navigation")
	screen.queue_free()
	await get_tree().process_frame
