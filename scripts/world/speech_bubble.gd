extends Node3D
# Balon ucapan di atas kepala karakter. Panggil say("teks", detik).

var _border: MeshInstance3D
var _fill: MeshInstance3D
var _label: Label3D
var _border_mat: StandardMaterial3D
var _fill_mat: StandardMaterial3D
var _tw: Tween = null


func _init() -> void:
	visible = false
	_border_mat = _bubble_mat(Color(0.35, 0.22, 0.12, 0.95), 1)
	_fill_mat = _bubble_mat(Color(1.0, 0.98, 0.92, 0.95), 2)

	_border = MeshInstance3D.new()
	_border.mesh = QuadMesh.new()
	_border.material_override = _border_mat
	_border.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_border)

	_fill = MeshInstance3D.new()
	_fill.mesh = QuadMesh.new()
	_fill.material_override = _fill_mat
	_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fill)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.pixel_size = 0.008
	_label.font_size = 30
	_label.outline_size = 0
	_label.render_priority = 3
	_label.modulate = Color(0.25, 0.15, 0.1, 1.0)
	add_child(_label)


func _bubble_mat(c: Color, prio: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = true
	m.render_priority = prio
	m.albedo_color = c
	return m


static func wrap_text(text: String, max_chars: int) -> String:
	var words := text.split(" ")
	var lines := PackedStringArray()
	var cur := ""
	for w in words:
		if cur == "":
			cur = w
		elif cur.length() + 1 + w.length() <= max_chars:
			cur += " " + w
		else:
			lines.append(cur)
			cur = w
	if cur != "":
		lines.append(cur)
	return "\n".join(lines)


func say(text: String, duration: float = 3.0) -> void:
	if text == "":
		return
	var wrapped := wrap_text(text, 20)
	var lines := wrapped.split("\n")
	var maxlen := 0
	for ln in lines:
		maxlen = maxi(maxlen, ln.length())
	var w := maxlen * 0.125 + 0.4
	var h := lines.size() * 0.31 + 0.25

	var fm: QuadMesh = _fill.mesh
	fm.size = Vector2(w, h)
	var bm: QuadMesh = _border.mesh
	bm.size = Vector2(w + 0.1, h + 0.1)
	_fill.position.y = h * 0.5
	_border.position.y = h * 0.5
	_label.position.y = h * 0.5
	_label.text = wrapped

	_border_mat.albedo_color = Color(0.35, 0.22, 0.12, 0.95)
	_fill_mat.albedo_color = Color(1.0, 0.98, 0.92, 0.95)
	_label.modulate = Color(0.25, 0.15, 0.1, 1.0)
	visible = true

	if _tw != null:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_interval(duration)
	_tw.tween_property(_fill_mat, "albedo_color:a", 0.0, 0.4)
	_tw.parallel().tween_property(_border_mat, "albedo_color:a", 0.0, 0.4)
	_tw.parallel().tween_property(_label, "modulate:a", 0.0, 0.4)
	_tw.tween_callback(_hide_bubble)


func _hide_bubble() -> void:
	visible = false
