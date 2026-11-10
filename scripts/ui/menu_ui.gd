extends RefCounted
# Layar "Atur Menu": tingkat es, pilihan topping, maksimum topping, dan daftar
# minuman (saklar aktif/nonaktif, tombol Latihan, tanda stok). Perubahan baru
# berlaku setelah menekan Simpan. Permainan dijeda selama layar ini terbuka.
#
# Efek ke gameplay saat ini: minuman yang dimatikan tidak dipesan pelanggan dan
# menambah bonus harga. Tingkat es dan topping baru tersimpan (belum dipakai).

const Style = preload("res://scripts/ui/ui_style.gd")
const Data = preload("res://scripts/common/data.gd")
const RecipeManager = preload("res://scripts/cooking/recipe_manager.gd")
const MenuManagerScript = preload("res://scripts/cooking/menu_manager.gd")
const ToggleScript = preload("res://scripts/ui/toggle.gd")

const TOPPING_COLORS := {
	"boba": Color(0.25, 0.15, 0.1),
	"jelly": Color(0.95, 0.6, 0.2),
	"red_bean": Color(0.65, 0.2, 0.2),
	"coconut_jelly": Color(0.95, 0.95, 0.9),
	"chia": Color(0.4, 0.38, 0.35),
	"pudding": Color(0.95, 0.75, 0.3),
}

var main = null
var overlay: Control
var scroll: ScrollContainer
var content: VBoxContainer
var bonus_label: Label
var dirty_label: Label
var save_btn: Button
var draft := {}
var _toggles := {}
var _cards := {}


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

	# Judul + tombol tutup
	var title_row := HBoxContainer.new()
	var left_pad := Control.new()
	left_pad.custom_minimum_size = Vector2(46, 46)
	title_row.add_child(left_pad)
	title_row.add_child(Style.spacer())
	var title := Style.card(Color(0.78, 0.9, 0.66), Color(0.5, 0.7, 0.4), 16)
	title.add_child(Style.label("Atur Menu", 26, Style.GREEN_DARK))
	title_row.add_child(title)
	title_row.add_child(Style.spacer())
	var close_btn := Style.icon_button("cross")
	close_btn.pressed.connect(close_panel)
	title_row.add_child(close_btn)
	col.add_child(title_row)

	# Panel utama (bisa digulir)
	var main_panel := Style.card(Color(0.99, 0.97, 0.93, 1.0), Style.BORDER, 22)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	main_panel.add_child(scroll)
	col.add_child(main_panel)

	# Bar bawah: bonus, status, reset, simpan
	var bottom := Style.card(Color(0.99, 0.97, 0.93, 1.0), Style.BORDER, 20)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	bottom.add_child(hb)
	var bonus_pill := Style.card(Color(0.78, 0.5, 0.25), Color(0.6, 0.38, 0.18), 14)
	bonus_label = Style.label("Bonus +10%", 18, Color.WHITE)
	bonus_pill.add_child(bonus_label)
	hb.add_child(bonus_pill)
	hb.add_child(Style.spacer())
	dirty_label = Style.label("Perubahan belum disimpan", 13, Style.SOFT)
	hb.add_child(dirty_label)
	var reset_btn := Style.button("Reset", Color(0.82, 0.62, 0.4))
	reset_btn.custom_minimum_size = Vector2(110, 44)
	reset_btn.pressed.connect(_on_reset)
	hb.add_child(reset_btn)
	save_btn = Style.button("Simpan", Style.GREEN_DARK)
	save_btn.custom_minimum_size = Vector2(190, 44)
	save_btn.pressed.connect(_on_save)
	hb.add_child(save_btn)
	col.add_child(bottom)


func open() -> void:
	draft = main.menu.snapshot()
	overlay.visible = true
	_fill()
	main.get_tree().paused = true


func close_panel() -> void:
	overlay.visible = false
	main.hud.update_pause()


# ============================================================
#  Isi layar
# ============================================================

func refresh_after_unlock() -> void:
	# Dipanggil setelah membeli menu di Toko Menu supaya kartu terkunci ikut berubah.
	_refill_keep_scroll()


func _refill_keep_scroll() -> void:
	var sv := scroll.scroll_vertical
	_fill()
	scroll.set_deferred("scroll_vertical", sv)


func _fill() -> void:
	Style.clear(content)
	_toggles.clear()
	_cards.clear()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_ice_panel())
	row.add_child(_topping_panel())
	row.add_child(_max_panel())
	content.add_child(row)

	content.add_child(_divider("Menu Minuman"))

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for rid in Data.RECIPES.keys():
		grid.add_child(_drink_card(str(rid)))
	content.add_child(grid)
	_update_footer()


