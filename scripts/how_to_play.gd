extends Control
## How To Play — 3 tabs: Controls | Epuka (Avoid) | Kusanya (Collect) + Tips.
## All entity cards use drawn colour swatches so no external art is needed.

const UIFactory := preload("res://ui/ui_factory.gd")

# Obstacle catalog: id, color, localized title, localized description.
const OBSTACLES := [
	{"id":"bodaboda",   "color":Color("#e74c3c"), "title":"NAME_BODABODA", "desc":"OBS_BODABODA"},
	{"id":"bajaji",     "color":Color("#27ae60"), "title":"NAME_BAJAJI", "desc":"OBS_BAJAJI"},
	{"id":"car",        "color":Color("#9b59b6"), "title":"NAME_CAR", "desc":"OBS_CAR"},
	{"id":"pothole",    "color":Color("#555555"), "title":"NAME_POTHOLE", "desc":"OBS_POTHOLE"},
	{"id":"cone",       "color":Color("#e67e22"), "title":"NAME_CONE", "desc":"OBS_CONE"},
	{"id":"police",     "color":Color("#1f4e79"), "title":"NAME_POLICE", "desc":"OBS_POLICE"},
	{"id":"barrier",    "color":Color("#f1c40f"), "title":"NAME_BARRIER", "desc":"OBS_BARRIER"},
	{"id":"truck",      "color":Color("#2c3e50"), "title":"NAME_TRUCK", "desc":"OBS_TRUCK"},
	{"id":"pedestrian", "color":Color("#fdcb6e"), "title":"NAME_PEDESTRIAN", "desc":"OBS_PEDESTRIAN"},
	{"id":"tire",       "color":Color("#1a1a2e"), "title":"NAME_TIRE", "desc":"OBS_TIRE"},
	{"id":"mbuzi",      "color":Color("#d7ccc8"), "title":"NAME_MBUZI", "desc":"OBS_MBUZI"},
]

# Collectible catalog: id, color, name key, desc key
const COLLECTIBLES := [
	{"id":"coin",        "color":Color("#ffd23f"), "title":"NAME_COIN", "desc":"COL_COIN"},
	{"id":"passenger",   "color":Color("#fab1a0"), "title":"NAME_PASSENGER", "desc":"COL_PASSENGER"},
	{"id":"fuel",        "color":Color("#e74c3c"), "title":"NAME_FUEL", "desc":"COL_FUEL"},
	{"id":"shield",      "color":Color("#1f8fff"), "title":"NAME_SHIELD", "desc":"COL_SHIELD"},
	{"id":"magnet",      "color":Color("#a55eea"), "title":"NAME_MAGNET", "desc":"COL_MAGNET"},
	{"id":"speed_boost", "color":Color("#2ecc71"), "title":"NAME_SPEED", "desc":"COL_SPEED"},
	{"id":"slow",        "color":Color("#74b9ff"), "title":"NAME_SLOW", "desc":"COL_SLOW"},
]

var _tab_buttons: Array = []
var _pages: Array = []
var _active_tab: int = 0

var _back_btn: Button
var _title_lbl: Label
# per-tab containers holding all labels that need locale refresh
var _refresh_targets: Array = []

func _ready() -> void:
	_build_ui()
	LocaleManager.locale_changed.connect(_refresh_all)

# ────────────────────────────── Layout ──────────────────────────────

func _build_ui() -> void:
	# Background gradient feel
	var bg := ColorRect.new()
	bg.color = UIFactory.COL_BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# ---- Header ----
	var header := _make_header_bar()
	var safe_top := UIFactory.safe_top_inset(get_viewport_rect().size.y)
	header.offset_top = safe_top
	header.offset_bottom = 72 + safe_top
	add_child(header)

	# ---- Tab bar ----
	var tab_bar := HBoxContainer.new()
	tab_bar.anchor_right = 1.0
	tab_bar.offset_top = 72 + safe_top
	tab_bar.offset_bottom = 120 + safe_top
	tab_bar.offset_left = 0
	tab_bar.offset_right = 0
	tab_bar.add_theme_constant_override("separation", 0)
	add_child(tab_bar)

	var tab_keys := ["TAB_CONTROLS", "TAB_AVOID", "TAB_COLLECT", "TAB_TIPS"]
	for i in range(tab_keys.size()):
		var idx: int = i
		var tb := _make_tab_button(i, tab_keys[i])
		tb.pressed.connect(func(): _switch_tab(idx))
		tab_bar.add_child(tb)
		_tab_buttons.append({"btn": tb, "key": tab_keys[i]})

	# ---- Pages (inside a scroll area) ----
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 12
	scroll.offset_right = -12
	scroll.offset_top = 122 + safe_top
	scroll.offset_bottom = -12 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var page_stack := VBoxContainer.new()
	page_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_stack.add_theme_constant_override("separation", 0)
	scroll.add_child(page_stack)

	var pages_data := [
		_build_controls_page(),
		_build_grid_page(OBSTACLES, "obstacle", "AVOID_LABEL", Color("#e74c3c")),
		_build_grid_page(COLLECTIBLES, "collectible", "COLLECT_LABEL", Color("#2ecc71")),
		_build_tips_page(),
	]
	for p in pages_data:
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_stack.add_child(p)
		_pages.append(p)

	_switch_tab(0)
	_refresh_all()

