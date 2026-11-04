extends Node

const Hub := preload("res://scripts/world_hub.gd")

var _failures: Array[String] = []
var _saved_profile: Dictionary
var _saved_depth: int
var _saved_dirty: bool
var _saved_events: Array

func _ready() -> void:
	_saved_profile = SaveSystem.data.duplicate(true)
	_saved_depth = SaveSystem._batch_depth
	_saved_dirty = SaveSystem._batch_dirty
	_saved_events = AnalyticsService._queue.duplicate(true)
	SaveSystem.data = SaveSystem.DEFAULTS.duplicate(true)
	SaveSystem._batch_depth += 1
	call_deferred("_run")

func _run() -> void:
	var hub := Hub.new()
	add_child(hub)
	await get_tree().process_frame
	hub.call("_update_nearby")
	_check(hub.get("_nearby_id") == "stop", "New visitor should arrive beside the passenger stop")
	hub.call("_start_errand")
	for stop in ["market", "garage", "plaza"]:
		var spot: Dictionary = hub.call("_spot", stop)
		var point: Vector2 = spot.get("position", Vector2.ZERO)
		hub.set("_player_position", point)
		hub.call("_update_nearby")
	var after_errand := int(SaveSystem.get_value("total_coins", 0))
	_check(after_errand == Hub.ERRAND_REWARD, "Completing the three neighborhood stops must pay once")
	_check(String(SaveSystem.get_value("hub_daily_completed_date", "")) == Time.get_date_string_from_system(),
		"Completed neighborhood errand should persist today's date")
	hub.set("_player_position", Vector2(270, 738))
	hub.call("_start_errand")
	_check(int(SaveSystem.get_value("total_coins", 0)) == after_errand,
		"A second same-day errand must not pay twice")
	SaveSystem.set_value("total_coins", 400)
	hub.call("_buy_decor", "kanga_flag", 90)
	_check(int(SaveSystem.get_value("total_coins", 0)) == 310,
		"Buying one plaza decoration should atomically debit its price")
	_check("kanga_flag" in SaveSystem.get_value("hub_owned_decor", []),
		"Purchased decoration should be owned")
	hub.call("_buy_decor", "kanga_flag", 90)
	_check(int(SaveSystem.get_value("total_coins", 0)) == 310,
		"Purchasing an owned decoration again must not debit coins")
	SaveSystem.data = _saved_profile
	SaveSystem._batch_depth = _saved_depth
	SaveSystem._batch_dirty = _saved_dirty
	AnalyticsService._queue = _saved_events
	AnalyticsService._save_log()
	hub.queue_free()
	await get_tree().process_frame
	for failure in _failures:
		push_error("WORLD HUB: " + failure)
	print("WORLD HUB CONTRACTS: " + ("PASS" if _failures.is_empty() else "FAIL"))
	get_tree().quit(0 if _failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
