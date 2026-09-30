extends Node
## Captures the main menu in both locales across common portrait widths.
## Run with the normal renderer: godot --path . res://tests/ui_layout_qa.tscn

const VIEW_SIZES: Array[Vector2i] = [
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
	if _failures.is_empty():
		if _capture_count == LOCALES.size() * VIEW_SIZES.size() * 3:
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
	menu.queue_free()
	viewport.queue_free()
	await get_tree().process_frame

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
				_failures.append("%s %dx%d horizontal overflow: %s at %s" % [
					locale_id, view_size.x, view_size.y, control.get_path(), rect,
				])
	for child in node.get_children():
		_check_horizontal_bounds(child, view_size, locale_id)
