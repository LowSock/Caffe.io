extends Node
# Status global permainan (autoload): hari, jam, dan shift.

const DAY_START := 8 * 60      # 08:00
const DAY_END := 17 * 60       # 17:00
const GAME_MIN_PER_SEC := 2.0  # 1 detik asli = 2 menit di game

var day := 1
var game_min := float(DAY_START)
var shift_active := false


func start_shift() -> void:
	game_min = float(DAY_START)
	shift_active = true
	EventBus.shift_started.emit(day)


func end_shift() -> void:
	if not shift_active:
		return
	shift_active = false
	EventBus.shift_ended.emit(day)


func next_day() -> void:
	day += 1
	start_shift()


func tick(delta: float) -> void:
	if not shift_active:
		return
	game_min += delta * GAME_MIN_PER_SEC
	if game_min >= DAY_END:
		end_shift()


func day_progress() -> float:
	# 0.0 saat buka, 1.0 saat tutup
	return clampf((game_min - DAY_START) / float(DAY_END - DAY_START), 0.0, 1.0)
