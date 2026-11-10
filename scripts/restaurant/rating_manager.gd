extends Node
# Rating restoran dari ulasan pelanggan. Tiap pelanggan yang selesai dilayani
# memberi 1 sampai 5 bintang menurut seberapa lama ia menunggu (puas = tinggi,
# tidak puas = rendah); pelanggan yang pergi karena kesal memberi 1 bintang.
# Rating harian adalah rata-rata ulasan hari itu. Rating restoran adalah rata-rata
# ulasan dalam beberapa hari terakhir dan memengaruhi seberapa ramai pelanggan datang.

const KEEP_DAYS := 7

var main = null
var today: Array = []            # bintang (int 1..5) hari ini
var history: Array = []          # ringkasan hari-hari lalu: {day, count, sum, dist}
var last_summary := {}           # ringkasan hari yang baru selesai (untuk panel akhir shift)
var _rng := RandomNumberGenerator.new()


func setup(p_main) -> void:
	main = p_main
	_rng.randomize()
	EventBus.shift_started.connect(_on_shift_started)
	EventBus.shift_ended.connect(_on_shift_ended)


func rate(ratio: float) -> int:
	# ratio = sisa kesabaran pelanggan saat dilayani (0..1). Ada sedikit acak
	# supaya tiap pelanggan punya selera sendiri.
	var score := ratio + _rng.randf_range(-0.07, 0.07) + float(main.popularity.satisfaction_bonus())
	if score >= 0.72:
		return 5
	if score >= 0.5:
		return 4
	if score >= 0.3:
		return 3
	if score >= 0.12:
		return 2
	return 1


func add_review(stars: int) -> void:
	var s := clampi(stars, 1, 5)
	today.append(s)
	EventBus.review_added.emit(s)


func today_count() -> int:
	return today.size()


func today_avg() -> float:
	if today.is_empty():
		return 0.0
	var sum := 0
	for s in today:
		sum += int(s)
	return float(sum) / float(today.size())


func distribution(list: Array = []) -> Array:
	# Jumlah ulasan untuk 1..5 bintang (indeks 0 = 1 bintang). Tanpa argumen = hari ini.
	var src: Array = list
	if list.is_empty():
		src = today
	var d := [0, 0, 0, 0, 0]
	for s in src:
		var i := clampi(int(s), 1, 5) - 1
		d[i] = int(d[i]) + 1
	return d


func overall() -> float:
	# Rata-rata ulasan dalam KEEP_DAYS hari terakhir (termasuk hari ini). 0 = belum ada ulasan.
	var sum := 0
	var count := 0
	var start := maxi(0, history.size() - (KEEP_DAYS - 1))
	for i in range(start, history.size()):
		sum += int(history[i]["sum"])
		count += int(history[i]["count"])
	for s in today:
		sum += int(s)
		count += 1
	if count == 0:
		return 0.0
	return float(sum) / float(count)


func spawn_factor() -> float:
	# Rating tinggi = pelanggan lebih sering datang (faktor kecil = jarak datang lebih pendek).
	var o := overall()
	if o <= 0.0:
		return 1.0
	return lerpf(1.25, 0.8, clampf((o - 1.0) / 4.0, 0.0, 1.0))


func _on_shift_started(_day: int) -> void:
	today.clear()


func _on_shift_ended(day: int) -> void:
	var sum := 0
	for s in today:
		sum += int(s)
	var summary := {
		"day": day,
		"count": today.size(),
		"sum": sum,
		"avg": today_avg(),
		"dist": distribution(),
	}
	last_summary = summary
	if today.size() > 0:
		history.append({"day": day, "count": today.size(), "sum": sum, "dist": distribution()})
		while history.size() > 30:
			history.pop_front()


func to_dict() -> Dictionary:
	return {"history": history.duplicate(true)}


func from_dict(d) -> void:
	history.clear()
	if typeof(d) != TYPE_DICTIONARY:
		return
	var src: Dictionary = d
	var h = src.get("history", [])
	if typeof(h) != TYPE_ARRAY:
		return
	for e in h:
		if typeof(e) == TYPE_DICTIONARY and e.has("count") and e.has("sum"):
			var dist = e.get("dist", [0, 0, 0, 0, 0])
			history.append({"day": int(e.get("day", 0)), "count": int(e["count"]), "sum": int(e["sum"]), "dist": dist})
