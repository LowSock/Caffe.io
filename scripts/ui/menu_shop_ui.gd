extends RefCounted
# Toko: tab "Menu" untuk membeli resep minuman baru (di awal hanya Boba Milk Tea) dan
# tab "Peti Bahan" untuk membeli peti bahan (di awal hanya boba, susu, dan teh).
# Permainan dijeda saat terbuka.

const Style = preload("res://scripts/ui/ui_style.gd")
const Data = preload("res://scripts/common/data.gd")
const RecipeManager = preload("res://scripts/cooking/recipe_manager.gd")

var main = null
var overlay: Control
var scroll: ScrollContainer
var grid: GridContainer
var gold_label: Label
var tab_row: HBoxContainer
var tab := "menu"


func build(root: Control, p_main) -> void:
	main = p_main
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.07, 0.03, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)

	var title_row := HBoxContainer.new()
	var gold_card := Style.card(Color(1.0, 0.96, 0.85), Style.BORDER, 14)
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 6)
	gh.add_child(Style.icon("coin", Color.WHITE, 26.0))
	gold_label = Style.label("0", 20, Style.GREEN_DARK)
	gh.add_child(gold_label)
	gold_card.add_child(gh)
	gold_card.custom_minimum_size = Vector2(130, 0)
	title_row.add_child(gold_card)
	title_row.add_child(Style.spacer())
	var title := Style.card(Color(0.78, 0.9, 0.66), Color(0.5, 0.7, 0.4), 16)
	title.add_child(Style.label("Toko", 26, Style.GREEN_DARK))
	title_row.add_child(title)
	title_row.add_child(Style.spacer())
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(84, 0)
	title_row.add_child(pad)
	var close_btn := Style.icon_button("cross")
	close_btn.pressed.connect(close_panel)
	title_row.add_child(close_btn)
	col.add_child(title_row)

	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(tab_row)

	var panel := Style.card(Color(0.99, 0.97, 0.93, 1.0), Style.BORDER, 22)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	panel.add_child(scroll)
	col.add_child(panel)


func open(start_tab: String = "") -> void:
	if start_tab != "":
		tab = start_tab
	overlay.visible = true
	fill()
	main.get_tree().paused = true


func close_panel() -> void:
	overlay.visible = false
	main.hud.update_pause()
	if main.hud.menu_ui.overlay.visible:
		main.hud.menu_ui.refresh_after_unlock()
	if main.hud.management.overlay.visible:
		main.hud.management.fill()


func _tab_btn(text: String, key: String) -> Button:
	var b := Style.button(text, Style.GREEN_DARK)
	if tab != key:
		var normal := Style.style(Color(0.96, 0.92, 0.84), 10, 6.0)
		normal.set_border_width_all(2)
		normal.border_color = Style.BORDER
		var hover := Style.style(Color(1.0, 0.97, 0.9), 10, 6.0)
		hover.set_border_width_all(2)
		hover.border_color = Style.GREEN
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", hover)
		b.add_theme_color_override("font_color", Style.INK)
		b.add_theme_color_override("font_hover_color", Style.INK)
		b.add_theme_color_override("font_pressed_color", Style.INK)
	b.custom_minimum_size = Vector2(160, 40)
	b.pressed.connect(_on_tab.bind(key))
	return b


func _on_tab(key: String) -> void:
	tab = key
	fill()


func fill() -> void:
	gold_label.text = str(main.economy.gold)
	Style.clear(tab_row)
	tab_row.add_child(_tab_btn("Menu", "menu"))
	tab_row.add_child(_tab_btn("Peti Bahan", "crates"))
	Style.clear(grid)
	if tab == "menu":
		for rid in Data.RECIPES.keys():
			grid.add_child(_card(str(rid)))
	else:
		for k in Data.INGREDIENTS.keys():
			grid.add_child(_crate_card(str(k)))


