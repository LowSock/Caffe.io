extends Control
# Saklar hidup/mati bergaya pil (pengganti CheckButton bawaan).

signal toggled(on: bool)

var on := false


func _init() -> void:
	custom_minimum_size = Vector2(48, 26)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func set_on(v: bool, emit: bool = false) -> void:
	on = v
	queue_redraw()
	if emit:
		toggled.emit(on)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		on = not on
		queue_redraw()
		toggled.emit(on)
		accept_event()


func _draw() -> void:
	var h := size.y
	var bg := Color(0.72, 0.72, 0.74)
	if on:
		bg = Color(0.4, 0.7, 0.33)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(h * 0.5))
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var cx := h * 0.5
	if on:
		cx = size.x - h * 0.5
	draw_circle(Vector2(cx, h * 0.5), h * 0.5 - 3.0, Color.WHITE)
