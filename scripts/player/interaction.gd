extends Node
# Interaksi staf dengan stasiun (peti, mesin, meja saji) + pemilihan stasiun
# dari klik/tap. Hasil interaksi: "ok" | "busy" | "wait" | "fail".

const Data = preload("res://scripts/common/data.gd")
const Inv = preload("res://scripts/player/inventory.gd")
const RecipeManager = preload("res://scripts/cooking/recipe_manager.gd")

var main = null


func setup(p_main) -> void:
	main = p_main


# ---------- memilih stasiun ----------

func pick_station(p: Vector3) -> Variant:
	var best = null
	var best_d := 9999.0
	for st in main.furniture.stations:
		var d := Vector2(p.x - st.position.x, p.z - st.position.z).length()
		if d <= st.hit_radius and d < best_d:
			best = st
			best_d = d
	return best


func nearest_station(pos: Vector3, max_extra: float = 1.2) -> Variant:
	var best = null
	var best_d := 9999.0
	for st in main.furniture.stations:
		var d := Vector2(pos.x - st.position.x, pos.z - st.position.z).length()
		if d <= st.radius + max_extra and d < best_d:
			best = st
			best_d = d
	return best


# ---------- interaksi ----------

func interact(actor, st, act: String) -> String:
	match st.kind:
		"crate":
			return _do_grab(actor, st)
		"machine":
			var a := act
			if a == "auto":
				if st.state == "ready":
					a = "collect"
				else:
					a = "brew"
			if a == "collect":
				return _do_collect(actor, st)
			return _do_brew(actor, st)
		"counter":
			return _do_serve(actor, st)
	return "fail"


func _popup(actor, msg: String, force: bool = false) -> void:
	if not force and not actor.controlled:
		return
	EventBus.popup_requested.emit(actor.position + Vector3(0, 4.4, 0), msg, Color(1, 1, 1))


func _do_grab(actor, st) -> String:
	if Inv.is_full(actor.carry):
		_popup(actor, "Tangan penuh")
		return "fail"
	if not main.ingredients.take(str(st.key)):
		_popup(actor, "Stok habis!")
		return "fail"
	actor.carry.append("ing:" + str(st.key))
	return "ok"


func _do_brew(actor, st) -> String:
	if st.state == "ready" and not actor.controlled:
		# AI menemukan minuman siap milik orang lain: ambil dulu, lalu coba lagi.
		_do_collect(actor, st)
		return "busy"
	if st.state != "idle":
		_popup(actor, "Mesin sedang dipakai")
		return "busy"
	var rid := ""
	if actor.assigned_recipe != "":
		var ar = Data.RECIPES[actor.assigned_recipe]
		if ar["machine"] == st.key and Inv.has_ingredients(actor.carry, ar["ingredients"]):
			rid = actor.assigned_recipe
	if rid == "":
		rid = RecipeManager.find_for_machine(str(st.key), actor.carry, main.order_manager.orders)
	if rid == "":
		_popup(actor, "Belum ada pesanan yang cocok")
		return "fail"
	Inv.remove_ingredients(actor.carry, Data.RECIPES[rid]["ingredients"])
	var brew_time := float(Data.RECIPES[rid]["time"]) * float(main.upgrades.brew_mult(str(st.key)))
	st.start_brew(rid, brew_time, actor.actor_id)
	actor.speak("chef_brew", 0.3)
	return "ok"


func _do_collect(actor, st) -> String:
	if st.state == "brewing":
		return "wait"
	if st.state != "ready":
		return "fail"
	if Inv.is_full(actor.carry):
		_popup(actor, "Tangan penuh")
		return "fail"
	actor.carry.append("drink:" + st.take_drink())
	return "ok"


func _do_serve(actor, st) -> String:
	var served_any := false
	var i: int = actor.carry.size() - 1
	while i >= 0:
		var item: String = str(actor.carry[i])
		if item.begins_with("drink:"):
			var order = main.order_manager.find_for(item.substr(6))
			if order != null:
				main.order_manager.complete(order, actor)
				actor.carry.remove_at(i)
				served_any = true
		i -= 1
	if not served_any:
		_popup(actor, "Tidak ada pesanan yang cocok")
		return "fail"
	actor.speak("chef_serve", 0.45)
	return "ok"
