extends RefCounted
# Slot isi tangan di bawah layar: kotak-kotak krem berisi ikon item yang
# sedang dibawa staf yang dikendalikan.

const Style = preload("res://scripts/ui/ui_style.gd")
const Inv = preload("res://scripts/player/inventory.gd")

var main = null
var panel: PanelContainer
var box: HBoxContainer
var _sig := "x"


func build(root: Control, p_main) -> void:
	main = p_main
	panel = Style.card()
	box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	root.add_child(panel)
	Style.anchor_bottom_center(panel, 12.0)


func _slot(item) -> Control:
	var p := PanelContainer.new()
	var sb := Style.style(Color(0.96, 0.92, 0.84), 12, 4.0)
	sb.set_border_width_all(2)
	sb.border_color = Style.BORDER
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(62, 66)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	if item != null:
		var parts: PackedStringArray = str(item).split(":")
		var ic: Control
		if parts[0] == "ing":
			ic = Style.ingredient_icon(parts[1], 30.0)
		else:
			ic = Style.drink_icon(parts[1], 32.0)
		var cc := CenterContainer.new()
		cc.add_child(ic)
		v.add_child(cc)
		var nm := Style.label(Inv.item_name(item), 10, Style.SOFT)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		v.add_child(nm)
	return p


func refresh() -> void:
	var c = main.employees.controlled
	var sig := "none"
	if c != null:
		sig = str(c.actor_id) + str(c.carry) + str(Inv.max_carry)
	if sig == _sig:
		return
	_sig = sig
	Style.clear(box)
	for i in range(Inv.max_carry):
		var item = null
		if c != null and i < c.carry.size():
			item = c.carry[i]
		box.add_child(_slot(item))
