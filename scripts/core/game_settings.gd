extends Node
# Pengaturan pemain (autoload), disimpan terpisah dari progres game di
# user://settings.cfg. Saat ini: mode kontrol dan joystick virtual.

signal changed()

const PATH := "user://settings.cfg"
const SIZE_SCALES := [0.8, 1.0, 1.25]

var control_mode := "tap"        # tap | joystick | both
var joystick_side := "left"      # left | right
var joystick_size := 1           # 0 kecil, 1 sedang, 2 besar
var joystick_vector := Vector2.ZERO   # diisi oleh joystick virtual (-1..1)


func _ready() -> void:
	if OS.has_feature("mobile"):
		control_mode = "both"
	load_settings()


func uses_tap() -> bool:
	return control_mode != "joystick"


func uses_joystick() -> bool:
	return control_mode != "tap"


func size_scale() -> float:
	return float(SIZE_SCALES[clampi(joystick_size, 0, 2)])


func set_mode(m: String) -> void:
	control_mode = m
	if not uses_joystick():
		joystick_vector = Vector2.ZERO
	save_settings()
	changed.emit()


func set_side(s: String) -> void:
	joystick_side = s
	save_settings()
	changed.emit()


func set_size(i: int) -> void:
	joystick_size = clampi(i, 0, 2)
	save_settings()
	changed.emit()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	var m := str(cf.get_value("controls", "mode", control_mode))
	if m == "tap" or m == "joystick" or m == "both":
		control_mode = m
	var s := str(cf.get_value("controls", "side", joystick_side))
	if s == "left" or s == "right":
		joystick_side = s
	joystick_size = clampi(int(cf.get_value("controls", "size", joystick_size)), 0, 2)


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("controls", "mode", control_mode)
	cf.set_value("controls", "side", joystick_side)
	cf.set_value("controls", "size", joystick_size)
	cf.save(PATH)
