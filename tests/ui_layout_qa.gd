extends Node
## Captures menu and gameplay UI in both locales across common portrait widths.
## Run with the normal renderer: godot --path . res://tests/ui_layout_qa.tscn

const GameScript := preload("res://scripts/game.gd")
const VIEW_SIZES: Array[Vector2i] = [
	Vector2i(320, 568),
	Vector2i(360, 640),
	Vector2i(393, 873),
	Vector2i(412, 915),
	Vector2i(540, 960),
	Vector2i(720, 1600),
]
const LOCALES: Array[String] = ["sw", "en"]
const OUTPUT_DIR := "user://ui_qa"

var _failures: Array[String] = []
var _capture_count: int = 0
var _capture_enabled: bool = true
var _saved_profile: Dictionary = {}
var _saved_batch_depth: int = 0
var _saved_batch_dirty: bool = false
var _saved_analytics_queue: Array = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_saved_profile = SaveSystem.data.duplicate(true)
	_saved_batch_depth = SaveSystem._batch_depth
	_saved_batch_dirty = SaveSystem._batch_dirty
	_saved_analytics_queue = AnalyticsService._queue.duplicate(true)
	SaveSystem._batch_depth += 1
	_capture_enabled = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for locale_id in LOCALES:
		LocaleManager.current_locale = locale_id
		LocaleManager.locale_changed.emit(locale_id)
		for view_size in VIEW_SIZES:
			await _capture_menu(locale_id, view_size)
			await _capture_game_ui(locale_id, view_size)
	if _failures.is_empty():
		if _capture_count == LOCALES.size() * VIEW_SIZES.size() * 5:
			print("UI LAYOUT QA: PASS (%d screenshots and bounds)" % _capture_count)
		else:
			print("UI LAYOUT QA: BOUNDS PASS; screenshots skipped because no renderer is available")
		_restore_profile()
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("UI LAYOUT QA: " + failure)
	_restore_profile()
	get_tree().quit(1)

func _restore_profile() -> void:
	SaveSystem.data = _saved_profile
	SaveSystem._batch_depth = _saved_batch_depth
	SaveSystem._batch_dirty = _saved_batch_dirty
	AnalyticsService._queue = _saved_analytics_queue
	AnalyticsService._save_log()

func _capture_menu(locale_id: String, view_size: Vector2i) -> void:
	# Exercise the daily-claim pulse consistently, independent of the real save.
	SaveSystem.data["streak_count"] = 0
	SaveSystem.data["streak_last_date"] = ""
	var viewport := SubViewport.new()
	viewport.size = view_size
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(viewport)
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate() as Control
	viewport.add_child(menu)
	for _frame in range(4):
		await get_tree().process_frame
	_check_horizontal_bounds(menu, view_size, locale_id)
	_save_capture(viewport, locale_id, view_size, "collapsed")
	var more_button: Button = _find_button(menu, LocaleManager.t("MORE_OPTIONS"))
	if more_button == null:
		_failures.append("%s %dx%d has no More button" % [locale_id, view_size.x, view_size.y])
	else:
		more_button.pressed.emit()
		for _frame in range(3):
			await get_tree().process_frame
		_check_horizontal_bounds(menu, view_size, locale_id)
		_save_capture(viewport, locale_id, view_size, "expanded_top")
		var scroll: ScrollContainer = _find_scroll_container(menu)
		if scroll != null:
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
			for _frame in range(3):
				await get_tree().process_frame
			_check_horizontal_bounds(menu, view_size, locale_id)
			_save_capture(viewport, locale_id, view_size, "expanded_bottom")
		if locale_id == "en" and view_size == Vector2i(320, 568):
			await _check_live_event_banner_refresh(menu)
	menu.queue_free()
	viewport.queue_free()
	await get_tree().process_frame

func _check_live_event_banner_refresh(menu: Node) -> void:
	var prior_values: Dictionary = RemoteConfig._values.duplicate(true)
	RemoteConfig._values["event_banner_en"] = "Live route event"
	RemoteConfig.config_updated.emit()
	await get_tree().process_frame
	var label: Label = menu.get("_event_label") as Label
	if not label.visible or label.text != "Live route event":
		_failures.append("An open menu must show remote event text when config arrives")
	RemoteConfig._values = prior_values
	RemoteConfig.config_updated.emit()
	await get_tree().process_frame

