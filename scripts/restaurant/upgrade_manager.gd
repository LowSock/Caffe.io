extends Node
# Upgrade restoran: beli level untuk mempercepat staf dan mesin, menambah
# kapasitas tangan, kesabaran pelanggan, harga jual, diskon stok, dan keramaian.
# Semua data ada di DEFS di bawah; tambah upgrade baru cukup menambah satu entri
# lalu memakai efeknya di tempat yang sesuai (lihat fungsi pengali di bawah).

const Inv = preload("res://scripts/player/inventory.gd")
const Nav = preload("res://scripts/world/navigation.gd")

# step = besar efek per level (persen, atau jumlah untuk "hands"), base = nilai awal
# yang ditampilkan, cost = harga level pertama, growth = pengali harga tiap level.
const DEFS := [
	{"id": "size", "name": "Perluas Kafe", "desc": "Lantai kafe makin luas supaya muat lebih banyak perabot.", "icon": "house", "color": Color(0.8, 0.55, 0.35),
		"max": 3, "cost": 600, "growth": 2.5, "step": 1, "base": 0, "fmt": "Luas level %d"},
	{"id": "speed", "name": "Sepatu Lari Chef", "desc": "Staf berjalan lebih cepat.", "icon": "clock", "color": Color(0.35, 0.55, 0.9),
		"max": 5, "cost": 150, "growth": 1.6, "step": 8, "base": 0, "fmt": "+%d%% kecepatan jalan"},
	{"id": "hands", "name": "Nampan Besar", "desc": "Chef bisa membawa lebih banyak item sekaligus.", "icon": "menu", "color": Color(0.75, 0.5, 0.3),
		"max": 2, "cost": 400, "growth": 2.0, "step": 1, "base": 4, "fmt": "Muat %d item"},
	{"id": "m_coffee", "name": "Mesin Kopi Pro", "desc": "Minuman kopi selesai lebih cepat.", "icon": "ing_beans", "color": Color(0.36, 0.22, 0.12),
		"max": 5, "cost": 180, "growth": 1.7, "step": 12, "base": 0, "fmt": "Seduh %d%% lebih cepat"},
	{"id": "m_tea", "name": "Teko Teh Cepat", "desc": "Minuman teh selesai lebih cepat.", "icon": "ing_tea", "color": Color(0.35, 0.55, 0.25),
		"max": 5, "cost": 180, "growth": 1.7, "step": 12, "base": 0, "fmt": "Seduh %d%% lebih cepat"},
	{"id": "m_blender", "name": "Blender Turbo", "desc": "Minuman blender selesai lebih cepat.", "icon": "glass", "color": Color(0.7, 0.85, 0.95),
		"max": 5, "cost": 180, "growth": 1.7, "step": 12, "base": 0, "fmt": "Blender %d%% lebih cepat"},
	{"id": "patience", "name": "Kursi Antre Nyaman", "desc": "Pelanggan lebih sabar menunggu pesanan.", "icon": "star", "color": Color(1.0, 0.8, 0.2),
		"max": 5, "cost": 200, "growth": 1.6, "step": 8, "base": 0, "fmt": "+%d%% kesabaran pelanggan"},
	{"id": "price", "name": "Resep Premium", "desc": "Harga jual semua minuman naik.", "icon": "coin", "color": Color(0.93, 0.68, 0.12),
		"max": 5, "cost": 250, "growth": 1.7, "step": 6, "base": 0, "fmt": "+%d%% harga jual"},
	{"id": "supplier", "name": "Kontrak Supplier", "desc": "Belanja stok bahan jadi lebih murah.", "icon": "receipt", "color": Color(0.5, 0.65, 0.4),
		"max": 5, "cost": 220, "growth": 1.6, "step": 7, "base": 0, "fmt": "-%d%% harga stok"},
	{"id": "promo", "name": "Promosi Kafe", "desc": "Pelanggan lebih sering datang.", "icon": "arrow_up", "color": Color(0.9, 0.45, 0.35),
		"max": 5, "cost": 260, "growth": 1.7, "step": 7, "base": 0, "fmt": "-%d%% jeda kedatangan"},
]

var main = null
var levels := {}


func _init() -> void:
	for d in DEFS:
		levels[str(d["id"])] = 0


func setup(p_main) -> void:
	main = p_main
	apply()


func def(id: String) -> Dictionary:
	for d in DEFS:
		if str(d["id"]) == id:
			return d
	return {}


func level(id: String) -> int:
	return int(levels.get(id, 0))


func max_level(id: String) -> int:
	return int(def(id).get("max", 0))


func total_levels() -> int:
	var n := 0
	for k in levels.keys():
		n += int(levels[k])
	return n


func is_maxed(id: String) -> bool:
	return level(id) >= max_level(id)


func cost(id: String) -> int:
	var d := def(id)
	var raw := float(d["cost"]) * pow(float(d["growth"]), float(level(id)))
	return roundi(raw / 10.0) * 10


func effect_text(id: String, lvl: int) -> String:
	if id == "size":
		return "Lantai " + Nav.footprint_text(lvl)
	var d := def(id)
	return str(d["fmt"]) % (int(d["base"]) + int(d["step"]) * lvl)


func buy(id: String) -> bool:
	if is_maxed(id):
		return false
	if not main.economy.spend(cost(id)):
		return false
	levels[id] = level(id) + 1
	apply()
	EventBus.upgrade_bought.emit(id, level(id))
	return true


func apply() -> void:
	Inv.max_carry = Inv.DEFAULT_CARRY + level("hands")
	Nav.set_expansion(level("size"))


# ---------- pengali efek ----------

func _pct(id: String) -> float:
	return float(def(id)["step"]) * 0.01 * float(level(id))


func speed_mult() -> float:
	return 1.0 + _pct("speed")


func brew_mult(machine_key: String) -> float:
	return maxf(0.4, 1.0 - _pct("m_" + machine_key))


func patience_mult() -> float:
	return 1.0 + _pct("patience")


func price_mult() -> float:
	return 1.0 + _pct("price")


func supplier_mult() -> float:
	return maxf(0.5, 1.0 - _pct("supplier"))


func spawn_mult() -> float:
	return maxf(0.5, 1.0 - _pct("promo"))


# ---------- simpan ----------

func to_dict() -> Dictionary:
	return {"levels": levels.duplicate()}


func from_dict(d) -> void:
	for k in levels.keys():
		levels[k] = 0
	if typeof(d) == TYPE_DICTIONARY:
		var src: Dictionary = d
		var lv = src.get("levels", {})
		if typeof(lv) == TYPE_DICTIONARY:
			for k in levels.keys():
				if lv.has(k):
					levels[k] = clampi(int(lv[k]), 0, max_level(str(k)))
	apply()
