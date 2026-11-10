extends Node3D
# Perabot kafe: peti bahan, mesin minuman, meja saji (fungsional) dan dekorasi.
# Tiap perabot adalah item {uid, type, x, z, rot, node}. Tata letak bisa diubah
# lewat PlacementSystem (mode bangun) dan tersimpan di SaveManager.
#
# Jenis item: "counter", "crate_<bahan>", "machine_<mesin>", atau id dekorasi di
# FurnitureCatalog.ITEMS.

const Data = preload("res://scripts/common/data.gd")
const StationScript = preload("res://scripts/cooking/cooking_station.gd")
const Catalog = preload("res://scripts/building/furniture_catalog.gd")
const Nav = preload("res://scripts/world/navigation.gd")

var main = null
var items: Array = []
var stations: Array = []
var next_uid := 1
var forced_node = null     # perabot terpilih di mode bangun (labelnya tampil)
var label_station = null   # stasiun terdekat dengan chef (labelnya tampil)


func setup(p_main) -> void:
	main = p_main
	EventBus.stock_changed.connect(refresh_crates)
	EventBus.shift_ended.connect(_on_shift_ended)
	EventBus.upgrade_bought.connect(_on_upgrade_bought)


# ============================================================
#  Tata letak
# ============================================================

const CRATE_POS := {
	"milk": Vector2(-3.0, 3.6), "tea": Vector2(-1.2, 3.6), "boba": Vector2(0.6, 3.6),
	"beans": Vector2(2.4, 3.6), "lemon": Vector2(4.2, 3.6), "coconut": Vector2(-3.0, 5.4),
}


func _crate_pos(k: String) -> Vector2:
	if CRATE_POS.has(k):
		return CRATE_POS[k]
	return Vector2(0.0, 5.4)


func default_layout() -> Array:
	var out: Array = [{"type": "counter", "x": -7.45, "z": -0.5, "rot": 0}]
	for k in Data.INGREDIENTS.keys():
		if not bool(Data.INGREDIENTS[k].get("starter", false)):
			continue    # peti bahan lain dibeli di Toko
		var cp := _crate_pos(str(k))
		out.append({"type": "crate_" + str(k), "x": cp.x, "z": cp.y, "rot": 0})
	var mx := [-2.4, 0.6, 3.6]
	var j := 0
	for mk in Data.MACHINES.keys():
		out.append({"type": "machine_" + str(mk), "x": mx[j], "z": -4.3, "rot": 0})
		j += 1
	out.append({"type": "rug", "x": -0.8, "z": 0.8, "rot": 0})
	out.append({"type": "plant", "x": -7.6, "z": -5.0, "rot": 0})
	out.append({"type": "plant", "x": 4.9, "z": 6.0, "rot": 0})
	out.append({"type": "plant", "x": -7.6, "z": 6.2, "rot": 0})
	out.append({"type": "floor_lamp", "x": 4.9, "z": -4.9, "rot": 0})
	return out


func build_default_layout() -> void:
	load_layout(default_layout())


func load_layout(list: Array) -> void:
	clear_all()
	var has_counter := false
	for e in list:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var t := str(e.get("type", ""))
		if t == "counter":
			has_counter = true
		add_item(t, float(e.get("x", 0.0)), float(e.get("z", 0.0)), int(e.get("rot", 0)))
	if not has_counter:
		add_item("counter", -7.45, -0.5, 0)
	_ensure_stations()
	_resolve_overlaps()
	refresh_crates()
	refresh_levels()


func _find_free_spot(type: String, prefer: Vector2, ignore_uid: int = -1) -> Vector2:
	# Titik kosong terdekat dari posisi yang diinginkan (dipindai per 0,5 unit di dalam kafe).
	if can_place(type, prefer.x, prefer.y, 0, ignore_uid):
		return prefer
	var best := prefer
	var best_d := 1.0e9
	var x := Nav.CAFE_X_MIN + 1.0
	while x < Nav.cafe_x_max - 0.9:
		var z := Nav.CAFE_Z_MIN + 1.0
		while z < Nav.cafe_z_max - 0.9:
			if can_place(type, x, z, 0, ignore_uid):
				var d := Vector2(x, z).distance_to(prefer)
				if d < best_d:
					best_d = d
					best = Vector2(x, z)
			z += 0.5
		x += 0.5
	return best