func _make_header_bar() -> Control:
	var bar := Control.new()
	bar.anchor_right = 1.0
	bar.custom_minimum_size = Vector2(0, 72)

	var bg2 := ColorRect.new()
	bg2.color = UIFactory.COL_PANEL
	bg2.anchor_right = 1.0
	bg2.anchor_bottom = 1.0
	bar.add_child(bg2)

	_title_lbl = UIFactory.make_title("", 26)
	_title_lbl.anchor_left = 0.0
	_title_lbl.anchor_right = 1.0
	_title_lbl.anchor_top = 0.5
	_title_lbl.anchor_bottom = 0.5
	_title_lbl.offset_left = 16
	_title_lbl.offset_right = -100
	_title_lbl.offset_top = -18
	_title_lbl.offset_bottom = 18
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bar.add_child(_title_lbl)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.custom_minimum_size = Vector2(88, 48)
	_back_btn.anchor_right = 1.0
	_back_btn.anchor_top = 0.5
	_back_btn.anchor_bottom = 0.5
	_back_btn.offset_left = -100
	_back_btn.offset_right = -8
	_back_btn.offset_top = -24
	_back_btn.offset_bottom = 24
	_back_btn.pressed.connect(_on_back)
	bar.add_child(_back_btn)
	return bar

func _make_tab_button(idx: int, key: String) -> Button:
	var b := Button.new()
	b.text = LocaleManager.t(key)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 48)
	_style_tab_btn(b, false)
	return b

func _style_tab_btn(btn: Button, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIFactory.COL_PRIMARY if active else UIFactory.COL_PANEL
	sb.border_width_bottom = 3 if active else 0
	sb.border_color = UIFactory.COL_ACCENT
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	btn.add_theme_stylebox_override("normal", sb)
	var sh := sb.duplicate() as StyleBoxFlat
	sh.bg_color = sb.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", sh)
	btn.add_theme_color_override("font_color", UIFactory.COL_ACCENT if active else UIFactory.COL_TEXT)
	btn.add_theme_font_size_override("font_size", 15)

func _switch_tab(idx: int) -> void:
	_active_tab = idx
	for i in range(_pages.size()):
		_pages[i].visible = (i == idx)
	for i in range(_tab_buttons.size()):
		_style_tab_btn(_tab_buttons[i].btn, i == idx)

# ──────────────────────── Controls page ────────────────────────────

func _build_controls_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)
	page.offset_left = 16
	page.offset_right = -16

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	page.add_child(inner)

	# Lane diagram
	inner.add_child(_spacer(8))
	var intro := UIFactory.make_label(LocaleManager.t("HOW_INTRO"), 18, UIFactory.COL_ACCENT)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(intro)
	_refresh_targets.append({"lbl": intro, "key": "HOW_INTRO"})
	inner.add_child(_spacer(4))
	inner.add_child(_lane_diagram())
	inner.add_child(_spacer(4))

	# Control rows
	var ctrl_rows := [
		["◀  ▶",  "CTRL_SWIPE"],
		["[ ]",   "CTRL_BUTTONS"],
		[" II",   "CTRL_PAUSE"],
	]
	for row in ctrl_rows:
		inner.add_child(_ctrl_row(row[0], row[1]))

	inner.add_child(_spacer(8))
	return page

func _lane_diagram() -> Control:
	var d := _DrawLaneDiagram.new()
	d.custom_minimum_size = Vector2(0, 140)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return d

