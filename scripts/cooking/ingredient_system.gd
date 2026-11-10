extends Node
# Stok bahan. Semua perubahan stok lewat sini supaya sistem lain
# (peti, HUD, simpan data) selalu sinkron lewat EventBus.stock_changed.

const Data = preload("res://scripts/common/data.gd")

var stock := {}


func _init() -> void:
	reset()


func reset() -> void:
	for k in Data.INGREDIENTS.keys():
		stock[k] = int(Data.INGREDIENTS[k]["start"])


func count(k: String) -> int:
	return int(stock.get(k, 0))


func has(k: String) -> bool:
	return count(k) > 0


func take(k: String) -> bool:
	if count(k) <= 0:
		return false
	stock[k] = count(k) - 1
	EventBus.stock_changed.emit()
	return true


func add(k: String, n: int) -> void:
	stock[k] = count(k) + n
	EventBus.stock_changed.emit()


func low_stock(threshold: int = 5, owned: Dictionary = {}) -> PackedStringArray:
	# owned = bahan yang punya peti (kosong = semua bahan).
	var out := PackedStringArray()
	for k in Data.INGREDIENTS.keys():
		if not owned.is_empty() and not owned.has(k):
			continue
		if count(k) <= threshold:
			out.append("%s %d" % [Data.INGREDIENTS[k]["name"], count(k)])
	return out
