extends RefCounted
# Akses data resep: mana yang bisa dibuat, dan resep apa yang cocok
# dengan bahan di tangan untuk sebuah mesin.

const Data = preload("res://scripts/common/data.gd")
const Inv = preload("res://scripts/player/inventory.gd")


static func recipe(rid: String) -> Dictionary:
	return Data.RECIPES[rid]


static func recipe_name(rid: String) -> String:
	return str(Data.RECIPES[rid]["name"])


static func available(stock: Dictionary, enabled: Dictionary = {}) -> Array:
	# Resep yang dinyalakan di menu dan semua bahannya masih ada stoknya.
	var out: Array = []
	for rid in Data.RECIPES.keys():
		if enabled.has(rid) and not bool(enabled[rid]):
			continue
		var ok := true
		for ing in Data.RECIPES[rid]["ingredients"]:
			if int(stock.get(ing, 0)) <= 0:
				ok = false
		if ok:
			out.append(rid)
	return out


static func find_for_machine(machine_key: String, carry: Array, orders: Array) -> String:
	# Cari pesanan yang resepnya dibuat di mesin ini dan bahannya lengkap di tangan.
	for o in orders:
		var r = Data.RECIPES[o["recipe"]]
		if r["machine"] == machine_key and Inv.has_ingredients(carry, r["ingredients"]):
			return str(o["recipe"])
	return ""


static func ingredient_text(rid: String) -> String:
	var names := PackedStringArray()
	for ing in Data.RECIPES[rid]["ingredients"]:
		names.append(str(Data.INGREDIENTS[ing]["name"]))
	return " + ".join(names)
