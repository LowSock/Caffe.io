extends Node3D
# Lingkungan: cahaya hangat (berubah sepanjang hari), cangkang kafe yang cozy,
# jalan raya lebar di sisi BARAT kafe, toko-toko seberang jalan, halaman
# belakang, dan mobil lalu-lalang.
#
# Arah: utara = atas layar (-Z), barat = kiri layar (-X).

const Data = preload("res://scripts/common/data.gd")
const Gfx = preload("res://scripts/common/gfx.gd")
const Nav = preload("res://scripts/world/navigation.gd")

const USE_SHADOWS := true

# Toko di seberang jalan (sisi barat)
const SHOPS := [
	{"name": "TOKO ROTI", "color": Color(0.93, 0.78, 0.55), "a": Color(0.85, 0.3, 0.25), "b": Color(0.97, 0.93, 0.85), "deco": "pots"},
	{"name": "APOTEK", "color": Color(0.85, 0.92, 0.85), "a": Color(0.25, 0.6, 0.4), "b": Color(0.97, 0.93, 0.85), "deco": "cross"},
	{"name": "TOKO BUKU", "color": Color(0.82, 0.84, 0.92), "a": Color(0.3, 0.4, 0.7), "b": Color(0.97, 0.93, 0.85), "deco": "pots"},
	{"name": "BUNGA", "color": Color(0.98, 0.87, 0.88), "a": Color(0.88, 0.45, 0.58), "b": Color(0.97, 0.93, 0.85), "deco": "flowers"},
	{"name": "MINIMART", "color": Color(0.95, 0.91, 0.78), "a": Color(0.93, 0.58, 0.2), "b": Color(0.97, 0.93, 0.85), "deco": "pots"},
	{"name": "LAUNDRY", "color": Color(0.82, 0.92, 0.93), "a": Color(0.2, 0.58, 0.66), "b": Color(0.97, 0.93, 0.85), "deco": "pots"},
]

var sun: DirectionalLight3D
var env: Environment
var _lamps: Array = []
var _cars: Array = []
var _hour_pivot: Node3D
var _min_pivot: Node3D
var _bulb_mat: StandardMaterial3D
var _cafe: Node3D = null
var _rng := RandomNumberGenerator.new()


func build() -> void:
	_rng.randomize()
	_bulb_mat = Gfx.glow_mat(Color(1.0, 0.8, 0.48), 2.2)
	_build_lighting()
	rebuild_cafe()
	EventBus.upgrade_bought.connect(_on_upgrade_bought)
	_build_street()
	_build_shops()
	_build_backyard()
	_build_cars()
	_build_vignette()


func _process(delta: float) -> void:
	_update_daylight()
	_update_clock()
	_update_cars(delta)


func _box(pos: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	return Gfx.box(self, size, pos, c)


# ============================================================
#  Pencahayaan: hangat, redup, dan berubah sepanjang hari
# ============================================================

func _build_lighting() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.45, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.84, 0.7)
	env.ambient_light_energy = 0.26
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.88
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_hdr_threshold = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 55.0, 0.0)
	sun.light_color = Color(1.0, 0.85, 0.68)
	sun.light_energy = 0.55
	sun.shadow_enabled = USE_SHADOWS and not OS.has_feature("mobile")
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_blur = 1.8
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30.0, -120.0, 0.0)
	fill.light_color = Color(0.85, 0.78, 0.95)
	fill.light_energy = 0.1
	add_child(fill)

	# Lampu hangat: dekat jendela saji, tengah kafe, dan dua titik di jalan
	var spots := [Vector3(-6.2, 2.6, -0.5), Vector3(0.0, 3.6, 0.5), Vector3(-10.5, 3.0, -4.0), Vector3(-10.5, 3.0, 3.0), Vector3(7.0, 2.8, 1.0)]
	for sp in spots:
		var omni := OmniLight3D.new()
		omni.position = sp
		omni.light_color = Color(1.0, 0.78, 0.5)
		omni.light_energy = 0.7
		omni.omni_range = 8.0
		add_child(omni)
		_lamps.append(omni)


