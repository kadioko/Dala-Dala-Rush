extends Control
## Livery editor: paint your daladala — body/accent colors, pattern, slogan.
## Edits apply to the currently selected vehicle and persist per vehicle.

const UIFactory := preload("res://ui/ui_factory.gd")
const Vehicles := preload("res://data/vehicles.gd")

var _vehicle: Dictionary = {}
var _livery: Dictionary = {}

var _title: Label
var _back_btn: Button
var _share_btn: Button
var _msg: Label
var _preview: _BusPreview
var _slogan_edit: LineEdit
var _pattern_btns: Array = []

func _ready() -> void:
	UIFactory.paint_background(self)
	_vehicle = Vehicles.get_by_id(GameState.selected_vehicle_id)
	_livery = LiveryLib.get_livery(_vehicle)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 28 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	root.offset_bottom = -16 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	_title = UIFactory.make_title("", 28)
	root.add_child(_title)

	# ── Live preview ─────────────────────────────────────────────
	_preview = _BusPreview.new()
	_preview.livery = _livery
	_preview.custom_minimum_size = Vector2(0, 190)
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_preview)

	# ── Body colors ──────────────────────────────────────────────
	root.add_child(_swatch_row(LiveryLib.BODY_PALETTE, func(c: Color):
		_livery.body = c.to_html(false)
		_apply()))

	# ── Accent colors ────────────────────────────────────────────
	root.add_child(_swatch_row(LiveryLib.ACCENT_PALETTE, func(c: Color):
		_livery.accent = c.to_html(false)
		_apply()))

	# ── Patterns ─────────────────────────────────────────────────
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 6)
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(prow)
	for p in LiveryLib.PATTERNS:
		var pb := UIFactory.make_button("", false)
		pb.custom_minimum_size = Vector2(0, 46)
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.add_theme_font_size_override("font_size", 14)
		var pat: String = p
		pb.pressed.connect(func():
			_livery.pattern = pat
			_apply())
		prow.add_child(pb)
		_pattern_btns.append({"btn": pb, "pattern": p})

	# ── Slogan: presets + custom ─────────────────────────────────
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 8)
	root.add_child(srow)
	_slogan_edit = LineEdit.new()
	_slogan_edit.max_length = 16
	_slogan_edit.text = String(_livery.slogan)
	_slogan_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slogan_edit.custom_minimum_size = Vector2(0, 44)
	_slogan_edit.text_changed.connect(func(txt: String):
		_livery.slogan = txt.to_upper()
		_apply(false))
	srow.add_child(_slogan_edit)
	var dice := UIFactory.make_button("🎲", false)
	dice.custom_minimum_size = Vector2(56, 44)
	dice.pressed.connect(func():
		var s: String = LiveryLib.SLOGAN_PRESETS[randi() % LiveryLib.SLOGAN_PRESETS.size()]
		_livery.slogan = s
		_slogan_edit.text = s
		_apply())
	srow.add_child(dice)

	_msg = UIFactory.make_label("", 14, UIFactory.COL_MUTED)
	root.add_child(_msg)

	# ── Actions ──────────────────────────────────────────────────
	_share_btn = UIFactory.make_button("", false)
	_share_btn.pressed.connect(_on_share)
	root.add_child(_share_btn)

	_back_btn = UIFactory.make_button("")
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)

	LocaleManager.locale_changed.connect(_refresh)
	_refresh()

func _swatch_row(palette: Array, on_pick: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for c in palette:
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		var sb := StyleBoxFlat.new()
		sb.bg_color = c
		sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8; sb.corner_radius_bottom_right = 8
		sb.border_width_bottom = 2; sb.border_width_top = 2
		sb.border_width_left = 2; sb.border_width_right = 2
		sb.border_color = Color(1, 1, 1, 0.25)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		var col: Color = c
		b.pressed.connect(func():
			AudioManager.play_sfx("click")
			on_pick.call(col))
		row.add_child(b)
	return row

func _apply(save := true) -> void:
	if save:
		AudioManager.play_sfx("click")
	LiveryLib.save_livery(String(_vehicle.id), _livery)
	_preview.livery = _livery
	_preview.queue_redraw()
	_refresh_pattern_btns()

func _refresh(_l := "") -> void:
	_title.text = LocaleManager.t("LIVERY")
	_back_btn.text = LocaleManager.t("BACK")
	_share_btn.text = LocaleManager.t("SHARE_BUS")
	_slogan_edit.placeholder_text = LocaleManager.t("SLOGAN_HINT")
	_refresh_pattern_btns()

func _refresh_pattern_btns() -> void:
	for e in _pattern_btns:
		var key: String = "PATTERN_" + String(e.pattern).to_upper()
		e.btn.text = ("● " if String(_livery.pattern) == String(e.pattern) else "") + LocaleManager.t(key)

func _on_share() -> void:
	AudioManager.play_sfx("click")
	# Save the save_livery first, then share a brag line.
	LiveryLib.save_livery(String(_vehicle.id), _livery)
	var text: String = LocaleManager.t("SHARE_BUS_TEXT") \
		.replace("{slogan}", String(_livery.slogan) if String(_livery.slogan) != "" else "Dala Dala") \
		.replace("{score}", str(int(SaveSystem.get_value("best_score", 0))))
	if OS.get_name() == "Android":
		OS.shell_open("intent:#Intent;action=android.intent.action.SEND;type=text/plain;S.android.intent.extra.TEXT=" + text.uri_encode() + ";end")
	else:
		DisplayServer.clipboard_set(text)
		_msg.text = LocaleManager.t("SHARE_COPIED")

func _on_back() -> void:
	AudioManager.play_sfx("click")
	LiveryLib.save_livery(String(_vehicle.id), _livery)
	TransitionManager.go_to("res://scenes/garage.tscn")

# ─── Big live preview ─────────────────────────────────────────────

class _BusPreview extends Control:
	var livery: Dictionary = {}
	func _draw() -> void:
		# Road backdrop
		draw_rect(Rect2(Vector2.ZERO, size), Color("#3d3d3d"))
		var lane_w := size.x / 3.0
		for i in range(1, 3):
			var y := 0.0
			while y < size.y:
				draw_rect(Rect2(Vector2(lane_w * i - 2, y), Vector2(4, 16)), Color("#fff7b3"))
				y += 34
		# Bus, scaled up
		var s := Vector2(96, 150)
		var tl := Vector2(size.x * 0.5, size.y * 0.52) - s * 0.5
		LiveryLib.draw_bus(self, tl, s,
			Color(String(livery.get("body", "1f8fff"))),
			Color(String(livery.get("accent", "ffd23f"))),
			String(livery.get("pattern", "none")),
			String(livery.get("slogan", "")))
