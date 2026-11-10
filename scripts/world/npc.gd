extends Node3D
# Pejalan kaki di trotoar barat (dekat kafe) dan trotoar seberang jalan.
# Mereka berjalan bolak-balik di sepanjang jalan, sesekali berhenti sambil
# bicara, dan saling menyapa kalau berpapasan.

const CharacterFactory = preload("res://scripts/common/character_factory.gd")
const Nav = preload("res://scripts/world/navigation.gd")
const Dialogue = preload("res://scripts/world/npc_dialogue.gd")
const BubbleScript = preload("res://scripts/world/speech_bubble.gd")

const COUNT := 10

var main = null
var rng := RandomNumberGenerator.new()
var _peds: Array = []
var _meet_timer := 0.0


func setup(p_main) -> void:
	main = p_main
	rng.randomize()


func spawn() -> void:
	for i in range(COUNT):
		_spawn_one(i)


func _spawn_one(i: int) -> void:
	var x := Nav.SIDEWALK_FAR_X
	if i % 2 == 0:
		x = Nav.SIDEWALK_NEAR_X
	x += rng.randf_range(-0.1, 0.1)

	var node := Node3D.new()
	node.position = Vector3(x, 0.0, rng.randf_range(Nav.STREET_MIN_Z, Nav.STREET_MAX_Z))
	add_child(node)

	var kind: String = CharacterFactory.CUSTOMER_KINDS[rng.randi() % CharacterFactory.CUSTOMER_KINDS.size()]
	var rig := CharacterFactory.build(node, kind, rng.randi() % 3)

	var bubble = BubbleScript.new()
	bubble.position = Vector3(0, 3.1, 0)
	node.add_child(bubble)

	var dir := 1.0
	if rng.randf() < 0.5:
		dir = -1.0

	_peds.append({
		"node": node, "rig": rig, "kind": kind, "bubble": bubble,
		"dir": dir, "speed": rng.randf_range(1.5, 2.3), "pause": 0.0,
		"chat": rng.randf_range(3.0, 9.0), "cool": rng.randf_range(0.0, 6.0),
		"t": rng.randf() * 10.0, "lane_x": x,
	})


func _process(delta: float) -> void:
	for p in _peds:
		var n: Node3D = p["node"]
		p["t"] = float(p["t"]) + delta
		p["cool"] = maxf(0.0, float(p["cool"]) - delta)
		var moving := false
		if float(p["pause"]) > 0.0:
			p["pause"] = float(p["pause"]) - delta
		else:
			n.position.z += float(p["dir"]) * float(p["speed"]) * delta
			if n.position.z > Nav.STREET_MAX_Z:
				p["dir"] = -1.0
			elif n.position.z < Nav.STREET_MIN_Z:
				p["dir"] = 1.0
			n.rotation.y = atan2(0.0, float(p["dir"]))
			moving = true
		CharacterFactory.animate(p["rig"], float(p["t"]), moving, false)

		p["chat"] = float(p["chat"]) - delta
		if float(p["chat"]) <= 0.0:
			p["chat"] = rng.randf_range(7.0, 15.0)
			var bub = p["bubble"]
			bub.say(Dialogue.pick(str(p["kind"]), "street"), 3.2)
			if rng.randf() < 0.35:
				p["pause"] = 2.8

	_meet_timer -= delta
	if _meet_timer <= 0.0:
		_meet_timer = 0.4
		_check_meetings()


func _check_meetings() -> void:
	for i in range(_peds.size()):
		for j in range(i + 1, _peds.size()):
			var a = _peds[i]
			var b = _peds[j]
			if float(a["cool"]) > 0.0 or float(b["cool"]) > 0.0:
				continue
			if absf(float(a["lane_x"]) - float(b["lane_x"])) > 0.8:
				continue
			if float(a["dir"]) == float(b["dir"]):
				continue
			var na: Node3D = a["node"]
			var nb: Node3D = b["node"]
			if absf(na.position.z - nb.position.z) < 2.0:
				_meet(a, b)
				return


func _meet(a: Dictionary, b: Dictionary) -> void:
	a["pause"] = 3.4
	b["pause"] = 3.4
	a["cool"] = 20.0
	b["cool"] = 20.0
	var na: Node3D = a["node"]
	var nb: Node3D = b["node"]
	# saling menghadap (sepanjang sumbu Z)
	var toward := signf(nb.position.z - na.position.z)
	na.rotation.y = atan2(0.0, toward)
	nb.rotation.y = atan2(0.0, -toward)
	var ba = a["bubble"]
	ba.say(Dialogue.pick(str(a["kind"]), "greet"), 2.4)
	await get_tree().create_timer(1.6).timeout
	var bb = b["bubble"]
	bb.say(Dialogue.pick(str(b["kind"]), "reply"), 2.4)