func _update_daylight() -> void:
	if sun == null:
		return
	var h := sin(GameManager.day_progress() * PI)    # 0 pagi, 1 siang, 0 sore
	sun.rotation_degrees.x = lerpf(-20.0, -52.0, h)
	sun.light_energy = lerpf(0.45, 0.62, h)
	sun.light_color = Color(1.0, 0.62, 0.38).lerp(Color(1.0, 0.9, 0.78), h)
	env.ambient_light_energy = lerpf(0.2, 0.28, h)
	# lampu dalam ruangan makin terasa saat pagi dan sore
	var lamp_e := lerpf(0.95, 0.55, h)
	for l in _lamps:
		l.light_energy = lamp_e


# ============================================================
#  Kafe: ukuran mengikuti level perluasan dan dibangun ulang saat diperluas
# ============================================================

func rebuild_cafe() -> void:
	if _cafe != null:
		remove_child(_cafe)
		_cafe.queue_free()
	_cafe = Node3D.new()
	_cafe.name = "Cafe"
	add_child(_cafe)
	_hour_pivot = null
	_min_pivot = null
	_build_cafe_shell()
	_build_cafe_decor()
	_build_garden()


func _on_upgrade_bought(id: String, _level: int) -> void:
	if id == "size":
		rebuild_cafe()


