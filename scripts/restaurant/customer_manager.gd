extends Node3D
# Pelanggan: muncul dari jalan, masuk lewat pintu, antre di meja saji,
# mengobrol sambil menunggu, lalu pergi (senang atau kesal).

const Data = preload("res://scripts/common/data.gd")
const CharacterFactory = preload("res://scripts/common/character_factory.gd")
const RecipeManager = preload("res://scripts/cooking/recipe_manager.gd")
const Nav = preload("res://scripts/world/navigation.gd")
const Dialogue = preload("res://scripts/world/npc_dialogue.gd")
const BubbleScript = preload("res://scripts/world/speech_bubble.gd")

const WALK_SPEED := 3.4

var main = null
var rng := RandomNumberGenerator.new()
var spawn_timer := 2.0
var _arriving: Array = []
var _leaving: Array = []


func setup(p_main) -> void:
	main = p_main
	rng.randomize()
	EventBus.order_completed.connect(_on_order_completed)
	EventBus.order_lost.connect(_on_order_lost)
	EventBus.shift_started.connect(_on_shift_started)
	EventBus.shift_ended.connect(_on_shift_ended)


func _on_shift_started(_day: int) -> void:
	spawn_timer = 4.0


func _on_shift_ended(_day: int) -> void:
	for c in _arriving:
		var n = c["node"]
		if is_instance_valid(n):
			n.queue_free()
	_arriving.clear()
	for c in _leaving:
		var n2 = c["node"]
		if is_instance_valid(n2):
			n2.queue_free()
	_leaving.clear()


func _process(delta: float) -> void:
	_tick_arriving(delta)
	_tick_leaving(delta)
	_tick_seated(delta)
	if GameManager.shift_active:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_customer()
			spawn_timer = main.popularity.next_interval(rng)


# ---------- muncul ----------

func _used_slots() -> Array:
	var used: Array = []
	for o in main.order_manager.orders:
		used.append(o["slot"])
	for c in _arriving:
		used.append(c["slot"])
	return used


func _spawn_customer() -> void:
	var om = main.order_manager
	if om.orders.size() + _arriving.size() >= om.max_orders:
		return
	var avail: Array = []
	var owned: Dictionary = main.furniture.owned_ingredient_keys()
	for rid in RecipeManager.available(main.ingredients.stock, main.menu.active()):
		var has_crates := true
		for ing in RecipeManager.recipe(str(rid))["ingredients"]:
			if not owned.has(str(ing)):
				has_crates = false
		if has_crates:
			avail.append(rid)
	if avail.is_empty():
		return

	var used := _used_slots()
	var slot := 0
	while used.has(slot):
		slot += 1

	var rid: String = str(avail[rng.randi() % avail.size()])
	var kind: String = CharacterFactory.CUSTOMER_KINDS[rng.randi() % CharacterFactory.CUSTOMER_KINDS.size()]

	var cust := Node3D.new()
	cust.position = Nav.ARRIVE_POINT
	add_child(cust)
	var rig := CharacterFactory.build(cust, kind, rng.randi() % 3)

	var lab := Label3D.new()
	lab.text = RecipeManager.recipe_name(rid)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	lab.pixel_size = 0.009
	lab.font_size = 34
	lab.outline_size = 8
	lab.position = Vector3(0, 2.9, 0)
	lab.visible = false
	cust.add_child(lab)

	var bubble = BubbleScript.new()
	bubble.position = Vector3(0, 3.5, 0)
	cust.add_child(bubble)

	_arriving.append({
		"node": cust, "rig": rig, "label": lab, "bubble": bubble,
		"recipe": rid, "slot": slot, "kind": kind,
		"path": [Vector3(Nav.QUEUE_OUTER_X, 0.0, Nav.customer_slot(slot).z), Nav.customer_slot(slot)],
		"idx": 0, "t": rng.randf() * 10.0,
	})


# ---------- berjalan masuk ----------

func _tick_arriving(delta: float) -> void:
	var i := _arriving.size() - 1
	while i >= 0:
		var c = _arriving[i]
		var node: Node3D = c["node"]
		c["t"] = float(c["t"]) + delta
		var path: Array = c["path"]
		var target: Vector3 = path[int(c["idx"])]
		var offset := target - node.position
		offset.y = 0.0
		if offset.length() < 0.12:
			c["idx"] = int(c["idx"]) + 1
			if int(c["idx"]) >= path.size():
				_arrived(c)
				_arriving.remove_at(i)
				i -= 1
				continue
		else:
			var step := offset.normalized() * minf(WALK_SPEED * delta, offset.length())
			node.position += step
			node.rotation.y = atan2(offset.x, offset.z)
		CharacterFactory.animate(c["rig"], float(c["t"]), true, false)
		i -= 1


