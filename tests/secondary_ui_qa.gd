extends Node
## Secondary screens, rich returning profiles, and new-player states.

const SIZES: Array[Vector2i] = [Vector2i(320, 568), Vector2i(360, 640),
	Vector2i(393, 873), Vector2i(412, 915), Vector2i(540, 960), Vector2i(720, 1600)]
const SCREENS := ["splash", "game_over", "settings", "garage", "routes", "shop",
	"how_to_play", "leaderboard", "missions", "stats", "referrals", "livery"]
var _failures: Array[String] = []
var _checks: int = 0
var _captures: int = 0
var _profile: Dictionary
var _depth: int
var _dirty: bool
var _events: Array

func _ready() -> void:
	_profile = SaveSystem.data.duplicate(true)
	_depth = SaveSystem._batch_depth
	_dirty = SaveSystem._batch_dirty
	_events = AnalyticsService._queue.duplicate(true)
	SaveSystem._batch_depth += 1
	SaveSystem.data["online_leaderboard_opt_in"] = false
	SaveSystem.data["online_telemetry_opt_in"] = false
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://secondary_ui_qa"))
	for locale_id in ["sw", "en"]:
		LocaleManager.current_locale = locale_id
		for rich_profile in [false, true]:
			_seed_profile(rich_profile)
			for viewport_size in SIZES:
				for scene_id in SCREENS:
					await _check_screen(scene_id, locale_id, viewport_size, rich_profile)
	SaveSystem.data = _profile
	SaveSystem._batch_depth = _depth
	SaveSystem._batch_dirty = _dirty
	AnalyticsService._queue = _events
	AnalyticsService._save_log()
	for failure in _failures.slice(0, 60):
		push_error(failure)
	print("SECONDARY UI QA: %s (%d screens, %d captures, %d failures)" % [
		"PASS" if _failures.is_empty() else "FAIL", _checks, _captures, _failures.size()])
	get_tree().quit(0 if _failures.is_empty() else 1)

func _seed_profile(rich: bool) -> void:
	SaveSystem.data = SaveSystem.DEFAULTS.duplicate(true)
	SaveSystem.data["leaderboard_display_name"] = "DerevaWaKariakoo1"
	SaveSystem.data["total_coins"] = 1234567 if rich else 0
	SaveSystem.data["total_runs"] = 100 if rich else 0
	SaveSystem.data["regular_runs"] = 100 if rich else 0
	SaveSystem.data["route_goals_completed"] = 12345 if rich else 0
	if rich:
		for route in preload("res://data/routes.gd").LIST:
			SaveSystem.unlock_route(String(route.id))
		SaveSystem.data["unlocked_vehicles"] = ["classic_blue", "kariakoo_yellow", "night_bus"]
	GameState.selected_route_id = "kariakoo"
	GameState.selected_vehicle_id = "classic_blue"
	GameState.finish_daily_route_challenge()
	GameState.last_score = 1234567 if rich else 8
	GameState.last_coins = 999 if rich else 0
	GameState.last_passengers = 123 if rich else 0
	GameState.last_is_new_record = rich
	GameState.last_is_route_record = rich
	GameState.last_end_reason = "bodaboda" if rich else "unknown"
	if rich:
		SaveSystem.data["active_run_id"] = preload("res://data/operation_ids.gd").create()
		SaveSystem.data["last_reward_receipt"] = {"run_ref": SaveSystem.data.active_run_id,
			"components": {"pickups": 999, "fares": 1440, "fines": -90,
				"route_goal": 70, "missions": 180, "season": 120, "mastery": 100, "daily": 80, "contract": 60},
			"segments": ["initial"], "summary": {"route": "kariakoo", "score": GameState.last_score,
				"distance": 12345, "elapsed": 120.0, "end_reason": "bodaboda"}}
	GameState.rewarded_choice_used = ""
	GameState.continue_used = false

func _check_screen(scene_id: String, locale_id: String, viewport_size: Vector2i, rich: bool) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(viewport)
	var screen: Node = load("res://scenes/%s.tscn" % scene_id).instantiate()
	viewport.add_child(screen)
	if scene_id == "splash":
		screen.set_process(false)
		screen.set_process_input(false)
		screen.get("_anim").set("dala_y", viewport_size.y * 0.62)
		await get_tree().create_timer(0.3).timeout
	for frame in range(6):
		await get_tree().process_frame
	var context := "%s %s %s %s" % [scene_id, locale_id, viewport_size, "returning" if rich else "new"]
	_check_bounds(screen, viewport_size, context)
	if scene_id == "game_over":
		await get_tree().create_timer(0.4).timeout
		screen.set("_anim_score", float(GameState.last_score))
		screen.set("_anim_coins", float(GameState.last_coins))
		screen.set("_anim_pass", float(GameState.last_passengers))
		screen.call("_update_stats_labels")
		if rich:
			_capture(viewport, locale_id, scene_id + "_primary", viewport_size)
		var details := screen.get("_details_button") as Button
		details.pressed.emit()
		for frame in range(4):
			await get_tree().process_frame
		_check_bounds(screen, viewport_size, context + " details")
	if DisplayServer.get_name() != "headless" and rich:
		_capture(viewport, locale_id, scene_id, viewport_size)
	_checks += 1
	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame

func _capture(viewport: SubViewport, locale_id: String, scene_id: String, viewport_size: Vector2i) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var result: Error = viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(
		"user://secondary_ui_qa/%s_%s_%dx%d.png" % [locale_id, scene_id, viewport_size.x, viewport_size.y]))
	if result == OK:
		_captures += 1
	else:
		_failures.append("Capture failed: " + scene_id)

func _check_bounds(node: Node, viewport_size: Vector2i, context: String) -> void:
	if node is Control and (node as Control).is_visible_in_tree():
		var control := node as Control
		var rect := control.get_global_rect()
		if rect.position.x < -1.0 or rect.end.x > viewport_size.x + 1.0:
			_failures.append("%s horizontal overflow: %s %s" % [context, control.get_path(), rect])
		if (rect.position.y < -1.0 or rect.end.y > viewport_size.y + 1.0) and not _can_scroll_to(control):
			_failures.append("%s inaccessible vertical content: %s %s" % [context, control.get_path(), rect])
	for child in node.get_children():
		_check_bounds(child, viewport_size, context)

func _can_scroll_to(node: Node) -> bool:
	var parent := node.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false
