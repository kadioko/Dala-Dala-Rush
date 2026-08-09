extends Control
## Career stats, route personal bests, and achievements overview.

const UIFactory := preload("res://ui/ui_factory.gd")
const Routes    := preload("res://data/routes.gd")

var _title: Label
var _back_btn: Button
var _content: VBoxContainer

func _ready() -> void:
	UIFactory.paint_background(self)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 36 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	root.offset_bottom = -20 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	_title = UIFactory.make_title("", 32)
	root.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)

	LocaleManager.locale_changed.connect(func(_l := ""): _rebuild())
	_rebuild()

func _rebuild() -> void:
	_title.text = LocaleManager.t("STATS")
	_back_btn.text = LocaleManager.t("BACK")
	for c in _content.get_children():
		c.queue_free()
	_build_career_panel()
	_build_route_bests_panel()
	_build_achievements_panel()

# ─── Career stats ─────────────────────────────────────────────────

func _build_career_panel() -> void:
	var panel := UIFactory.make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var runs    := int(SaveSystem.get_value("total_runs", 0))
	var dist_km := float(SaveSystem.get_value("total_distance_ever", 0.0)) / 1000.0
	var coins   := int(SaveSystem.get_value("total_coins_ever", 0))
	var pax     := int(SaveSystem.get_value("total_passengers_ever", 0))
	_add_row(vb, LocaleManager.t("TOTAL_RUNS"),            str(runs))
	_add_row(vb, LocaleManager.t("TOTAL_DISTANCE"),        "%.2f %s" % [dist_km, LocaleManager.t("KM")])
	_add_row(vb, LocaleManager.t("TOTAL_COINS_EVER"),      str(coins))
	_add_row(vb, LocaleManager.t("TOTAL_PASSENGERS_EVER"), str(pax))

# ─── Route bests ──────────────────────────────────────────────────

func _build_route_bests_panel() -> void:
	var panel := UIFactory.make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var hdr := UIFactory.make_label(LocaleManager.t("ROUTE_BESTS"), 17, UIFactory.COL_ACCENT)
	vb.add_child(hdr)
	for r in Routes.LIST:
		var best := SaveSystem.get_route_best(r.id)
		var col: Color = UIFactory.COL_TEXT if best > 0 else UIFactory.COL_MUTED
		_add_row(vb, LocaleManager.t(r.name_key), str(best), col)

# ─── Achievements ─────────────────────────────────────────────────

func _build_achievements_panel() -> void:
	var panel := UIFactory.make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var hdr := UIFactory.make_label(LocaleManager.t("ACHIEVEMENTS"), 17, UIFactory.COL_ACCENT)
	vb.add_child(hdr)
	for ach in AchievementManager.get_all():
		var unlocked := AchievementManager.is_unlocked(ach.id)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		vb.add_child(hb)
		# Colored dot
		var dot := _AchDot.new()
		dot.custom_minimum_size = Vector2(22, 22)
		dot.dot_color = ach.color if unlocked else Color(0.25, 0.25, 0.25, 0.7)
		hb.add_child(dot)
		# Achievement name
		var name_lbl := UIFactory.make_label(
			LocaleManager.t(ach.key), 16,
			UIFactory.COL_TEXT if unlocked else UIFactory.COL_MUTED)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(name_lbl)
		# Lock indicator
		if not unlocked:
			var lock_lbl := UIFactory.make_label(LocaleManager.t("LOCKED"), 12, UIFactory.COL_MUTED)
			hb.add_child(lock_lbl)

# ─── Helpers ──────────────────────────────────────────────────────

func _add_row(parent: Control, label: String, value: String,
		val_col: Color = UIFactory.COL_TEXT) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	parent.add_child(hb)
	var lbl := UIFactory.make_label(label + ":", 17, UIFactory.COL_MUTED)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)
	var val := UIFactory.make_label(value, 17, val_col)
	hb.add_child(val)

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")

# ── Achievement dot indicator ─────────────────────────────────────

class _AchDot extends Control:
	var dot_color: Color = Color("#ffd23f")

	func _draw() -> void:
		draw_circle(size * 0.5, min(size.x, size.y) * 0.44, dot_color)
