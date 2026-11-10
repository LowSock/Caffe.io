extends Node
# Keramaian dan kepuasan pelanggan.
#
# Keramaian (seberapa sering pelanggan datang) di awal sepi, lalu naik seiring:
#   - waktu (hari demi hari),
#   - jumlah menu yang dimiliki,
#   - kenyamanan furnitur (jumlah dan jenis dekorasi),
#   - level upgrade restoran (termasuk Promosi Kafe dan perluasan),
#   - rating restoran.
# Furnitur dan upgrade juga menambah "bonus kepuasan": peluang pelanggan memberi
# bintang 5 makin sering (dipakai RatingManager.rate).

const Data = preload("res://scripts/common/data.gd")

const AMBIENCE_MAX := 28.0     # poin kenyamanan furnitur untuk efek maksimum
const UPGRADE_MAX := 30.0      # total level upgrade untuk efek maksimum

var main = null
var rate := 0.5                # pengali laju kedatangan (1.0 = normal)
var satisfaction := 0.0        # tambahan skor kepuasan (0 sampai sekitar 0.34)
var parts := {}
var _timer := 0.0


func setup(p_main) -> void:
	main = p_main
	recalc()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.5
		recalc()


func recalc() -> void:
	if main == null or main.furniture == null or main.menu == null or main.upgrades == null or main.ratings == null:
		return
	var day := GameManager.day
	var time_f := clampf(0.45 + 0.08 * float(day - 1), 0.45, 1.25)
	var daypart := 0.85 + 0.35 * sin(GameManager.day_progress() * PI)
	var m_count: int = main.menu.unlocked_count()
	var menu_f := minf(1.9, 1.0 + 0.12 * float(m_count - 1))
	var amb := clampf(float(main.furniture.decor_score()) / AMBIENCE_MAX, 0.0, 1.0)
	var furn_f := 1.0 + 0.6 * amb
	var up := clampf(float(main.upgrades.total_levels()) / UPGRADE_MAX, 0.0, 1.0)
	var up_f := 1.0 + 0.5 * up
	var rating_f := 1.0 / maxf(0.1, float(main.ratings.spawn_factor()))
	var promo_f := 1.0 / maxf(0.1, float(main.upgrades.spawn_mult()))
	parts = {
		"Waktu": time_f, "Jam": daypart, "Menu": menu_f, "Furnitur": furn_f,
		"Upgrade": up_f, "Rating": rating_f, "Promosi": promo_f,
	}
	rate = time_f * daypart * menu_f * furn_f * up_f * rating_f * promo_f
	var menu_amb := clampf(float(m_count - 1) / maxf(1.0, float(Data.RECIPES.size() - 1)), 0.0, 1.0)
	satisfaction = 0.18 * amb + 0.12 * up + 0.04 * menu_amb


func next_interval(rng: RandomNumberGenerator) -> float:
	# Jeda sampai pelanggan berikutnya (detik). Makin ramai, makin pendek.
	return clampf(rng.randf_range(6.0, 10.0) / maxf(rate, 0.05), 2.5, 40.0)


func satisfaction_bonus() -> float:
	return satisfaction


func level_text() -> String:
	if rate < 0.7:
		return "Sepi"
	if rate < 1.4:
		return "Biasa"
	if rate < 2.4:
		return "Ramai"
	return "Padat"


func describe() -> String:
	var lines := PackedStringArray()
	lines.append("Keramaian: %s (x%.1f)" % [level_text(), rate])
	var bits := PackedStringArray()
	for k in ["Waktu", "Menu", "Furnitur", "Upgrade", "Rating", "Promosi"]:
		bits.append("%s x%.2f" % [k, float(parts.get(k, 1.0))])
	lines.append("  ".join(bits))
	lines.append("Peluang bintang 5 naik +%d%% dari furnitur, upgrade, dan menu" % roundi(satisfaction * 100.0))
	return "\n".join(lines)
