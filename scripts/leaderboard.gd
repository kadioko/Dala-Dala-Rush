extends Control
## Local top-5 leaderboard display.

const UIFactory := preload("res://ui/ui_factory.gd")
const Routes    := preload("res://data/routes.gd")

var _title: Label
var _back_btn: Button
var _content: VBoxContainer
var _ghost_msg: Label
var _copy_ghost_btn: Button
var _import_ghost_btn: Button

func _ready() -> void:
	UIFactory.paint_background(self)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 36 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	root.offset_bottom = -20 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	_title = UIFactory.make_title("", 32)
	root.add_child(_title)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content)

	# ── Ghost racing share/import ─────────────────────────────────
	_ghost_msg = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
	root.add_child(_ghost_msg)

	var ghost_row := HBoxContainer.new()
	ghost_row.add_theme_constant_override("separation", 8)
	root.add_child(ghost_row)

	_copy_ghost_btn = UIFactory.make_button("", false)
	_copy_ghost_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_copy_ghost_btn.custom_minimum_size = Vector2(0, 50)
	_copy_ghost_btn.add_theme_font_size_override("font_size", 15)
	_copy_ghost_btn.pressed.connect(_on_copy_ghost)
	ghost_row.add_child(_copy_ghost_btn)

	_import_ghost_btn = UIFactory.make_button("", false)
	_import_ghost_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_import_ghost_btn.custom_minimum_size = Vector2(0, 50)
	_import_ghost_btn.add_theme_font_size_override("font_size", 15)
	_import_ghost_btn.pressed.connect(_on_import_ghost)
	ghost_row.add_child(_import_ghost_btn)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)

	LocaleManager.locale_changed.connect(func(_l := ""): _rebuild())
	_rebuild()

func _rebuild() -> void:
	_title.text = LocaleManager.t("LEADERBOARD")
	_back_btn.text = LocaleManager.t("BACK")
	_copy_ghost_btn.text = "👻 " + LocaleManager.t("GHOST_COPY")
	_import_ghost_btn.text = "📥 " + LocaleManager.t("GHOST_IMPORT")
	var rival: Variant = SaveSystem.get_value("ghost_rival", null)
	if typeof(rival) == TYPE_DICTIONARY:
		_ghost_msg.text = LocaleManager.t("GHOST_RIVAL_SET") \
			.replace("{n}", str(int((rival as Dictionary).get("score", 0))))
	for c in _content.get_children():
		c.queue_free()

	var lb: Array = SaveSystem.get_leaderboard()
	if lb.is_empty():
		var empty := UIFactory.make_label(LocaleManager.t("NO_SCORES_YET"), 20, UIFactory.COL_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content.add_child(empty)
		return

	var panel := UIFactory.make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	for i in range(lb.size()):
		var e: Dictionary = lb[i]
		var route_data := Routes.get_by_id(e.get("route", "kariakoo"))
		var is_top: bool = i == 0

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		vb.add_child(hb)

		# Rank
		var rank_lbl := UIFactory.make_label(
			"#%d" % (i + 1), 26,
			UIFactory.COL_ACCENT if is_top else Color(0.5, 0.5, 0.5))
		rank_lbl.custom_minimum_size = Vector2(44, 0)
		hb.add_child(rank_lbl)

		# Name (3-char initials)
		var name_lbl := UIFactory.make_label(
			str(e.get("name", "---")), 26,
			Color("#ffd23f") if is_top else UIFactory.COL_TEXT)
		name_lbl.custom_minimum_size = Vector2(60, 0)
		hb.add_child(name_lbl)

		# Score
		var score_lbl := UIFactory.make_label(
			str(int(e.get("score", 0))), 26,
			UIFactory.COL_PRIMARY if is_top else UIFactory.COL_TEXT)
		score_lbl.custom_minimum_size = Vector2(88, 0)
		hb.add_child(score_lbl)

		# Route name (truncated)
		var route_lbl := UIFactory.make_label(
			LocaleManager.t(route_data.name_key), 14, UIFactory.COL_MUTED)
		route_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		route_lbl.clip_text = true
		hb.add_child(route_lbl)

# ─── Ghost codes ──────────────────────────────────────────────────
## A ghost code is base64 JSON of {events, end, score, name} — small
## enough to paste into WhatsApp. Works fully offline.

func _on_copy_ghost() -> void:
	AudioManager.play_sfx("click")
	var ghost: Variant = SaveSystem.get_value("ghost_best", null)
	if typeof(ghost) != TYPE_DICTIONARY:
		_ghost_msg.text = LocaleManager.t("GHOST_NONE")
		return
	var code := Marshalls.utf8_to_base64(JSON.stringify(ghost))
	DisplayServer.clipboard_set("DDRTZ-GHOST:" + code)
	_ghost_msg.text = LocaleManager.t("GHOST_COPIED")

func _on_import_ghost() -> void:
	AudioManager.play_sfx("click")
	var clip := DisplayServer.clipboard_get().strip_edges()
	if not clip.begins_with("DDRTZ-GHOST:"):
		_ghost_msg.text = LocaleManager.t("GHOST_BAD_CODE")
		return
	var json_text := Marshalls.base64_to_utf8(clip.trim_prefix("DDRTZ-GHOST:"))
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY or not (parsed as Dictionary).has("events"):
		_ghost_msg.text = LocaleManager.t("GHOST_BAD_CODE")
		return
	SaveSystem.set_value("ghost_rival", parsed)
	_ghost_msg.text = LocaleManager.t("GHOST_RIVAL_SET") \
		.replace("{n}", str(int((parsed as Dictionary).get("score", 0))))
	AudioManager.play_sfx("powerup")

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")