func _ctrl_row(icon_text: String, desc_key: String) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)

	var panel := _make_colored_badge(UIFactory.COL_PRIMARY, icon_text, 16)
	hb.add_child(panel)

	var lbl := UIFactory.make_label(LocaleManager.t(desc_key), 17, UIFactory.COL_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)
	_refresh_targets.append({"lbl": lbl, "key": desc_key})
	return hb

# ─────────────────── Obstacle / Collectible grid page ──────────────

func _build_grid_page(data: Array, entity_kind: String, header_key: String, header_color: Color) -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	page.offset_left = 12
	page.offset_right = -12

	page.add_child(_spacer(8))

	# Section badge header
	var header_lbl := UIFactory.make_title(LocaleManager.t(header_key), 20)
	header_lbl.add_theme_color_override("font_color", header_color)
	page.add_child(header_lbl)
	_refresh_targets.append({"lbl": header_lbl, "key": header_key})

	# Full-width rows preserve readable descriptions in both languages.
	for item in data:
		var entry: Dictionary = item
		var card := _make_entity_card(entity_kind, entry.id, entry.color, entry.title, entry.desc)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_child(card)

	page.add_child(_spacer(8))
	return page

func _make_entity_card(entity_kind: String, entity_id: String, entity_color: Color, title_key: String, desc_key: String) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIFactory.COL_PANEL
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	# Left-side accent stripe
	sb.border_width_left = 5
	sb.border_color = entity_color
	sb.content_margin_left = 12
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.add_child(hb)

	var preview := _EntityPreview.new()
	preview.entity_kind = entity_kind
	preview.entity_id = entity_id
	preview.entity_color = entity_color
	preview.custom_minimum_size = Vector2(64, 64)
	hb.add_child(preview)

	# Name and its gameplay effect.
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(vb)

	var title_lbl := UIFactory.make_label(LocaleManager.t(title_key), 16, UIFactory.COL_TEXT)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(title_lbl)
	_refresh_targets.append({"lbl": title_lbl, "key": title_key})

	var desc_lbl := UIFactory.make_label(LocaleManager.t(desc_key), 13, UIFactory.COL_MUTED)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc_lbl)
	_refresh_targets.append({"lbl": desc_lbl, "key": desc_key})

	return panel

# ───────────────────────── Tips page ───────────────────────────────

func _build_tips_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	page.offset_left = 16
	page.offset_right = -16

	page.add_child(_spacer(8))
	var intro := UIFactory.make_label(LocaleManager.t("TIP_INTRO"), 17, UIFactory.COL_MUTED)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)
	_refresh_targets.append({"lbl": intro, "key": "TIP_INTRO"})
	page.add_child(_spacer(4))

	var tip_keys := ["TIP1","TIP2","TIP3","TIP4","TIP5","TIP6","TIP7","TIP8"]
	var tip_icons := ["◀▶","  ★","  ×","  ★","  ⛽","  ↑","  🚏","  👤"]

	for i in range(0):
		page.add_child(_tip_row(tip_icons[i], tip_keys[i]))

	var tip_groups: Array = [
		{"title": "TIP_GROUP_DRIVE", "color": UIFactory.COL_PRIMARY, "tips": [["<>", "TIP1"], ["+", "TIP2"], ["x", "TIP3"]]},
		{"title": "TIP_GROUP_SURVIVE", "color": UIFactory.COL_DANGER, "tips": [["O", "TIP4"], ["S", "TIP5"], ["^", "TIP6"]]},
		{"title": "TIP_GROUP_DALADALA", "color": UIFactory.COL_ACCENT, "tips": [["P", "TIP7"], ["!", "TIP8"]]}
	]
	for group in tip_groups:
		page.add_child(_tip_section(group.title, group.color))
		for tip in group.tips:
			page.add_child(_tip_card(tip[0], tip[1], group.color))

	page.add_child(_spacer(8))
	return page

func _tip_section(key: String, color: Color) -> Control:
	var section := UIFactory.make_label(LocaleManager.t(key), 13, color.lightened(0.15))
	section.add_theme_constant_override("outline_size", 0)
	section.add_theme_constant_override("letter_spacing", 1)
	section.add_theme_constant_override("margin_top", 8)
	_refresh_targets.append({"lbl": section, "key": key})
	return section

