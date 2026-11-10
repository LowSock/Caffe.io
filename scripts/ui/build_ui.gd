extends RefCounted
# Antarmuka mode bangun: banner "Mode Bangun" + tombol Selesai, katalog dekorasi di
# bawah (bisa digulir), dan panel aksi (Putar, Taruh, Batal / Pindah, Putar, Jual).

const Style = preload("res://scripts/ui/ui_style.gd")
const Catalog = preload("res://scripts/building/furniture_catalog.gd")

var main = null
var banner: PanelContainer
var catalog_panel: PanelContainer
var cards_box: HBoxContainer
var action_panel: PanelContainer
var info_label: Label
var action_row: HBoxContainer
var _last_state := "?"


func build(root: Control, p_main) -> void:
	main = p_main

	# Banner di atas
	banner = Style.card(Color(0.78, 0.9, 0.66), Color(0.5, 0.7, 0.4), 16)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	bh.add_child(Style.icon("hammer", Style.GREEN_DARK, 28.0, Color(0.78, 0.9, 0.66)))
	bh.add_child(Style.label("Mode Bangun", 20, Style.GREEN_DARK))
	var done := Style.button("Selesai", Style.GREEN_DARK)
	done.pressed.connect(_on_done)
	bh.add_child(done)
	banner.add_child(bh)
	banner.visible = false
	root.add_child(banner)
	Style.anchor_top_center(banner, 12.0)

	# Panel aksi (di atas katalog)
	action_panel = Style.card()
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 6)
	info_label = Style.label("", 15)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(info_label)
	action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	av.add_child(action_row)
	action_panel.add_child(av)
	action_panel.visible = false
	root.add_child(action_panel)
	Style.anchor_bottom_center(action_panel, 142.0)

	# Katalog di bawah
	catalog_panel = Style.card()
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 4)
	cv.add_child(Style.label("Katalog Dekorasi", 14, Style.SOFT))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(760, 126)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 8)
	sc.add_child(cards_box)
	cv.add_child(sc)
	catalog_panel.add_child(cv)
	catalog_panel.visible = false
	root.add_child(catalog_panel)
	Style.anchor_bottom_center(catalog_panel, 12.0)

	EventBus.build_mode_changed.connect(_on_mode)
	EventBus.build_state_changed.connect(_refresh)
	EventBus.gold_changed.connect(_on_gold)


func _on_mode(active: bool) -> void:
	banner.visible = active
	catalog_panel.visible = active
	action_panel.visible = active
	_last_state = "?"
	if active:
		_fill_catalog()
		_refresh()


func _on_gold(_g: int) -> void:
	if catalog_panel.visible:
		_fill_catalog()


func _on_done() -> void:
	main.placement.exit_mode()


# ---------- katalog ----------

func _fill_catalog() -> void:
	Style.clear(cards_box)
	for t in Catalog.ITEMS.keys():
		cards_box.add_child(_card(str(t)))


func _card(t: String) -> Control:
	var cost := Catalog.cost(t)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(112, 102)
	var normal := Style.style(Color(0.99, 0.96, 0.9), 14, 4.0)
	normal.set_border_width_all(2)
	normal.border_color = Style.BORDER
	var hover := Style.style(Color(1.0, 0.98, 0.93), 14, 4.0)
	hover.set_border_width_all(2)
	hover.border_color = Style.GREEN
	var off := Style.style(Color(0.9, 0.88, 0.84), 14, 4.0)
	off.set_border_width_all(2)
	off.border_color = Color(0.8, 0.77, 0.72)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", off)
	b.disabled = not main.economy.can_afford(cost)
	b.pressed.connect(_on_pick.bind(t))

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(Style.icon(Catalog.icon(t), Catalog.color(t), 36.0, Color(0.93, 0.83, 0.68)))
	v.add_child(cc)
	var nm := Style.label(Catalog.item_name(t), 12)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var pr := Style.label("%d gold" % cost, 12, Style.GREEN_DARK)
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(pr)
	var cf := Style.label("Nyaman +%s" % str(snappedf(Catalog.comfort(t), 0.1)), 11, Style.SOFT)
	cf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cf)
	b.add_child(v)
	return b


func _on_pick(t: String) -> void:
	main.placement.begin_new(t)


# ---------- panel aksi ----------

func _act_button(text: String, color: Color, cb: Callable) -> Button:
	var b := Style.button(text, color)
	b.custom_minimum_size = Vector2(96, 42)
	b.pressed.connect(cb)
	return b


func _refresh() -> void:
	var p = main.placement
	if not p.active:
		return
	var state: String = p.state
	var tname := ""
	if p.type != "":
		tname = Catalog.item_name(p.type)

	match state:
		"placing":
			var ok: bool = p.is_valid()
			info_label.text = "Pasang %s (%d gold) - %s" % [tname, Catalog.cost(p.type), "muat" if ok else "tidak muat"]
		"moving":
			var ok2: bool = p.is_valid()
			info_label.text = "Pindahkan %s - %s" % [tname, "muat" if ok2 else "tidak muat"]
		"selected":
			info_label.text = tname
		_:
			info_label.text = "Ketuk perabot untuk memilih, atau pilih dari katalog."

	if state == _last_state:
		return
	_last_state = state
	Style.clear(action_row)
	match state:
		"placing", "moving":
			action_row.add_child(_act_button("Putar", Style.BLUE, p.rotate_ghost))
			action_row.add_child(_act_button("Taruh", Style.GREEN_DARK, p.confirm))
			action_row.add_child(_act_button("Batal", Style.RED, p.cancel))
		"selected":
			action_row.add_child(_act_button("Pindah", Style.BLUE, p.begin_move))
			action_row.add_child(_act_button("Putar", Style.BLUE, p.rotate_ghost))
			if Catalog.is_sellable(p.type):
				var refund := roundi(float(Catalog.cost(p.type)) * 0.5)
				action_row.add_child(_act_button("Jual +%d" % refund, Style.ORANGE, p.sell_selected))
			action_row.add_child(_act_button("Tutup", Style.RED, p.deselect))
