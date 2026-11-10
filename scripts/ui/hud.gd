extends CanvasLayer
# HUD utama bergaya kartu krem: kartu staf (Ambil alih), tiket pesanan, panel
# hari/jam/gold, kantong "Masuk ke dompet", peringatan stok yang bisa dilipat,
# dan tombol menu/pengaturan. Modul lain: InventoryUI (slot bawah), Management
# (akhir shift), MenuUI (Atur Menu), SettingsUI, CameraUI.

const Style = preload("res://scripts/ui/ui_style.gd")
const InventoryUIScript = preload("res://scripts/ui/inventory_ui.gd")
const ManagementScript = preload("res://scripts/ui/management.gd")
const CameraUIScript = preload("res://scripts/ui/camera_ui.gd")
const MenuUIScript = preload("res://scripts/ui/menu_ui.gd")
const SettingsUIScript = preload("res://scripts/ui/settings_ui.gd")
const TouchControlsScript = preload("res://scripts/ui/touch_controls.gd")
const UpgradeUIScript = preload("res://scripts/ui/upgrade_ui.gd")
const BuildUIScript = preload("res://scripts/ui/build_ui.gd")
const MenuShopUIScript = preload("res://scripts/ui/menu_shop_ui.gd")
const RecipeManager = preload("res://scripts/cooking/recipe_manager.gd")

var main = null
var root: Control

var staff_box: HBoxContainer
var staff_cards: Array = []

var order_box: VBoxContainer
var order_cards: Array = []
var order_sig := "x"

var stock_panel: PanelContainer
var stock_count: Label
var stock_list: Label
var stock_btn: Button
var stock_open := false

var day_label: Label
var time_label: Label
var rating_label: Label
var gold_label: Label
var sold_label: Label
var bonus_label: Label
var crowd_label: Label

var toast_panel: PanelContainer
var toast_total: Label
var toast_detail: Label
var toast_stars: Label
var toast_tween: Tween = null

var notice_panel: PanelContainer
var notice_label: Label
var notice_tween: Tween = null

var inventory_ui = null
var management = null
var camera_ui = null
var menu_ui = null
var settings_ui = null
var touch_controls = null
var upgrade_ui = null
var build_ui = null
var menu_shop_ui = null
var _mgmt_was_open := false


func setup(p_main) -> void:
	main = p_main
	process_mode = Node.PROCESS_MODE_ALWAYS    # tetap jalan saat permainan dijeda oleh menu
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	staff_box = HBoxContainer.new()
	staff_box.add_theme_constant_override("separation", 6)
	staff_box.position = Vector2(12, 12)
	root.add_child(staff_box)

	order_box = VBoxContainer.new()
	order_box.add_theme_constant_override("separation", 8)
	order_box.position = Vector2(12, 200)
	root.add_child(order_box)

	_build_info_panel()
	_build_toast()
	_build_notice()
	_build_stock_alert()

	inventory_ui = InventoryUIScript.new()
	inventory_ui.build(root, main)
	camera_ui = CameraUIScript.new()
	camera_ui.build(root, main)
	management = ManagementScript.new()
	management.build(root, main)
	menu_ui = MenuUIScript.new()
	menu_ui.build(root, main)
	menu_shop_ui = MenuShopUIScript.new()
	menu_shop_ui.build(root, main)
	settings_ui = SettingsUIScript.new()
	settings_ui.build(root, main)
	upgrade_ui = UpgradeUIScript.new()
	upgrade_ui.build(root, main)
	build_ui = BuildUIScript.new()
	build_ui.build(root, main)
	touch_controls = TouchControlsScript.new()
	touch_controls.build(root, main)

	EventBus.controlled_changed.connect(_on_controlled_changed)
	EventBus.staff_changed.connect(rebuild_staff)
	EventBus.shift_ended.connect(_on_shift_ended)
	EventBus.sale_made.connect(_on_sale_made)
	EventBus.build_mode_changed.connect(_on_build_mode)
	rebuild_staff()


func _on_controlled_changed(_actor) -> void:
	rebuild_staff()


func _on_shift_ended(_day: int) -> void:
	management.show_panel()


# ============================================================
#  Panel info kanan atas
# ============================================================

