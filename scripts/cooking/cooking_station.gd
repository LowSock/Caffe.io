extends Node3D
# Satu script untuk tiga jenis stasiun: "crate" (peti bahan),
# "machine" (mesin minuman), dan "counter" (meja saji).

const Data = preload("res://scripts/common/data.gd")
const Gfx = preload("res://scripts/common/gfx.gd")

const REVEAL_DIST := 2.6   # label stasiun terdekat muncul kalau chef sedekat ini

var kind := ""
var key := ""
var title := ""
var extra := ""
var radius := 1.5        # jarak berdiri staf saat berinteraksi
var hit_radius := 1.4    # jarak klik/tap yang dianggap mengenai stasiun

# khusus mesin
var state := "idle"      # idle | brewing | ready
var recipe_id := ""
var timer := 0.0
var duration := 1.0
var last_user := -1
var level := 1           # level mesin dari upgrade
var main = null          # diisi FurnitureManager (untuk mendeteksi pemain yang dekat)
var _alpha := 0.0
var _trim_added := false

var _label: Label3D
var _bar: MeshInstance3D
var _bar_back: MeshInstance3D
var _lamp: MeshInstance3D
var _top_y := 1.0
var _size := Vector3.ONE


func setup(p_kind: String, p_key: String, p_title: String, color: Color, size: Vector3) -> void:
	kind = p_kind
	key = p_key
	title = p_title
	_top_y = size.y
	_size = size

	Gfx.blob_shadow(self, size.x * 0.75, size.z * 0.75, 0.9)
	Gfx.box(self, size, Vector3(0, size.y * 0.5, 0), color)

	var label_y := size.y + 0.95
	if kind == "machine":
		label_y = size.y + 1.55

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.pixel_size = 0.012
	_label.font_size = 34
	_label.outline_size = 10
	_label.position = Vector3(0, label_y, 0)
	add_child(_label)

	match kind:
		"crate":
			_decorate_crate()
		"machine":
			_decorate_machine()
		"counter":
			_decorate_counter()

	refresh_label()
	_apply_alpha()


# ============================================================
#  Dekorasi
# ============================================================

func _decorate_crate() -> void:
	var s := _size
	var post := Color(0.42, 0.25, 0.13)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Gfx.box(self, Vector3(0.14, s.y + 0.04, 0.14), Vector3(sx * (s.x * 0.5 - 0.04), s.y * 0.5, sz * (s.z * 0.5 - 0.04)), post)
	Gfx.box(self, Vector3(s.x + 0.02, 0.08, s.z + 0.02), Vector3(0, s.y * 0.3, 0), post.lightened(0.05))
	Gfx.box(self, Vector3(s.x + 0.02, 0.08, s.z + 0.02), Vector3(0, s.y * 0.75, 0), post.lightened(0.05))
	Gfx.box(self, Vector3(s.x - 0.24, 0.05, s.z - 0.24), Vector3(0, s.y + 0.02, 0), Color(0.24, 0.15, 0.1))


func add_topper(ing: String, c: Color) -> void:
	var y := _top_y + 0.05
	# Pelat warna di sisi depan peti (dengan alas krem) supaya jenis bahan gampang dibedakan.
	var plate_y := _top_y * 0.52
	var plate_z := _size.z * 0.5
	Gfx.box(self, Vector3(1.22, 0.26, 0.04), Vector3(0, plate_y, plate_z + 0.025), Color(0.96, 0.92, 0.82))
	Gfx.box(self, Vector3(1.06, 0.16, 0.05), Vector3(0, plate_y, plate_z + 0.045), c)
	match ing:
		"boba":
			var pearl := Color(0.14, 0.08, 0.06)
			for i in range(4):
				Gfx.sphere(self, 0.13, Vector3(-0.42 + i * 0.28, y + 0.13, -0.15), pearl, 1.0)
				Gfx.sphere(self, 0.13, Vector3(-0.42 + i * 0.28, y + 0.13, 0.15), pearl, 1.0)
			for i in range(3):
				Gfx.sphere(self, 0.13, Vector3(-0.28 + i * 0.28, y + 0.34, 0.0), pearl.lightened(0.08), 1.0)
			for hx in [-0.3, 0.1, 0.4]:
				Gfx.sphere(self, 0.03, Vector3(hx, y + 0.45, -0.04), Color(1, 1, 1, 0.8), 1.0)
		"beans":
			for off in [Vector3(-0.4, 0, -0.1), Vector3(0.0, 0, 0.2), Vector3(0.4, 0, -0.1), Vector3(-0.1, 0, -0.2)]:
				Gfx.sphere(self, 0.2, off + Vector3(0, y + 0.1, 0), c, 0.7)
		"milk":
			Gfx.box(self, Vector3(0.3, 0.5, 0.3), Vector3(-0.3, y + 0.25, 0), c)
			Gfx.box(self, Vector3(0.3, 0.5, 0.3), Vector3(0.2, y + 0.25, 0.05), c)
			Gfx.box(self, Vector3(0.32, 0.12, 0.32), Vector3(-0.3, y + 0.32, 0), Color(0.45, 0.65, 0.9))
			Gfx.box(self, Vector3(0.32, 0.12, 0.32), Vector3(0.2, y + 0.32, 0.05), Color(0.45, 0.65, 0.9))
		"lemon":
			for off in [Vector3(-0.35, 0, 0.0), Vector3(0.1, 0, 0.15), Vector3(0.4, 0, -0.1)]:
				Gfx.sphere(self, 0.24, off + Vector3(0, y + 0.15, 0), c, 0.78)
				Gfx.sphere(self, 0.07, off + Vector3(0.24, y + 0.15, 0), c.darkened(0.12), 1.0)
			var leaf_l := Gfx.box(self, Vector3(0.3, 0.04, 0.16), Vector3(0.0, y + 0.42, 0.25), Color(0.3, 0.65, 0.3))
			leaf_l.rotation_degrees.y = 25.0
		"coconut":
			Gfx.sphere(self, 0.3, Vector3(-0.3, y + 0.28, 0), Color(0.35, 0.22, 0.14))
			Gfx.sphere(self, 0.3, Vector3(0.25, y + 0.28, 0.05), c)
		"tea":
			for i in range(3):
				var leaf := Gfx.box(self, Vector3(0.5, 0.1, 0.28), Vector3(-0.3 + i * 0.3, y + 0.1 + i * 0.05, 0), c)
				leaf.rotation_degrees.y = -20.0 + i * 20.0
		_:
			Gfx.sphere(self, 0.32, Vector3(0, y + 0.3, 0), c)


