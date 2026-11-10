extends Node
# Uang, bintang (reputasi), dan statistik harian.

const Data = preload("res://scripts/common/data.gd")

var gold := 100
var served_today := 0
var lost_today := 0
var earned_today := 0


func reset_day() -> void:
	served_today = 0
	lost_today = 0
	earned_today = 0


func complete_order(rid: String, ratio: float, bonus_percent: int = 0, stars: int = 5, price_mult: float = 1.0) -> int:
	# ratio = sisa kesabaran pelanggan (0..1). Makin cepat, makin besar tip.
	# bonus_percent = bonus harga dari pengaturan menu (lihat MenuManager).
	var r = Data.RECIPES[rid]
	var sale := roundi(float(r["price"]) * price_mult)
	var tip := roundi(float(sale) * 0.5 * ratio)
	var bonus := roundi(float(sale) * float(bonus_percent) / 100.0)
	var total := sale + tip + bonus
	gold += total
	earned_today += total
	served_today += 1
	EventBus.gold_changed.emit(gold)
	EventBus.sale_made.emit(sale, tip, bonus, stars)
	return total


func record_lost() -> void:
	lost_today += 1


func earn(n: int) -> void:
	gold += n
	EventBus.gold_changed.emit(gold)


func can_afford(n: int) -> bool:
	return gold >= n


func spend(n: int) -> bool:
	if gold < n:
		return false
	gold -= n
	EventBus.gold_changed.emit(gold)
	return true


func hire_cost(staff_count: int) -> int:
	return 120 + 80 * maxi(0, staff_count - 2)
