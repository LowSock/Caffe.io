extends RefCounted
# Katalog perabot dekorasi (bisa dibeli, dipindah, diputar, dijual) dan helper
# ukuran/nama untuk perabot fungsional (peti, mesin, meja saji).
# Tambah dekorasi baru: tambah entri di ITEMS dan satu fungsi pembangun di bawah.

const Data = preload("res://scripts/common/data.gd")
const Gfx = preload("res://scripts/common/gfx.gd")

# size = jejak di lantai (x, z) saat tidak diputar. flat = datar (karpet): boleh di bawah perabot lain.
const ITEMS := {
	"table_round": {"name": "Meja Bulat", "cost": 120, "size": Vector2(2.6, 1.6), "icon": "table", "color": Color(0.55, 0.36, 0.2), "comfort": 2.0},
	"table_square": {"name": "Meja Kotak", "cost": 150, "size": Vector2(2.6, 2.6), "icon": "table", "color": Color(0.62, 0.43, 0.26), "comfort": 3.0},
	"sofa": {"name": "Sofa", "cost": 220, "size": Vector2(2.6, 1.0), "icon": "sofa", "color": Color(0.7, 0.42, 0.3), "comfort": 3.0},
	"coffee_table": {"name": "Meja Kopi", "cost": 80, "size": Vector2(0.9, 1.4), "icon": "table", "color": Color(0.5, 0.33, 0.2), "comfort": 1.0},
	"bookshelf": {"name": "Rak Buku", "cost": 180, "size": Vector2(1.8, 0.5), "icon": "shelf", "color": Color(0.5, 0.33, 0.2), "comfort": 2.0},
	"floor_lamp": {"name": "Lampu Lantai", "cost": 90, "size": Vector2(0.6, 0.6), "icon": "lamp", "color": Color(1.0, 0.85, 0.55), "comfort": 1.5},
	"plant": {"name": "Tanaman", "cost": 60, "size": Vector2(1.0, 1.0), "icon": "plant", "color": Color(0.3, 0.6, 0.3), "comfort": 1.0},
	"rug": {"name": "Karpet", "cost": 100, "size": Vector2(3.2, 2.2), "icon": "rug", "color": Color(0.55, 0.3, 0.26), "flat": true, "comfort": 1.0},
}

const STATION_SIZES := {
	"crate": Vector2(1.6, 1.3),
	"machine": Vector2(1.6, 1.3),
	"counter": Vector2(1.4, 5.0),
}


static func exists(type: String) -> bool:
	return ITEMS.has(type) or is_station(type)


static func is_station(type: String) -> bool:
	return type == "counter" or type.begins_with("crate_") or type.begins_with("machine_")


static func base_of(type: String) -> String:
	if type == "counter":
		return "counter"
	if type.begins_with("crate_"):
		return "crate"
	if type.begins_with("machine_"):
		return "machine"
	return type


static func is_flat(type: String) -> bool:
	return bool(ITEMS.get(type, {}).get("flat", false))


static func is_sellable(type: String) -> bool:
	return ITEMS.has(type)


static func comfort(type: String) -> float:
	return float(ITEMS.get(type, {}).get("comfort", 0.0))


static func cost(type: String) -> int:
	return int(ITEMS.get(type, {}).get("cost", 0))


static func footprint_size(type: String) -> Vector2:
	if ITEMS.has(type):
		return ITEMS[type]["size"]
	return STATION_SIZES.get(base_of(type), Vector2(1.0, 1.0))


static func item_name(type: String) -> String:
	if ITEMS.has(type):
		return str(ITEMS[type]["name"])
	if type == "counter":
		return "Meja Saji"
	if type.begins_with("crate_"):
		var k := type.substr(6)
		if Data.INGREDIENTS.has(k):
			return "Peti " + str(Data.INGREDIENTS[k]["name"])
	if type.begins_with("machine_"):
		var m := type.substr(8)
		if Data.MACHINES.has(m):
			return str(Data.MACHINES[m]["name"])
	return type


static func icon(type: String) -> String:
	if ITEMS.has(type):
		return str(ITEMS[type]["icon"])
	if type.begins_with("machine_"):
		return "machine"
	return "crate"


static func color(type: String) -> Color:
	if ITEMS.has(type):
		return ITEMS[type]["color"]
	if type.begins_with("machine_"):
		var m := type.substr(8)
		if Data.MACHINES.has(m):
			return Data.MACHINES[m]["color"]
	return Color(0.58, 0.36, 0.2)