func _decorate_machine() -> void:
	var s := _size
	var top := s.y
	var fz := s.z * 0.5
	var dark := Color(0.22, 0.17, 0.15)
	var metal := Color(0.78, 0.78, 0.8)
	var gold := Color(0.95, 0.78, 0.2)

	match key:
		"coffee":
			Gfx.box(self, Vector3(1.3, 0.55, 0.05), Vector3(0, 0.78, fz + 0.02), dark)
			for sx in [-0.38, 0.38]:
				Gfx.cylinder(self, 0.2, 0.2, 0.22, Vector3(sx, 0.9, fz + 0.12), metal, 10)
				Gfx.box(self, Vector3(0.1, 0.06, 0.4), Vector3(sx, 0.7, fz + 0.3), dark)
			Gfx.box(self, Vector3(1.3, 0.06, 0.45), Vector3(0, 0.34, fz + 0.22), metal)
			for sx in [-0.38, 0.38]:
				Gfx.cylinder(self, 0.14, 0.11, 0.18, Vector3(sx, 0.46, fz + 0.3), Color(0.97, 0.96, 0.94), 8)
			Gfx.cylinder(self, 0.32, 0.22, 0.5, Vector3(-0.4, top + 0.25, -0.1), Color(0.3, 0.2, 0.12), 8)
			Gfx.cylinder(self, 0.34, 0.34, 0.08, Vector3(-0.4, top + 0.54, -0.1), Color(0.45, 0.6, 0.35), 8)
			for kx in [0.2, 0.45]:
				Gfx.cylinder(self, 0.07, 0.07, 0.1, Vector3(kx, top + 0.05, 0.3), gold, 8)
		"tea":
			Gfx.cylinder(self, 0.5, 0.5, 0.8, Vector3(0, top + 0.4, 0), Color(0.72, 0.76, 0.7), 12)
			Gfx.cylinder(self, 0.4, 0.5, 0.12, Vector3(0, top + 0.86, 0), Color(0.5, 0.58, 0.45), 12)
			Gfx.sphere(self, 0.09, Vector3(0, top + 1.0, 0), gold)
			Gfx.box(self, Vector3(0.1, 0.1, 0.3), Vector3(0, top + 0.3, 0.6), dark)
			Gfx.box(self, Vector3(1.2, 0.4, 0.05), Vector3(0, 0.7, fz + 0.02), Color(0.2, 0.3, 0.2))
			for sx in [-0.3, 0.3]:
				Gfx.sphere(self, 0.08, Vector3(sx, 0.7, fz + 0.07), gold)
		"blender":
			Gfx.box(self, Vector3(1.3, 0.5, 0.05), Vector3(0, 0.7, fz + 0.02), dark)
			var btn_colors := [Color(0.85, 0.3, 0.3), Color(0.95, 0.8, 0.25), Color(0.4, 0.75, 0.4)]
			for i in range(3):
				Gfx.box(self, Vector3(0.14, 0.14, 0.06), Vector3(-0.3 + i * 0.3, 0.7, fz + 0.06), btn_colors[i])
			var jar := Gfx.cylinder(self, 0.44, 0.3, 0.9, Vector3(0, top + 0.45, 0), Color(0.8, 0.92, 1.0), 10)
			jar.material_override = Gfx.glass_mat(Color(0.8, 0.92, 1.0), 0.4)
			Gfx.cylinder(self, 0.3, 0.2, 0.45, Vector3(0, top + 0.25, 0), Color(0.95, 0.93, 0.7), 10)
			Gfx.cylinder(self, 0.46, 0.46, 0.1, Vector3(0, top + 0.95, 0), dark, 10)

	# lampu status: abu = diam, kuning = diproses, hijau = siap
	_lamp = Gfx.sphere(self, 0.09, Vector3(0.55, 0.28, fz + 0.06), Color(0.4, 0.4, 0.4))

	_bar_back = MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(1.3, 0.14, 0.14)
	_bar_back.mesh = bb
	_bar_back.material_override = Gfx.mat(Color(0.2, 0.15, 0.1))
	_bar_back.position = Vector3(0, 0.14, fz + 0.1)
	_bar_back.visible = false
	add_child(_bar_back)

	_bar = MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(1.2, 0.16, 0.16)
	_bar.mesh = fb
	_bar.material_override = Gfx.mat(Color(0.4, 0.85, 0.35))
	_bar.position = Vector3(0, 0.14, fz + 0.12)
	_bar.visible = false
	add_child(_bar)


