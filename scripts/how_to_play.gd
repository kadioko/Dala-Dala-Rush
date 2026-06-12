extends Control
## How To Play — 3 tabs: Controls | Epuka (Avoid) | Kusanya (Collect) + Tips.
## All entity cards use drawn colour swatches so no external art is needed.

const UIFactory := preload("res://ui/ui_factory.gd")

# Obstacle catalog: id, color, name key, desc key
const OBSTACLES := [
	{"id":"bodaboda",   "color":Color("#e74c3c"), "name":"OBS_BODABODA"},
	{"id":"bajaji",     "color":Color("#27ae60"), "name":"OBS_BAJAJI"},
	{"id":"car",        "color":Color("#9b59b6"), "name":"OBS_CAR"},
	{"id":"pothole",    "color":Color("#555555"), "name":"OBS_POTHOLE"},
	{"id":"cone",       "color":Color("#e67e22"), "name":"OBS_CONE"},
	{"id":"police",     "color":Color("#1f4e79"), "name":"OBS_POLICE"},
	{"id":"barrier",    "color":Color("#f1c40f"), "name":"OBS_BARRIER"},
	{"id":"truck",      "color":Color("#2c3e50"), "name":"OBS_TRUCK"},
	{"id":"pedestrian", "color":Color("#fdcb6e"), "name":"OBS_PEDESTRIAN"},
	{"id":"tire",       "color":Color("#1a1a2e"), "name":"OBS_TIRE"},
	{"id":"mbuzi",      "color":Color("#d7ccc8"), "name":"OBS_MBUZI"},
]

# Collectible catalog: id, color, name key, desc key
const COLLECTIBLES := [
	{"id":"coin",        "color":Color("#ffd23f"), "name":"COL_COIN"},
	{"id":"passenger",   "color":Color("#fab1a0"), "name":"COL_PASSENGER"},
	{"id":"fuel",        "color":Color("#e74c3c"), "name":"COL_FUEL"},
	{"id":"shield",      "color":Color("#1f8fff"), "name":"COL_SHIELD"},
	{"id":"magnet",      "color":Color("#a55eea"), "name":"COL_MAGNET"},
	{"id":"speed_boost", "color":Color("#2ecc71"), "name":"COL_SPEED"},
	{"id":"slow",        "color":Color("#74b9ff"), "name":"COL_SLOW"},
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
	add_child(header)

	# ---- Tab bar ----
	var tab_bar := HBoxContainer.new()
	tab_bar.anchor_right = 1.0
	tab_bar.offset_top = 72
	tab_bar.offset_bottom = 120
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
	scroll.offset_top = 122
	scroll.offset_bottom = -8
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var page_stack := Control.new()
	page_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_stack.custom_minimum_size = Vector2(0, 0)
	scroll.add_child(page_stack)

	var pages_vbox := VBoxContainer.new()
	pages_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages_vbox.anchor_right = 1.0
	page_stack.add_child(pages_vbox)

	var pages_data := [
		_build_controls_page(),
		_build_grid_page(OBSTACLES, "AVOID_LABEL", Color("#e74c3c")),
		_build_grid_page(COLLECTIBLES, "COLLECT_LABEL", Color("#2ecc71")),
		_build_tips_page(),
	]
	for p in pages_data:
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pages_vbox.add_child(p)
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

func _build_grid_page(data: Array, header_key: String, header_color: Color) -> Control:
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

	# 2-column grid
	var i := 0
	while i < data.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_child(row)
		for col in range(2):
			if i + col < data.size():
				var entry: Dictionary = data[i + col]
				var card := _make_entity_card(entry.color, entry.name)
				card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(card)
			else:
				# filler to keep columns balanced
				var filler := Control.new()
				filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(filler)
		i += 2

	page.add_child(_spacer(8))
	return page

func _make_entity_card(entity_color: Color, name_key: String) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIFactory.COL_PANEL
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
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

	# Colour swatch
	var swatch_panel := _DrawSwatch.new()
	swatch_panel.swatch_color = entity_color
	swatch_panel.custom_minimum_size = Vector2(44, 44)
	hb.add_child(swatch_panel)

	# Name + type hint
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(vb)

	var name_lbl := UIFactory.make_label(LocaleManager.t(name_key), 15, UIFactory.COL_TEXT)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(name_lbl)
	_refresh_targets.append({"lbl": name_lbl, "key": name_key})

	return panel

# ───────────────────────── Tips page ───────────────────────────────

func _build_tips_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	page.offset_left = 16
	page.offset_right = -16

	page.add_child(_spacer(8))

	var tip_keys := ["TIP1","TIP2","TIP3","TIP4","TIP5","TIP6","TIP7","TIP8"]
	var tip_icons := ["◀▶","  ★","  ×","  ★","  ⛽","  ↑","  🚏","  👤"]

	for i in range(tip_keys.size()):
		page.add_child(_tip_row(tip_icons[i], tip_keys[i]))

	page.add_child(_spacer(8))
	return page

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

## Coloured rounded square swatch used in entity cards.
class _DrawSwatch extends Control:
	var swatch_color: Color = Color.WHITE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Rounded fill
		draw_rect(Rect2(Vector2(4,0), Vector2(size.x-8, size.y)), swatch_color)
		draw_rect(Rect2(Vector2(0,4), Vector2(size.x, size.y-8)), swatch_color)
		draw_circle(Vector2(4,4), 4.0, swatch_color)
		draw_circle(Vector2(size.x-4,4), 4.0, swatch_color)
		draw_circle(Vector2(4,size.y-4), 4.0, swatch_color)
		draw_circle(Vector2(size.x-4,size.y-4), 4.0, swatch_color)


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
		var bw: float = 36.0
		var bh: float = 52.0
		draw_rect(Rect2(Vector2(cx - bw*0.5, cy - bh*0.5), Vector2(bw, bh)), Color("#1f8fff"))
		draw_rect(Rect2(Vector2(cx - bw*0.5, cy - bh*0.5 + 6), Vector2(bw, 7)), Color("#ffd23f"))
		draw_rect(Rect2(Vector2(cx - bw*0.5 + 4, cy - bh*0.5 + 16), Vector2(bw - 8, 12)), Color("#a8d0ff"))

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
