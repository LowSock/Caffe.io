extends RefCounted
# Karakter low-poly chibi dibangun dari kotak/silinder lewat kode (placeholder
# bergaya mirip gambar referensi). Kalau nanti punya model .glb sendiri,
# taruh di res://models/<jenis>.glb (chef.glb, customer_f.glb, pedestrian.glb,
# mailman.glb, police.glb, office.glb) dan model itu otomatis dipakai.

const Gfx = preload("res://scripts/common/gfx.gd")

const SKIN := Color(0.98, 0.82, 0.68)
const CHAR_SCALE := 0.9
const CUSTOMER_KINDS := ["customer_f", "pedestrian", "mailman", "police", "office"]


static func build(parent: Node3D, kind: String, variant: int = 0) -> Dictionary:
	var path := "res://models/%s.glb" % kind
	if ResourceLoader.exists(path):
		var scn = load(path)
		if scn is PackedScene:
			var inst = scn.instantiate()
			parent.add_child(inst)
			Gfx.blob_shadow(parent, 0.75, 0.75, 1.0)
			return {"rig": inst, "arm_l": null, "arm_r": null, "leg_l": null, "leg_r": null}

	var p := _palette(kind, variant)
	var rig := Node3D.new()
	rig.scale = Vector3.ONE * CHAR_SCALE
	parent.add_child(rig)
	Gfx.blob_shadow(parent, 0.8, 0.7, 1.0)
	var refs := _base(rig, p)
	_accessories(rig, kind, p)
	refs["rig"] = rig
	return refs


static func animate(refs: Dictionary, t: float, moving: bool, carrying: bool) -> void:
	var rig: Node3D = refs.get("rig")
	var la: Node3D = refs.get("arm_l")
	var ra: Node3D = refs.get("arm_r")
	var ll: Node3D = refs.get("leg_l")
	var rl: Node3D = refs.get("leg_r")
	if rig == null or la == null:
		return
	var s := 0.0
	if moving:
		s = sin(t * 11.0)
		rig.position.y = absf(s) * 0.08
	else:
		rig.position.y = sin(t * 2.5) * 0.015
	ll.rotation.x = s * 0.7
	rl.rotation.x = -s * 0.7
	if carrying:
		la.rotation.x = -1.0 + s * 0.05
		ra.rotation.x = -1.0 - s * 0.05
	else:
		la.rotation.x = -s * 0.6
		ra.rotation.x = s * 0.6


# ============================================================
#  Palet warna per jenis karakter (variant = variasi warna)
# ============================================================

