extends Control
# Ikon vektor sederhana yang digambar lewat kode (tanpa file gambar).
# Jenis: glass, coin, calendar, clock, star, gear, menu, check, cross, warn,
# hat, ice, receipt, dot, arrow_up, hammer, house, table, sofa, lamp, plant, shelf, rug, crate,
# machine, ing_beans, ing_milk, ing_lemon, ing_coconut, ing_tea

var kind := ""
var color := Color.WHITE
var color2 := Color(0.98, 0.95, 0.88)


func setup(p_kind: String, p_color: Color, p_size: float, p_color2: Color) -> Control:
	kind = p_kind
	color = p_color
	color2 = p_color2
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func _s() -> float:
	return minf(size.x, size.y)


func _p(x: float, y: float) -> Vector2:
	var s := _s()
	return (size - Vector2(s, s)) * 0.5 + Vector2(x, y) * s


func _poly(pts: Array, c: Color) -> void:
	var arr := PackedVector2Array()
	for pt in pts:
		arr.append(_p(pt[0], pt[1]))
	draw_colored_polygon(arr, c)


func _ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var arr := PackedVector2Array()
	for i in range(22):
		var a := TAU * float(i) / 22.0
		arr.append(_p(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(arr, c)


func _line(x1: float, y1: float, x2: float, y2: float, c: Color, w: float) -> void:
	draw_line(_p(x1, y1), _p(x2, y2), c, maxf(1.0, w * _s()))


func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(_p(x, y), Vector2(w, h) * _s()), c)


func _draw() -> void:
	var dark := Color(0.32, 0.2, 0.12)
	match kind:
		"glass":
			_poly([[0.22, 0.22], [0.78, 0.22], [0.70, 0.94], [0.30, 0.94]], color)
			_poly([[0.22, 0.22], [0.78, 0.22], [0.76, 0.38], [0.24, 0.38]], color.lightened(0.35))
			_line(0.58, 0.0, 0.64, 0.3, color2.darkened(0.25), 0.06)
			_rect(0.16, 0.12, 0.68, 0.12, color2)
			var o := PackedVector2Array([_p(0.22, 0.22), _p(0.30, 0.94), _p(0.70, 0.94), _p(0.78, 0.22)])
			draw_polyline(o, Color(0.3, 0.18, 0.1, 0.4), 1.5)
		"coin":
			_ellipse(0.5, 0.5, 0.44, 0.44, Color(0.93, 0.68, 0.12))
			_ellipse(0.5, 0.5, 0.32, 0.32, Color(1.0, 0.86, 0.36))
			_line(0.5, 0.32, 0.5, 0.68, Color(0.8, 0.55, 0.1), 0.07)
		"calendar":
			_rect(0.1, 0.18, 0.8, 0.72, Color(0.99, 0.97, 0.93))
			_rect(0.1, 0.18, 0.8, 0.22, Color(0.85, 0.35, 0.3))
			_rect(0.26, 0.08, 0.1, 0.18, dark)
			_rect(0.64, 0.08, 0.1, 0.18, dark)
			_rect(0.26, 0.52, 0.14, 0.14, Color(0.85, 0.35, 0.3, 0.7))
			_rect(0.6, 0.52, 0.14, 0.14, Color(0.85, 0.35, 0.3, 0.7))
		"clock":
			_ellipse(0.5, 0.5, 0.44, 0.44, dark)
			_ellipse(0.5, 0.5, 0.36, 0.36, Color(0.99, 0.97, 0.93))
			_line(0.5, 0.5, 0.5, 0.26, dark, 0.07)
			_line(0.5, 0.5, 0.68, 0.58, dark, 0.07)
		"star":
			var pts: Array = []
			for i in range(10):
				var r := 0.46
				if i % 2 == 1:
					r = 0.2
				var a := -PI * 0.5 + float(i) * PI / 5.0
				pts.append([0.5 + cos(a) * r, 0.52 + sin(a) * r])
			_poly(pts, Color(1.0, 0.8, 0.2))
		"gear":
			var g: Array = []
			for i in range(8):
				var a0 := float(i) * TAU / 8.0
				g.append([0.5 + cos(a0 - 0.2) * 0.34, 0.5 + sin(a0 - 0.2) * 0.34])
				g.append([0.5 + cos(a0 - 0.1) * 0.46, 0.5 + sin(a0 - 0.1) * 0.46])
				g.append([0.5 + cos(a0 + 0.1) * 0.46, 0.5 + sin(a0 + 0.1) * 0.46])
				g.append([0.5 + cos(a0 + 0.2) * 0.34, 0.5 + sin(a0 + 0.2) * 0.34])
			_poly(g, color)
			_ellipse(0.5, 0.5, 0.17, 0.17, color2)
		"menu":
			_rect(0.2, 0.1, 0.6, 0.8, color)
			_rect(0.26, 0.22, 0.48, 0.07, color2)
			_rect(0.26, 0.42, 0.48, 0.07, color2)
			_rect(0.26, 0.62, 0.34, 0.07, color2)
		"arrow_up":
			_poly([[0.5, 0.08], [0.92, 0.52], [0.66, 0.52], [0.66, 0.92], [0.34, 0.92], [0.34, 0.52], [0.08, 0.52]], color)
		"hammer":
			_line(0.22, 0.88, 0.58, 0.36, Color(0.55, 0.35, 0.2), 0.14)
			_poly([[0.4, 0.14], [0.86, 0.14], [0.86, 0.36], [0.4, 0.36]], color)
		"house":
			_poly([[0.08, 0.5], [0.5, 0.1], [0.92, 0.5]], Color(0.8, 0.35, 0.3))
			_rect(0.2, 0.5, 0.6, 0.4, color)
			_rect(0.43, 0.62, 0.15, 0.28, Color(0.45, 0.3, 0.2))
		"table":
			_ellipse(0.5, 0.38, 0.42, 0.17, color)
			_rect(0.46, 0.4, 0.08, 0.45, color.darkened(0.3))
			_rect(0.3, 0.85, 0.4, 0.06, color.darkened(0.3))
		"sofa":
			_rect(0.14, 0.28, 0.72, 0.3, color.darkened(0.12))
			_rect(0.14, 0.52, 0.72, 0.26, color)
			_rect(0.06, 0.38, 0.16, 0.42, color.darkened(0.2))
			_rect(0.78, 0.38, 0.16, 0.42, color.darkened(0.2))
			_rect(0.18, 0.8, 0.08, 0.1, Color(0.3, 0.2, 0.12))
			_rect(0.74, 0.8, 0.08, 0.1, Color(0.3, 0.2, 0.12))
		"lamp":
			_poly([[0.3, 0.12], [0.7, 0.12], [0.84, 0.46], [0.16, 0.46]], color)
			_rect(0.47, 0.46, 0.06, 0.4, Color(0.3, 0.22, 0.16))
			_rect(0.3, 0.86, 0.4, 0.07, Color(0.3, 0.22, 0.16))
		"plant":
			_poly([[0.3, 0.62], [0.7, 0.62], [0.64, 0.93], [0.36, 0.93]], Color(0.72, 0.4, 0.27))
			_ellipse(0.5, 0.4, 0.28, 0.26, Color(0.3, 0.6, 0.3))
			_ellipse(0.3, 0.5, 0.15, 0.13, Color(0.35, 0.65, 0.35))
			_ellipse(0.7, 0.48, 0.15, 0.13, Color(0.27, 0.55, 0.3))
		"shelf":
			_rect(0.2, 0.08, 0.6, 0.84, Color(0.5, 0.33, 0.2))
			_rect(0.26, 0.14, 0.48, 0.2, Color(0.95, 0.9, 0.8))
			_rect(0.26, 0.4, 0.48, 0.2, Color(0.95, 0.9, 0.8))
			_rect(0.26, 0.66, 0.48, 0.2, Color(0.95, 0.9, 0.8))
			_rect(0.3, 0.18, 0.1, 0.16, Color(0.8, 0.4, 0.35))
			_rect(0.45, 0.44, 0.1, 0.16, Color(0.4, 0.55, 0.75))
			_rect(0.6, 0.7, 0.1, 0.16, Color(0.5, 0.7, 0.45))
		"rug":
			_rect(0.08, 0.28, 0.84, 0.48, color)
			_rect(0.16, 0.36, 0.68, 0.32, color2)
		"crate":
			_rect(0.12, 0.3, 0.76, 0.56, Color(0.58, 0.36, 0.2))
			_rect(0.12, 0.5, 0.76, 0.05, Color(0.4, 0.24, 0.12))
			_rect(0.12, 0.7, 0.76, 0.05, Color(0.4, 0.24, 0.12))
			_ellipse(0.5, 0.28, 0.22, 0.12, color)
		"machine":
			_rect(0.2, 0.18, 0.6, 0.72, color)
			_rect(0.28, 0.3, 0.44, 0.22, Color(0.25, 0.2, 0.18))
			_ellipse(0.5, 0.64, 0.12, 0.12, Color(0.78, 0.78, 0.8))
			_ellipse(0.7, 0.2, 0.06, 0.06, Color(0.95, 0.78, 0.2))
		"check":
			_line(0.2, 0.52, 0.42, 0.74, color, 0.16)
			_line(0.42, 0.74, 0.8, 0.28, color, 0.16)
		"cross":
			_line(0.2, 0.2, 0.8, 0.8, color, 0.14)
			_line(0.8, 0.2, 0.2, 0.8, color, 0.14)
		"warn":
			_ellipse(0.5, 0.5, 0.46, 0.46, color)
			_rect(0.45, 0.2, 0.1, 0.35, color2)
			_ellipse(0.5, 0.72, 0.07, 0.07, color2)
		"dot":
			_ellipse(0.5, 0.5, 0.46, 0.46, color)
			_line(0.28, 0.5, 0.72, 0.5, color2, 0.1)
			_line(0.5, 0.28, 0.5, 0.72, color2, 0.1)
		"hat":
			_ellipse(0.5, 0.36, 0.36, 0.28, Color(0.98, 0.96, 0.97))
			_rect(0.26, 0.5, 0.48, 0.34, Color(0.94, 0.92, 0.93))
			_line(0.26, 0.5, 0.74, 0.5, Color(0.8, 0.78, 0.8), 0.04)
		"ice":
			_poly([[0.18, 0.3], [0.62, 0.18], [0.84, 0.42], [0.82, 0.8], [0.4, 0.88], [0.16, 0.64]], Color(0.7, 0.88, 0.98))
			_poly([[0.18, 0.3], [0.62, 0.18], [0.6, 0.4], [0.34, 0.5]], Color(0.9, 0.97, 1.0))
		"receipt":
			_rect(0.18, 0.08, 0.5, 0.84, Color(0.99, 0.96, 0.88))
			_rect(0.26, 0.24, 0.34, 0.06, Color(0.7, 0.6, 0.5))
			_rect(0.26, 0.4, 0.34, 0.06, Color(0.7, 0.6, 0.5))
			_ellipse(0.66, 0.68, 0.22, 0.22, Color(0.93, 0.68, 0.12))
			_ellipse(0.66, 0.68, 0.15, 0.15, Color(1.0, 0.86, 0.36))
		"ing_beans":
			_ellipse(0.38, 0.56, 0.2, 0.3, color)
			_ellipse(0.64, 0.46, 0.2, 0.3, color.lightened(0.12))
			_line(0.38, 0.34, 0.38, 0.78, color.darkened(0.4), 0.04)
			_line(0.64, 0.24, 0.64, 0.68, color.darkened(0.4), 0.04)
		"ing_boba":
			_ellipse(0.34, 0.64, 0.2, 0.2, color)
			_ellipse(0.66, 0.62, 0.2, 0.2, color.lightened(0.08))
			_ellipse(0.5, 0.36, 0.2, 0.2, color)
			_ellipse(0.28, 0.58, 0.05, 0.05, Color(1, 1, 1, 0.6))
			_ellipse(0.6, 0.56, 0.05, 0.05, Color(1, 1, 1, 0.6))
			_ellipse(0.44, 0.3, 0.05, 0.05, Color(1, 1, 1, 0.6))
		"ing_milk":
			_rect(0.3, 0.3, 0.4, 0.62, color)
			_poly([[0.3, 0.3], [0.5, 0.08], [0.7, 0.3]], Color(0.45, 0.65, 0.9))
			_rect(0.3, 0.5, 0.4, 0.14, Color(0.45, 0.65, 0.9))
			draw_rect(Rect2(_p(0.3, 0.3), Vector2(0.4, 0.62) * _s()), Color(0.4, 0.3, 0.2, 0.35), false, 1.0)
		"ing_lemon":
			_ellipse(0.5, 0.52, 0.42, 0.3, color)
			_poly([[0.88, 0.52], [0.99, 0.44], [0.92, 0.6]], color)
			_ellipse(0.5, 0.52, 0.3, 0.18, color.lightened(0.25))
			_poly([[0.45, 0.2], [0.62, 0.08], [0.6, 0.26]], Color(0.35, 0.65, 0.3))
		"ing_coconut":
			_ellipse(0.5, 0.5, 0.42, 0.42, Color(0.4, 0.26, 0.16))
			_ellipse(0.5, 0.5, 0.3, 0.3, Color(0.98, 0.97, 0.93))
			_ellipse(0.5, 0.5, 0.18, 0.18, Color(0.9, 0.88, 0.82))
		"ing_tea":
			_poly([[0.12, 0.82], [0.26, 0.32], [0.58, 0.1], [0.9, 0.2], [0.82, 0.62], [0.46, 0.9]], color)
			_line(0.2, 0.8, 0.78, 0.26, color.darkened(0.3), 0.04)
		_:
			_ellipse(0.5, 0.5, 0.4, 0.4, color)
