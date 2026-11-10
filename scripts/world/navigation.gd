extends RefCounted
# Batas area jalan, ukuran kafe menurut level perluasan, titik antrean pelanggan,
# zona terlarang untuk perabot, dan jalur trotoar.
# Tata letak: jalan raya di sisi BARAT kafe. Pelanggan antre di trotoar dan
# dilayani lewat jendela saji di tembok barat. Kafe bisa diperluas ke timur dan selatan.

# Ukuran kafe tiap level perluasan: (x_maks, z_maks). x_min dan z_min tetap.
const EXPANSIONS := [Vector2(5.65, 7.0), Vector2(9.0, 9.0), Vector2(12.0, 11.0), Vector2(15.0, 13.0)]
const CAFE_X_MIN := -8.25
const CAFE_Z_MIN := -5.65

# Area jalan staf (batas timur dan selatan ikut level perluasan)
const MIN_X := -6.2
const MIN_Z := -3.4

# Zona yang tidak boleh diisi perabot: depan jendela saji dan pintu staf (x, z, lebar, dalam)
const RESERVED := [Rect2(-8.25, -3.6, 3.0, 6.4), Rect2(-8.25, 3.5, 2.2, 2.2)]

static var expansion := 0
static var cafe_x_max := 5.65
static var cafe_z_max := 7.0
static var max_x := 4.65
static var max_z := 5.4

# Antrean pelanggan di trotoar dekat jendela saji
const QUEUE_X := -9.1
const QUEUE_OUTER_X := -9.95
const ARRIVE_POINT := Vector3(-9.95, 0.0, -12.0)
const LEAVE_POINT := Vector3(-9.95, 0.0, 14.0)

# Jalur pejalan kaki (berjalan sepanjang sumbu Z)
const SIDEWALK_NEAR_X := -10.4
const SIDEWALK_FAR_X := -16.7
const STREET_MIN_Z := -24.0
const STREET_MAX_Z := 20.0


static func set_expansion(level: int) -> void:
	expansion = clampi(level, 0, EXPANSIONS.size() - 1)
	var e: Vector2 = EXPANSIONS[expansion]
	cafe_x_max = e.x
	cafe_z_max = e.y
	max_x = e.x - 1.0
	max_z = e.y - 1.6


static func footprint_text(level: int) -> String:
	var e: Vector2 = EXPANSIONS[clampi(level, 0, EXPANSIONS.size() - 1)]
	return "%d x %d" % [roundi(e.x - CAFE_X_MIN), roundi(e.y - CAFE_Z_MIN)]


static func clamp_to_room(v: Vector3) -> Vector3:
	return Vector3(clampf(v.x, MIN_X, max_x), 0.0, clampf(v.z, MIN_Z, max_z))


static func customer_slot(slot: int) -> Vector3:
	return Vector3(QUEUE_X, 0.0, -2.6 + slot * 1.1)