static func _palette(kind: String, v: int) -> Dictionary:
	var i := absi(v) % 3
	match kind:
		"chef":
			var hair := [Color(0.18, 0.1, 0.1), Color(0.35, 0.2, 0.12), Color(0.55, 0.42, 0.22), Color(0.1, 0.1, 0.15)]
			var scarf := [Color(0.75, 0.12, 0.14), Color(0.75, 0.12, 0.14), Color(0.2, 0.5, 0.75), Color(0.85, 0.55, 0.15)]
			var apron := [Color(0.7, 0.12, 0.14), Color(0.7, 0.12, 0.14), Color(0.15, 0.4, 0.65), Color(0.75, 0.45, 0.1)]
			return {"torso": Color(0.97, 0.95, 0.93), "sleeve": Color(0.97, 0.95, 0.93), "cuff": Color(0.25, 0.22, 0.22),
				"leg": Color(0.2, 0.17, 0.17), "shoe": Color(0.42, 0.26, 0.16), "hair": hair[absi(v) % 4],
				"hair_style": "spiky", "hat_on": true, "apron": apron[absi(v) % 4], "scarf": scarf[absi(v) % 4]}
		"customer_f":
			var hat := [Color(0.84, 0.72, 0.55), Color(0.9, 0.55, 0.65), Color(0.35, 0.55, 0.4)]
			var skirt := [Color(0.62, 0.28, 0.25), Color(0.85, 0.5, 0.6), Color(0.25, 0.45, 0.35)]
			var top := [Color(0.9, 0.8, 0.65), Color(0.95, 0.75, 0.8), Color(0.55, 0.72, 0.55)]
			return {"torso": top[i], "sleeve": top[i], "leg": SKIN, "shoe": Color(0.3, 0.2, 0.15),
				"sock": Color(0.95, 0.93, 0.9), "hair": Color(0.2, 0.12, 0.1), "hair_style": "long", "hat_on": true,
				"hat": hat[i], "skirt": skirt[i], "bag": Color(0.5, 0.32, 0.18)}
		"pedestrian":
			var main_c := [Color(0.2, 0.38, 0.82), Color(0.78, 0.27, 0.27), Color(0.3, 0.62, 0.36)]
			var mc: Color = main_c[i]
			return {"torso": mc, "sleeve": mc.lightened(0.18), "leg": Color(0.15, 0.15, 0.18), "shoe": Color(0.92, 0.92, 0.95),
				"hair": Color(0.2, 0.12, 0.1), "hair_style": "spiky", "bag": Color(0.25, 0.25, 0.3)}
		"mailman":
			var caps := [Color(0.2, 0.3, 0.7), Color(0.25, 0.5, 0.3), Color(0.75, 0.22, 0.22)]
			var cc: Color = caps[i]
			return {"torso": Color(0.55, 0.72, 0.92), "sleeve": Color(0.55, 0.72, 0.92), "leg": Color(0.15, 0.15, 0.2),
				"shoe": Color(0.35, 0.22, 0.15), "hair": Color(0.2, 0.12, 0.1), "hair_style": "spiky", "hat_on": true,
				"cap": cc, "vest": cc.darkened(0.1)}
		"police":
			var shirts := [Color(0.55, 0.72, 0.92), Color(0.22, 0.22, 0.26), Color(0.85, 0.78, 0.6)]
			var pants := [Color(0.15, 0.2, 0.4), Color(0.12, 0.12, 0.15), Color(0.5, 0.42, 0.3)]
			var capsp := [Color(0.15, 0.2, 0.4), Color(0.12, 0.12, 0.15), Color(0.4, 0.34, 0.24)]
			return {"torso": shirts[i], "sleeve": shirts[i], "leg": pants[i], "shoe": Color(0.1, 0.1, 0.12),
				"hair": Color(0.2, 0.12, 0.1), "hair_style": "spiky", "hat_on": true, "cap": capsp[i]}
		"office":
			var suits := [Color(0.15, 0.17, 0.3), Color(0.5, 0.5, 0.53), Color(0.85, 0.75, 0.6)]
			return {"torso": suits[i], "sleeve": suits[i], "leg": SKIN, "shoe": Color(0.2, 0.15, 0.15),
				"hair": Color(0.25, 0.15, 0.12), "hair_style": "bun", "eye_z": 0.42, "case": Color(0.2, 0.18, 0.18)}
	return {"torso": Color(0.7, 0.7, 0.7), "sleeve": Color(0.7, 0.7, 0.7), "leg": Color(0.3, 0.3, 0.3),
		"shoe": Color(0.2, 0.2, 0.2), "hair": Color(0.2, 0.12, 0.1)}


# ============================================================
#  Bagian tubuh
# ============================================================

static func _leg(rig: Node3D, x: float, pants_c: Color, shoe_c: Color, sock_c) -> Node3D:
	var piv := Node3D.new()
	piv.position = Vector3(x, 0.5, 0.0)
	rig.add_child(piv)
	Gfx.box(piv, Vector3(0.24, 0.36, 0.26), Vector3(0, -0.18, 0), pants_c)
	if sock_c != null:
		Gfx.box(piv, Vector3(0.25, 0.1, 0.27), Vector3(0, -0.31, 0), sock_c)
	Gfx.box(piv, Vector3(0.27, 0.14, 0.37), Vector3(0, -0.43, 0.05), shoe_c)
	return piv