func _decorate_counter() -> void:
	var s := _size
	var gold := Color(0.95, 0.78, 0.2)
	Gfx.box(self, Vector3(s.x + 0.24, 0.08, s.z + 0.24), Vector3(0, s.y + 0.04, 0), Color(0.94, 0.86, 0.7))
	Gfx.box(self, Vector3(0.05, s.y * 0.7, s.z - 0.4), Vector3(s.x * 0.5 + 0.02, s.y * 0.5, 0), Color(0.55, 0.35, 0.2))
	Gfx.box(self, Vector3(0.5, 0.3, 0.45), Vector3(0.1, s.y + 0.23, -1.6), Color(0.25, 0.25, 0.28))
	Gfx.box(self, Vector3(0.4, 0.2, 0.04), Vector3(-0.1, s.y + 0.45, -1.6), Color(0.5, 0.8, 0.6))
	Gfx.sphere(self, 0.13, Vector3(-0.3, s.y + 0.2, 1.2), gold, 0.7)


# ============================================================
#  Label & status mesin
# ============================================================

func set_level(l: int) -> void:
	level = l
	if kind == "machine" and level >= 3 and not _trim_added:
		_trim_added = true
		Gfx.box(self, Vector3(_size.x + 0.06, 0.08, _size.z + 0.06), Vector3(0, _size.y - 0.04, 0), Color(0.95, 0.78, 0.2))
	if _label != null:
		refresh_label()


func set_extra(t: String) -> void:
	extra = t
	refresh_label()


func refresh_label() -> void:
	var t := title
	if kind == "machine" and level > 1:
		t += "  Lv%d" % level
	var ex := extra
	_label.modulate = Color(1, 1, 1, _alpha)
	if kind == "machine":
		if state == "brewing":
			ex = str(Data.RECIPES[recipe_id]["name"]) + "..."
		elif state == "ready":
			ex = "SIAP: " + str(Data.RECIPES[recipe_id]["name"])
			_label.modulate = Color(1.0, 0.95, 0.45, _alpha)
		_update_lamp()
	if ex != "":
		t += "\n" + ex
	_label.text = t


func _update_lamp() -> void:
	if _lamp == null:
		return
	match state:
		"brewing":
			_lamp.material_override = Gfx.glow_mat(Color(1.0, 0.8, 0.2), 2.0)
		"ready":
			_lamp.material_override = Gfx.glow_mat(Color(0.3, 1.0, 0.4), 2.5)
		_:
			_lamp.material_override = Gfx.mat(Color(0.4, 0.4, 0.4))


func start_brew(rid: String, dur: float, actor_id: int) -> void:
	state = "brewing"
	recipe_id = rid
	timer = 0.0
	duration = dur
	last_user = actor_id
	_set_bar(0.0)
	_show_bar(true)
	refresh_label()


func take_drink() -> String:
	var rid := recipe_id
	state = "idle"
	recipe_id = ""
	refresh_label()
	return rid


func reset_machine() -> void:
	if kind != "machine":
		return
	state = "idle"
	recipe_id = ""
	timer = 0.0
	_show_bar(false)
	refresh_label()


func _show_bar(v: bool) -> void:
	if _bar != null:
		_bar.visible = v
		_bar_back.visible = v


func _set_bar(p: float) -> void:
	if _bar == null:
		return
	_bar.scale.x = maxf(p, 0.001)
	_bar.position.x = -0.6 * (1.0 - p)


func _apply_alpha() -> void:
	if _label == null:
		return
	var c := _label.modulate
	c.a = _alpha
	_label.modulate = c
	_label.visible = _alpha > 0.02


func update_label(delta: float, show_it: bool) -> void:
	# Dipanggil FurnitureManager: hanya stasiun terdekat dengan chef (atau yang dipilih
	# di mode bangun) yang labelnya muncul, jadi label tetangga tidak saling menumpuk.
	var target := 0.0
	if show_it:
		target = 1.0
	if absf(_alpha - target) > 0.001:
		_alpha = move_toward(_alpha, target, delta * 6.0)
		_apply_alpha()


func _process(delta: float) -> void:
	if kind == "machine" and state == "brewing":
		timer += delta
		var p := clampf(timer / duration, 0.0, 1.0)
		_set_bar(p)
		if timer >= duration:
			state = "ready"
			_show_bar(false)
			refresh_label()