func _cb(pos: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	return Gfx.box(_cafe, size, pos, c)


func _build_cafe_shell() -> void:
	var xmin := Nav.CAFE_X_MIN
	var xmax := Nav.cafe_x_max
	var zmin := Nav.CAFE_Z_MIN
	var zmax := Nav.cafe_z_max
	var zend := zmax + 0.15
	var wl := zend + 5.95            # panjang tembok barat/timur (dari z = -5.95)
	var wc := (zend - 5.95) * 0.5    # titik tengahnya

	# Lantai ubin hangat
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var fw := xmax - xmin
	var fd := zmax - zmin
	pm.size = Vector2(fw, fd)
	floor_mi.mesh = pm
	floor_mi.position = Vector3((xmax + xmin) * 0.5, 0.0, (zmax + zmin) * 0.5)
	var fm := Gfx.mat(Color(0.93, 0.85, 0.78), 0.8)
	fm.albedo_texture = Gfx.tile_texture()
	fm.uv1_scale = Vector3(fw / 4.0, fd / 4.0, 1.0)
	floor_mi.material_override = fm
	_cafe.add_child(floor_mi)

	var wall_low := Color(0.5, 0.34, 0.22)
	var wall_up := Color(0.95, 0.87, 0.74)
	var trim := Color(0.36, 0.23, 0.14)

	# Tembok utara
	var left := xmin - 0.3
	var right := xmax + 0.3
	var nx := (left + right) * 0.5
	var nl := right - left
	_cb(Vector3(nx, 0.6, -5.8), Vector3(nl, 1.2, 0.3), wall_low)
	_cb(Vector3(nx, 2.15, -5.8), Vector3(nl, 1.9, 0.3), wall_up)
	_cb(Vector3(nx, 1.22, -5.62), Vector3(nl, 0.1, 0.12), trim)

	# Tembok timur
	_cb(Vector3(xmax + 0.15, 0.6, wc), Vector3(0.3, 1.2, wl), wall_low)
	_cb(Vector3(xmax + 0.15, 2.15, wc), Vector3(0.3, 1.9, wl), wall_up)
	_cb(Vector3(xmax - 0.03, 1.22, wc), Vector3(0.12, 0.1, wl), trim)

	# Tembok barat (rendah, supaya jalan tetap terlihat) dengan jendela saji
	# di z -3.4 sampai 2.4 dan pintu staf di z 3.9 sampai 5.1
	var lb := zend - 5.1
	var lbc := 5.1 + lb * 0.5
	_cb(Vector3(-8.4, 0.6, -1.025), Vector3(0.3, 1.2, 9.85), wall_low)
	_cb(Vector3(-8.4, 0.6, lbc), Vector3(0.3, 1.2, lb), wall_low)
	_cb(Vector3(-8.4, 1.8, -4.675), Vector3(0.3, 1.2, 2.55), wall_up)
	_cb(Vector3(-8.4, 1.8, 3.15), Vector3(0.3, 1.2, 1.5), wall_up)
	_cb(Vector3(-8.4, 1.8, lbc), Vector3(0.3, 1.2, lb), wall_up)
	_cb(Vector3(-8.4, 2.25, 4.5), Vector3(0.3, 0.3, 1.2), wall_up)
	_cb(Vector3(-8.22, 1.22, wc), Vector3(0.12, 0.08, wl), trim)
	_cb(Vector3(-8.4, 1.8, -3.4), Vector3(0.34, 1.2, 0.12), trim)
	_cb(Vector3(-8.4, 1.8, 2.4), Vector3(0.34, 1.2, 0.12), trim)
	_cb(Vector3(-8.4, 2.4, -0.5), Vector3(0.34, 0.12, 5.92), trim)
	_cb(Vector3(-8.4, 1.05, 3.9), Vector3(0.34, 2.1, 0.14), trim)
	_cb(Vector3(-8.4, 1.05, 5.1), Vector3(0.34, 2.1, 0.14), trim)

	# Tirai kain bergaris di atas jendela saji (sisi dalam)
	var stripes := 12
	var sw := 5.8 / float(stripes)
	for k in range(stripes):
		var c := Color(0.82, 0.32, 0.26)
		if k % 2 == 1:
			c = Color(0.98, 0.93, 0.84)
		_cb(Vector3(-8.16, 2.2, -3.4 + sw * (k + 0.5)), Vector3(0.06, 0.34, sw), c)

	# Jendela utara + kotak bunga (jumlahnya mengikuti lebar kafe)
	var xs: Array = [-5.2, 0.2]
	var wx := 5.6
	while wx < xmax - 1.4:
		xs.append(wx)
		wx += 5.4
	var fcolors := [Color(0.9, 0.45, 0.55), Color(0.95, 0.75, 0.3), Color(0.9, 0.5, 0.4)]
	for i in range(xs.size()):
		_window(Vector3(xs[i], 2.4, -5.62), true)
		_flower_box(Vector3(xs[i], 1.32, -5.42), fcolors[i % fcolors.size()])


func _window(center: Vector3, along_x: bool) -> void:
	var frame_c := Color(0.88, 0.8, 0.68)
	var glass := MeshInstance3D.new()
	var b := BoxMesh.new()
	if along_x:
		b.size = Vector3(2.0, 1.3, 0.06)
	else:
		b.size = Vector3(0.06, 1.3, 2.0)
	glass.mesh = b
	glass.position = center
	glass.material_override = Gfx.glow_mat(Color(0.95, 0.85, 0.65), 0.5)
	_cafe.add_child(glass)
	if along_x:
		_cb(center + Vector3(0, 0.7, 0), Vector3(2.2, 0.12, 0.12), frame_c)
		_cb(center + Vector3(0, -0.7, 0), Vector3(2.2, 0.12, 0.12), frame_c)
		_cb(center + Vector3(-1.05, 0, 0), Vector3(0.12, 1.4, 0.12), frame_c)
		_cb(center + Vector3(1.05, 0, 0), Vector3(0.12, 1.4, 0.12), frame_c)
		_cb(center, Vector3(0.06, 1.3, 0.1), frame_c)
	else:
		_cb(center + Vector3(0, 0.7, 0), Vector3(0.12, 0.12, 2.2), frame_c)
		_cb(center + Vector3(0, -0.7, 0), Vector3(0.12, 0.12, 2.2), frame_c)
		_cb(center + Vector3(0, 0, -1.05), Vector3(0.12, 1.4, 0.12), frame_c)
		_cb(center + Vector3(0, 0, 1.05), Vector3(0.12, 1.4, 0.12), frame_c)
		_cb(center, Vector3(0.1, 1.3, 0.06), frame_c)


func _flower_box(pos: Vector3, flower: Color) -> void:
	_cb(pos, Vector3(2.0, 0.26, 0.3), Color(0.5, 0.32, 0.2))
	for i in range(5):
		Gfx.sphere(_cafe, 0.14, pos + Vector3(-0.8 + i * 0.4, 0.22, 0.0), flower, 0.9)
		Gfx.sphere(_cafe, 0.12, pos + Vector3(-0.6 + i * 0.4, 0.2, 0.05), Color(0.3, 0.55, 0.3), 0.9)


# ============================================================
#  Dekorasi tetap dalam kafe (perabot lain ada di FurnitureManager)
# ============================================================

func _build_cafe_decor() -> void:
	var xmax := Nav.cafe_x_max

	# Papan menu di tembok timur (isinya dibaca dari data resep)
	_cb(Vector3(xmax - 0.07, 2.1, -2.0), Vector3(0.1, 1.5, 2.4), Color(0.45, 0.3, 0.18))
	_cb(Vector3(xmax - 0.11, 2.1, -2.0), Vector3(0.06, 1.3, 2.2), Color(0.2, 0.26, 0.22))
	var menu := "MENU"
	for rid in Data.RECIPES.keys():
		menu += "\n%s  %d" % [Data.RECIPES[rid]["name"], int(Data.RECIPES[rid]["price"])]
	var ml := Label3D.new()
	ml.text = menu
	ml.font_size = 20
	ml.pixel_size = 0.0075
	ml.outline_size = 0
	ml.modulate = Color(0.97, 0.95, 0.85)
	ml.position = Vector3(xmax - 0.16, 2.1, -2.0)
	ml.rotation_degrees.y = -90.0
	_cafe.add_child(ml)

	# Jam dinding (jarumnya ikut waktu game)
	var clock := Node3D.new()
	clock.position = Vector3(xmax - 0.09, 2.5, 2.6)
	_cafe.add_child(clock)
	var face := Gfx.cylinder(clock, 0.4, 0.4, 0.06, Vector3(0, 0, 0), Color(0.97, 0.94, 0.86), 16)
	face.rotation_degrees.z = 90.0
	var rim := Gfx.cylinder(clock, 0.45, 0.45, 0.04, Vector3(0.015, 0, 0), Color(0.4, 0.25, 0.15), 16)
	rim.rotation_degrees.z = 90.0
	_hour_pivot = Node3D.new()
	_hour_pivot.position = Vector3(-0.05, 0, 0)
	clock.add_child(_hour_pivot)
	Gfx.box(_hour_pivot, Vector3(0.03, 0.2, 0.05), Vector3(0, 0.1, 0), Color(0.15, 0.1, 0.08))
	_min_pivot = Node3D.new()
	_min_pivot.position = Vector3(-0.07, 0, 0)
	clock.add_child(_min_pivot)
	Gfx.box(_min_pivot, Vector3(0.03, 0.3, 0.03), Vector3(0, 0.15, 0), Color(0.15, 0.1, 0.08))

	# Bingkai gambar di tembok utara
	_frame(Vector3(-3.3, 2.3, -5.58), Color(0.85, 0.6, 0.4))
	_frame(Vector3(-2.0, 2.45, -5.58), Color(0.5, 0.65, 0.55))

	# Lampu meja di meja saji
	_table_lamp(Vector3(-7.45, 1.08, -2.4))

	# Lampu hias (festoon) di dalam kafe
	_festoon(Vector3(-8.1, 2.95, -5.45), Vector3(xmax - 0.15, 2.95, -5.45), int((xmax + 8.1) * 2.4), 0.35, _cafe)
	_festoon(Vector3(-8.0, 2.6, -3.4), Vector3(-8.0, 2.6, 2.4), 14, 0.2, _cafe)


func _frame(pos: Vector3, art: Color) -> void:
	_cb(pos, Vector3(0.95, 0.75, 0.06), Color(0.42, 0.27, 0.16))
	_cb(pos + Vector3(0, 0, 0.035), Vector3(0.78, 0.58, 0.02), art)
	_cb(pos + Vector3(0, -0.08, 0.05), Vector3(0.5, 0.2, 0.02), art.lightened(0.25))


func _table_lamp(pos: Vector3) -> void:
	Gfx.cylinder(_cafe, 0.12, 0.16, 0.08, pos + Vector3(0, 0.04, 0), Color(0.4, 0.26, 0.16), 8)
	Gfx.cylinder(_cafe, 0.03, 0.03, 0.25, pos + Vector3(0, 0.2, 0), Color(0.4, 0.26, 0.16), 6)
	var shade := Gfx.cylinder(_cafe, 0.12, 0.22, 0.3, pos + Vector3(0, 0.45, 0), Color(1.0, 0.85, 0.55), 10)
	shade.material_override = Gfx.glow_mat(Color(1.0, 0.8, 0.5), 1.6)


func _festoon(a: Vector3, b: Vector3, count: int, sag: float, parent: Node3D = null) -> void:
	# Untaian lampu kecil dari a ke b yang melengkung ke bawah.
	var par: Node3D = self
	if parent != null:
		par = parent
	for i in range(count + 1):
		var t := float(i) / float(count)
		var p := a.lerp(b, t) + Vector3(0.0, -sag * sin(PI * t), 0.0)
		var bulb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.14
		sm.radial_segments = 6
		sm.rings = 3
		bulb.mesh = sm
		bulb.material_override = _bulb_mat
		bulb.position = p
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		par.add_child(bulb)


func _build_garden() -> void:
	# Semak dan pohon di timur dan selatan kafe (ikut bergeser saat kafe diperluas).
	var green := Color(0.25, 0.46, 0.27)
	var xmax := Nav.cafe_x_max
	var zmax := Nav.cafe_z_max
	var zend := zmax + 0.15
	_cb(Vector3(xmax + 1.45, 0.4, (zend - 5.95) * 0.5), Vector3(0.9, 0.8, zend + 5.95), green)
	var left := Nav.CAFE_X_MIN - 0.3
	var right := xmax + 1.9
	_cb(Vector3((left + right) * 0.5, 0.4, zmax + 1.45), Vector3(right - left, 0.8, 0.9), green)
	var tz := -3.0
	while tz < zmax:
		_tree(Vector3(xmax + 3.4, 0.0, tz), _cafe)
		tz += 6.0
	var tx := -4.0
	while tx < xmax:
		_tree(Vector3(tx, 0.0, zmax + 3.2), _cafe)
		tx += 7.0


func _update_clock() -> void:
	if _hour_pivot == null:
		return
	var m := GameManager.game_min
	_hour_pivot.rotation.x = fmod(m / 60.0, 12.0) / 12.0 * TAU
	_min_pivot.rotation.x = fmod(m, 60.0) / 60.0 * TAU


# ============================================================
#  Jalan raya lebar di sisi barat
#  Trotoar dekat kafe x -10.95..-8.55, jalan x -16.0..-10.95,
#  trotoar seberang x -17.4..-16.0
# ============================================================

func _paved(pos: Vector3, size: Vector3) -> void:
	var mi := Gfx.box(self, size, pos, Color(1, 1, 1))
	var m := Gfx.mat(Color(0.92, 0.9, 0.88), 0.9)
	m.albedo_texture = Gfx.paving_texture()
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.5, 0.5, 0.5)
	mi.material_override = m