func _section(title: String, icon_kind: String, ratio: float) -> Dictionary:
	var p := Style.card(Color(0.995, 0.98, 0.95, 1.0), Style.BORDER, 16)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_stretch_ratio = ratio
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 6)
	if icon_kind != "":
		head.add_child(Style.icon(icon_kind, Color(0.7, 0.88, 0.98), 24.0))
	head.add_child(Style.label(title, 17))
	v.add_child(head)
	return {"panel": p, "body": v}


func _divider(text: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := HSeparator.new()
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	h.add_child(Style.card(Color(0.82, 0.92, 0.7), Color(0.55, 0.72, 0.42), 14))
	h.get_child(1).add_child(Style.label(text, 17, Style.GREEN_DARK))
	var r := HSeparator.new()
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(r)
	return h


func _choice(text: String, selected: bool, icon_kind: String, cb: Callable) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(110, 80)
	var border := Style.BORDER
	var bw := 2
	if selected:
		border = Style.GREEN
		bw = 3
	var normal := Style.style(Color(0.99, 0.96, 0.9), 14, 4.0)
	normal.set_border_width_all(bw)
	normal.border_color = border
	var hover := Style.style(Color(1.0, 0.98, 0.93), 14, 4.0)
	hover.set_border_width_all(bw)
	hover.border_color = border.lightened(0.1)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.pressed.connect(cb)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	if icon_kind != "":
		var cc := CenterContainer.new()
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(Style.icon(icon_kind, Color(0.7, 0.88, 0.98), 34.0))
		v.add_child(cc)
	var lab := Style.label(text, 16 if icon_kind != "" else 24)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lab)
	b.add_child(v)

	if selected:
		var badge := PanelContainer.new()
		var sb := Style.style(Style.GREEN, 11, 2.0)
		badge.add_theme_stylebox_override("panel", sb)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(Style.icon("check", Color.WHITE, 16.0))
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -28.0
		badge.offset_right = -4.0
		badge.offset_top = 4.0
		badge.offset_bottom = 28.0
		b.add_child(badge)
	return b


# ---------- tingkat es ----------

func _ice_panel() -> Control:
	var sec := _section("Tingkat Es", "ice", 1.0)
	var body: VBoxContainer = sec["body"]
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	h.add_child(_choice("Mati", bool(draft["ice_off"]), "ice", _on_ice.bind(true)))
	h.add_child(_choice("Custom", not bool(draft["ice_off"]), "ice", _on_ice.bind(false)))
	body.add_child(h)
	return sec["panel"]


func _on_ice(off: bool) -> void:
	draft["ice_off"] = off
	_refill_keep_scroll()


# ---------- topping ----------

func _topping_panel() -> Control:
	var sec := _section("Pilihan Topping", "", 1.7)
	var body: VBoxContainer = sec["body"]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for t in MenuManagerScript.TOPPINGS.keys():
		var on := bool(draft["toppings"].get(t, true))
		var cell := Style.card(Color(0.99, 0.96, 0.9), Style.GREEN if on else Style.BORDER, 12)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		hb.add_child(Style.icon("blob", TOPPING_COLORS[t], 20.0))
		hb.add_child(Style.label(str(MenuManagerScript.TOPPINGS[t]), 14))
		hb.add_child(Style.spacer())
		var tg = ToggleScript.new()
		tg.custom_minimum_size = Vector2(42, 22)
		tg.set_on(on)
		tg.toggled.connect(_on_topping.bind(str(t)))
		hb.add_child(tg)
		cell.add_child(hb)
		grid.add_child(cell)
	body.add_child(grid)
	return sec["panel"]


func _on_topping(on: bool, t: String) -> void:
	draft["toppings"][t] = on
	_refill_keep_scroll()


# ---------- maksimum topping ----------

func _max_panel() -> Control:
	var sec := _section("Maks. Topping", "", 1.0)
	var body: VBoxContainer = sec["body"]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for n in range(4):
		var b := _choice(str(n), int(draft["max_toppings"]) == n, "", _on_max.bind(n))
		b.custom_minimum_size = Vector2(70, 46)
		grid.add_child(b)
	body.add_child(grid)
	return sec["panel"]


func _on_max(n: int) -> void:
	draft["max_toppings"] = n
	_refill_keep_scroll()


# ---------- minuman ----------

func _drink_style(enabled: bool) -> StyleBoxFlat:
	var border := Style.GREEN
	if not enabled:
		border = Color(0.8, 0.77, 0.72)
	var sb := Style.style(Color(0.995, 0.98, 0.95, 1.0), 16, 10.0)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.shadow_size = 4
	sb.shadow_color = Color(0.2, 0.1, 0.0, 0.15)
	sb.shadow_offset = Vector2(0, 2)
	return sb