func _card(rid: String) -> Control:
	var owned: bool = main.menu.is_unlocked(rid)
	var cost: int = main.menu.unlock_cost(rid)
	var border := Style.BORDER
	if not owned:
		border = Style.GREEN
	var card := Style.card(Color(0.995, 0.98, 0.95, 1.0), border, 16)
	card.custom_minimum_size = Vector2(280, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(Style.drink_icon(rid, 58.0))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 2)
	names.add_child(Style.label(RecipeManager.recipe_name(rid), 17))
	names.add_child(Style.label("Harga jual %d gold" % int(RecipeManager.recipe(rid)["price"]), 13, Style.GREEN_DARK))
	var ir := HBoxContainer.new()
	ir.add_theme_constant_override("separation", 3)
	for ing in RecipeManager.recipe(rid)["ingredients"]:
		ir.add_child(Style.ingredient_icon(str(ing), 22.0))
	names.add_child(ir)
	top.add_child(names)
	v.add_child(top)

	if not owned:
		var missing := PackedStringArray()
		for ing in RecipeManager.recipe(rid)["ingredients"]:
			if main.furniture.get_station("crate", str(ing)) == null:
				missing.append(str(Data.INGREDIENTS[ing]["name"]))
		if not missing.is_empty():
			var warn := Style.label("Butuh peti: " + ", ".join(missing), 12, Style.ORANGE)
			warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			warn.custom_minimum_size = Vector2(250, 0)
			v.add_child(warn)

	var btn: Button
	if owned:
		btn = Style.button("Dimiliki", Color(0.6, 0.6, 0.6))
		btn.disabled = true
	else:
		btn = Style.button("Beli  (%d gold)" % cost, Style.GREEN_DARK)
		btn.disabled = not main.economy.can_afford(cost)
		btn.pressed.connect(_on_buy.bind(rid))
	v.add_child(btn)
	return card


func _on_buy(rid: String) -> void:
	var sv := scroll.scroll_vertical
	var cost: int = main.menu.unlock_cost(rid)
	if main.economy.spend(cost):
		main.menu.unlock(rid)
		main.hud.notify("Menu baru: %s" % RecipeManager.recipe_name(rid))
	fill()
	scroll.set_deferred("scroll_vertical", sv)


# ---------- tab Peti Bahan ----------

func _crate_card(k: String) -> Control:
	var info = Data.INGREDIENTS[k]
	var owned: bool = main.furniture.get_station("crate", k) != null
	var cost := int(info.get("crate_cost", 0))
	var border := Style.BORDER
	if not owned:
		border = Style.GREEN
	var card := Style.card(Color(0.995, 0.98, 0.95, 1.0), border, 16)
	card.custom_minimum_size = Vector2(280, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(Style.ingredient_icon(k, 52.0))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 2)
	names.add_child(Style.label("Peti " + str(info["name"]), 17))
	if owned:
		names.add_child(Style.label("Sudah dipasang di kafe", 13, Style.GREEN_DARK))
	else:
		names.add_child(Style.label("Isi awal %d" % int(info.get("crate_stock", 12)), 13, Style.GREEN_DARK))
	top.add_child(names)
	v.add_child(top)

	var users := PackedStringArray()
	for rid in Data.RECIPES.keys():
		if Data.RECIPES[rid]["ingredients"].has(k):
			users.append(RecipeManager.recipe_name(str(rid)))
	var use_lab := Style.label("Dipakai: " + ", ".join(users), 12, Style.SOFT)
	use_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	use_lab.custom_minimum_size = Vector2(250, 0)
	v.add_child(use_lab)

	var btn: Button
	if owned:
		btn = Style.button("Dimiliki", Color(0.6, 0.6, 0.6))
		btn.disabled = true
	else:
		btn = Style.button("Beli  (%d gold)" % cost, Style.GREEN_DARK)
		btn.disabled = not main.economy.can_afford(cost)
		btn.pressed.connect(_on_buy_crate.bind(k))
	v.add_child(btn)
	return card


func _on_buy_crate(k: String) -> void:
	var sv := scroll.scroll_vertical
	if main.buy_crate(k):
		main.hud.notify("Peti %s dipasang. Atur posisinya di Mode Bangun." % str(Data.INGREDIENTS[k]["name"]))
	fill()
	scroll.set_deferred("scroll_vertical", sv)
