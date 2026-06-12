class_name UIFactory
## Helpers to build consistent menu UI without external theme files.

const COL_BG := Color("#0e1116")
const COL_PANEL := Color("#1b2230")
const COL_PRIMARY := Color("#1f8fff")
const COL_ACCENT := Color("#ffd23f")
const COL_DANGER := Color("#e63946")
const COL_TEXT := Color("#f5f5f5")
const COL_MUTED := Color("#9aa3b2")

static func make_button(text: String, primary: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PRIMARY if primary else COL_PANEL
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	b.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate()
	sb_hover.bg_color = sb.bg_color.lightened(0.1)
	b.add_theme_stylebox_override("hover", sb_hover)
	var sb_press := sb.duplicate()
	sb_press.bg_color = sb.bg_color.darkened(0.15)
	b.add_theme_stylebox_override("pressed", sb_press)
	b.add_theme_color_override("font_color", COL_TEXT)
	b.add_theme_font_size_override("font_size", 22)
	return b

static func make_title(text: String, font_size: int = 42) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", COL_ACCENT)
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func make_label(text: String, font_size: int = 20, color: Color = COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func make_panel(color: Color = COL_PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	p.add_theme_stylebox_override("panel", sb)
	return p

## Top inset (in viewport units) needed to clear notches/camera cutouts.
static func safe_top_inset(viewport_height: float = 960.0) -> float:
	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		return 0.0
	var sa := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return 0.0
	return clampf(float(sa.position.y) * viewport_height / float(win.y), 0.0, 80.0)

static func paint_background(control: Control, color: Color = COL_BG) -> void:
	var bg := ColorRect.new()
	bg.color = color
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(bg)
	control.move_child(bg, 0)
