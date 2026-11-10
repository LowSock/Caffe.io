extends Node
# Daftar pesanan aktif: kesabaran, klaim oleh staf AI, selesai, atau hilang.
# Order dibuat oleh CustomerManager saat pelanggan sampai di meja saji.

const Data = preload("res://scripts/common/data.gd")

var main = null
var max_orders := 5
var orders: Array = []
var next_order_id := 1


func setup(p_main) -> void:
	main = p_main
	EventBus.shift_ended.connect(_on_shift_ended)


func patience_for_day() -> float:
	return maxf(45.0, 75.0 - GameManager.day * 2.0) * float(main.upgrades.patience_mult())


func add_order(rid: String, slot: int, node: Node3D, rig: Dictionary, label: Label3D, bubble, kind: String) -> Dictionary:
	var p := patience_for_day()
	var o := {
		"id": next_order_id,
		"recipe": rid,
		"patience": p,
		"max": p,
		"claimed": 0,
		"slot": slot,
		"node": node,
		"rig": rig,
		"label": label,
		"bubble": bubble,
		"kind": kind,
		"chat": 8.0,
		"stage": 0,
	}
	next_order_id += 1
	orders.append(o)
	EventBus.order_created.emit(o)
	return o


func _process(delta: float) -> void:
	if not GameManager.shift_active:
		return
	var i := orders.size() - 1
	while i >= 0:
		var o = orders[i]
		o["patience"] = float(o["patience"]) - delta
		if float(o["patience"]) <= 0.0:
			lose(o)
		i -= 1


func find_for(rid: String) -> Variant:
	for o in orders:
		if o["recipe"] == rid:
			return o
	return null


func claim_order(actor) -> Variant:
	# Dipakai staf AI: ambil pesanan yang belum diklaim dan bahannya masih ada.
	for o in orders:
		if int(o["claimed"]) == 0:
			var ok := true
			for ing in Data.RECIPES[o["recipe"]]["ingredients"]:
				if not main.ingredients.has(str(ing)) or main.furniture.get_station("crate", str(ing)) == null:
					ok = false
			if ok:
				o["claimed"] = actor.actor_id
				return o
	return null


func release_claim(actor) -> void:
	for o in orders:
		if int(o["claimed"]) == actor.actor_id:
			o["claimed"] = 0


func complete(order: Dictionary, actor) -> int:
	var ratio := clampf(float(order["patience"]) / float(order["max"]), 0.0, 1.0)
	var stars: int = main.ratings.rate(ratio)
	order["stars"] = stars
	main.ratings.add_review(stars)
	var total: int = main.economy.complete_order(str(order["recipe"]), ratio, main.menu.bonus_percent(), stars, float(main.upgrades.price_mult()))
	EventBus.popup_requested.emit(actor.position + Vector3(0, 4.4, 0), "+%d gold" % total, Color(1.0, 0.95, 0.5))
	orders.erase(order)
	EventBus.order_completed.emit(order, total)
	return total


func lose(order: Dictionary) -> void:
	main.economy.record_lost()
	order["stars"] = 1
	main.ratings.add_review(1)
	var n = order["node"]
	if n != null and is_instance_valid(n):
		EventBus.popup_requested.emit(n.position + Vector3(0, 4.0, 0), "Pelanggan pergi", Color(1.0, 0.5, 0.45))
	orders.erase(order)
	EventBus.order_lost.emit(order)


func _on_shift_ended(_day: int) -> void:
	for o in orders:
		var n = o["node"]
		if n != null and is_instance_valid(n):
			n.queue_free()
	orders.clear()
