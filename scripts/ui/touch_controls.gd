extends RefCounted
# Kontrol layar sentuh: joystick virtual + tombol Aksi (interaksi dengan
# stasiun terdekat). Tampil menurut pengaturan (GameSettings.control_mode):
# tap = tidak tampil, joystick/both = tampil.

const Style = preload("res://scripts/ui/ui_style.gd")
const JoystickScript = preload("res://scripts/ui/virtual_joystick.gd")

var main = null
var joystick: Control
var action_btn: Button
var _last_text := ""


func build(root: Control, p_main) -> void:
	main = p_main
	joystick = JoystickScript.new()
	root.add_child(joystick)

	action_btn = Button.new()
	action_btn.focus_mode = Control.FOCUS_NONE
	action_btn.text = "Aksi"
	action_btn.clip_text = true
	action_btn.add_theme_font_size_override("font_size", 14)
	action_btn.add_theme_color_override("font_color", Color.WHITE)
	action_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	action_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	action_btn.pressed.connect(_on_action)
	root.add_child(action_btn)

	GameSettings.changed.connect(apply_settings)
	apply_settings()


func apply_settings() -> void:
	var s := GameSettings.size_scale()
	joystick.apply_scale(s)

	var d := 96.0 * s
	action_btn.custom_minimum_size = Vector2(d, d)
	var r := int(d * 0.5)
	var normal := Style.style(Style.GREEN_DARK, r, 4.0)
	normal.set_border_width_all(3)
	normal.border_color = Color(0.85, 0.95, 0.75)
	var hover := Style.style(Style.GREEN, r, 4.0)
	hover.set_border_width_all(3)
	hover.border_color = Color(0.85, 0.95, 0.75)
	var pressed := Style.style(Style.GREEN_DARK.darkened(0.2), r, 4.0)
	pressed.set_border_width_all(3)
	pressed.border_color = Color(0.85, 0.95, 0.75)
	action_btn.add_theme_stylebox_override("normal", normal)
	action_btn.add_theme_stylebox_override("hover", hover)
	action_btn.add_theme_stylebox_override("pressed", pressed)
	action_btn.add_theme_stylebox_override("disabled", Style.style(Color(0.6, 0.6, 0.6, 0.6), r, 4.0))

	if GameSettings.joystick_side == "left":
		Style.anchor_bottom_left(joystick, 26.0)
		Style.anchor_bottom_right(action_btn, 26.0)
	else:
		Style.anchor_bottom_right(joystick, 26.0)
		Style.anchor_bottom_left(action_btn, 26.0)
	refresh()


func refresh() -> void:
	var show: bool = GameSettings.uses_joystick() and GameManager.shift_active and not main.get_tree().paused
	joystick.visible = show
	action_btn.visible = show
	if not show:
		GameSettings.joystick_vector = Vector2.ZERO
		return
	var c = main.employees.controlled
	var text := "Aksi"
	var usable := false
	if c != null:
		var st = main.interaction.nearest_station(c.position)
		if st != null:
			text = str(st.title)
			usable = true
	action_btn.disabled = not usable
	if text != _last_text:
		_last_text = text
		action_btn.text = text


func _on_action() -> void:
	main.interact_nearest()
