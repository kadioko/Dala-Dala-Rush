extends Node
## Achievement tracking + slide-in toast notifications.
## Call AchievementManager.try_unlock("id") from anywhere.
## Toasts queue automatically and do not overlap.

signal achievement_unlocked(id: String)

const ACHIEVEMENTS: Array = [
	{"id": "first_run",   "key": "ACH_FIRST_RUN",   "color": Color("#ffd23f")},
	{"id": "coins_50",    "key": "ACH_COINS_50",     "color": Color("#f1c40f")},
	{"id": "pass_10",     "key": "ACH_PASS_10",      "color": Color("#fab1a0")},
	{"id": "dist_1km",    "key": "ACH_DIST_1KM",     "color": Color("#27ae60")},
	{"id": "score_1000",  "key": "ACH_SCORE_1000",   "color": Color("#1f8fff")},
	{"id": "score_5000",  "key": "ACH_SCORE_5000",   "color": Color("#9b59b6")},
	{"id": "near_miss_5", "key": "ACH_NEAR_MISS_5",  "color": Color("#e74c3c")},
	{"id": "combo_5",     "key": "ACH_COMBO_5",      "color": Color("#a55eea")},
	{"id": "shield_use",  "key": "ACH_SHIELD_USE",   "color": Color("#74b9ff")},
	{"id": "horn_3",      "key": "ACH_HORN_3",       "color": Color("#e67e22")},
]

var _canvas: CanvasLayer
var _toast_queue: Array = []
var _showing: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = CanvasLayer.new()
	_canvas.layer = 98
	add_child(_canvas)

func try_unlock(id: String) -> void:
	var unlocked: Array = SaveSystem.get_value("achievements", [])
	if id in unlocked:
		return
	unlocked.append(id)
	SaveSystem.set_value("achievements", unlocked)
	emit_signal("achievement_unlocked", id)
	var def: Dictionary = _get_def(id)
	if not def.is_empty():
		_queue_toast(def)

func is_unlocked(id: String) -> bool:
	return id in SaveSystem.get_value("achievements", [])

func get_all() -> Array:
	return ACHIEVEMENTS

func _get_def(id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if a.id == id:
			return a
	return {}

# ─── Toast system ────────────────────────────────────────────────

func _queue_toast(def: Dictionary) -> void:
	_toast_queue.append(def)
	if not _showing:
		_show_next()

func _show_next() -> void:
	if _toast_queue.is_empty():
		_showing = false
		return
	_showing = true
	_show_toast(_toast_queue.pop_front())

func _show_toast(def: Dictionary) -> void:
	var vsize: Vector2 = get_viewport().get_visible_rect().size

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.14, 0.96)
	sb.border_color = def.color
	sb.border_width_left = 5
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(290, 0)
	_canvas.add_child(panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	panel.add_child(hb)

	var star := Label.new()
	star.text = "★"
	star.add_theme_color_override("font_color", def.color)
	star.add_theme_font_size_override("font_size", 30)
	star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(star)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(vb)

	var cap := Label.new()
	cap.text = LocaleManager.t("ACHIEVEMENT")
	cap.add_theme_font_size_override("font_size", 12)
	cap.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	vb.add_child(cap)

	var name_lbl := Label.new()
	name_lbl.text = LocaleManager.t(def.key)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(name_lbl)

	# Slide in from right
	panel.position = Vector2(vsize.x + 10, 90)
	var target_x: float = vsize.x - 310.0

	var tw := panel.create_tween()
	tw.tween_property(panel, "position:x", target_x, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.4)
	tw.tween_property(panel, "position:x", vsize.x + 10, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		panel.queue_free()
		_show_next()
	)
