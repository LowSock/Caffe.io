extends RefCounted
# Layar "Upgrade Restoran": kartu tiap upgrade dengan level, efek sekarang dan
# berikutnya, dan tombol beli. Permainan dijeda selama layar ini terbuka.

const Style = preload("res://scripts/ui/ui_style.gd")
const UpgradeScript = preload("res://scripts/restaurant/upgrade_manager.gd")

var main = null
var overlay: Control
var scroll: ScrollContainer
var grid: GridContainer
var gold_label: Label


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

	# Judul, saldo gold, dan tombol tutup
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
	title.add_child(Style.label("Upgrade Restoran", 26, Style.GREEN_DARK))
	title_row.add_child(title)
	title_row.add_child(Style.spacer())
	var spacer_w := Control.new()
	spacer_w.custom_minimum_size = Vector2(84, 0)
	title_row.add_child(spacer_w)
	var close_btn := Style.icon_button("cross")
	close_btn.pressed.connect(close_panel)
	title_row.add_child(close_btn)
	col.add_child(title_row)

	var panel := Style.card(Color(0.99, 0.97, 0.93, 1.0), Style.BORDER, 22)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	panel.add_child(scroll)
	col.add_child(panel)


func open() -> void:
	overlay.visible = true
	fill()
	main.get_tree().paused = true


func close_panel() -> void:
	overlay.visible = false
	main.hud.update_pause()
	if main.hud.management.overlay.visible:
		main.hud.management.fill()    # saldo gold di panel akhir shift ikut diperbarui


func fill() -> void:
	gold_label.text = str(main.economy.gold)
	Style.clear(grid)
	for d in UpgradeScript.DEFS:
		grid.add_child(_card(d))


func _card(d: Dictionary) -> Control:
	var id := str(d["id"])
	var up = main.upgrades
	var lv: int = up.level(id)
	var mx := int(d["max"])
	var maxed := lv >= mx

	var card := Style.card(Color(0.995, 0.98, 0.95, 1.0), Style.BORDER if maxed else Style.GREEN, 16)
	card.custom_minimum_size = Vector2(280, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(Style.icon(str(d["icon"]), d["color"], 44.0))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(Style.label(str(d["name"]), 17))
	names.add_child(Style.label("Lv %d / %d" % [lv, mx], 13, Style.SOFT))
	top.add_child(names)
	v.add_child(top)

	var desc := Style.label(str(d["desc"]), 13, Style.SOFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(250, 0)
	v.add_child(desc)

	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 4)
	for i in range(mx):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(26, 8)
		if i < lv:
			pip.color = Style.ORANGE
		else:
			pip.color = Color(0.85, 0.8, 0.72)
		pips.add_child(pip)
	v.add_child(pips)

	v.add_child(Style.label("Sekarang: " + up.effect_text(id, lv), 14))
	if not maxed:
		v.add_child(Style.label("Berikutnya: " + up.effect_text(id, lv + 1), 14, Style.GREEN_DARK))

	var btn: Button
	if maxed:
		btn = Style.button("MAKS", Color(0.6, 0.6, 0.6))
		btn.disabled = true
	else:
		var cost: int = up.cost(id)
		btn = Style.button("Upgrade  (%d gold)" % cost, Style.GREEN_DARK)
		btn.disabled = not main.economy.can_afford(cost)
		btn.pressed.connect(_on_buy.bind(id))
	v.add_child(btn)
	return card


func _on_buy(id: String) -> void:
	var sv := scroll.scroll_vertical
	if main.upgrades.buy(id):
		var d: Dictionary = main.upgrades.def(id)
		main.hud.notify("%s naik ke Lv %d" % [d["name"], main.upgrades.level(id)])
	fill()
	scroll.set_deferred("scroll_vertical", sv)