func owned_ingredient_keys() -> Dictionary:
	# Bahan yang punya peti di kafe: {kunci: true}.
	var m := {}
	for st in stations:
		if st.kind == "crate":
			m[str(st.key)] = true
	return m


func free_spot(type: String) -> Vector2:
	# Titik kosong untuk perabot baru (dekat posisi bawaan peti).
	var prefer := Vector2(0.0, 5.4)
	if type.begins_with("crate_"):
		prefer = _crate_pos(type.substr(6))
	return _find_free_spot(type, prefer)


func _ensure_stations() -> void:
	# Simpanan lama bisa belum punya peti/mesin baru: tambahkan di tempat yang kosong.
	for k in Data.INGREDIENTS.keys():
		if not bool(Data.INGREDIENTS[k].get("starter", false)):
			continue
		if get_station("crate", str(k)) == null:
			var t := "crate_" + str(k)
			var spot := _find_free_spot(t, _crate_pos(str(k)))
			add_item(t, spot.x, spot.y, 0)
	var mx := {"coffee": -2.4, "tea": 0.6, "blender": 3.6}
	for m in Data.MACHINES.keys():
		if get_station("machine", str(m)) == null:
			var t2 := "machine_" + str(m)
			var spot2 := _find_free_spot(t2, Vector2(float(mx.get(str(m), 0.6)), -4.3))
			add_item(t2, spot2.x, spot2.y, 0)


func _resolve_overlaps() -> void:
	# Perbaiki simpanan yang perabotnya saling menumpuk (misalnya peti baru di atas peti lama).
	var placed: Array = []
	for it in items:
		var t := str(it["type"])
		if t == "counter" or Catalog.is_flat(t):
			placed.append(it)
			continue
		var r := footprint_rect(t, float(it["x"]), float(it["z"]), int(it["rot"]))
		var clash := false
		for o in placed:
			var ot := str(o["type"])
			if Catalog.is_flat(ot):
				continue
			var orr := footprint_rect(ot, float(o["x"]), float(o["z"]), int(o["rot"]))
			if r.grow(-0.02).intersects(orr):
				clash = true
				break
		if clash:
			var spot := _find_free_spot(t, Vector2(float(it["x"]), float(it["z"])), int(it["uid"]))
			move_item(int(it["uid"]), spot.x, spot.y, int(it["rot"]))
		placed.append(it)


func decor_score() -> float:
	# Jumlah poin kenyamanan semua dekorasi yang terpasang.
	var s := 0.0
	for it in items:
		s += Catalog.comfort(str(it["type"]))
	return s


func to_list() -> Array:
	var out: Array = []
	for it in items:
		out.append({"type": str(it["type"]), "x": float(it["x"]), "z": float(it["z"]), "rot": int(it["rot"])})
	return out


func clear_all() -> void:
	for it in items:
		var n = it["node"]
		if n != null and is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	items.clear()
	stations.clear()


# ============================================================
#  Membuat dan mengelola item
# ============================================================

func create_node(type: String) -> Variant:
	if type == "counter":
		var c = StationScript.new()
		c.setup("counter", "counter", "Meja Saji", Color(0.7, 0.45, 0.25), Vector3(1.4, 1.0, 5.0))
		c.radius = 1.7
		c.hit_radius = 3.0
		return c
	if type.begins_with("crate_"):
		var k := type.substr(6)
		if not Data.INGREDIENTS.has(k):
			return null
		var info = Data.INGREDIENTS[k]
		var st = StationScript.new()
		st.setup("crate", k, str(info["name"]), Color(0.58, 0.36, 0.2), Vector3(1.6, 0.9, 1.3))
		st.add_topper(k, info["color"])
		return st
	if type.begins_with("machine_"):
		var m := type.substr(8)
		if not Data.MACHINES.has(m):
			return null
		var minfo = Data.MACHINES[m]
		var ms = StationScript.new()
		ms.setup("machine", m, str(minfo["name"]), minfo["color"], Vector3(1.6, 1.3, 1.3))
		return ms
	if Catalog.exists(type):
		return Catalog.build(type)
	return null


func add_item(type: String, x: float, z: float, rot: int) -> Dictionary:
	var node = create_node(type)
	if node == null:
		return {}
	node.position = Vector3(x, 0.0, z)
	node.rotation_degrees.y = float(rot) * 90.0
	add_child(node)
	return register(type, node, x, z, rot)