func _stat(row: HBoxContainer, title: String, ic: Control) -> Label:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(Style.label(title, 12, Style.SOFT))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(ic)
	var val := Style.label("-", 20)
	h.add_child(val)
	v.add_child(h)
	row.add_child(v)
	return val


func _build_info_panel() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var panel := Style.card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 8)
	r1.add_child(Style.icon("calendar", Color.WHITE, 26.0))
	day_label = Style.label("Hari 1", 19)
	r1.add_child(day_label)
	r1.add_child(Style.spacer())
	r1.add_child(Style.icon("clock", Color.WHITE, 26.0))
	time_label = Style.label("08:00", 19)
	r1.add_child(time_label)
	r1.add_child(Style.spacer())
	r1.add_child(Style.icon("star", Color.WHITE, 24.0))
	rating_label = Style.label("-", 19)
	r1.add_child(rating_label)
	v.add_child(r1)
	v.add_child(HSeparator.new())

	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 16)
	gold_label = _stat(r2, "Gold", Style.icon("coin", Color.WHITE, 22.0))
	sold_label = _stat(r2, "Terjual", Style.icon("glass", Color(0.86, 0.68, 0.5), 22.0))
	bonus_label = _stat(r2, "Bonus", Style.icon("dot", Style.GREEN, 22.0))
	crowd_label = _stat(r2, "Ramai", Style.icon("arrow_up", Style.ORANGE, 22.0))
	v.add_child(r2)
	box.add_child(panel)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	btns.alignment = BoxContainer.ALIGNMENT_END
	var end_btn := Style.button("Akhiri shift", Style.RED)
	end_btn.custom_minimum_size = Vector2(0, 46)
	end_btn.pressed.connect(_on_end_pressed)
	btns.add_child(end_btn)
	var menu_btn := Style.icon_button("menu")
	menu_btn.pressed.connect(_on_menu_pressed)
	btns.add_child(menu_btn)
	var shop_btn := Style.icon_button("receipt")
	shop_btn.pressed.connect(_on_shop_pressed)
	btns.add_child(shop_btn)
	var build_btn := Style.icon_button("hammer", Color(0.55, 0.35, 0.2))
	build_btn.pressed.connect(_on_build_pressed)
	btns.add_child(build_btn)
	var up_btn := Style.icon_button("arrow_up", Style.GREEN_DARK)
	up_btn.pressed.connect(_on_upgrade_pressed)
	btns.add_child(up_btn)
	var set_btn := Style.icon_button("gear")
	set_btn.pressed.connect(_on_settings_pressed)
	btns.add_child(set_btn)
	box.add_child(btns)

	root.add_child(box)
	Style.anchor_top_right(box, 12.0)


func _on_end_pressed() -> void:
	GameManager.end_shift()


func _on_menu_pressed() -> void:
	menu_ui.open()


func _on_shop_pressed() -> void:
	menu_shop_ui.open()


func update_pause() -> void:
	# Permainan dijeda selama ada layar penuh (menu, toko, upgrade, pengaturan) atau mode bangun.
	var any: bool = menu_ui.overlay.visible or menu_shop_ui.overlay.visible or settings_ui.overlay.visible or upgrade_ui.overlay.visible or main.placement.active
	main.get_tree().paused = any


func _on_build_pressed() -> void:
	main.placement.enter_mode()


func _on_build_mode(active: bool) -> void:
	# Mode bangun: sembunyikan HUD permainan; panel akhir shift disembunyikan sementara.
	staff_box.visible = not active
	order_box.visible = not active
	inventory_ui.panel.visible = not active
	if active:
		toast_panel.visible = false
		stock_panel.visible = false
		_mgmt_was_open = management.overlay.visible
		management.hide_panel()
	else:
		if _mgmt_was_open and not GameManager.shift_active:
			management.show_panel()
		_mgmt_was_open = false


func _process(_delta: float) -> void:
	# Tetap berjalan saat permainan dijeda supaya joystick ikut tersembunyi.
	if touch_controls != null:
		touch_controls.refresh()


func _on_upgrade_pressed() -> void:
	upgrade_ui.open()


func _on_settings_pressed() -> void:
	settings_ui.open()


# ============================================================
#  Kantong "Masuk ke dompet" dan banner pemberitahuan
# ============================================================