func _capture_game_ui(locale_id: String, view_size: Vector2i) -> void:
	var previous_route: String = GameState.selected_route_id
	var previous_vehicle: String = GameState.selected_vehicle_id
	var previous_daily: Dictionary = GameState.daily_route_challenge.duplicate(true)
	var previous_continue_pending: bool = GameState.continue_pending
	var previous_continue_state: Dictionary = GameState.continue_state.duplicate(true)
	GameState.finish_daily_route_challenge()
	GameState.selected_route_id = "kariakoo"
	GameState.selected_vehicle_id = "classic_blue"
	GameState.continue_pending = true
	GameState.continue_state = {
		"fuel": 0.8,
		"distance": 0.0,
		"elapsed": 0.0,
		"horn_charges": 3,
		"max_horn_charges": 3,
		"condition": "rain",
		"rush_hour": true,
	}

	var viewport := SubViewport.new()
	viewport.size = view_size
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(viewport)
	var game := GameScript.new()
	viewport.add_child(game)
	game.set_process(false)
	game.set_process_input(false)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var hud := game.get("hud_layer") as CanvasLayer
	var countdown := game.get("_countdown_layer") as CanvasLayer
	var pause_overlay := game.get("pause_overlay") as Control
	hud.visible = false
	countdown.visible = true
	for _frame in range(3):
		await get_tree().process_frame
	_check_all_bounds(countdown, view_size, locale_id, "run intro")
	_save_capture(viewport, locale_id, view_size, "game_intro")
	if locale_id == "en" and view_size == Vector2i(320, 568):
		game.notification(NOTIFICATION_APPLICATION_PAUSED)
		if not bool(game.get("paused")) or not bool(game.get("_restart_countdown_on_resume")) \
		or countdown.visible:
			_failures.append("Backgrounding during the intro must pause safely without ending the run")
		game.notification(NOTIFICATION_APPLICATION_RESUMED)
		countdown = game.get("_countdown_layer") as CanvasLayer
		if bool(game.get("paused")) or not bool(game.get("_counting_down")) \
		or not countdown.visible:
			_failures.append("Returning to the app must restart the route briefing countdown")
	hud.visible = true
	countdown.visible = false
	for _frame in range(3):
		await get_tree().process_frame
	_check_all_bounds(hud, view_size, locale_id, "gameplay HUD")
	if locale_id == "en" and view_size == Vector2i(320, 568):
		_check_drive_input_isolation(game)
	for control_name in ["btn_left", "_horn_btn", "btn_right"]:
		var drive_button := game.get(control_name) as Control
		var button_rect: Rect2 = drive_button.get_global_rect()
		if button_rect.size.x < 48.0 or button_rect.size.y < 48.0:
			_failures.append("%s %dx%d has undersized %s touch target: %s" % [
				locale_id, view_size.x, view_size.y, control_name, button_rect,
			])
	var dock := game.get("drive_dock") as Control
	if dock.get_global_rect().position.x < -1.0 \
		or dock.get_global_rect().end.x > float(view_size.x) + 1.0:
		_failures.append("%s %dx%d driving dock exceeds viewport: %s" % [
			locale_id, view_size.x, view_size.y, dock.get_global_rect(),
		])
	_save_capture(viewport, locale_id, view_size, "game_hud")

	game.set("paused", true)
	pause_overlay.visible = true
	game.call("_show_pause_menu")
	await get_tree().process_frame
	_check_all_bounds(pause_overlay, view_size, locale_id, "pause menu")
	game.call("_request_pause_exit", "res://scenes/game.tscn", "CONFIRM_RESTART")
	await get_tree().process_frame
	_check_all_bounds(pause_overlay, view_size, locale_id, "pause confirmation")

	game.queue_free()
	viewport.queue_free()
	await get_tree().process_frame
	GameState.selected_route_id = previous_route
	GameState.selected_vehicle_id = previous_vehicle
	GameState.daily_route_challenge = previous_daily
	GameState.continue_pending = previous_continue_pending
	GameState.continue_state = previous_continue_state

