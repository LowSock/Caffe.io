extends Node3D
# Daftar staf (chef), siapa yang sedang dikendalikan pemain, rekrut staf,
# dan rencana langkah kerja untuk staf AI.

const ActorScript = preload("res://scripts/player/actor.gd")
const Data = preload("res://scripts/common/data.gd")

var main = null
var actors: Array = []
var controlled = null
var max_staff := 6
var next_actor_id := 1


func setup(p_main) -> void:
	main = p_main
	EventBus.shift_ended.connect(_on_shift_ended)


func spawn_initial() -> void:
	_spawn(Vector3(-1.0, 0.0, 1.0), 0)
	_spawn(Vector3(1.5, 0.0, 1.0), 1)


func add_staff() -> Variant:
	var a = _spawn(Vector3(0.0, 0.0, 1.5), actors.size())
	EventBus.staff_changed.emit()
	return a


func _spawn(pos: Vector3, variant: int) -> Variant:
	var a = ActorScript.new()
	a.position = pos
	add_child(a)
	a.setup(next_actor_id, main, variant)
	next_actor_id += 1
	actors.append(a)
	return a


func staff_full() -> bool:
	return actors.size() >= max_staff


func set_controlled(actor) -> void:
	if controlled != null:
		controlled.controlled = false
		controlled.reset_ai()
	controlled = actor
	actor.controlled = true
	actor.reset_ai()
	actor.has_target = false
	actor.target_station = null
	EventBus.controlled_changed.emit(actor)


func plan_steps(rid: String) -> Array:
	# Urutan stasiun yang harus dikunjungi staf AI untuk satu resep.
	var r = Data.RECIPES[rid]
	var steps: Array = []
	for ing in r["ingredients"]:
		steps.append({"st": main.furniture.get_station("crate", str(ing)), "act": "grab"})
	var m = main.furniture.get_station("machine", str(r["machine"]))
	steps.append({"st": m, "act": "brew"})
	steps.append({"st": m, "act": "collect"})
	steps.append({"st": main.furniture.get_station("counter", "counter"), "act": "serve"})
	return steps


func _on_shift_ended(_day: int) -> void:
	for a in actors:
		a.carry.clear()
		a.has_target = false
		a.target_station = null
		a.reset_ai()
