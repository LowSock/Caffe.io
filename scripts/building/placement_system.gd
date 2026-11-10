extends Node
# Mode bangun: beli, pasang, pindah, putar, dan jual dekorasi; peti dan mesin
# hanya bisa dipindah/diputar. Permainan dijeda selama mode ini aktif.
#
# Cara pakai: ketuk perabot untuk memilih, atau pilih dari katalog lalu seret/ketuk
# lantai untuk menaruh; hijau = muat, merah = tidak muat. Putar dan Taruh ada di
# panel bawah (lihat ui/build_ui.gd).

const Catalog = preload("res://scripts/building/furniture_catalog.gd")

const GRID := 0.5
const TAP_LIMIT := 12.0

var main = null
var active := false
var state := "idle"        # idle | placing | moving | selected
var type := ""
var uid := -1              # -1 = item baru yang belum terpasang
var gx := 0.0
var gz := 0.0
var grot := 0

var _ghost: Node3D = null
var _overlay: MeshInstance3D = null
var _overlay_mat: StandardMaterial3D = null
var _orig := {}
var _press_pos := Vector2.ZERO
var _press_valid := false
var _dragged := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(p_main) -> void:
	main = p_main


func _process(delta: float) -> void:
	# Node ini berjalan terus saat permainan dijeda, jadi dipakai untuk memperbarui label stasiun.
	if main != null and main.furniture != null:
		main.furniture.update_labels(delta)


func snap(v: float) -> float:
	return snappedf(v, GRID)


# ============================================================
#  Masuk dan keluar mode bangun
# ============================================================

func enter_mode() -> void:
	if active:
		return
	active = true
	state = "idle"
	main.get_tree().paused = true
	EventBus.build_mode_changed.emit(true)
	_changed()


func exit_mode() -> void:
	if not active:
		return
	cancel()
	_clear_selection()
	active = false
	main.hud.update_pause()
	EventBus.build_mode_changed.emit(false)
	SaveManager.save_game(main)


func _changed() -> void:
	EventBus.build_state_changed.emit()


# ============================================================
#  Aksi
# ============================================================

func begin_new(t: String) -> void:
	if not active:
		return
	cancel()
	_clear_selection()
	var cost := Catalog.cost(t)
	if not main.economy.can_afford(cost):
		main.hud.notify("Gold tidak cukup (%d gold)" % cost)
		return
	var node = main.furniture.create_node(t)
	if node == null:
		return
	main.furniture.add_child(node)
	_ghost = node
	type = t
	uid = -1
	grot = 0
	var c = main.camera_rig.screen_to_ground(main.get_viewport().get_visible_rect().size * 0.5)
	var p := Vector3(main.camera_rig.focus.x, 0.0, main.camera_rig.focus.z)
	if c != null:
		p = c
	_set_ghost(p.x, p.z)
	state = "placing"
	_changed()


func begin_move() -> void:
	if state != "selected":
		return
	var it = main.furniture.get_item(uid)
	if it == null:
		return
	_ghost = it["node"]
	_orig = {"x": float(it["x"]), "z": float(it["z"]), "rot": int(it["rot"])}
	gx = float(it["x"])
	gz = float(it["z"])
	grot = int(it["rot"])
	state = "moving"
	_update_overlay()
	_changed()


func rotate_ghost() -> void:
	if state == "placing" or state == "moving":
		grot = (grot + 1) % 4
		_ghost.rotation_degrees.y = float(grot) * 90.0
		_update_overlay()
		_changed()
	elif state == "selected":
		var it = main.furniture.get_item(uid)
		if it == null:
			return
		var nr := (int(it["rot"]) + 1) % 4
		if main.furniture.can_place(type, float(it["x"]), float(it["z"]), nr, uid):
			main.furniture.move_item(uid, float(it["x"]), float(it["z"]), nr)
			grot = nr
			_update_overlay()
		else:
			main.hud.notify("Tidak muat kalau diputar")


func confirm() -> void:
	if state != "placing" and state != "moving":
		return
	if not is_valid():
		main.hud.notify("Tidak muat di sini")
		return
	if state == "placing":
		var cost := Catalog.cost(type)
		if not main.economy.spend(cost):
			main.hud.notify("Gold tidak cukup (%d gold)" % cost)
			return
		var it: Dictionary = main.furniture.register(type, _ghost, gx, gz, grot)
		uid = int(it["uid"])
		main.hud.notify("%s dipasang" % Catalog.item_name(type))
	else:
		main.furniture.move_item(uid, gx, gz, grot)
	_ghost = null
	state = "selected"
	_update_overlay()
	_changed()


