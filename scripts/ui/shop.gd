extends RefCounted
# Toko stok: baris beli bahan (ikon + tombol). Dipakai di panel akhir shift.

const Style = preload("res://scripts/ui/ui_style.gd")
const Data = preload("res://scripts/common/data.gd")


func fill(container: Node, main, on_change: Callable) -> void:
	container.add_child(Style.label("Belanja stok", 20))
	var owned: Dictionary = main.furniture.owned_ingredient_keys()
	for k in Data.INGREDIENTS.keys():
		if not owned.has(k):
			continue
		var info = Data.INGREDIENTS[k]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(Style.ingredient_icon(str(k), 30.0))
		var price: int = main.stock_cost(str(k))
		var text := "+%d %s  (%d gold)   stok: %d" % [info["pack"], info["name"], price, main.ingredients.count(str(k))]
		var b := Style.button(text, Style.GREEN)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not main.economy.can_afford(price)
		b.pressed.connect(_on_buy.bind(str(k), main, on_change))
		row.add_child(b)
		container.add_child(row)


func _on_buy(k: String, main, on_change: Callable) -> void:
	main.buy_stock(k)
	on_change.call()