func _build_street() -> void:
	var curb := Color(0.7, 0.68, 0.64)
	var line := Color(0.92, 0.89, 0.78)

	_box(Vector3(-14.0, -0.07, -5.0), Vector3(110, 0.1, 110), Color(0.44, 0.5, 0.38))

	_paved(Vector3(-9.75, 0.06, -5.0), Vector3(2.4, 0.12, 100))
	_box(Vector3(-11.01, 0.09, -5.0), Vector3(0.12, 0.18, 100), curb)

	_box(Vector3(-13.475, 0.03, -5.0), Vector3(5.05, 0.06, 100), Color(0.22, 0.22, 0.25))
	for i in range(-22, 22):
		_box(Vector3(-13.475, 0.066, i * 2.4), Vector3(0.12, 0.012, 1.2), line)
	_box(Vector3(-11.2, 0.066, -5.0), Vector3(0.08, 0.012, 100), line)
	_box(Vector3(-15.75, 0.066, -5.0), Vector3(0.08, 0.012, 100), line)
	for k in range(6):
		_box(Vector3(-13.475, 0.068, -10.8 + k * 0.9), Vector3(4.6, 0.012, 0.45), Color(0.93, 0.92, 0.88))

	_box(Vector3(-16.01, 0.09, -5.0), Vector3(0.12, 0.18, 100), curb)
	_paved(Vector3(-16.7, 0.06, -5.0), Vector3(1.4, 0.12, 100))

	for k in range(8):
		var lz := -22.0 + k * 6.0
		_street_lamp(lz)
		if k < 7:
			# untaian lampu antar-tiang lampu jalan
			_festoon(Vector3(-12.1, 3.1, lz), Vector3(-12.1, 3.1, lz + 6.0), 12, 0.5)

	_bench(Vector3(-9.0, 0.0, -5.4))
	_bench(Vector3(-9.0, 0.0, 6.2))
	_tree(Vector3(-10.9, 0.0, -12.5))
	_tree(Vector3(-10.9, 0.0, 3.0))
	_tree(Vector3(-10.9, 0.0, -20.0))
	_tree(Vector3(-10.9, 0.0, 14.0))


