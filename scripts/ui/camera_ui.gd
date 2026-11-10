extends RefCounted
# Tombol kamera di tepi kanan layar (vertikal): zoom masuk/keluar, ikuti chef, reset.

const Style = preload("res://scripts/ui/ui_style.gd")

var main = null
var panel: PanelContainer
var follow_btn: Button
var _last_follow := false


func build(root: Control, p_main) -> void:
	main = p_main
	panel = Style.card()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	var plus := Style.button("+", Style.BLUE)
	plus.custom_minimum_size = Vector2(54, 44)
	plus.pressed.connect(_on_zoom.bind(0.83))
	col.add_child(plus)

	var minus := Style.button("-", Style.BLUE)
	minus.custom_minimum_size = Vector2(54, 44)
	minus.pressed.connect(_on_zoom.bind(1.2))
	col.add_child(minus)

	follow_btn = Style.button("Ikuti", Style.GREEN)
	follow_btn.custom_minimum_size = Vector2(54, 44)
	follow_btn.pressed.connect(_on_follow)
	col.add_child(follow_btn)

	var reset := Style.button("Reset", Style.RED)
	reset.custom_minimum_size = Vector2(54, 44)
	reset.pressed.connect(_on_reset)
	col.add_child(reset)

	root.add_child(panel)
	# tengah-kanan layar
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -12.0
	panel.offset_right = -12.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH


func refresh() -> void:
	var f: bool = main.camera_rig.follow
	if f != _last_follow:
		_last_follow = f
		follow_btn.text = "Ikuti*" if f else "Ikuti"


func _on_zoom(factor: float) -> void:
	main.camera_rig.zoom_by(factor)


func _on_follow() -> void:
	main.camera_rig.toggle_follow()


func _on_reset() -> void:
	main.camera_rig.reset_view()