func register(type: String, node: Node3D, x: float, z: float, rot: int) -> Dictionary:
	var it := {"uid": next_uid, "type": type, "x": x, "z": z, "rot": rot, "node": node}
	next_uid += 1
	items.append(it)
	if node.get("kind") != null:
		node.main = main
		stations.append(node)
	return it


func get_item(uid: int) -> Variant:
	for it in items:
		if int(it["uid"]) == uid:
			return it
	return null


func move_item(uid: int, x: float, z: float, rot: int) -> void:
	var it = get_item(uid)
	if it == null:
		return
	it["x"] = x
	it["z"] = z
	it["rot"] = rot
	var n: Node3D = it["node"]
	n.position = Vector3(x, 0.0, z)
	n.rotation_degrees.y = float(rot) * 90.0


func remove_item(uid: int) -> void:
	var it = get_item(uid)
	if it == null:
		return
	var n = it["node"]
	if n != null and is_instance_valid(n):
		if stations.has(n):
			stations.erase(n)
		remove_child(n)
		n.queue_free()
	items.erase(it)


func footprint_rect(type: String, x: float, z: float, rot: int) -> Rect2:
	var s := Catalog.footprint_size(type)
	if rot % 2 != 0:
		s = Vector2(s.y, s.x)
	return Rect2(Vector2(x - s.x * 0.5, z - s.y * 0.5), s)


func item_at(p: Vector3) -> Variant:
	# Perabot di titik lantai p (karpet hanya dipilih kalau tidak ada perabot lain).
	var flat_hit = null
	for it in items:
		var t := str(it["type"])
		if t == "counter":
			continue
		var r := footprint_rect(t, float(it["x"]), float(it["z"]), int(it["rot"]))
		if r.grow(0.15).has_point(Vector2(p.x, p.z)):
			if not Catalog.is_flat(t):
				return it
			if flat_hit == null:
				flat_hit = it
	return flat_hit


func can_place(type: String, x: float, z: float, rot: int, ignore_uid: int = -1) -> bool:
	var r := footprint_rect(type, x, z, rot)
	var inner := Rect2(
		Vector2(Nav.CAFE_X_MIN + 0.1, Nav.CAFE_Z_MIN + 0.1),
		Vector2(Nav.cafe_x_max - Nav.CAFE_X_MIN - 0.2, Nav.cafe_z_max - Nav.CAFE_Z_MIN - 0.2))
	if not inner.encloses(r):
		return false
	for zone in Nav.RESERVED:
		if r.intersects(zone):
			return false
	if Catalog.is_flat(type):
		return true
	for it in items:
		if int(it["uid"]) == ignore_uid:
			continue
		var t := str(it["type"])
		if Catalog.is_flat(t):
			continue
		var o := footprint_rect(t, float(it["x"]), float(it["z"]), int(it["rot"]))
		if r.grow(-0.02).intersects(o):
			return false
	return true


# ============================================================
#  Stasiun
# ============================================================

func get_station(kind: String, key: String) -> Variant:
	for st in stations:
		if st.kind == kind and st.key == key:
			return st
	return null


func refresh_crates() -> void:
	if main == null:
		return
	for st in stations:
		if st.kind == "crate":
			st.set_extra("Stok: %d" % main.ingredients.count(str(st.key)))


func refresh_levels() -> void:
	if main == null:
		return
	for st in stations:
		if st.kind == "machine":
			st.set_level(1 + main.upgrades.level("m_" + str(st.key)))


func update_labels(delta: float) -> void:
	# Hanya satu label stasiun yang tampil: yang terdekat dengan chef (dalam REVEAL_DIST).
	label_station = null
	var building: bool = main != null and main.placement != null and main.placement.active
	if main != null and main.employees != null and main.employees.controlled != null and not building:
		var p: Vector3 = main.employees.controlled.position
		var best: float = StationScript.REVEAL_DIST
		for st in stations:
			var d := Vector2(p.x - st.position.x, p.z - st.position.z).length()
			if d <= best:
				best = d
				label_station = st
	for st in stations:
		st.update_label(delta, st == label_station or st == forced_node)


func _on_upgrade_bought(_id: String, _level: int) -> void:
	refresh_levels()


func _on_shift_ended(_day: int) -> void:
	for st in stations:
		st.reset_machine()