func _street_lamp(z: float) -> void:
	var l := Node3D.new()
	l.position = Vector3(-11.25, 0.0, z)
	add_child(l)
	var dark := Color(0.22, 0.2, 0.2)
	Gfx.cylinder(l, 0.06, 0.09, 3.2, Vector3(0, 1.6, 0), dark, 6)
	Gfx.box(l, Vector3(0.9, 0.07, 0.07), Vector3(-0.4, 3.2, 0), dark)
	var bulb := Gfx.sphere(l, 0.17, Vector3(-0.85, 3.1, 0), Color(1.0, 0.9, 0.7))
	bulb.material_override = Gfx.glow_mat(Color(1.0, 0.8, 0.5), 2.2)


func _bench(pos: Vector3) -> void:
	var b := Node3D.new()
	b.position = pos
	b.rotation_degrees.y = -90.0
	add_child(b)
	Gfx.blob_shadow(b, 0.9, 0.4, 0.6)
	var wood := Color(0.55, 0.36, 0.2)
	Gfx.box(b, Vector3(1.4, 0.08, 0.45), Vector3(0, 0.45, 0), wood)
	Gfx.box(b, Vector3(1.4, 0.45, 0.06), Vector3(0, 0.75, -0.2), wood)
	Gfx.box(b, Vector3(0.08, 0.45, 0.4), Vector3(-0.6, 0.22, 0), Color(0.2, 0.2, 0.22))
	Gfx.box(b, Vector3(0.08, 0.45, 0.4), Vector3(0.6, 0.22, 0), Color(0.2, 0.2, 0.22))


