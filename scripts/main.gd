extends Node3D
# Akar permainan: merakit semua sistem, kamera, input klik/tap, dan teks melayang.
# Logika permainan ada di modul masing-masing (lihat README untuk peta folder).

const Data = preload("res://scripts/common/data.gd")
const EnvironmentScript = preload("res://scripts/world/environment.gd")
const CameraRigScript = preload("res://scripts/world/camera_rig.gd")
const NpcScript = preload("res://scripts/world/npc.gd")
const IngredientScript = preload("res://scripts/cooking/ingredient_system.gd")
const MenuScript = preload("res://scripts/cooking/menu_manager.gd")
const RatingScript = preload("res://scripts/restaurant/rating_manager.gd")
const UpgradeScript = preload("res://scripts/restaurant/upgrade_manager.gd")
const PopularityScript = preload("res://scripts/restaurant/popularity_manager.gd")
const EconomyScript = preload("res://scripts/restaurant/economy_manager.gd")
const OrderScript = preload("res://scripts/restaurant/order_manager.gd")
const CustomerScript = preload("res://scripts/restaurant/customer_manager.gd")
const EmployeeScript = preload("res://scripts/restaurant/employee_manager.gd")
const FurnitureScript = preload("res://scripts/building/furniture_manager.gd")
const PlacementScript = preload("res://scripts/building/placement_system.gd")
const InteractionScript = preload("res://scripts/player/interaction.gd")
const HudScript = preload("res://scripts/ui/hud.gd")

# Ambang geser (piksel) supaya seretan tidak dihitung sebagai klik
const CLICK_MOVE_LIMIT := 14.0

var camera_rig = null
var world_env = null
var street_npcs = null
var ingredients = null
var menu = null
var ratings = null
var upgrades = null
var popularity = null
var economy = null
var order_manager = null
var customers = null
var employees = null
var furniture = null
var placement = null
var interaction = null
var hud = null

var _press_pos := Vector2.ZERO
var _press_valid := false


func _make(script, node_name: String) -> Variant:
	var n = script.new()
	n.name = node_name
	add_child(n)
	return n


func _ready() -> void:
	# World
	world_env = _make(EnvironmentScript, "Environment")
	world_env.build()
	camera_rig = _make(CameraRigScript, "CameraRig")
	camera_rig.setup(self)

	# Sistem permainan
	ingredients = _make(IngredientScript, "IngredientSystem")
	menu = _make(MenuScript, "MenuManager")
	economy = _make(EconomyScript, "EconomyManager")
	upgrades = _make(UpgradeScript, "UpgradeManager")
	ratings = _make(RatingScript, "RatingManager")
	popularity = _make(PopularityScript, "PopularityManager")
	order_manager = _make(OrderScript, "OrderManager")
	customers = _make(CustomerScript, "CustomerManager")
	employees = _make(EmployeeScript, "EmployeeManager")
	furniture = _make(FurnitureScript, "FurnitureManager")
	placement = _make(PlacementScript, "PlacementSystem")
	interaction = _make(InteractionScript, "Interaction")
	street_npcs = _make(NpcScript, "StreetNPC")

	upgrades.setup(self)
	ratings.setup(self)
	popularity.setup(self)
	order_manager.setup(self)
	customers.setup(self)
	employees.setup(self)
	furniture.setup(self)
	interaction.setup(self)
	placement.setup(self)
	street_npcs.setup(self)

	furniture.build_default_layout()
	employees.spawn_initial()
	street_npcs.spawn()

	if SaveManager.has_save():
		SaveManager.load_game(self)

	employees.set_controlled(employees.actors[0])

	hud = HudScript.new()
	add_child(hud)
	hud.setup(self)

	EventBus.popup_requested.connect(_on_popup_requested)
	EventBus.shift_ended.connect(_on_shift_ended)

	GameManager.start_shift()
	if GameManager.day == 1 and menu.unlocked_count() <= 1:
		hud.notify("Menu awal: Boba Milk Tea. Beli menu dan peti bahan lain di Toko!")


func _process(delta: float) -> void:
	GameManager.tick(delta)
	if hud != null:
		hud.refresh()


# ============================================================
#  Input (klik / tap / keyboard)
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.shift_active or employees.controlled == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Klik diproses saat dilepas, dan dibatalkan kalau jadi seretan atau gestur dua jari.
		if event.pressed:
			_press_pos = event.position
			_press_valid = not camera_rig.gesturing
		else:
			if _press_valid and not camera_rig.gesturing and event.position.distance_to(_press_pos) < CLICK_MOVE_LIMIT:
				_world_click(event.position)
			_press_valid = false
	elif event is InputEventMouseMotion:
		if _press_valid and event.position.distance_to(_press_pos) >= CLICK_MOVE_LIMIT:
			_press_valid = false
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			interact_nearest()


func interact_nearest() -> void:
	# Dipakai tombol Aksi di layar dan tombol E/Spasi.
	if employees.controlled == null or not GameManager.shift_active:
		return
	var st = interaction.nearest_station(employees.controlled.position)
	if st != null:
		employees.controlled.go_to_station(st, "auto")


func _world_click(screen_pos: Vector2) -> void:
	if not GameSettings.uses_tap():
		return    # mode analog saja: ketukan di dunia tidak menggerakkan chef
	var hit = camera_rig.screen_to_ground(screen_pos)
	if hit == null:
		return
	var p: Vector3 = hit
	var st = interaction.pick_station(p)
	if st != null:
		employees.controlled.go_to_station(st, "auto")
	else:
		employees.controlled.go_to_point(p)


# ============================================================
#  Aksi tingkat atas (dipanggil UI)
# ============================================================

func buy_crate(k: String) -> bool:
	# Beli peti bahan di Toko: dipasang otomatis di titik kosong, lengkap dengan isi awal.
	var info = Data.INGREDIENTS[k]
	var cost := int(info.get("crate_cost", 0))
	var type := "crate_" + k
	if furniture.get_station("crate", k) != null:
		return false
	if not economy.can_afford(cost):
		return false
	var spot: Vector2 = furniture.free_spot(type)
	if not furniture.can_place(type, spot.x, spot.y, 0):
		hud.notify("Tidak ada ruang untuk peti ini. Perluas kafe atau rapikan perabot.")
		return false
	economy.spend(cost)
	furniture.add_item(type, spot.x, spot.y, 0)
	ingredients.add(k, int(info.get("crate_stock", 12)))
	furniture.refresh_crates()
	return true


func stock_cost(k: String) -> int:
	# Harga belanja satu paket bahan setelah diskon upgrade "Kontrak Supplier".
	return roundi(float(Data.INGREDIENTS[k]["cost"]) * upgrades.supplier_mult())


func buy_stock(k: String) -> bool:
	var info = Data.INGREDIENTS[k]
	if not economy.spend(stock_cost(k)):
		return false
	ingredients.add(k, int(info["pack"]))
	return true


func hire_staff() -> bool:
	if employees.staff_full():
		return false
	if not economy.spend(economy.hire_cost(employees.actors.size())):
		return false
	employees.add_staff()
	return true


func start_next_day() -> void:
	economy.reset_day()
	SaveManager.save_game(self)
	hud.management.hide_panel()
	GameManager.next_day()


func _on_shift_ended(_day: int) -> void:
	SaveManager.save_game(self)


# ============================================================
#  Teks melayang
# ============================================================

func _on_popup_requested(pos: Vector3, msg: String, color: Color) -> void:
	var l := Label3D.new()
	l.text = msg
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.01
	l.font_size = 44
	l.outline_size = 12
	l.modulate = color
	l.position = pos
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + 1.2, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(l.queue_free)
