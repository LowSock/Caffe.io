extends RefCounted
# Helper gerak: arah keyboard, langkah menuju target, dan arah hadap.


static func keyboard_dir() -> Vector3:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		dir.z += 1.0
	if Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	return dir.normalized()


static func input_dir() -> Vector3:
	# Arah gerak dari keyboard (WASD) atau joystick virtual. Panjang joystick (0..1)
	# dipertahankan supaya geraknya analog.
	var d := keyboard_dir()
	if d != Vector3.ZERO:
		return d
	var j: Vector2 = GameSettings.joystick_vector
	if j.length() > 0.12:
		return Vector3(j.x, 0.0, j.y)
	return Vector3.ZERO


static func step_toward(pos: Vector3, target: Vector3, speed: float, delta: float) -> Vector3:
	# Mengembalikan offset langkah (bukan posisi baru).
	var to := target - pos
	to.y = 0.0
	var dist := to.length()
	if dist < 0.0001:
		return Vector3.ZERO
	return to.normalized() * minf(speed * delta, dist)


static func facing(offset: Vector3) -> float:
	return atan2(offset.x, offset.z)
