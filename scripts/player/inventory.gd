extends RefCounted
# Isi tangan staf. Item berupa teks: "ing:<bahan>" atau "drink:<resep>".
# Semua fungsi static dan bekerja pada Array milik staf (actor.carry).

const Data = preload("res://scripts/common/data.gd")
const DEFAULT_CARRY := 4

static var max_carry := 4    # naik lewat upgrade "Nampan Besar"


static func is_full(carry: Array) -> bool:
	return carry.size() >= max_carry


static func has_drink(carry: Array) -> bool:
	for item in carry:
		if str(item).begins_with("drink:"):
			return true
	return false


static func has_ingredients(carry: Array, needed: Array) -> bool:
	var tmp := carry.duplicate()
	for n in needed:
		var idx := tmp.find("ing:" + str(n))
		if idx == -1:
			return false
		tmp.remove_at(idx)
	return true


static func remove_ingredients(carry: Array, needed: Array) -> void:
	for n in needed:
		var idx := carry.find("ing:" + str(n))
		if idx != -1:
			carry.remove_at(idx)


static func item_name(item) -> String:
	var parts: PackedStringArray = str(item).split(":")
	if parts[0] == "ing":
		return str(Data.INGREDIENTS[parts[1]]["name"])
	return str(Data.RECIPES[parts[1]]["name"])


static func item_color(item) -> Color:
	var parts: PackedStringArray = str(item).split(":")
	if parts[0] == "ing":
		return Data.INGREDIENTS[parts[1]]["color"]
	return Color(0.8, 0.5, 0.25)


static func text(carry: Array) -> String:
	var names := PackedStringArray()
	for item in carry:
		names.append(item_name(item))
	return ", ".join(names)
