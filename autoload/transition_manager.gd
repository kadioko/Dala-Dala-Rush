extends CanvasLayer
## Fade-to-black transitions between every scene.
## Replace get_tree().change_scene_to_file() with TransitionManager.go_to().

var _overlay: ColorRect
var _busy: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.modulate.a = 0.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func go_to(path: String) -> void:
	if _busy:
		# Ignore duplicate taps while the current transition owns navigation.
		# Changing immediately here leaves the first tween's stale callback alive.
		return
	_busy = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _do_change(path))

func _do_change(path: String) -> void:
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Transition: failed to open %s (error %d)." % [path, error])
		_overlay.modulate.a = 0.0
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_busy = false
		return
	# Wait two frames for the new scene to render before fading back in.
	await get_tree().process_frame
	await get_tree().process_frame
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		_busy = false
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)

# ─── Android hardware back button ─────────────────────────────────

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()

func _handle_back() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	# Scenes can define handle_back() for custom behaviour (e.g. pause).
	if scene.has_method("handle_back"):
		scene.handle_back()
		return
	var path := String(scene.scene_file_path)
	if path.ends_with("main_menu.tscn"):
		get_tree().quit()
	elif path.ends_with("splash.tscn"):
		pass  # ignore during splash
	else:
		go_to("res://scenes/main_menu.tscn")

## Optional: fade in immediately on game boot (first scene already shown).
func fade_in_only() -> void:
	_overlay.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)
