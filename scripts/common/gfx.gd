extends RefCounted
# Helper grafis bersama (semua static).

static var _blob_tex: Texture2D = null
static var _tile_tex: Texture2D = null
static var _paving_tex: Texture2D = null


static func mat(c: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


static func glow_mat(c: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


static func glass_mat(c: Color, alpha: float = 0.45) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.15
	return m


static func box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat(c)
	parent.add_child(mi)
	return mi


static func sphere(parent: Node3D, radius: float, pos: Vector3, c: Color, squash: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0 * squash
	s.radial_segments = 10
	s.rings = 5
	mi.mesh = s
	mi.position = pos
	mi.material_override = mat(c)
	parent.add_child(mi)
	return mi


static func cylinder(parent: Node3D, top_r: float, bottom_r: float, height: float, pos: Vector3, c: Color, segments: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bottom_r
	cm.height = height
	cm.radial_segments = segments
	cm.rings = 1
	mi.mesh = cm
	mi.position = pos
	mi.material_override = mat(c)
	parent.add_child(mi)
	return mi


static func blob_texture() -> Texture2D:
	if _blob_tex != null:
		return _blob_tex
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.5))
	g.set_color(1, Color(0, 0, 0, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	_blob_tex = t
	return _blob_tex


static func blob_shadow(parent: Node3D, sx: float, sz: float, strength: float = 1.0) -> void:
	# Bayangan kontak lembut di lantai (pengganti ambient occlusion).
	var mi := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(sx * 2.0, sz * 2.0)
	mi.mesh = p
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = blob_texture()
	m.albedo_color = Color(1, 1, 1, strength)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, 0.03, 0)
	parent.add_child(mi)


static func tile_texture() -> Texture2D:
	# Tekstur ubin terakota: 2x2 ubin per gambar, ada nat dan variasi tipis.
	if _tile_tex != null:
		return _tile_tex
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var base_a := Color(0.88, 0.63, 0.45)
	var base_b := Color(0.84, 0.59, 0.41)
	var grout := Color(0.70, 0.47, 0.33)
	for y in range(size):
		for x in range(size):
			var tx := floori(x / 64.0)
			var ty := floori(y / 64.0)
			var lx := x % 64
			var ly := y % 64
			var c := base_a
			if (tx + ty) % 2 == 1:
				c = base_b
			if lx < 2 or ly < 2:
				c = grout
			elif lx == 2 or ly == 2:
				c = c.lightened(0.08)
			var n := fmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0) * 0.015
			img.set_pixel(x, y, Color(c.r + n, c.g + n, c.b + n, 1.0))
	img.generate_mipmaps()
	_tile_tex = ImageTexture.create_from_image(img)
	return _tile_tex


static func paving_texture() -> Texture2D:
	# Tekstur paving abu-abu untuk trotoar (ubin kotak kecil dengan nat).
	if _paving_tex != null:
		return _paving_tex
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var base_a := Color(0.74, 0.73, 0.70)
	var base_b := Color(0.70, 0.69, 0.66)
	var grout := Color(0.52, 0.51, 0.49)
	for y in range(size):
		for x in range(size):
			var tx := floori(x / 32.0)
			var ty := floori(y / 32.0)
			var lx := x % 32
			var ly := y % 32
			var c := base_a
			if (tx + ty) % 2 == 1:
				c = base_b
			if lx < 1 or ly < 1:
				c = grout
			var n := fmod(sin(float(x) * 9.1 + float(y) * 41.3) * 9371.7, 1.0) * 0.012
			img.set_pixel(x, y, Color(c.r + n, c.g + n, c.b + n, 1.0))
	img.generate_mipmaps()
	_paving_tex = ImageTexture.create_from_image(img)
	return _paving_tex
