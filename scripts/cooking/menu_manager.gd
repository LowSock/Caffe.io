extends Node
# Pengaturan menu. Di awal hanya satu minuman yang dimiliki (Boba Milk Tea);
# minuman lain dibeli di Toko Menu (lihat ui/menu_shop_ui.gd). Dari minuman yang
# dimiliki, pemain memilih mana yang dijual lewat Atur Menu: minuman yang dimatikan
# tidak dipesan pelanggan dan menambah bonus harga. Tingkat es dan topping baru
# tersimpan (belum memengaruhi pesanan).

const Data = preload("res://scripts/common/data.gd")

const TOPPINGS := {
	"boba": "Boba",
	"jelly": "Jeli",
	"red_bean": "Kacang Merah",
	"coconut_jelly": "Jeli Kelapa",
	"chia": "Biji Chia",
	"pudding": "Puding",
}

var enabled := {}
var unlocked := {}
var ice_off := false
var toppings := {}
var max_toppings := 2


func _init() -> void:
	reset_defaults()


func reset_defaults() -> void:
	enabled.clear()
	unlocked.clear()
	for rid in Data.RECIPES.keys():
		enabled[rid] = true
		unlocked[rid] = int(Data.RECIPES[rid].get("unlock", 0)) == 0
	ice_off = false
	toppings.clear()
	for t in TOPPINGS.keys():
		toppings[t] = true
	max_toppings = 2


# ---------- kepemilikan menu ----------

func is_unlocked(rid: String) -> bool:
	return bool(unlocked.get(rid, false))


func unlock_cost(rid: String) -> int:
	return int(Data.RECIPES[rid].get("unlock", 0))


func unlock(rid: String) -> void:
	unlocked[rid] = true
	enabled[rid] = true
	EventBus.menu_changed.emit()


func unlocked_count() -> int:
	var n := 0
	for rid in Data.RECIPES.keys():
		if is_unlocked(str(rid)):
			n += 1
	return n


# ---------- menu yang dijual ----------

func is_enabled(rid: String) -> bool:
	return is_unlocked(rid) and bool(enabled.get(rid, true))


func enabled_count() -> int:
	var n := 0
	for rid in Data.RECIPES.keys():
		if is_enabled(str(rid)):
			n += 1
	return n


func active() -> Dictionary:
	# Peta resep -> boleh dipesan pelanggan (dimiliki dan dinyalakan).
	var m := {}
	for rid in Data.RECIPES.keys():
		m[rid] = is_enabled(str(rid))
	return m


func bonus_percent() -> int:
	return bonus_for(enabled, unlocked)


static func bonus_for(enabled_map: Dictionary, unlocked_map: Dictionary) -> int:
	# Semua menu yang dimiliki aktif = +10%. Tiap menu dimiliki yang dimatikan menambah +10% (maks +60%).
	var disabled := 0
	for rid in Data.RECIPES.keys():
		if bool(unlocked_map.get(rid, false)) and enabled_map.has(rid) and not bool(enabled_map[rid]):
			disabled += 1
	return mini(60, 10 + 10 * disabled)


# ---------- draf pengaturan (tanpa status kepemilikan) ----------

func snapshot() -> Dictionary:
	return {
		"enabled": enabled.duplicate(),
		"ice_off": ice_off,
		"toppings": toppings.duplicate(),
		"max_toppings": max_toppings,
	}


func apply(d: Dictionary) -> void:
	enabled = Dictionary(d["enabled"]).duplicate()
	ice_off = bool(d["ice_off"])
	toppings = Dictionary(d["toppings"]).duplicate()
	max_toppings = int(d["max_toppings"])
	EventBus.menu_changed.emit()


static func defaults() -> Dictionary:
	var en := {}
	for rid in Data.RECIPES.keys():
		en[rid] = true
	var tp := {}
	for t in TOPPINGS.keys():
		tp[t] = true
	return {"enabled": en, "ice_off": false, "toppings": tp, "max_toppings": 2}


# ---------- simpan ----------

func to_dict() -> Dictionary:
	var d := snapshot()
	d["unlocked"] = unlocked.duplicate()
	return d


func from_dict(d) -> void:
	if typeof(d) != TYPE_DICTIONARY:
		return
	var src: Dictionary = d
	# Kepemilikan: simpanan lama (tanpa data ini) dianggap memiliki semua menu.
	if src.has("unlocked") and typeof(src["unlocked"]) == TYPE_DICTIONARY:
		for rid in Data.RECIPES.keys():
			var free := int(Data.RECIPES[rid].get("unlock", 0)) == 0
			unlocked[rid] = free or bool(src["unlocked"].get(rid, false))
	else:
		for rid in Data.RECIPES.keys():
			unlocked[rid] = true
	if src.has("enabled") and typeof(src["enabled"]) == TYPE_DICTIONARY:
		for rid in Data.RECIPES.keys():
			if src["enabled"].has(rid):
				enabled[rid] = bool(src["enabled"][rid])
	if enabled_count() == 0:
		for rid in Data.RECIPES.keys():
			enabled[rid] = true
	ice_off = bool(src.get("ice_off", false))
	max_toppings = clampi(int(src.get("max_toppings", 2)), 0, 3)
	if src.has("toppings") and typeof(src["toppings"]) == TYPE_DICTIONARY:
		for t in TOPPINGS.keys():
			if src["toppings"].has(t):
				toppings[t] = bool(src["toppings"][t])