# ============================================================
#  Pembangun dekorasi (pusat di titik asal, bagian depan menghadap +Z)
# ============================================================

static func build(type: String) -> Node3D:
	var n := Node3D.new()
	match type:
		"table_round":
			_table_round(n)
		"table_square":
			_table_square(n)
		"sofa":
			_sofa(n)
		"coffee_table":
			_coffee_table(n)
		"bookshelf":
			_bookshelf(n)
		"floor_lamp":
			_floor_lamp(n)
		"plant":
			_plant(n)
		"rug":
			_rug(n)
	return n


static func _chair(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var c := Node3D.new()
	c.position = pos
	c.rotation_degrees.y = yaw
	parent.add_child(c)
	var wood := Color(0.5, 0.33, 0.2)
	Gfx.box(c, Vector3(0.5, 0.07, 0.5), Vector3(0, 0.45, 0), wood)
	Gfx.box(c, Vector3(0.5, 0.55, 0.06), Vector3(0, 0.75, -0.22), wood)
	for lx in [-0.2, 0.2]:
		for lz in [-0.2, 0.2]:
			Gfx.box(c, Vector3(0.05, 0.42, 0.05), Vector3(lx, 0.21, lz), wood.darkened(0.2))
	Gfx.box(c, Vector3(0.44, 0.06, 0.44), Vector3(0, 0.5, 0), Color(0.82, 0.45, 0.35))


static func _table_round(n: Node3D) -> void:
	Gfx.blob_shadow(n, 1.4, 1.1, 0.7)
	Gfx.cylinder(n, 0.6, 0.6, 0.08, Vector3(0, 0.78, 0), Color(0.55, 0.36, 0.2), 14)
	Gfx.cylinder(n, 0.06, 0.06, 0.74, Vector3(0, 0.39, 0), Color(0.3, 0.22, 0.16), 8)
	Gfx.cylinder(n, 0.3, 0.3, 0.05, Vector3(0, 0.03, 0), Color(0.3, 0.22, 0.16), 10)
	Gfx.cylinder(n, 0.1, 0.08, 0.12, Vector3(-0.2, 0.88, 0.1), Color(0.97, 0.95, 0.9), 8)
	var candle := Gfx.sphere(n, 0.06, Vector3(0.18, 0.9, -0.1), Color(1.0, 0.85, 0.5))
	candle.material_override = Gfx.glow_mat(Color(1.0, 0.8, 0.45), 2.0)
	_chair(n, Vector3(-1.0, 0.0, 0.0), 90.0)
	_chair(n, Vector3(1.0, 0.0, 0.0), -90.0)


static func _table_square(n: Node3D) -> void:
	Gfx.blob_shadow(n, 1.5, 1.5, 0.7)
	Gfx.box(n, Vector3(1.2, 0.08, 1.2), Vector3(0, 0.78, 0), Color(0.62, 0.43, 0.26))
	Gfx.box(n, Vector3(0.12, 0.74, 0.12), Vector3(0, 0.39, 0), Color(0.3, 0.22, 0.16))
	Gfx.box(n, Vector3(0.7, 0.05, 0.7), Vector3(0, 0.03, 0), Color(0.3, 0.22, 0.16))
	Gfx.cylinder(n, 0.1, 0.08, 0.12, Vector3(0.2, 0.88, -0.2), Color(0.97, 0.95, 0.9), 8)
	Gfx.cylinder(n, 0.1, 0.08, 0.12, Vector3(-0.25, 0.88, 0.25), Color(0.97, 0.95, 0.9), 8)
	_chair(n, Vector3(-1.0, 0.0, 0.0), 90.0)
	_chair(n, Vector3(1.0, 0.0, 0.0), -90.0)
	_chair(n, Vector3(0.0, 0.0, -1.0), 0.0)
	_chair(n, Vector3(0.0, 0.0, 1.0), 180.0)


static func _sofa(n: Node3D) -> void:
	Gfx.blob_shadow(n, 1.5, 0.8, 0.7)
	var fab := Color(0.7, 0.42, 0.3)
	Gfx.box(n, Vector3(2.4, 0.4, 0.9), Vector3(0, 0.3, 0), fab)
	Gfx.box(n, Vector3(2.4, 0.75, 0.25), Vector3(0, 0.75, -0.33), fab.darkened(0.1))
	for ax in [-1.15, 1.15]:
		Gfx.box(n, Vector3(0.25, 0.6, 0.9), Vector3(ax, 0.5, 0), fab.darkened(0.15))
	for cx in [-0.55, 0.55]:
		Gfx.box(n, Vector3(0.8, 0.12, 0.7), Vector3(cx, 0.56, 0.05), fab.lightened(0.15))
	Gfx.box(n, Vector3(0.4, 0.4, 0.12), Vector3(-0.8, 0.85, -0.15), Color(0.95, 0.85, 0.6))


static func _coffee_table(n: Node3D) -> void:
	Gfx.blob_shadow(n, 0.8, 1.0, 0.6)
	var wood := Color(0.5, 0.33, 0.2)
	Gfx.box(n, Vector3(0.9, 0.06, 1.4), Vector3(0, 0.4, 0), wood)
	for lx in [-0.4, 0.4]:
		for lz in [-0.6, 0.6]:
			Gfx.box(n, Vector3(0.06, 0.38, 0.06), Vector3(lx, 0.19, lz), wood.darkened(0.25))
	Gfx.cylinder(n, 0.09, 0.07, 0.1, Vector3(0.05, 0.48, -0.3), Color(0.97, 0.95, 0.9), 8)
	Gfx.box(n, Vector3(0.3, 0.04, 0.4), Vector3(-0.1, 0.45, 0.3), Color(0.35, 0.5, 0.6))


static func _bookshelf(n: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var wood := Color(0.45, 0.3, 0.18)
	Gfx.box(n, Vector3(1.8, 2.2, 0.08), Vector3(0, 1.1, -0.2), wood.darkened(0.2))
	Gfx.box(n, Vector3(0.08, 2.2, 0.45), Vector3(-0.9, 1.1, 0), wood)
	Gfx.box(n, Vector3(0.08, 2.2, 0.45), Vector3(0.9, 1.1, 0), wood)
	for r in range(4):
		var y := 0.1 + r * 0.7
		Gfx.box(n, Vector3(1.8, 0.06, 0.45), Vector3(0, y, 0), wood)
		if r < 3:
			var x := -0.75
			while x < 0.75:
				var bw := rng.randf_range(0.1, 0.2)
				var bh := rng.randf_range(0.35, 0.55)
				Gfx.box(n, Vector3(bw, bh, 0.28), Vector3(x + bw * 0.5, y + 0.03 + bh * 0.5, 0.0), Color.from_hsv(rng.randf(), 0.45, 0.8))
				x += bw + 0.02


static func _floor_lamp(n: Node3D) -> void:
	Gfx.blob_shadow(n, 0.4, 0.4, 0.6)
	var dark := Color(0.25, 0.2, 0.18)
	Gfx.cylinder(n, 0.2, 0.25, 0.06, Vector3(0, 0.03, 0), dark, 8)
	Gfx.cylinder(n, 0.03, 0.03, 1.6, Vector3(0, 0.85, 0), dark, 6)
	var shade := Gfx.cylinder(n, 0.18, 0.3, 0.4, Vector3(0, 1.8, 0), Color(1.0, 0.85, 0.55), 10)
	shade.material_override = Gfx.glow_mat(Color(1.0, 0.8, 0.5), 1.8)


static func _plant(n: Node3D) -> void:
	Gfx.blob_shadow(n, 0.7, 0.7, 0.8)
	Gfx.cylinder(n, 0.4, 0.3, 0.55, Vector3(0, 0.275, 0), Color(0.72, 0.4, 0.27), 8)
	Gfx.sphere(n, 0.5, Vector3(0, 0.95, 0), Color(0.26, 0.5, 0.28), 0.9)
	Gfx.sphere(n, 0.35, Vector3(0.25, 1.35, 0.1), Color(0.32, 0.6, 0.33), 0.9)
	Gfx.sphere(n, 0.3, Vector3(-0.25, 1.25, -0.1), Color(0.25, 0.48, 0.28), 0.9)


static func _rug(n: Node3D) -> void:
	Gfx.box(n, Vector3(3.2, 0.008, 2.2), Vector3(0, 0.004, 0), Color(0.55, 0.3, 0.26))
	Gfx.box(n, Vector3(2.8, 0.01, 1.8), Vector3(0, 0.006, 0), Color(0.93, 0.83, 0.68))