func _tree(pos: Vector3, parent: Node3D = null) -> void:
	var t := Node3D.new()
	t.position = pos
	if parent != null:
		parent.add_child(t)
	else:
		add_child(t)
	Gfx.blob_shadow(t, 1.1, 1.1, 0.7)
	Gfx.cylinder(t, 0.14, 0.2, 1.8, Vector3(0, 0.9, 0), Color(0.4, 0.28, 0.18), 6)
	Gfx.sphere(t, 0.95, Vector3(0, 2.5, 0), Color(0.3, 0.52, 0.3), 0.95)
	Gfx.sphere(t, 0.7, Vector3(0.5, 3.0, 0.2), Color(0.36, 0.6, 0.33), 0.95)
	Gfx.sphere(t, 0.65, Vector3(-0.5, 2.9, -0.2), Color(0.27, 0.48, 0.28), 0.95)


# ============================================================
#  Toko-toko seberang jalan (menghadap timur, ke arah kafe)
# ============================================================

func _build_shops() -> void:
	var step := 5.6
	var z0 := -29.0
	for i in range(9):
		var root := Node3D.new()
		root.position = Vector3(-17.4, 0.0, z0 + i * step)
		root.rotation_degrees.y = 90.0
		add_child(root)
		_build_shop(SHOPS[i % SHOPS.size()], root)


