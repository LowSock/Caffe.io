extends Node3D
# Kamera yang bisa diatur pemain: geser (pan), zoom, dan mode ikuti chef.
#
# PC     : klik kanan/tengah lalu seret = geser | roda mouse = zoom
#          panah = geser | + / - atau PageUp / PageDown = zoom
#          F = ikuti chef (hidup/mati) | R = kembalikan tampilan
# Sentuh : dua jari geser = pan | cubit = zoom
# Tombol kamera juga ada di pojok kanan bawah layar.

const OFFSET := Vector3(0.0, 14.0, 12.6)     # posisi kamera relatif ke titik fokus (zoom 1.0)
const FOV := 45.0
const ZOOM_MIN := 0.45
const ZOOM_MAX := 1.9
const BOUNDS_MIN := Vector2(-26.0, -24.0)    # batas titik fokus (x, z)
const BOUNDS_MAX := Vector2(26.0, 20.0)
const PAN_KEY_SPEED := 12.0
const DEFAULT_FOCUS := Vector3(-4.0, 0.0, -1.0)
const DEFAULT_ZOOM := 1.1

var main = null
var camera: Camera3D
var focus := DEFAULT_FOCUS
var zoom := DEFAULT_ZOOM
var follow := false
var gesturing := false

var _focus_goal := DEFAULT_FOCUS
var _zoom_goal := DEFAULT_ZOOM
var _dragging := false
var _last_mouse := Vector2.ZERO
var _touches := {}
var _prev_centroid := Vector2.ZERO
var _prev_dist := 1.0
var _grace := 0.0


func setup(p_main) -> void:
	main = p_main
	process_mode = Node.PROCESS_MODE_ALWAYS    # tetap bisa digeser saat mode bangun (permainan dijeda)
	camera = Camera3D.new()
	camera.fov = FOV
	add_child(camera)
	_update_camera()


# ---------- perintah dari UI / input ----------

func zoom_by(factor: float) -> void:
	_zoom_goal = clampf(_zoom_goal * factor, ZOOM_MIN, ZOOM_MAX)


func toggle_follow() -> void:
	follow = not follow


func reset_view() -> void:
	follow = false
	_focus_goal = DEFAULT_FOCUS
	_zoom_goal = DEFAULT_ZOOM


func screen_to_ground(p: Vector2) -> Variant:
	var o := camera.project_ray_origin(p)
	var d := camera.project_ray_normal(p)
	return Plane(Vector3.UP, 0.0).intersects_ray(o, d)


func _clamp_goal() -> void:
	_focus_goal.x = clampf(_focus_goal.x, BOUNDS_MIN.x, BOUNDS_MAX.x)
	_focus_goal.z = clampf(_focus_goal.z, BOUNDS_MIN.y, BOUNDS_MAX.y)


func _pan_screen(prev: Vector2, cur: Vector2) -> void:
	# "Menggenggam tanah": titik tanah di bawah jari/mouse tetap menempel.
	var a = screen_to_ground(prev)
	var b = screen_to_ground(cur)
	if a == null or b == null:
		return
	var va: Vector3 = a
	var vb: Vector3 = b
	follow = false
	_focus_goal.x += va.x - vb.x
	_focus_goal.z += va.z - vb.z
	_clamp_goal()
	focus = _focus_goal


# ---------- input ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			_last_mouse = mb.position
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(0.9)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.1)
	elif event is InputEventMouseMotion:
		if _dragging:
			var mm := event as InputEventMouseMotion
			_pan_screen(_last_mouse, mm.position)
			_last_mouse = mm.position
			_update_camera()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
		else:
			_touches.erase(st.index)
		if _touches.size() >= 2:
			_grace = 0.4
			_reset_gesture_baseline()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_touches[sd.index] = sd.position
		if _touches.size() >= 2:
			_update_gesture()
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		zoom_by(1.0 / maxf(mg.factor, 0.1))
	elif event is InputEventPanGesture:
		var pg := event as InputEventPanGesture
		follow = false
		_focus_goal.x += pg.delta.x * 0.4 * zoom
		_focus_goal.z += pg.delta.y * 0.4 * zoom
		_clamp_goal()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_F:
				toggle_follow()
			elif k.keycode == KEY_R:
				reset_view()


func _two_touch_info() -> Dictionary:
	var pts: Array = _touches.values()
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[1]
	return {"c": (a + b) * 0.5, "d": a.distance_to(b)}


func _reset_gesture_baseline() -> void:
	var info := _two_touch_info()
	_prev_centroid = info["c"]
	_prev_dist = maxf(float(info["d"]), 1.0)


func _update_gesture() -> void:
	var info := _two_touch_info()
	var c: Vector2 = info["c"]
	var d := maxf(float(info["d"]), 1.0)
	_pan_screen(_prev_centroid, c)
	zoom_by(_prev_dist / d)
	_prev_centroid = c
	_prev_dist = d


# ---------- per frame ----------

func _process(delta: float) -> void:
	_grace = maxf(0.0, _grace - delta)
	gesturing = _touches.size() >= 2 or _grace > 0.0

	if _dragging and not (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
		_dragging = false

	var pan := Vector2.ZERO
	if Input.is_key_pressed(KEY_UP):
		pan.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		pan.y += 1.0
	if Input.is_key_pressed(KEY_LEFT):
		pan.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		pan.x += 1.0
	if pan != Vector2.ZERO:
		follow = false
		_focus_goal.x += pan.x * PAN_KEY_SPEED * zoom * delta
		_focus_goal.z += pan.y * PAN_KEY_SPEED * zoom * delta

	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD) or Input.is_key_pressed(KEY_PAGEUP):
		zoom_by(1.0 - 1.4 * delta)
	if Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT) or Input.is_key_pressed(KEY_PAGEDOWN):
		zoom_by(1.0 + 1.4 * delta)

	if follow and main != null and main.employees != null and main.employees.controlled != null:
		var p: Vector3 = main.employees.controlled.position
		_focus_goal.x = p.x
		_focus_goal.z = p.z

	_clamp_goal()
	var k := clampf(delta * 9.0, 0.0, 1.0)
	focus = focus.lerp(_focus_goal, k)
	zoom = lerpf(zoom, _zoom_goal, k)
	_update_camera()


func _update_camera() -> void:
	camera.position = focus + OFFSET * zoom
	camera.look_at(focus, Vector3.UP)