func _stock_info(rid: String) -> Array:
	var worst := 999
	var parts := PackedStringArray()
	for ing in RecipeManager.recipe(rid)["ingredients"]:
		var n: int = main.ingredients.count(str(ing))
		worst = mini(worst, n)
		parts.append("%s %d" % [Data.INGREDIENTS[ing]["name"], n])
	var c := Style.GREEN
	if worst <= 0:
		c = Style.RED
	elif worst <= 5:
		c = Style.ORANGE
	return [c, "Stok: " + ", ".join(parts)]


func _locked_card(rid: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(208, 0)
	var sb := Style.style(Color(0.93, 0.91, 0.87), 16, 10.0)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.8, 0.77, 0.72)
	card.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var title := Style.label(RecipeManager.recipe_name(rid), 15, Style.SOFT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var cc := CenterContainer.new()
	var ic := Style.drink_icon(rid, 78.0)
	ic.modulate = Color(1, 1, 1, 0.45)
	cc.add_child(ic)
	v.add_child(cc)
	var lock := Style.label("Terkunci", 14, Style.SOFT)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lock)
	var shop := Style.button("Beli di Toko", Style.ORANGE)
	shop.pressed.connect(_on_open_shop)
	v.add_child(shop)
	return card


func _on_open_shop() -> void:
	main.hud.menu_shop_ui.open()


func _drink_card(rid: String) -> Control:
	if not main.menu.is_unlocked(rid):
		return _locked_card(rid)
	var enabled := bool(draft["enabled"].get(rid, true))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(208, 0)
	card.add_theme_stylebox_override("panel", _drink_style(enabled))
	_cards[rid] = card

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var top := HBoxContainer.new()
	var title := Style.label(RecipeManager.recipe_name(rid), 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var tg = ToggleScript.new()
	tg.set_on(enabled)
	tg.toggled.connect(_on_drink_toggled.bind(rid))
	_toggles[rid] = tg
	top.add_child(tg)
	v.add_child(top)

	var cc := CenterContainer.new()
	cc.add_child(Style.drink_icon(rid, 78.0))
	v.add_child(cc)

	var ing_wrap := CenterContainer.new()
	var ing_panel := PanelContainer.new()
	var isb := Style.style(Color(0.96, 0.92, 0.85), 12, 4.0)
	isb.set_border_width_all(1)
	isb.border_color = Style.BORDER
	ing_panel.add_theme_stylebox_override("panel", isb)
	var ir := HBoxContainer.new()
	ir.add_theme_constant_override("separation", 4)
	var first := true
	for ing in RecipeManager.recipe(rid)["ingredients"]:
		if not first:
			ir.add_child(Style.label("+", 14, Style.SOFT))
		ir.add_child(Style.ingredient_icon(str(ing), 22.0))
		first = false
	ing_panel.add_child(ir)
	ing_wrap.add_child(ing_panel)
	v.add_child(ing_wrap)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	var prac := Style.button("Latihan", Style.GREEN)
	prac.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prac.pressed.connect(_on_practice)
	bottom.add_child(prac)
	var info := _stock_info(rid)
	var warn := Style.icon_button("warn", info[0])
	warn.custom_minimum_size = Vector2(38, 38)
	warn.pressed.connect(_on_stock_info.bind(str(info[1])))
	bottom.add_child(warn)
	v.add_child(bottom)
	return card


func _on_drink_toggled(on: bool, rid: String) -> void:
	var en: Dictionary = draft["enabled"]
	en[rid] = on
	var count := 0
	for r in Data.RECIPES.keys():
		if main.menu.is_unlocked(str(r)) and bool(en.get(r, true)):
			count += 1
	if count == 0:
		en[rid] = true
		_toggles[rid].set_on(true)
		main.hud.notify("Minimal satu minuman harus aktif")
		return
	_cards[rid].add_theme_stylebox_override("panel", _drink_style(on))
	_update_footer()


func _on_practice() -> void:
	main.hud.notify("Mode latihan segera hadir")


func _on_stock_info(text: String) -> void:
	main.hud.notify(text)


# ============================================================
#  Bar bawah
# ============================================================

func _update_footer() -> void:
	bonus_label.text = "Bonus +%d%%" % MenuManagerScript.bonus_for(draft["enabled"], main.menu.unlocked)
	var dirty: bool = draft != main.menu.snapshot()
	dirty_label.visible = dirty
	save_btn.disabled = not dirty


func _on_reset() -> void:
	draft = MenuManagerScript.defaults()
	_refill_keep_scroll()


func _on_save() -> void:
	main.menu.apply(draft)
	draft = main.menu.snapshot()
	_update_footer()
	main.hud.notify("Menu disimpan")
