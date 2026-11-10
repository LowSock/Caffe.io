extends RefCounted
# Panel akhir shift: ringkasan hari, belanja stok (Shop), Atur Menu,
# rekrut staf, dan tombol mulai hari berikutnya.

const Style = preload("res://scripts/ui/ui_style.gd")
const ShopScript = preload("res://scripts/ui/shop.gd")
const RatingScript = preload("res://scripts/restaurant/rating_manager.gd")

var main = null
var overlay: Control
var box: VBoxContainer
var _shop = null


func build(root: Control, p_main) -> void:
	main = p_main
	_shop = ShopScript.new()

	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.06, 0.03, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var p := Style.card(Color(0.99, 0.97, 0.93, 1.0), Style.BORDER, 22)
	p.custom_minimum_size = Vector2(470, 0)
	center.add_child(p)

	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	p.add_child(box)


func show_panel() -> void:
	overlay.visible = true
	fill()


func hide_panel() -> void:
	overlay.visible = false


func fill() -> void:
	var eco = main.economy
	Style.clear(box)

	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 8)
	title.add_child(Style.icon("calendar", Color.WHITE, 30.0))
	title.add_child(Style.label("Shift selesai - Hari %d" % GameManager.day, 25))
	box.add_child(title)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 14)
	stats.add_child(Style.label("Selesai: %d" % eco.served_today, 17))
	stats.add_child(Style.label("Pergi: %d" % eco.lost_today, 17))
	stats.add_child(Style.label("Pendapatan: %d" % eco.earned_today, 17))
	box.add_child(stats)

	var total := HBoxContainer.new()
	total.add_theme_constant_override("separation", 6)
	total.add_child(Style.icon("coin", Color.WHITE, 24.0))
	total.add_child(Style.label("%d gold" % eco.gold, 20, Style.GREEN_DARK))
	box.add_child(total)
	box.add_child(HSeparator.new())
	_fill_rating()
	box.add_child(HSeparator.new())
	_fill_popularity()
	box.add_child(HSeparator.new())

	_shop.fill(box, main, fill)
	box.add_child(HSeparator.new())

	var shop_btn := Style.button("Toko (menu dan peti bahan)", Color(0.4, 0.6, 0.35))
	shop_btn.pressed.connect(_on_shop)
	box.add_child(shop_btn)

	var build_btn := Style.button("Mode Bangun (tata letak)", Color(0.6, 0.4, 0.25))
	build_btn.pressed.connect(_on_build)
	box.add_child(build_btn)

	var up_btn := Style.button("Upgrade Restoran", Style.ORANGE)
	up_btn.pressed.connect(_on_upgrade)
	box.add_child(up_btn)

	var menu_btn := Style.button("Atur Menu", Style.GREEN_DARK)
	menu_btn.pressed.connect(_on_menu)
	box.add_child(menu_btn)

	var cost: int = eco.hire_cost(main.employees.actors.size())
	var hire := Style.button("Rekrut karyawan (%d gold)   staf: %d" % [cost, main.employees.actors.size()], Style.BLUE)
	hire.disabled = not eco.can_afford(cost) or main.employees.staff_full()
	hire.pressed.connect(_on_hire)
	box.add_child(hire)

	var nxt := Style.button("Mulai hari berikutnya", Style.RED)
	nxt.pressed.connect(_on_next_day)
	box.add_child(nxt)


func _fill_popularity() -> void:
	# Rincian kenapa kafe sepi atau ramai (dan kenapa bintang 5 lebih sering).
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(Style.icon("arrow_up", Style.ORANGE, 24.0))
	head.add_child(Style.label("Keramaian", 18))
	box.add_child(head)
	var txt := Style.label(str(main.popularity.describe()), 12, Style.SOFT)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size = Vector2(430, 0)
	box.add_child(txt)
	box.add_child(Style.label("Menu, furnitur, dan upgrade membuat kafe makin ramai.", 12, Style.GREEN_DARK))


func _fill_rating() -> void:
	# Rating hari ini = rata-rata ulasan pelanggan hari itu.
	var r = main.ratings
	var summary: Dictionary = r.last_summary
	var count := int(summary.get("count", 0))
	var avg := float(summary.get("avg", 0.0))
	var dist: Array = summary.get("dist", [0, 0, 0, 0, 0])

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(Style.icon("star", Color.WHITE, 28.0))
	if count == 0:
		head.add_child(Style.label("Rating hari ini: belum ada ulasan", 18))
	else:
		head.add_child(Style.label("Rating hari ini: %.1f / 5" % avg, 20))
		head.add_child(Style.label("(%d ulasan)" % count, 14, Style.SOFT))
	box.add_child(head)

	if count > 0:
		var most := 1
		for c in dist:
			most = maxi(most, int(c))
		for s in range(5, 0, -1):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var n := int(dist[s - 1])
			var lab := Style.label("%d bintang" % s, 13, Style.SOFT)
			lab.custom_minimum_size = Vector2(70, 0)
			row.add_child(lab)
			var pb := Style.bar(220.0)
			pb.value = 100.0 * float(n) / float(most)
			pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(pb)
			row.add_child(Style.label(str(n), 13))
			box.add_child(row)

	var ov := float(r.overall())
	var tail := "Rating restoran (%d hari terakhir): " % RatingScript.KEEP_DAYS
	if ov <= 0.0:
		tail += "-"
	else:
		tail += "%.1f / 5" % ov
	box.add_child(Style.label(tail, 15, Style.GREEN_DARK))
	box.add_child(Style.label("Rating tinggi membuat pelanggan lebih sering datang.", 12, Style.SOFT))


func _on_shop() -> void:
	main.hud.menu_shop_ui.open()


func _on_build() -> void:
	main.placement.enter_mode()


func _on_upgrade() -> void:
	main.hud.upgrade_ui.open()


func _on_menu() -> void:
	main.hud.menu_ui.open()


func _on_hire() -> void:
	main.hire_staff()
	fill()


func _on_next_day() -> void:
	main.start_next_day()