func _build_shop(data: Dictionary, root: Node3D) -> void:
	# Koordinat lokal: muka toko di z = 0 menghadap +Z lokal (jadi timur di dunia).
	var w := 5.4
	var h := 4.6
	var depth := 3.2
	var body: Color = data["color"]
	var awn_a: Color = data["a"]
	var awn_b: Color = data["b"]

	Gfx.box(root, Vector3(w, h, depth), Vector3(0, h * 0.5, -depth * 0.5), body)
	Gfx.box(root, Vector3(w + 0.1, 0.8, 0.12), Vector3(0, 0.4, 0.03), body.darkened(0.25))
	Gfx.box(root, Vector3(w + 0.3, 0.2, depth + 0.3), Vector3(0, h + 0.1, -depth * 0.5), body.darkened(0.4))

	var win := Gfx.box(root, Vector3(w * 0.45, 1.3, 0.06), Vector3(-w * 0.17, 1.5, 0.04), Color(0.95, 0.9, 0.75))
	win.material_override = Gfx.glow_mat(Color(1.0, 0.85, 0.6), 0.7)
	Gfx.box(root, Vector3(w * 0.45 + 0.16, 0.08, 0.1), Vector3(-w * 0.17, 2.18, 0.05), Color(0.35, 0.28, 0.22))
	Gfx.box(root, Vector3(1.0, 2.1, 0.08), Vector3(w * 0.3, 1.05, 0.05), Color(0.45, 0.3, 0.2))
	Gfx.box(root, Vector3(w * 0.8, 0.7, 0.1), Vector3(0, 3.5, 0.06), Color(0.2, 0.17, 0.16))
	var name_lab := Label3D.new()
	name_lab.text = str(data["name"])
	name_lab.font_size = 44
	name_lab.pixel_size = 0.01
	name_lab.outline_size = 0
	name_lab.modulate = Color(1.0, 0.92, 0.7)
	name_lab.position = Vector3(0, 3.5, 0.13)
	root.add_child(name_lab)

	var stripes := 10
	var sw := (w - 0.2) / float(stripes)
	for k in range(stripes):
		var c := awn_a
		if k % 2 == 1:
			c = awn_b
		var aw := Gfx.box(root, Vector3(sw, 0.08, 1.1), Vector3(-(w - 0.2) * 0.5 + sw * (k + 0.5), 2.75, 0.55), c)
		aw.rotation_degrees.x = 14.0

	match str(data["deco"]):
		"cross":
			var green := Color(0.3, 0.9, 0.5)
			Gfx.box(root, Vector3(0.5, 0.14, 0.05), Vector3(-w * 0.43, 3.5, 0.15), green).material_override = Gfx.glow_mat(green, 1.5)
			Gfx.box(root, Vector3(0.14, 0.5, 0.05), Vector3(-w * 0.43, 3.5, 0.15), green).material_override = Gfx.glow_mat(green, 1.5)
		"flowers":
			for fx in [-1.2, 0.0, 1.2]:
				var pot := Node3D.new()
				pot.position = Vector3(fx, 0.0, 1.3)
				root.add_child(pot)
				Gfx.cylinder(pot, 0.28, 0.2, 0.4, Vector3(0, 0.26, 0), Color(0.72, 0.4, 0.27), 8)
				Gfx.sphere(pot, 0.3, Vector3(0, 0.65, 0), Color(0.9, 0.4 + 0.1 * fx, 0.55), 0.9)
		_:
			var pot2 := Node3D.new()
			pot2.position = Vector3(w * 0.3 + 1.0, 0.0, 0.6)
			root.add_child(pot2)
			Gfx.cylinder(pot2, 0.28, 0.2, 0.45, Vector3(0, 0.28, 0), Color(0.72, 0.4, 0.27), 8)
			Gfx.sphere(pot2, 0.4, Vector3(0, 0.8, 0), Color(0.28, 0.52, 0.3), 0.9)


# ============================================================
#  Halaman belakang (utara kafe): pagar, semak, pohon, rumah jauh
# ============================================================

func _build_backyard() -> void:
	var wood := Color(0.55, 0.38, 0.24)
	for i in range(0, 33):
		_box(Vector3(-12.0 + i * 1.0, 0.5, -8.4), Vector3(0.12, 1.0, 0.12), wood)
	_box(Vector3(4.0, 0.35, -8.4), Vector3(32.0, 0.08, 0.06), wood)
	_box(Vector3(4.0, 0.75, -8.4), Vector3(32.0, 0.08, 0.06), wood)
	_box(Vector3(5.7, 0.4, -7.2), Vector3(28.5, 0.8, 0.9), Color(0.25, 0.46, 0.27))

	_tree(Vector3(-4.5, 0.0, -10.5))
	_tree(Vector3(1.5, 0.0, -11.5))
	_tree(Vector3(5.0, 0.0, -10.0))
	_tree(Vector3(-8.0, 0.0, -11.0))

	_house(Vector3(-6.0, 0.0, -16.5), Color(0.92, 0.82, 0.68), Color(0.6, 0.3, 0.25))
	_house(Vector3(0.0, 0.0, -17.5), Color(0.82, 0.88, 0.8), Color(0.35, 0.4, 0.5))
	_house(Vector3(6.0, 0.0, -16.5), Color(0.95, 0.88, 0.72), Color(0.5, 0.3, 0.2))
	_house(Vector3(-12.5, 0.0, -17.0), Color(0.88, 0.8, 0.7), Color(0.45, 0.35, 0.3))
	_house(Vector3(12.0, 0.0, -17.0), Color(0.82, 0.86, 0.92), Color(0.55, 0.3, 0.3))
	_house(Vector3(18.0, 0.0, -17.0), Color(0.9, 0.84, 0.7), Color(0.4, 0.3, 0.3))


