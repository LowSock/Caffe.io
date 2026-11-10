extends Node
# Simpan dan muat progres (autoload). Format JSON di user://.

const SAVE_PATH := "user://kafe_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(main) -> void:
	var data := {
		"version": 1,
		"day": GameManager.day,
		"gold": main.economy.gold,
		"ratings": main.ratings.to_dict(),
		"stock": main.ingredients.stock,
		"staff": main.employees.actors.size(),
		"menu": main.menu.to_dict(),
		"upgrades": main.upgrades.to_dict(),
		"layout": main.furniture.to_list(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()


func load_game(main) -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	GameManager.day = maxi(1, int(d.get("day", 1)))
	main.economy.gold = int(d.get("gold", 100))
	main.ratings.from_dict(d.get("ratings", {}))
	var saved_stock = d.get("stock", {})
	if typeof(saved_stock) == TYPE_DICTIONARY:
		for k in saved_stock.keys():
			if main.ingredients.stock.has(k):
				main.ingredients.stock[k] = int(saved_stock[k])
	main.menu.from_dict(d.get("menu", {}))
	main.upgrades.from_dict(d.get("upgrades", {}))
	if main.upgrades.level("size") > 0:
		main.world_env.rebuild_cafe()
	var layout = d.get("layout", null)
	if typeof(layout) == TYPE_ARRAY and layout.size() > 0:
		main.furniture.load_layout(layout)
	else:
		main.furniture.refresh_levels()
	var staff_target := int(d.get("staff", 2))
	while main.employees.actors.size() < staff_target and not main.employees.staff_full():
		main.employees.add_staff()
	EventBus.gold_changed.emit(main.economy.gold)
	EventBus.stock_changed.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