func cancel() -> void:
	if state == "placing":
		if _ghost != null:
			main.furniture.remove_child(_ghost)
			_ghost.queue_free()
		_ghost = null
		state = "idle"
	elif state == "moving":
		if _ghost != null:
			_ghost.position = Vector3(float(_orig["x"]), 0.0, float(_orig["z"]))
			_ghost.rotation_degrees.y = float(int(_orig["rot"])) * 90.0
		_ghost = null
		state = "selected"
	_update_overlay()
	_changed()


func sell_selected() -> void:
	if state != "selected" or not Catalog.is_sellable(type):
		return
	var refund := roundi(float(Catalog.cost(type)) * 0.5)
	main.economy.earn(refund)
	main.furniture.remove_item(uid)
	main.hud.notify("%s dijual (+%d gold)" % [Catalog.item_name(type), refund])
	_clear_selection()
	_changed()


func select(it: Dictionary) -> void:
	uid = int(it["uid"])
	type = str(it["type"])
	gx = float(it["x"])
	gz = float(it["z"])
	grot = int(it["rot"])
	state = "selected"
	main.furniture.forced_node = it["node"]
	_update_overlay()
	_changed()


func deselect() -> void:
	_clear_selection()
	_changed()


func _clear_selection() -> void:
	main.furniture.forced_node = null
	if state == "selected" or state == "idle":
		state = "idle"
		uid = -1
		type = ""
	_hide_overlay()


func is_valid() -> bool:
	return main.furniture.can_place(type, gx, gz, grot, uid)


# ============================================================
#  Ghost dan overlay
# ============================================================

func _set_ghost(x: float, z: float) -> void:
	gx = snap(x)
	gz = snap(z)
	if _ghost != null:
		_ghost.position = Vector3(gx, 0.0, gz)
		_ghost.rotation_degrees.y = float(grot) * 90.0
	_update_overlay()
	_changed()


func _ensure_overlay() -> void:
	if _overlay != null:
		return
	_overlay = MeshInstance3D.new()
	_overlay.mesh = BoxMesh.new()
	_overlay_mat = StandardMaterial3D.new()
	_overlay_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay_mat.no_depth_test = true
	_overlay.material_override = _overlay_mat
	_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	main.furniture.add_child(_overlay)
	_overlay.visible = false


func _hide_overlay() -> void:
	if _overlay != null:
		_overlay.visible = false


func _update_overlay() -> void:
	if type == "" or not (state == "placing" or state == "moving" or state == "selected"):
		_hide_overlay()
		return
	_ensure_overlay()
	var r: Rect2 = main.furniture.footprint_rect(type, gx, gz, grot)
	var bm: BoxMesh = _overlay.mesh
	bm.size = Vector3(r.size.x, 0.08, r.size.y)
	_overlay.position = Vector3(gx, 0.06, gz)
	if state == "selected":
		_overlay_mat.albedo_color = Color(0.4, 0.7, 1.0, 0.4)
	elif is_valid():
		_overlay_mat.albedo_color = Color(0.3, 1.0, 0.4, 0.45)
	else:
		_overlay_mat.albedo_color = Color(1.0, 0.3, 0.3, 0.45)
	_overlay.visible = true


# ============================================================
#  Input (klik/tap/seret) saat mode bangun
# ============================================================

func _ground(p: Vector2) -> Variant:
	return main.camera_rig.screen_to_ground(p)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_press_pos = mb.position
			_press_valid = not main.camera_rig.gesturing
			_dragged = false
		else:
			if _press_valid and not _dragged and not main.camera_rig.gesturing:
				_tap(mb.position)
			_press_valid = false
			_dragged = false
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var moving_ghost := state == "placing" or state == "moving"
		if _press_valid and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if main.camera_rig.gesturing:
				_press_valid = false
			elif mm.position.distance_to(_press_pos) > TAP_LIMIT:
				if moving_ghost:
					_dragged = true
					var g = _ground(mm.position)
					if g != null:
						var v: Vector3 = g
						_set_ghost(v.x, v.z)
				else:
					_press_valid = false
		elif moving_ghost and mm.button_mask == 0 and mm.device != InputEvent.DEVICE_ID_EMULATION:
			var g2 = _ground(mm.position)
			if g2 != null:
				var v2: Vector3 = g2
				_set_ghost(v2.x, v2.z)


func _tap(screen_pos: Vector2) -> void:
	var g = _ground(screen_pos)
	if g == null:
		return
	var p: Vector3 = g
	if state == "placing" or state == "moving":
		_set_ghost(p.x, p.z)
		return
	var it = main.furniture.item_at(p)
	if it == null:
		deselect()
	else:
		select(it)