func _tip_card(icon_text: String, key: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UIFactory.COL_PANEL.lightened(0.025)
	style.border_color = color.darkened(0.35)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	row.add_child(_make_colored_badge(color.darkened(0.15), icon_text, 16))

	var label := UIFactory.make_label(LocaleManager.t(key), 16, UIFactory.COL_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	_refresh_targets.append({"lbl": label, "key": key})
	return panel

func _tip_row(icon_char: String, key: String) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)

	var badge := _make_colored_badge(UIFactory.COL_ACCENT.darkened(0.3), icon_char, 18)
	hb.add_child(badge)

	var lbl := UIFactory.make_label(LocaleManager.t(key), 17, UIFactory.COL_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)
	_refresh_targets.append({"lbl": lbl, "key": key})
	return hb

# ──────────────────────── Helpers ──────────────────────────────────

func _make_colored_badge(col: Color, text: String, font_size: int) -> Control:
	var c := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	c.add_theme_stylebox_override("panel", sb)
	c.custom_minimum_size = Vector2(52, 0)
	var lbl := UIFactory.make_label(text, font_size, Color.WHITE)
	c.add_child(lbl)
	return c

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

# ──────────────────────── Locale refresh ───────────────────────────

func _refresh_all(_l := "") -> void:
	if _title_lbl:
		_title_lbl.text = LocaleManager.t("HOW_TO_PLAY")
	if _back_btn:
		_back_btn.text = LocaleManager.t("BACK")
	for entry in _tab_buttons:
		entry.btn.text = LocaleManager.t(entry.key)
	for entry in _refresh_targets:
		entry.lbl.text = LocaleManager.t(entry.key)

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")

# ══════════════════════════════════════════════════════════════════
#  Inner draw helpers (no external files needed)
# ══════════════════════════════════════════════════════════════════

## Mini versions of the actual road entities used by the game.
class _EntityPreview extends Control:
	var entity_kind: String = "obstacle"
	var entity_id: String = "car"
	var entity_color: Color = Color.WHITE

	func _draw() -> void:
		var frame := Rect2(Vector2(2, 2), size - Vector2(4, 4))
		draw_style_box(_frame_style(entity_color), frame)
		var tex := SpriteLib.get_tex(entity_kind, entity_id)
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(8, 8), size - Vector2(16, 16)), false)
			return
		if entity_kind == "collectible":
			_draw_collectible()
		else:
			_draw_obstacle()

	func _frame_style(color: Color) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.07, 0.10, 0.92)
		style.border_color = color.lightened(0.15)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		return style

	func _draw_obstacle() -> void:
		var c := size * 0.5
		match entity_id:
			"pothole":
				var hole := PackedVector2Array([c + Vector2(-24, -3), c + Vector2(-14, -16), c + Vector2(5, -13), c + Vector2(23, -7), c + Vector2(25, 7), c + Vector2(8, 15), c + Vector2(-12, 13), c + Vector2(-25, 5)])
				draw_colored_polygon(hole, Color("#151515"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-15, -3), c + Vector2(-4, -9), c + Vector2(15, -6), c + Vector2(18, 4), c + Vector2(3, 10), c + Vector2(-13, 7)]), Color("#3d3d3d"))
			"cone":
				var pts := PackedVector2Array([Vector2(c.x, 12), Vector2(c.x - 19, 50), Vector2(c.x + 19, 50)])
				draw_polygon(pts, PackedColorArray([entity_color, entity_color, entity_color]))
				draw_rect(Rect2(c.x - 13, 34, 26, 5), Color.WHITE)
				draw_rect(Rect2(c.x - 23, 50, 46, 6), Color("#f39c12"))
			"barrier":
				draw_rect(Rect2(10, 23, 44, 20), entity_color)
				for x in range(13, 52, 11):
					draw_line(Vector2(x, 42), Vector2(x + 9, 24), Color.WHITE, 4)
			"pedestrian":
				draw_rect(Rect2(8, 23, 48, 20), Color("#242a30"))
				for x in range(11, 55, 12):
					draw_rect(Rect2(x, 25, 7, 16), Color.WHITE)
				var warning := PackedVector2Array([c + Vector2(0, -23), c + Vector2(-13, 0), c + Vector2(13, 0)])
				draw_colored_polygon(warning, entity_color)
				draw_circle(c + Vector2(0, -14), 2.0, Color("#273746"))
			"tire":
				draw_circle(c, 21, Color("#202936"))
				draw_circle(c, 11, Color("#64748b"))
				draw_circle(c, 5, Color("#172033"))
			"mbuzi":
				_draw_preview_ellipse(c + Vector2(-2, 5), Vector2(23, 14), entity_color)
				draw_circle(c + Vector2(18, -6), 9, entity_color)
				draw_line(c + Vector2(14, -13), c + Vector2(10, -21), Color("#8d6e63"), 3)
				draw_line(c + Vector2(22, -13), c + Vector2(27, -21), Color("#8d6e63"), 3)
				draw_line(c + Vector2(-13, 15), c + Vector2(-13, 24), Color("#8d6e63"), 3)
				draw_line(c + Vector2(8, 15), c + Vector2(8, 24), Color("#8d6e63"), 3)
			"bodaboda":
				draw_circle(c + Vector2(-15, 14), 8, Color("#1b2230"))
				draw_circle(c + Vector2(15, 14), 8, Color("#1b2230"))
				draw_line(c + Vector2(-15, 14), c + Vector2(12, 4), entity_color, 6)
				draw_circle(c + Vector2(-2, -9), 7, Color("#fab1a0"))
				draw_rect(Rect2(c.x - 9, c.y - 1, 18, 12), Color("#f1c40f"))
			"bajaji":
				var bajaji_body := PackedVector2Array([Vector2(c.x - 18, c.y - 21), Vector2(c.x + 18, c.y - 21), Vector2(c.x + 22, c.y + 13), Vector2(c.x + 10, c.y + 23), Vector2(c.x - 10, c.y + 23), Vector2(c.x - 22, c.y + 13)])
				draw_colored_polygon(bajaji_body, entity_color)
				draw_rect(Rect2(c.x - 14, c.y - 16, 28, 17), Color("#8fd3e8"))
				draw_rect(Rect2(c.x - 18, c.y + 3, 36, 6), Color("#f4f6f7"))
				draw_circle(c + Vector2(-14, 20), 6, Color("#1b2230"))
				draw_circle(c + Vector2(14, 20), 6, Color("#1b2230"))
			"truck":
				draw_rect(Rect2(c.x - 19, c.y - 25, 38, 30), Color("#566573"))
				for rib in range(3):
					draw_line(c + Vector2(-15, -19 + rib * 9), c + Vector2(15, -19 + rib * 9), Color("#87939c"), 2)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 7), c + Vector2(20, 7), c + Vector2(17, 25), c + Vector2(-17, 25)]), Color("#e67e22"))
				draw_rect(Rect2(c.x - 13, c.y + 10, 26, 9), Color("#8fd3e8"))
				_draw_wheels(c, 20)
			_:
				var car_body := PackedVector2Array([Vector2(c.x - 13, c.y - 25), Vector2(c.x + 13, c.y - 25), Vector2(c.x + 20, c.y - 17), Vector2(c.x + 20, c.y + 17), Vector2(c.x + 13, c.y + 25), Vector2(c.x - 13, c.y + 25), Vector2(c.x - 20, c.y + 17), Vector2(c.x - 20, c.y - 17)])
				draw_colored_polygon(car_body, entity_color)
				draw_rect(Rect2(c.x - 13, c.y - 15, 26, 12), Color("#8fd3e8"))
				draw_rect(Rect2(c.x - 13, c.y + 3, 26, 12), Color("#8fd3e8"))
				if entity_id == "police":
					draw_rect(Rect2(c.x - 20, c.y - 2, 40, 6), Color.WHITE)
					draw_rect(Rect2(c.x - 11, c.y - 4, 11, 5), Color("#e74c3c"))
					draw_rect(Rect2(c.x, c.y - 4, 11, 5), Color("#1f8fff"))
				_draw_wheels(c, 18)

	func _draw_collectible() -> void:
		var c := size * 0.5
		match entity_id:
			"coin":
				draw_circle(c, 21, Color("#f39c12"))
				draw_circle(c, 16, entity_color)
				draw_arc(c, 11, 0.0, TAU, 20, Color("#fff1a8"), 2)
				draw_line(c + Vector2(0, -7), c + Vector2(0, 7), Color("#9a6b05"), 2)
			"passenger":
				draw_circle(c + Vector2(0, -14), 10, Color("#a86d48"))
				draw_arc(c + Vector2(0, -15), 9, PI, TAU, 12, Color("#273746"), 4)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-14, -3), c + Vector2(14, -3), c + Vector2(17, 23), c + Vector2(-17, 23)]), Color("#6c5ce7"))
				draw_line(c + Vector2(-10, 4), c + Vector2(10, 17), Color("#ffd23f"), 3)
			"fuel":
				draw_rect(Rect2(c.x - 15, c.y - 19, 30, 39), entity_color)
				draw_rect(Rect2(c.x - 9, c.y - 12, 18, 8), Color.WHITE)
				draw_line(c + Vector2(12, -17), c + Vector2(20, -24), Color.WHITE, 4)
			"shield":
				var pts := PackedVector2Array([c + Vector2(0, -24), c + Vector2(-20, -14), c + Vector2(-14, 13), c + Vector2(0, 22), c + Vector2(14, 13), c + Vector2(20, -14)])
				draw_polygon(pts, PackedColorArray([entity_color, entity_color, entity_color, entity_color, entity_color, entity_color]))
				draw_line(c + Vector2(-8, -1), c + Vector2(-2, 6), Color.WHITE, 3, true)
				draw_line(c + Vector2(-2, 6), c + Vector2(10, -9), Color.WHITE, 3, true)
			"magnet":
				draw_arc(c + Vector2(0, -3), 17, 0.0, PI, 18, entity_color, 9)
				draw_rect(Rect2(c.x - 22, c.y - 5, 10, 16), Color.WHITE)
				draw_rect(Rect2(c.x + 12, c.y - 5, 10, 16), Color.WHITE)
			"speed_boost":
				var bolt := PackedVector2Array([Vector2(c.x + 4, 8), Vector2(c.x - 15, 34), Vector2(c.x - 2, 34), Vector2(c.x - 8, 56), Vector2(c.x + 17, 27), Vector2(c.x + 3, 27)])
				draw_polygon(bolt, PackedColorArray([entity_color, entity_color, entity_color, entity_color, entity_color, entity_color]))
			"slow":
				for angle in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
					var arm := Vector2(cos(angle), sin(angle)) * 20.0
					draw_line(c - arm, c + arm, entity_color, 3, true)
				draw_circle(c, 4, Color.WHITE)

	func _draw_wheels(c: Vector2, spread: float) -> void:
		draw_circle(c + Vector2(-spread, 22), 6, Color("#1b2230"))
		draw_circle(c + Vector2(spread, 22), 6, Color("#1b2230"))

	func _draw_preview_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var points := PackedVector2Array()
		for i in range(20):
			var angle: float = TAU * float(i) / 20.0
			points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
		draw_polygon(points, PackedColorArray([color]))