func _check_drive_input_isolation(game: Node) -> void:
	game.set("_counting_down", false)
	var player: Node2D = game.get("player") as Node2D
	var starting_lane: int = int(player.get("current_lane"))
	var horn_button: Button = game.get("_horn_btn") as Button
	var horn_center: Vector2 = horn_button.get_global_rect().get_center()
	var horn_touch := InputEventScreenTouch.new()
	horn_touch.index = 0
	horn_touch.position = horn_center
	horn_touch.pressed = true
	game.call("_input", horn_touch)
	var horn_drag := InputEventScreenDrag.new()
	horn_drag.index = 0
	horn_drag.position = horn_center + Vector2(100.0, 0.0)
	game.call("_input", horn_drag)
	horn_touch.pressed = false
	game.call("_input", horn_touch)
	if int(player.get("current_lane")) != starting_lane:
		_failures.append("Dragging from the horn must never steer the bus")
	var charges_before: int = int(game.get("horn_charges"))
	horn_button.pressed.emit()
	if int(game.get("horn_charges")) != charges_before - 1 \
	or int(player.get("current_lane")) != starting_lane:
		_failures.append("Horn tap isolation failed (charges %d -> %d, lane %d -> %d)" % [
			charges_before, int(game.get("horn_charges")), starting_lane,
			int(player.get("current_lane")),
		])
	var road_touch := InputEventScreenTouch.new()
	road_touch.index = 1
	road_touch.position = Vector2(160.0, 300.0)
	road_touch.pressed = true
	game.call("_input", road_touch)
	var road_drag := InputEventScreenDrag.new()
	road_drag.index = 1
	road_drag.position = road_touch.position + Vector2(100.0, 0.0)
	game.call("_input", road_drag)
	if int(player.get("current_lane")) != mini(starting_lane + 1, 2):
		_failures.append("Swipe from the open road must steer exactly one lane")

func _check_all_bounds(node: Node, view_size: Vector2i, locale_id: String,
		view_name: String) -> void:
	if node is Control:
		var control := node as Control
		if control.is_visible_in_tree():
			var rect: Rect2 = control.get_global_rect()
			if rect.position.x < -1.0 or rect.end.x > float(view_size.x) + 1.0 \
			or rect.position.y < -1.0 or rect.end.y > float(view_size.y) + 1.0:
				var text_detail: String = ""
				if control is Label:
					text_detail = " text='%s'" % (control as Label).text
				elif control is Button:
					text_detail = " text='%s'" % (control as Button).text
				_failures.append("%s %dx%d %s overflow: %s (%s)%s at %s" % [
					locale_id, view_size.x, view_size.y, view_name,
					control.get_path(), control.get_class(), text_detail, rect,
				])
	for child in node.get_children():
		_check_all_bounds(child, view_size, locale_id, view_name)

func _save_capture(viewport: SubViewport, locale_id: String, view_size: Vector2i, state: String) -> void:
	var texture: ViewportTexture = viewport.get_texture()
	if _capture_enabled and texture != null:
		var image: Image = texture.get_image()
		if image != null and not image.is_empty():
			var output_path := "%s/%s_%s_%dx%d.png" % [OUTPUT_DIR, locale_id, state, view_size.x, view_size.y]
			var save_error: Error = image.save_png(ProjectSettings.globalize_path(output_path))
			if save_error != OK:
				_failures.append("%s %s screenshot save failed (%s)" % [locale_id, view_size, error_string(save_error)])
			else:
				_capture_count += 1
				print("Captured %s" % output_path)

func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child in node.get_children():
		var found: Button = _find_button(child, text)
		if found != null:
			return found
	return null

func _find_scroll_container(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node as ScrollContainer
	for child in node.get_children():
		var found: ScrollContainer = _find_scroll_container(child)
		if found != null:
			return found
	return null

func _check_horizontal_bounds(node: Node, view_size: Vector2i, locale_id: String) -> void:
	if node is Control:
		var control := node as Control
		if control.is_visible_in_tree():
			var rect: Rect2 = control.get_global_rect()
			if rect.position.x < -1.0 or rect.end.x > float(view_size.x) + 1.0:
				var control_detail := ""
				if control is Label:
					control_detail = " text='%s'" % (control as Label).text
				elif control is Button:
					control_detail = " text='%s'" % (control as Button).text
				var parent_detail := ""
				if control.get_parent() is Control:
					parent_detail = " parent_rect=%s" % (control.get_parent() as Control).get_global_rect()
				_failures.append("%s %dx%d horizontal overflow: %s at %s" % [
					locale_id, view_size.x, view_size.y,
					"%s (%s)%s%s" % [control.get_path(), control.get_class(), control_detail, parent_detail], rect,
				])
	for child in node.get_children():
		_check_horizontal_bounds(child, view_size, locale_id)