func _build_toast() -> void:
	toast_panel = Style.card()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	toast_panel.add_child(h)
	h.add_child(Style.icon("receipt", Color.WHITE, 44.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.add_child(Style.label("Masuk ke dompet", 13, Style.SOFT))
	toast_detail = Style.label("", 13)
	col.add_child(toast_detail)
	h.add_child(col)
	h.add_child(Style.spacer())
	toast_total = Style.label("+0", 30, Style.GREEN_DARK)
	h.add_child(toast_total)
	var sv := VBoxContainer.new()
	sv.add_child(Style.icon("star", Color.WHITE, 24.0))
	toast_stars = Style.label("5/5", 15)
	sv.add_child(toast_stars)
	h.add_child(sv)
	toast_panel.visible = false
	root.add_child(toast_panel)
	Style.anchor_top_right(toast_panel, 12.0)
	toast_panel.offset_top = 216.0
	toast_panel.offset_bottom = 216.0
	toast_panel.custom_minimum_size = Vector2(330, 0)


func _on_sale_made(sale: int, tip: int, bonus: int, stars: float) -> void:
	toast_total.text = "+%d" % (sale + tip + bonus)
	toast_detail.text = "Penjualan %d   Tip %d   Bonus %d" % [sale, tip, bonus]
	toast_stars.text = "%d/5" % stars
	toast_panel.visible = true
	toast_panel.modulate = Color(1, 1, 1, 1)
	if toast_tween != null:
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(3.0)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.5)
	toast_tween.tween_callback(_hide_toast)


func _hide_toast() -> void:
	toast_panel.visible = false


func _build_notice() -> void:
	notice_panel = Style.card(Color(0.3, 0.2, 0.12, 0.95), Color(0.5, 0.35, 0.2))
	notice_label = Style.label("", 16, Color(1.0, 0.95, 0.85))
	notice_panel.add_child(notice_label)
	notice_panel.visible = false
	root.add_child(notice_panel)
	Style.anchor_top_center(notice_panel, 160.0)


func notify(text: String) -> void:
	notice_label.text = text
	notice_panel.visible = true
	notice_panel.modulate = Color(1, 1, 1, 1)
	if notice_tween != null:
		notice_tween.kill()
	notice_tween = create_tween()
	notice_tween.tween_interval(2.4)
	notice_tween.tween_property(notice_panel, "modulate:a", 0.0, 0.4)
	notice_tween.tween_callback(_hide_notice)


func _hide_notice() -> void:
	notice_panel.visible = false


# ============================================================
#  Peringatan stok (bisa dilipat)
# ============================================================

func _build_stock_alert() -> void:
	stock_panel = Style.card(Color(1.0, 0.96, 0.88, 0.98))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	stock_panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(Style.icon("warn", Style.ORANGE, 26.0))
	head.add_child(Style.label("Peringatan Stok", 17))
	var cp := Style.pill("0", Style.ORANGE, 13)
	stock_count = cp.get_child(0)
	head.add_child(cp)
	stock_btn = Style.button("v", Style.ORANGE)
	stock_btn.custom_minimum_size = Vector2(30, 0)
	stock_btn.pressed.connect(_on_stock_toggle)
	head.add_child(stock_btn)
	v.add_child(head)
	stock_list = Style.label("", 14, Style.SOFT)
	stock_list.visible = false
	v.add_child(stock_list)
	stock_panel.visible = false
	root.add_child(stock_panel)
	Style.anchor_bottom_center(stock_panel, 112.0)


func _on_stock_toggle() -> void:
	stock_open = not stock_open
	stock_list.visible = stock_open
	stock_btn.text = "^" if stock_open else "v"


# ============================================================
#  Kartu staf
# ============================================================

func rebuild_staff() -> void:
	if staff_box == null:
		return
	Style.clear(staff_box)
	staff_cards.clear()
	for a in main.employees.actors:
		var card := Style.card()
		card.custom_minimum_size = Vector2(138, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 5)
		card.add_child(v)

		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 6)
		top.add_child(Style.label("#%d" % a.actor_id, 18))
		top.add_child(Style.pill("STAF", Style.BLUE, 11))
		top.add_child(Style.spacer())
		top.add_child(Style.icon("hat", Color.WHITE, 24.0))
		v.add_child(top)

		var mid := HBoxContainer.new()
		mid.add_theme_constant_override("separation", 8)
		var glass := Style.icon("glass", Color(0.8, 0.78, 0.72, 0.5), 38.0)
		mid.add_child(glass)
		var bp := Style.pill("-", Style.ORANGE, 13)
		var badge: Label = bp.get_child(0)
		mid.add_child(bp)
		v.add_child(mid)

		var status := Style.label("", 12, Style.SOFT)
		status.clip_text = true
		v.add_child(status)
		var pb := Style.bar(116.0)
		v.add_child(pb)

		var btn := Style.button("Ambil alih", Style.BLUE)
		if a.controlled:
			btn.text = "Kamu"
			btn.disabled = true
		else:
			btn.pressed.connect(_on_take_over.bind(a))
		v.add_child(btn)

		staff_box.add_child(card)
		staff_cards.append({"actor": a, "glass": glass, "badge": badge, "status": status, "bar": pb, "last": "?"})