## Visual lane diagram showing 3 lanes with a dala dala and arrows.
class _DrawLaneDiagram extends Control:
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var road_x: float = w * 0.1
		var road_w: float = w * 0.8
		var lane_w: float = road_w / 3.0

		# Road surface
		draw_rect(Rect2(Vector2(road_x, 0), Vector2(road_w, h)), Color("#3d3d3d"))
		# Lane dividers
		for i in range(1, 3):
			var lx: float = road_x + lane_w * i
			var y: float = 0.0
			while y < h:
				draw_rect(Rect2(Vector2(lx - 2, y), Vector2(4, 20)), Color("#fff7b3"))
				y += 40
		# Dala dala in centre lane
		var cx: float = road_x + lane_w * 1.5
		var cy: float = h * 0.6
		_draw_dala(cx, cy)
		# Arrows suggesting left/right movement
		_draw_arrow(road_x + lane_w * 0.5, cy, -1)
		_draw_arrow(road_x + lane_w * 2.5, cy, 1)

	func _draw_dala(cx: float, cy: float) -> void:
		var bus_size := Vector2(38, 56)
		LiveryLib.draw_bus(self, Vector2(cx, cy) - bus_size * 0.5, bus_size,
			Color("#1f8fff"), Color("#ffd23f"), "stripe", "")

	func _draw_arrow(cx: float, cy: float, direction: int) -> void:
		var col := Color(1,1,1,0.7)
		var pts := PackedVector2Array()
		if direction < 0:
			pts = PackedVector2Array([
				Vector2(cx + 14, cy - 12),
				Vector2(cx - 6,  cy),
				Vector2(cx + 14, cy + 12),
			])
		else:
			pts = PackedVector2Array([
				Vector2(cx - 14, cy - 12),
				Vector2(cx + 6,  cy),
				Vector2(cx - 14, cy + 12),
			])
		draw_polygon(pts, PackedColorArray([col, col, col]))
