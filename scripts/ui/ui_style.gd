extends RefCounted
# Gaya dan helper UI bersama (tema krem + hijau + biru). Semua static.

const IconScript = preload("res://scripts/ui/icon.gd")
const Data = preload("res://scripts/common/data.gd")

const INK := Color(0.32, 0.2, 0.12)
const SOFT := Color(0.5, 0.4, 0.3)
const CREAM := Color(0.99, 0.97, 0.93, 0.96)
const BLUE := Color(0.2, 0.52, 0.9)
const RED := Color(0.85, 0.38, 0.32)
const GREEN := Color(0.35, 0.65, 0.3)
const GREEN_DARK := Color(0.28, 0.55, 0.24)
const ORANGE := Color(0.9, 0.55, 0.2)
const BORDER := Color(0.93, 0.84, 0.7)


static func style(bg: Color, radius: int = 14, margin: float = 8.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


static func label(text: String, size: int = 16, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func panel(bg: Color = CREAM) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg))
	return p


static func button(text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", style(bg, 10, 6.0))
	b.add_theme_stylebox_override("hover", style(bg.lightened(0.12), 10, 6.0))
	b.add_theme_stylebox_override("pressed", style(bg.darkened(0.15), 10, 6.0))
	b.add_theme_stylebox_override("disabled", style(Color(0.7, 0.7, 0.7, 0.85), 10, 6.0))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.96, 0.96, 0.96))
	b.add_theme_font_size_override("font_size", 16)
	return b


static func bar(width: float) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 100.0
	pb.value = 0.0
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(width, 12)
	pb.add_theme_stylebox_override("background", style(Color(0.85, 0.8, 0.7), 6, 0.0))
	pb.add_theme_stylebox_override("fill", style(GREEN, 6, 0.0))
	return pb


static func anchor_top_right(c: Control, margin: float) -> void:
	c.anchor_left = 1.0
	c.anchor_right = 1.0
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = -margin
	c.offset_right = -margin
	c.offset_top = margin
	c.offset_bottom = margin
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	c.grow_vertical = Control.GROW_DIRECTION_END


static func anchor_bottom_center(c: Control, margin: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = 0.0
	c.offset_right = 0.0
	c.offset_top = -margin
	c.offset_bottom = -margin
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN


static func anchor_bottom_left(c: Control, margin: float) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 0.0
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = margin
	c.offset_right = margin
	c.offset_top = -margin
	c.offset_bottom = -margin
	c.grow_horizontal = Control.GROW_DIRECTION_END
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN


static func clear(container: Node) -> void:
	for c in container.get_children():
		container.remove_child(c)
		c.queue_free()


static func anchor_bottom_right(c: Control, margin: float) -> void:
	c.anchor_left = 1.0
	c.anchor_right = 1.0
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = -margin
	c.offset_right = -margin
	c.offset_top = -margin
	c.offset_bottom = -margin
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN


static func card(bg: Color = CREAM, border: Color = BORDER, radius: int = 18) -> PanelContainer:
	# Panel kartu: krem, sudut bulat, garis tepi tipis, dan bayangan lembut.
	var p := PanelContainer.new()
	var sb := style(bg, radius, 10.0)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.shadow_size = 6
	sb.shadow_color = Color(0.2, 0.1, 0.0, 0.22)
	sb.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func pill(text: String, bg: Color, font_size: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := style(bg, 12, 2.0)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(label(text, font_size, Color.WHITE))
	return p


static func icon(kind: String, color: Color = Color.WHITE, size: float = 32.0, color2: Color = Color(0.98, 0.95, 0.88)) -> Control:
	var ic = IconScript.new()
	ic.setup(kind, color, size, color2)
	return ic


static func ingredient_icon(key: String, size: float = 28.0) -> Control:
	return icon("ing_" + key, Data.INGREDIENTS[key]["color"], size)


static func drink_icon(rid: String, size: float = 40.0) -> Control:
	return icon("glass", Data.RECIPES[rid]["color"], size)


static func icon_button(kind: String, color: Color = INK) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(46, 46)
	var normal := style(CREAM, 14, 4.0)
	normal.set_border_width_all(2)
	normal.border_color = BORDER
	var hover := style(Color(1.0, 0.99, 0.95, 1.0), 14, 4.0)
	hover.set_border_width_all(2)
	hover.border_color = Color(0.95, 0.7, 0.4)
	var pressed := style(Color(0.95, 0.9, 0.8), 14, 4.0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(icon(kind, color, 26.0, CREAM))
	b.add_child(cc)
	return b


static func spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


static func anchor_top_center(c: Control, margin: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = 0.0
	c.offset_right = 0.0
	c.offset_top = margin
	c.offset_bottom = margin
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_END
