extends Control
# Joystick analog virtual. Memakai _input supaya bisa multi-sentuh (satu jari
# di joystick, jari lain tetap bisa geser/zoom kamera). Hasilnya ditulis ke
# GameSettings.joystick_vector (-1..1; y positif = ke bawah layar).

var base_radius := 70.0
var knob_radius := 30.0

var _touch_index := -2          # -2 = tidak aktif, -1 = mouse, >= 0 = nomor jari
var _vec := Vector2.ZERO
var _emu_capture := false       # sedang menelan mouse tiruan dari sentuhan


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func apply_scale(s: float) -> void:
	base_radius = 70.0 * s
	knob_radius = 30.0 * s
	custom_minimum_size = Vector2(base_radius * 2.0 + 8.0, base_radius * 2.0 + 8.0)
	queue_redraw()


func _center() -> Vector2:
	return get_global_rect().get_center()


func _inside(p: Vector2) -> bool:
	return p.distance_to(_center()) <= base_radius + 22.0


func _update(p: Vector2) -> void:
	var v := (p - _center()) / base_radius
	if v.length() > 1.0:
		v = v.normalized()
	_vec = v
	GameSettings.joystick_vector = v
	queue_redraw()


func _release() -> void:
	_touch_index = -2
	_vec = Vector2.ZERO
	GameSettings.joystick_vector = Vector2.ZERO
	queue_redraw()


func _exit_tree() -> void:
	GameSettings.joystick_vector = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		if _touch_index != -2:
			_release()
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if _touch_index == -2 and _inside(st.position):
				_touch_index = st.index
				_update(st.position)
				get_viewport().set_input_as_handled()
		elif st.index == _touch_index:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _touch_index:
			_update(sd.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.device == InputEvent.DEVICE_ID_EMULATION:
			# mouse tiruan dari sentuhan: telan kalau jarinya ada di joystick
			if mb.pressed:
				if _touch_index >= 0 or _inside(mb.position):
					_emu_capture = true
					get_viewport().set_input_as_handled()
			elif _emu_capture:
				_emu_capture = false
				get_viewport().set_input_as_handled()
		else:
			# mouse asli (uji coba di PC)
			if mb.pressed:
				if _touch_index == -2 and _inside(mb.position):
					_touch_index = -1
					_update(mb.position)
					get_viewport().set_input_as_handled()
			elif _touch_index == -1:
				_release()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mm.device == InputEvent.DEVICE_ID_EMULATION:
			if _emu_capture:
				get_viewport().set_input_as_handled()
		elif _touch_index == -1:
			_update(mm.position)
			get_viewport().set_input_as_handled()


func _draw() -> void:
	var c := size * 0.5
	draw_circle(c, base_radius, Color(1.0, 0.97, 0.9, 0.2))
	draw_arc(c, base_radius, 0.0, TAU, 48, Color(1.0, 0.9, 0.7, 0.65), 3.0)
	var knob := c + _vec * (base_radius - knob_radius * 0.3)
	draw_circle(knob, knob_radius, Color(1.0, 0.93, 0.8, 0.88))
	draw_arc(knob, knob_radius, 0.0, TAU, 32, Color(0.6, 0.4, 0.2, 0.8), 2.5)
