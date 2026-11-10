extends RefCounted
# Jendela pengaturan: mode kontrol (tap / analog / keduanya), posisi dan ukuran
# joystick, simpan, kembalikan kamera, hapus simpanan. Permainan dijeda saat terbuka.

const Style = preload("res://scripts/ui/ui_style.gd")

var main = null
var overlay: Control
var box: VBoxContainer


func build(root: Control, p_main) -> void:
	main = p_main
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.06, 0.03, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var p := Style.card(Color(0.99, 0.97, 0.93, 1.0), Style.BORDER, 22)
	p.custom_minimum_size = Vector2(440, 0)
	center.add_child(p)

	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	p.add_child(box)


func open() -> void:
	main.get_tree().paused = true
	overlay.visible = true
	fill()


func close_panel() -> void:
	overlay.visible = false
	main.hud.update_pause()


func _segment(items: Array, current, cb: Callable) -> HBoxContainer:
	# Baris tombol pilihan; items = [[nilai, teks], ...]. Yang terpilih berwarna hijau.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for it in items:
		var selected: bool = it[0] == current
		var b := Style.button(str(it[1]), Style.GREEN_DARK)
		if not selected:
			var normal := Style.style(Color(0.96, 0.92, 0.84), 10, 6.0)
			normal.set_border_width_all(2)
			normal.border_color = Style.BORDER
			var hover := Style.style(Color(1.0, 0.97, 0.9), 10, 6.0)
			hover.set_border_width_all(2)
			hover.border_color = Style.GREEN
			b.add_theme_stylebox_override("normal", normal)
			b.add_theme_stylebox_override("hover", hover)
			b.add_theme_stylebox_override("pressed", hover)
			b.add_theme_color_override("font_color", Style.INK)
			b.add_theme_color_override("font_hover_color", Style.INK)
			b.add_theme_color_override("font_pressed_color", Style.INK)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(cb.bind(it[0]))
		row.add_child(b)
	return row


func fill() -> void:
	Style.clear(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(Style.icon("gear", Style.INK, 28.0, Style.CREAM))
	head.add_child(Style.label("Pengaturan", 24))
	box.add_child(head)
	box.add_child(HSeparator.new())

	box.add_child(Style.label("Kontrol gerak", 17))
	box.add_child(_segment([["tap", "Tap"], ["joystick", "Analog"], ["both", "Keduanya"]], GameSettings.control_mode, _on_mode))
	var hint := ""
	match GameSettings.control_mode:
		"tap":
			hint = "Ketuk lantai untuk berjalan, ketuk stasiun untuk berinteraksi."
		"joystick":
			hint = "Geser joystick untuk berjalan, tekan tombol Aksi untuk berinteraksi."
		_:
			hint = "Ketuk lantai atau pakai joystick, tombol Aksi untuk berinteraksi."
	box.add_child(Style.label(hint, 12, Style.SOFT))

	if GameSettings.uses_joystick():
		box.add_child(Style.label("Posisi joystick", 17))
		box.add_child(_segment([["left", "Kiri"], ["right", "Kanan"]], GameSettings.joystick_side, _on_side))
		box.add_child(Style.label("Ukuran joystick", 17))
		box.add_child(_segment([[0, "Kecil"], [1, "Sedang"], [2, "Besar"]], GameSettings.joystick_size, _on_size))

	box.add_child(HSeparator.new())
	var save := Style.button("Simpan sekarang", Style.GREEN_DARK)
	save.pressed.connect(_on_save)
	box.add_child(save)
	var cam := Style.button("Kembalikan tampilan kamera", Style.BLUE)
	cam.pressed.connect(_on_camera)
	box.add_child(cam)
	var wipe := Style.button("Hapus data simpanan", Style.RED)
	wipe.pressed.connect(_on_wipe)
	box.add_child(wipe)
	var close := Style.button("Tutup", Style.ORANGE)
	close.pressed.connect(close_panel)
	box.add_child(close)


func _on_mode(v) -> void:
	GameSettings.set_mode(str(v))
	fill()


func _on_side(v) -> void:
	GameSettings.set_side(str(v))
	fill()


func _on_size(v) -> void:
	GameSettings.set_size(int(v))
	fill()


func _on_save() -> void:
	SaveManager.save_game(main)
	main.hud.notify("Progres disimpan")


func _on_camera() -> void:
	main.camera_rig.reset_view()
	main.hud.notify("Kamera dikembalikan")


func _on_wipe() -> void:
	SaveManager.delete_save()
	main.hud.notify("Data simpanan dihapus")
