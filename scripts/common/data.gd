extends RefCounted
# Data statis game. Tambah bahan / resep / mesin baru di sini.

# starter = punya peti sejak awal. Bahan lain: peti dibeli di Toko (crate_cost) dan
# datang dengan isi awal crate_stock. pack/cost = paket belanja stok.
const INGREDIENTS := {
	"beans": {"name": "Biji Kopi", "color": Color(0.36, 0.22, 0.12), "start": 0, "pack": 20, "cost": 40, "crate_cost": 120, "crate_stock": 12},
	"milk": {"name": "Susu", "color": Color(0.96, 0.95, 0.9), "start": 24, "pack": 20, "cost": 30, "starter": true},
	"lemon": {"name": "Lemon", "color": Color(0.98, 0.84, 0.2), "start": 0, "pack": 20, "cost": 30, "crate_cost": 100, "crate_stock": 12},
	"coconut": {"name": "Kelapa", "color": Color(0.88, 0.8, 0.66), "start": 0, "pack": 15, "cost": 45, "crate_cost": 160, "crate_stock": 10},
	"tea": {"name": "Daun Teh", "color": Color(0.35, 0.55, 0.25), "start": 20, "pack": 20, "cost": 30, "starter": true},
	"boba": {"name": "Boba", "color": Color(0.2, 0.12, 0.08), "start": 20, "pack": 20, "cost": 35, "starter": true},
}

const MACHINES := {
	"coffee": {"name": "Mesin Kopi", "color": Color(0.82, 0.78, 0.7)},
	"tea": {"name": "Teko Teh", "color": Color(0.55, 0.62, 0.4)},
	"blender": {"name": "Blender", "color": Color(0.7, 0.8, 0.85)},
}

# machine = mesin yang dipakai, time = detik proses, price = harga jual (gold),
# unlock = harga membeli resep di Toko Menu (0 = sudah ada dari awal)
const RECIPES := {
	"boba_tea": {"name": "Boba Milk Tea", "machine": "tea", "ingredients": ["tea", "milk", "boba"], "price": 22, "time": 4.5, "unlock": 0, "color": Color(0.78, 0.6, 0.42)},
	"espresso": {"name": "Espresso", "machine": "coffee", "ingredients": ["beans"], "price": 10, "time": 3.0, "unlock": 150, "color": Color(0.28, 0.16, 0.1)},
	"lemonade": {"name": "Limun", "machine": "blender", "ingredients": ["lemon"], "price": 11, "time": 3.0, "unlock": 180, "color": Color(0.96, 0.9, 0.4)},
	"latte": {"name": "Latte", "machine": "coffee", "ingredients": ["beans", "milk"], "price": 16, "time": 4.0, "unlock": 300, "color": Color(0.86, 0.68, 0.5)},
	"lemon_tea": {"name": "Teh Lemon", "machine": "tea", "ingredients": ["tea", "lemon"], "price": 14, "time": 3.5, "unlock": 350, "color": Color(0.86, 0.46, 0.14)},
	"milk_tea": {"name": "Teh Susu", "machine": "tea", "ingredients": ["tea", "milk"], "price": 15, "time": 3.5, "unlock": 400, "color": Color(0.92, 0.72, 0.5)},
	"coconut_shake": {"name": "Shake Kelapa", "machine": "blender", "ingredients": ["coconut", "milk"], "price": 18, "time": 4.5, "unlock": 650, "color": Color(0.95, 0.93, 0.86)},
}
