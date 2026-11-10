extends Node
# Bus sinyal global (autoload). Sistem saling memberi kabar lewat sini
# supaya tidak saling bergantung langsung.

signal shift_started(day: int)
signal shift_ended(day: int)
signal order_created(order: Dictionary)
signal order_completed(order: Dictionary, total: int)
signal order_lost(order: Dictionary)
signal gold_changed(gold: int)
signal stock_changed()
signal staff_changed()
signal controlled_changed(actor)
signal popup_requested(world_pos: Vector3, text: String, color: Color)
signal sale_made(sale: int, tip: int, bonus: int, stars: int)
signal review_added(stars: int)
signal menu_changed()
signal upgrade_bought(id: String, level: int)
signal build_mode_changed(active: bool)
signal build_state_changed()