static func _arm(rig: Node3D, x: float, sleeve_c: Color, cuff_c, hand_c: Color) -> Node3D:
	var piv := Node3D.new()
	piv.position = Vector3(x, 1.08, 0.0)
	rig.add_child(piv)
	var sl := 0.4
	Gfx.box(piv, Vector3(0.2, sl, 0.22), Vector3(0, -sl * 0.5, 0), sleeve_c)
	var y := -sl
	if cuff_c != null:
		Gfx.box(piv, Vector3(0.21, 0.06, 0.23), Vector3(0, y - 0.03, 0), cuff_c)
		y -= 0.06
	Gfx.box(piv, Vector3(0.17, 0.16, 0.19), Vector3(0, y - 0.08, 0), hand_c)
	return piv


static func _base(rig: Node3D, p: Dictionary) -> Dictionary:
	var leg_l := _leg(rig, -0.17, p["leg"], p["shoe"], p.get("sock"))
	var leg_r := _leg(rig, 0.17, p["leg"], p["shoe"], p.get("sock"))
	Gfx.box(rig, Vector3(0.62, 0.62, 0.4), Vector3(0, 0.81, 0), p["torso"])
	var arm_l := _arm(rig, -0.41, p["sleeve"], p.get("cuff"), SKIN)
	var arm_r := _arm(rig, 0.41, p["sleeve"], p.get("cuff"), SKIN)
	_head(rig, p)
	return {"leg_l": leg_l, "leg_r": leg_r, "arm_l": arm_l, "arm_r": arm_r}


static func _head(rig: Node3D, p: Dictionary) -> void:
	var hair: Color = p["hair"]
	var ez: float = p.get("eye_z", 0.4)
	var hat_on: bool = p.get("hat_on", false)
	var style: String = p.get("hair_style", "spiky")

	Gfx.box(rig, Vector3(0.88, 0.78, 0.78), Vector3(0, 1.51, 0), SKIN)
	Gfx.box(rig, Vector3(0.06, 0.16, 0.14), Vector3(-0.45, 1.48, 0), SKIN)
	Gfx.box(rig, Vector3(0.06, 0.16, 0.14), Vector3(0.45, 1.48, 0), SKIN)

	for sx in [-0.2, 0.2]:
		Gfx.box(rig, Vector3(0.11, 0.2, 0.03), Vector3(sx, 1.5, ez), Color(0.12, 0.08, 0.08))
		Gfx.box(rig, Vector3(0.04, 0.05, 0.035), Vector3(sx + 0.02, 1.57, ez + 0.005), Color(1, 1, 1))
		Gfx.box(rig, Vector3(0.12, 0.07, 0.02), Vector3(sx * 1.5, 1.37, 0.395), Color(0.97, 0.62, 0.58))
	Gfx.box(rig, Vector3(0.1, 0.035, 0.02), Vector3(0, 1.33, 0.395), Color(0.65, 0.3, 0.3))

	# tutup kepala (tipis kalau pakai topi supaya tidak menembus)
	if hat_on:
		Gfx.box(rig, Vector3(0.94, 0.18, 0.86), Vector3(0, 1.79, -0.02), hair)
	else:
		Gfx.box(rig, Vector3(0.94, 0.3, 0.86), Vector3(0, 1.86, -0.02), hair)

	match style:
		"long":
			Gfx.box(rig, Vector3(0.94, 0.95, 0.2), Vector3(0, 1.4, -0.44), hair)
			Gfx.box(rig, Vector3(0.08, 0.6, 0.5), Vector3(-0.48, 1.35, -0.05), hair)
			Gfx.box(rig, Vector3(0.08, 0.6, 0.5), Vector3(0.48, 1.35, -0.05), hair)
			Gfx.box(rig, Vector3(0.9, 0.16, 0.1), Vector3(0, 1.67, 0.4), hair)
		"bun":
			Gfx.box(rig, Vector3(0.94, 0.55, 0.2), Vector3(0, 1.62, -0.44), hair)
			Gfx.sphere(rig, 0.22, Vector3(0, 2.1, -0.28), hair)
			Gfx.box(rig, Vector3(0.9, 0.16, 0.1), Vector3(0, 1.67, 0.4), hair)
		_:
			Gfx.box(rig, Vector3(0.94, 0.6, 0.2), Vector3(0, 1.58, -0.44), hair)
			Gfx.box(rig, Vector3(0.07, 0.42, 0.7), Vector3(-0.47, 1.62, -0.05), hair)
			Gfx.box(rig, Vector3(0.07, 0.42, 0.7), Vector3(0.47, 1.62, -0.05), hair)
			Gfx.box(rig, Vector3(0.26, 0.2, 0.1), Vector3(-0.3, 1.66, 0.4), hair)
			Gfx.box(rig, Vector3(0.26, 0.24, 0.1), Vector3(0.0, 1.64, 0.4), hair)
			Gfx.box(rig, Vector3(0.26, 0.2, 0.1), Vector3(0.3, 1.67, 0.4), hair)