func _house(pos: Vector3, body: Color, roof: Color) -> void:
	var h := Node3D.new()
	h.position = pos
	add_child(h)
	Gfx.box(h, Vector3(4.0, 3.0, 3.2), Vector3(0, 1.5, 0), body)
	var r1 := Gfx.box(h, Vector3(2.5, 0.16, 3.6), Vector3(-0.95, 3.35, 0), roof)
	r1.rotation_degrees.z = 35.0
	var r2 := Gfx.box(h, Vector3(2.5, 0.16, 3.6), Vector3(0.95, 3.35, 0), roof)
	r2.rotation_degrees.z = -35.0
	for wx in [-1.0, 1.0]:
		Gfx.box(h, Vector3(0.7, 0.7, 0.05), Vector3(wx, 1.7, 1.62), Color(1.0, 0.8, 0.5)).material_override = Gfx.glow_mat(Color(1.0, 0.78, 0.45), 1.0)
	Gfx.box(h, Vector3(0.6, 1.2, 0.05), Vector3(0, 0.6, 1.62), Color(0.4, 0.28, 0.2))


# ============================================================
#  Mobil (jalan ke arah +Z dan -Z)
# ============================================================

func _make_car(color: Color) -> Node3D:
	var car := Node3D.new()
	Gfx.blob_shadow(car, 1.5, 0.8, 0.7)
	Gfx.box(car, Vector3(2.3, 0.55, 1.05), Vector3(0, 0.5, 0), color)
	Gfx.box(car, Vector3(1.2, 0.5, 0.95), Vector3(-0.1, 1.0, 0), color.lightened(0.1))
	Gfx.box(car, Vector3(1.0, 0.34, 0.97), Vector3(-0.1, 1.02, 0), Color(0.5, 0.65, 0.78))
	for wx in [-0.75, 0.75]:
		for wz in [-0.5, 0.5]:
			var wheel := Gfx.cylinder(car, 0.26, 0.26, 0.2, Vector3(wx, 0.26, wz), Color(0.1, 0.1, 0.12), 8)
			wheel.rotation_degrees.x = 90.0
	for lz in [-0.3, 0.3]:
		Gfx.box(car, Vector3(0.06, 0.14, 0.22), Vector3(1.16, 0.55, lz), Color(1, 0.95, 0.7)).material_override = Gfx.glow_mat(Color(1.0, 0.92, 0.65), 1.5)
		Gfx.box(car, Vector3(0.06, 0.14, 0.22), Vector3(-1.16, 0.55, lz), Color(0.9, 0.1, 0.1)).material_override = Gfx.glow_mat(Color(0.9, 0.1, 0.1), 1.2)
	return car


func _build_cars() -> void:
	var colors := [Color(0.78, 0.28, 0.22), Color(0.28, 0.45, 0.7), Color(0.9, 0.78, 0.35), Color(0.9, 0.88, 0.85), Color(0.35, 0.58, 0.42), Color(0.28, 0.27, 0.3)]
	# Jalur A (x -12.2) ke arah +Z, jalur B (x -14.75) ke arah -Z. Jarak antar
	# mobil sama dan kecepatan per jalur tetap, jadi tidak saling tembus.
	for i in range(5):
		var ca := _make_car(colors[_rng.randi() % colors.size()])
		ca.position = Vector3(-12.2, 0.0, -45.0 + i * 18.0)
		ca.rotation_degrees.y = -90.0
		add_child(ca)
		_cars.append({"node": ca, "dir": 1.0, "speed": 4.2})
		var cb := _make_car(colors[_rng.randi() % colors.size()])
		cb.position = Vector3(-14.75, 0.0, -36.0 + i * 18.0)
		cb.rotation_degrees.y = 90.0
		add_child(cb)
		_cars.append({"node": cb, "dir": -1.0, "speed": 3.4})


func _update_cars(delta: float) -> void:
	for c in _cars:
		var n: Node3D = c["node"]
		n.position.z += float(c["dir"]) * float(c["speed"]) * delta
		if float(c["dir"]) > 0.0 and n.position.z > 45.0:
			n.position.z = -45.0
		elif float(c["dir"]) < 0.0 and n.position.z < -45.0:
			n.position.z = 45.0


# ============================================================
#  Vinyet (tepi layar sedikit gelap supaya terasa hangat)
# ============================================================

func _build_vignette() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 0
	add_child(cl)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0.1, 0.04, 0.0, 0.0), Color(0.1, 0.04, 0.0, 0.0), Color(0.08, 0.03, 0.0, 0.5)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 256
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(tr)