func _on_take_over(a) -> void:
	main.employees.call_deferred("set_controlled", a)


# ============================================================
#  Tiket pesanan
# ============================================================

func _rebuild_orders() -> void:
	Style.clear(order_box)
	order_cards.clear()
	for o in main.order_manager.orders:
		var rid := str(o["recipe"])
		var card := Style.card()
		card.custom_minimum_size = Vector2(220, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		h.add_child(Style.drink_icon(rid, 46.0))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		h.add_child(v)
		v.add_child(Style.label("%s  (#%d)" % [RecipeManager.recipe_name(rid), int(o["id"])], 16))
		var ir := HBoxContainer.new()
		ir.add_theme_constant_override("separation", 3)
		for ing in RecipeManager.recipe(rid)["ingredients"]:
			ir.add_child(Style.ingredient_icon(str(ing), 20.0))
		v.add_child(ir)
		var pb := Style.bar(140.0)
		v.add_child(pb)
		order_box.add_child(card)
		order_cards.append({"order": o, "bar": pb})


func _refresh_orders() -> void:
	var sig := ""
	for o in main.order_manager.orders:
		sig += str(o["id"]) + ","
	if sig != order_sig:
		order_sig = sig
		_rebuild_orders()
	for oc in order_cards:
		var o = oc["order"]
		var pb: ProgressBar = oc["bar"]
		var ratio := clampf(float(o["patience"]) / float(o["max"]), 0.0, 1.0)
		pb.value = ratio * 100.0
		if ratio < 0.3:
			pb.modulate = Color(1.0, 0.45, 0.4)
		else:
			pb.modulate = Color(1, 1, 1)


# ============================================================
#  Refresh per frame
# ============================================================

func refresh() -> void:
	if main == null or root == null:
		return
	day_label.text = "Hari %d" % GameManager.day
	var h := floori(GameManager.game_min / 60.0)
	var m := int(GameManager.game_min) % 60
	time_label.text = "%02d:%02d" % [h, m]
	if main.ratings.today_count() == 0:
		rating_label.text = "-"
	else:
		rating_label.text = "%.1f" % main.ratings.today_avg()
	gold_label.text = str(main.economy.gold)
	sold_label.text = str(main.economy.served_today)
	bonus_label.text = "+%d%%" % main.menu.bonus_percent()
	crowd_label.text = main.popularity.level_text()

	for sc in staff_cards:
		var a = sc["actor"]
		var rid: String = a.assigned_recipe
		if rid != str(sc["last"]):
			sc["last"] = rid
			var g = sc["glass"]
			if rid == "":
				g.color = Color(0.8, 0.78, 0.72, 0.5)
			else:
				g.color = RecipeManager.recipe(rid)["color"]
			g.queue_redraw()
		var badge: Label = sc["badge"]
		if a.ai_total > 0 and not a.controlled:
			badge.text = "%d/%d" % [a.ai_total - a.ai_steps.size(), a.ai_total]
		else:
			badge.text = "-"
		var lbl: Label = sc["status"]
		lbl.text = a.status_text()
		var pb: ProgressBar = sc["bar"]
		pb.value = a.progress_value()

	_refresh_orders()
	inventory_ui.refresh()
	camera_ui.refresh()
	touch_controls.refresh()

	var low: PackedStringArray = main.ingredients.low_stock(5, main.furniture.owned_ingredient_keys())
	if low.is_empty():
		stock_panel.visible = false
	else:
		stock_panel.visible = true
		stock_count.text = str(low.size())
		stock_list.text = "\n".join(low)
