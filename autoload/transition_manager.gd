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
		# Still do the change even if somehow busy, just skip animation.
		get_tree().change_scene_to_file(path)
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _do_change(path))

func _do_change(path: String) -> void:
	get_tree().change_scene_to_file(path)
	# Wait two frames for the new scene to render before fading back in.
	await get_tree().process_frame
	await get_tree().process_frame
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _busy = false)

## Optional: fade in immediately on game boot (first scene already shown).
func fade_in_only() -> void:
	_overlay.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)