# ============================================================
#  Aksesori & pakaian khas tiap jenis
# ============================================================

static func _accessories(rig: Node3D, kind: String, p: Dictionary) -> void:
	match kind:
		"chef":
			var white := Color(0.96, 0.94, 0.95)
			var apron: Color = p["apron"]
			var scarf: Color = p["scarf"]
			# topi koki
			Gfx.cylinder(rig, 0.47, 0.47, 0.18, Vector3(0, 1.99, 0), white.darkened(0.05), 8)
			Gfx.cylinder(rig, 0.6, 0.46, 0.42, Vector3(0, 2.29, 0), white, 8)
			Gfx.sphere(rig, 0.52, Vector3(0, 2.5, 0), white.lightened(0.02), 0.55)
			# kancing jaket
			for by in [0.98, 0.88]:
				for bx in [-0.2, 0.2]:
					Gfx.box(rig, Vector3(0.07, 0.07, 0.03), Vector3(bx, by, 0.205), Color(0.12, 0.1, 0.1))
			# celemek dan tali pinggang
			Gfx.box(rig, Vector3(0.58, 0.5, 0.05), Vector3(0, 0.58, 0.225), apron)
			Gfx.box(rig, Vector3(0.66, 0.07, 0.44), Vector3(0, 0.66, 0), apron.darkened(0.15))
			# syal
			Gfx.box(rig, Vector3(0.5, 0.12, 0.46), Vector3(0, 1.16, 0.0), scarf)
			var knot := Gfx.box(rig, Vector3(0.15, 0.15, 0.06), Vector3(0, 1.06, 0.24), scarf.lightened(0.1))
			knot.rotation_degrees.z = 45.0
			Gfx.box(rig, Vector3(0.1, 0.2, 0.04), Vector3(-0.07, 0.93, 0.235), scarf)
			Gfx.box(rig, Vector3(0.1, 0.2, 0.04), Vector3(0.07, 0.93, 0.235), scarf)
		"customer_f":
			var hat: Color = p["hat"]
			var bag: Color = p["bag"]
			Gfx.cylinder(rig, 0.8, 0.8, 0.05, Vector3(0, 1.95, 0), hat, 12)
			Gfx.cylinder(rig, 0.42, 0.46, 0.28, Vector3(0, 2.1, 0), hat.lightened(0.05), 10)
			Gfx.cylinder(rig, 0.47, 0.47, 0.08, Vector3(0, 2.0, 0), Color(0.45, 0.28, 0.2), 10)
			Gfx.box(rig, Vector3(0.72, 0.4, 0.5), Vector3(0, 0.56, 0), p["skirt"])
			var strap := Gfx.box(rig, Vector3(0.07, 0.8, 0.04), Vector3(0, 0.82, 0.215), bag)
			strap.rotation_degrees.z = 38.0
			Gfx.box(rig, Vector3(0.34, 0.28, 0.14), Vector3(-0.38, 0.48, 0.1), bag)
		"pedestrian":
			var torso: Color = p["torso"]
			var bagc: Color = p["bag"]
			Gfx.box(rig, Vector3(0.7, 0.28, 0.28), Vector3(0, 1.17, -0.27), torso.darkened(0.1))
			Gfx.box(rig, Vector3(0.52, 0.56, 0.24), Vector3(0, 0.84, -0.3), bagc)
			Gfx.box(rig, Vector3(0.06, 0.5, 0.04), Vector3(-0.2, 0.85, 0.21), bagc)
			Gfx.box(rig, Vector3(0.06, 0.5, 0.04), Vector3(0.2, 0.85, 0.21), bagc)
			Gfx.box(rig, Vector3(0.04, 0.2, 0.03), Vector3(-0.08, 1.0, 0.212), Color(0.95, 0.95, 0.95))
			Gfx.box(rig, Vector3(0.04, 0.2, 0.03), Vector3(0.08, 1.0, 0.212), Color(0.95, 0.95, 0.95))
		"mailman":
			var capc: Color = p["cap"]
			Gfx.box(rig, Vector3(0.98, 0.3, 0.9), Vector3(0, 1.97, 0), capc)
			Gfx.box(rig, Vector3(0.7, 0.05, 0.36), Vector3(0, 1.86, 0.56), capc.darkened(0.15))
			Gfx.box(rig, Vector3(0.2, 0.14, 0.03), Vector3(0, 1.99, 0.46), Color(0.95, 0.95, 0.97))
			Gfx.box(rig, Vector3(0.66, 0.5, 0.44), Vector3(0, 0.87, 0), p["vest"])
			var strap2 := Gfx.box(rig, Vector3(0.07, 0.85, 0.04), Vector3(0, 0.85, 0.235), Color(0.4, 0.26, 0.16))
			strap2.rotation_degrees.z = -35.0
			Gfx.box(rig, Vector3(0.42, 0.34, 0.16), Vector3(0.4, 0.5, 0.1), Color(0.45, 0.3, 0.18))
		"police":
			var capp: Color = p["cap"]
			var black := Color(0.08, 0.08, 0.1)
			var gold := Color(0.95, 0.78, 0.2)
			Gfx.box(rig, Vector3(0.98, 0.34, 0.9), Vector3(0, 1.98, 0), capp)
			Gfx.box(rig, Vector3(1.0, 0.1, 0.92), Vector3(0, 1.85, 0), black)
			Gfx.box(rig, Vector3(0.72, 0.05, 0.38), Vector3(0, 1.82, 0.58), black)
			Gfx.box(rig, Vector3(0.17, 0.17, 0.03), Vector3(0, 1.99, 0.46), gold)
			Gfx.box(rig, Vector3(0.1, 0.4, 0.04), Vector3(0, 0.88, 0.205), capp)
			Gfx.box(rig, Vector3(0.66, 0.08, 0.44), Vector3(0, 0.58, 0), black)
			Gfx.box(rig, Vector3(0.1, 0.12, 0.03), Vector3(0.18, 1.0, 0.205), gold)
		"office":
			var suit: Color = p["torso"]
			Gfx.box(rig, Vector3(0.66, 0.62, 0.44), Vector3(0, 0.81, 0), suit)
			Gfx.box(rig, Vector3(0.22, 0.4, 0.04), Vector3(0, 0.95, 0.225), Color(0.97, 0.97, 0.98))
			Gfx.box(rig, Vector3(0.74, 0.42, 0.5), Vector3(0, 0.56, 0), suit.darkened(0.08))
			for sx in [-0.2, 0.2]:
				Gfx.box(rig, Vector3(0.3, 0.26, 0.02), Vector3(sx, 1.5, 0.402), Color(0.1, 0.08, 0.08))
				Gfx.box(rig, Vector3(0.24, 0.2, 0.02), Vector3(sx, 1.5, 0.411), Color(0.96, 0.94, 0.92))
			Gfx.box(rig, Vector3(0.12, 0.03, 0.02), Vector3(0, 1.52, 0.41), Color(0.1, 0.08, 0.08))
			Gfx.box(rig, Vector3(0.42, 0.34, 0.12), Vector3(0.52, 0.3, 0.08), p["case"])
