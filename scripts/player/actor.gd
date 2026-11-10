extends Node3D
# Satu kelas untuk semua staf (chef). Staf yang "controlled" digerakkan pemain
# (WASD / panah / klik / tap). Sisanya dijalankan AI sederhana.
# Tombol "Ambil alih" di HUD memindahkan kontrol antar staf.

const Data = preload("res://scripts/common/data.gd")
const CharacterFactory = preload("res://scripts/common/character_factory.gd")
const Inv = preload("res://scripts/player/inventory.gd")
const Move = preload("res://scripts/player/movement.gd")
const Nav = preload("res://scripts/world/navigation.gd")
const Dialogue = preload("res://scripts/world/npc_dialogue.gd")
const BubbleScript = preload("res://scripts/world/speech_bubble.gd")

var main = null
var actor_id := 0
var speed := 5.0
var controlled := false

var carry: Array = []          # isi tangan: "ing:beans" atau "drink:latte"
var has_target := false
var target := Vector3.ZERO
var target_station = null
var target_act := "auto"

# AI
var ai_steps: Array = []
var ai_total := 0
var ai_wait := 0.0
var assigned_recipe := ""

var _rig: Dictionary = {}
var _carry_label: Label3D
var _bubble = null
var _anim_t := 0.0
var _moving := false


func setup(p_id: int, p_main, variant: int) -> void:
	actor_id = p_id
	main = p_main
	_rig = CharacterFactory.build(self, "chef", variant)
	_anim_t = float(p_id) * 1.7

	var id_label := Label3D.new()
	id_label.text = "#%d" % actor_id
	id_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	id_label.no_depth_test = true
	id_label.pixel_size = 0.01
	id_label.font_size = 40
	id_label.outline_size = 10
	id_label.position = Vector3(0, 3.0, 0)
	add_child(id_label)

	_carry_label = Label3D.new()
	_carry_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_carry_label.no_depth_test = true
	_carry_label.pixel_size = 0.009
	_carry_label.font_size = 32
	_carry_label.outline_size = 8
	_carry_label.modulate = Color(1.0, 0.95, 0.6)
	_carry_label.position = Vector3(0, 3.5, 0)
	_carry_label.visible = false
	add_child(_carry_label)

	_bubble = BubbleScript.new()
	_bubble.position = Vector3(0, 4.0, 0)
	add_child(_bubble)


func speak(situation: String, chance: float = 1.0) -> void:
	if randf() > chance:
		return
	_bubble.say(Dialogue.pick("chef", situation), 2.4)


func _spd() -> float:
	return speed * float(main.upgrades.speed_mult())


func status_text() -> String:
	if controlled:
		return "Kamu yang kendalikan"
	if assigned_recipe != "":
		return str(Data.RECIPES[assigned_recipe]["name"])
	return "Menunggu pesanan"


func progress_value() -> float:
	if controlled or ai_total <= 0:
		return 0.0
	return 100.0 * float(ai_total - ai_steps.size()) / float(ai_total)


func reset_ai() -> void:
	ai_steps.clear()
	ai_total = 0
	ai_wait = 0.0
	assigned_recipe = ""
	if main != null:
		main.order_manager.release_claim(self)


# ---------- gerak ----------

func go_to_point(p: Vector3) -> void:
	target = Nav.clamp_to_room(p)
	has_target = true
	target_station = null
	target_act = "auto"


func go_to_station(st, act: String = "auto") -> void:
	var dir: Vector3 = position - st.position
	dir.y = 0.0
	if dir.length() <= st.radius + 0.3:
		target = position
	else:
		target = Nav.clamp_to_room(st.position + dir.normalized() * st.radius)
	has_target = true
	target_station = st
	target_act = act


func _move(offset: Vector3) -> void:
	if offset.length() < 0.0001:
		return
	position = Nav.clamp_to_room(position + offset)
	rotation.y = Move.facing(offset)
	_moving = true


func _follow_target(delta: float) -> void:
	var to: Vector3 = target - position
	to.y = 0.0
	if to.length() < 0.12:
		has_target = false
		if target_station != null:
			var st = target_station
			target_station = null
			var res: String = main.interaction.interact(self, st, target_act)
			if not controlled:
				_ai_result(res)
		return
	_move(Move.step_toward(position, target, _spd(), delta))


func _process(delta: float) -> void:
	if main == null or not GameManager.shift_active:
		return
	_moving = false
	_anim_t += delta
	if controlled:
		var dir := Move.input_dir()
		if dir != Vector3.ZERO:
			has_target = false
			target_station = null
			_move(dir * _spd() * delta)
	else:
		_ai(delta)
	if has_target:
		_follow_target(delta)
	_carry_label.text = Inv.text(carry)
	CharacterFactory.animate(_rig, _anim_t, _moving, not carry.is_empty())


# ---------- AI ----------

func _ai(delta: float) -> void:
	if has_target:
		return
	ai_wait -= delta
	if ai_wait > 0.0:
		return
	if ai_steps.is_empty():
		_ai_pick_work()
		return
	var step: Dictionary = ai_steps[0]
	go_to_station(step["st"], step["act"])


func _ai_pick_work() -> void:
	if Inv.has_drink(carry):
		ai_steps = [{"st": main.furniture.get_station("counter", "counter"), "act": "serve"}]
		ai_total = 1
		return
	carry.clear()
	var o = main.order_manager.claim_order(self)
	if o == null:
		ai_wait = 0.8
		return
	assigned_recipe = str(o["recipe"])
	ai_steps = main.employees.plan_steps(assigned_recipe)
	ai_total = ai_steps.size()


func _ai_result(res: String) -> void:
	if ai_steps.is_empty():
		return
	match res:
		"ok":
			ai_steps.pop_front()
			if ai_steps.is_empty():
				_ai_done()
		"busy", "wait":
			ai_wait = 0.6
		_:
			_ai_abort()


func _ai_done() -> void:
	main.order_manager.release_claim(self)
	assigned_recipe = ""
	ai_total = 0
	ai_wait = 0.3


func _ai_abort() -> void:
	ai_steps.clear()
	ai_total = 0
	carry.clear()
	main.order_manager.release_claim(self)
	assigned_recipe = ""
	ai_wait = 1.5