func _arrived(c: Dictionary) -> void:
	var node: Node3D = c["node"]
	node.rotation.y = PI * 0.5
	var lab: Label3D = c["label"]
	lab.visible = true
	var o: Dictionary = main.order_manager.add_order(str(c["recipe"]), int(c["slot"]), node, c["rig"], lab, c["bubble"], str(c["kind"]))
	o["chat"] = rng.randf_range(8.0, 14.0)
	var bub = c["bubble"]
	bub.say(Dialogue.pick(str(c["kind"]), "arrive", RecipeManager.recipe_name(str(c["recipe"]))), 3.5)


# ---------- menunggu di meja saji ----------

func _tick_seated(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for o in main.order_manager.orders:
		var ratio := float(o["patience"]) / float(o["max"])
		var lbl: Label3D = o["label"]
		var bub = o["bubble"]
		var kind := str(o["kind"])
		var drink := RecipeManager.recipe_name(str(o["recipe"]))
		o["chat"] = float(o["chat"]) - delta

		if ratio < 0.3:
			lbl.modulate = Color(1.0, 0.5, 0.45)

		var stage := int(o["stage"])
		if ratio < 0.18 and stage < 2:
			o["stage"] = 2
			o["chat"] = 10.0
			bub.say(Dialogue.pick(kind, "impatient", drink), 3.0)
		elif ratio < 0.45 and stage < 1:
			o["stage"] = 1
			o["chat"] = 10.0
			bub.say(Dialogue.pick(kind, "impatient", drink), 3.0)
		elif float(o["chat"]) <= 0.0 and ratio > 0.5:
			o["chat"] = rng.randf_range(9.0, 16.0)
			bub.say(Dialogue.pick(kind, "wait", drink), 3.0)

		CharacterFactory.animate(o["rig"], t + float(o["id"]), false, false)


# ---------- pergi ----------

func _on_order_completed(order: Dictionary, _total: int) -> void:
	var stars := int(order.get("stars", 5))
	var situation := "happy"
	if stars == 3:
		situation = "neutral"
	elif stars <= 2:
		situation = "unhappy"
	var bub = order["bubble"]
	bub.say(Dialogue.pick(str(order["kind"]), situation), 2.8)
	_review_popup(order, stars)
	_begin_leave(order)


func _on_order_lost(order: Dictionary) -> void:
	var bub = order["bubble"]
	bub.say(Dialogue.pick(str(order["kind"]), "angry"), 2.8)
	_review_popup(order, 1)
	_begin_leave(order)


func _review_popup(order: Dictionary, stars: int) -> void:
	# Teks melayang "Bintang N" di atas pelanggan: emas kalau puas, merah kalau kecewa.
	var n = order["node"]
	if n == null or not is_instance_valid(n):
		return
	var c := Color(1.0, 0.85, 0.3)
	if stars <= 2:
		c = Color(1.0, 0.45, 0.4)
	elif stars == 3:
		c = Color(1, 1, 1)
	EventBus.popup_requested.emit(n.position + Vector3(0, 5.0, 0), "Bintang %d" % stars, c)


func _begin_leave(order: Dictionary) -> void:
	var node = order["node"]
	if node == null or not is_instance_valid(node):
		return
	var lab: Label3D = order["label"]
	lab.visible = false
	_leaving.append({
		"node": node, "rig": order["rig"],
		"path": [Vector3(Nav.QUEUE_OUTER_X, 0.0, node.position.z), Nav.LEAVE_POINT],
		"idx": 0, "t": rng.randf() * 10.0,
	})


func _tick_leaving(delta: float) -> void:
	var i := _leaving.size() - 1
	while i >= 0:
		var c = _leaving[i]
		var node: Node3D = c["node"]
		if not is_instance_valid(node):
			_leaving.remove_at(i)
			i -= 1
			continue
		c["t"] = float(c["t"]) + delta
		var path: Array = c["path"]
		var target: Vector3 = path[int(c["idx"])]
		var offset := target - node.position
		offset.y = 0.0
		if offset.length() < 0.15:
			c["idx"] = int(c["idx"]) + 1
			if int(c["idx"]) >= path.size():
				node.queue_free()
				_leaving.remove_at(i)
				i -= 1
				continue
		else:
			var step := offset.normalized() * minf((WALK_SPEED + 0.6) * delta, offset.length())
			node.position += step
			node.rotation.y = atan2(offset.x, offset.z)
		CharacterFactory.animate(c["rig"], float(c["t"]), true, false)
		i -= 1
