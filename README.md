# Kafe Hewan - prototipe (Godot 4.7)

Game manajemen kafe minuman 2.5D. Staf dan pelanggan berupa manusia chibi
low-poly. Semua kode asli; semua model masih placeholder buatan kode.

## Cara jalanin
1. Buka Godot 4.7 > Import > pilih `project.godot` di folder ini.
2. Tekan F5.

## Kontrol
Chef (mode kontrol bisa dipilih di Pengaturan: Tap, Analog, atau Keduanya):
- Tap: ketuk lantai untuk jalan, ketuk peti/mesin/meja saji untuk jalan dan berinteraksi.
- Analog: joystick virtual (posisi kiri/kanan dan ukuran bisa diatur) + tombol Aksi di sisi lain layar; tombol Aksi menampilkan nama stasiun terdekat.
- Keyboard: WASD jalan, E / Spasi interaksi dengan stasiun terdekat.
- "Ambil alih" di kartu staf: pindah kontrol ke staf itu (yang tadinya kamu kendalikan jadi AI).

Kamera (bisa diatur sendiri):
- Klik kanan atau klik tengah lalu seret: geser peta. Dua jari geser di layar sentuh juga bisa.
- Roda mouse, tombol + / -, PageUp / PageDown, atau cubit dua jari: zoom.
- Panah: geser kamera. F: kamera mengikuti chef (hidup/mati). R: kembalikan tampilan.
- Tombol kamera juga ada di pojok kanan bawah layar (-, +, Ikuti, Reset).
- Batas geser dan zoom ada di `world/camera_rig.gd` (`BOUNDS_MIN`, `BOUNDS_MAX`, `ZOOM_MIN`, `ZOOM_MAX`).

## Peta folder (scripts/)
```
core/        event_bus | game_manager | save_manager | game_settings (semua autoload)
player/      movement | interaction | inventory | actor (staf chef)
cooking/     recipe_manager | ingredient_system | menu_manager (menu dimiliki/aktif) | cooking_station
restaurant/  customer_manager | order_manager | employee_manager | economy_manager | rating_manager
             upgrade_manager | popularity_manager (keramaian dan kepuasan)
building/    furniture_manager (item, tata letak, validasi) | furniture_catalog (dekorasi)
             placement_system (mode bangun: beli/pasang/pindah/putar/jual)
world/       npc (pejalan kaki) | environment (kafe, jalan, toko, mobil, cahaya) | navigation
             camera_rig (geser/zoom/ikuti kamera)
             + npc_dialogue (bank kalimat) | speech_bubble (balon ucapan)
ui/          hud | touch_controls | virtual_joystick | upgrade_ui | build_ui | menu_shop_ui | shop | inventory_ui | management | menu_ui (Atur Menu) | settings_ui | camera_ui
             ui_style | icon (ikon vektor) | toggle (saklar)
common/      data (resep, bahan, mesin) | gfx | character_factory
main.gd      perakit semua sistem + kamera + input
```

## Antarmuka
HUD bergaya kartu krem: kartu staf dengan tombol "Ambil alih", panel hari/jam/gold/terjual/bonus,
kantong "Masuk ke dompet" tiap penjualan (penjualan, tip, bonus, bintang), peringatan stok yang
bisa dilipat, dan slot isi tangan di bawah. Tombol menu (ikon dokumen) membuka **Atur Menu**:
saklar tiap minuman, tingkat es, pilihan topping, maks. topping, tombol Latihan, tanda stok,
bonus harga, Reset, dan Simpan. Permainan dijeda selama layar ini terbuka.
Efek ke gameplay saat ini: minuman yang dimatikan tidak dipesan pelanggan dan menambah bonus
harga (semua aktif = +10%, tiap minuman yang dimatikan +10%, maks +60%). Tingkat es, topping,
dan mode Latihan baru berupa tampilan/penyimpanan, belum memengaruhi pesanan.
Ikon digambar lewat kode (`ui/icon.gd`), jadi tidak butuh file gambar.

## Tata letak dunia
Utara = atas layar, barat = kiri layar. Kafe punya jendela saji di tembok barat; pelanggan
antre di trotoar barat dan dilayani lewat jendela itu. Jalan raya lebar (dua lajur) ada di
sebelah barat kafe, toko-toko di seberang jalan menghadap ke kafe, dan di utara kafe ada
halaman belakang dengan pagar, pohon, dan rumah-rumah jauh.

Peta sekarang lebih luas: kafe lebih lebar dengan area santai di sisi timur (meja, sofa, rak buku),
jalan raya yang panjang dengan sembilan toko, taman di timur dan selatan, dan halaman belakang.

## Progres: dari sepi sampai ramai
- **Awal sepi:** hari pertama pelanggan jarang datang (sekitar satu tiap 15 sampai 20 detik) dan hanya ada satu menu:
  **Boba Milk Tea** (teh + susu + boba, diseduh di Teko Teh). Peti bahan di awal juga hanya tiga: **boba, susu, teh**.
- **Toko** (tombol struk di kanan atas, atau di panel akhir shift) punya dua tab:
  - **Menu**: beli resep baru (Espresso, Limun, Latte, Teh Lemon, Teh Susu, Shake Kelapa). Menu lebih banyak = lebih
    banyak pilihan pelanggan dan pendapatan naik. Harga resep ada di `unlock` di `common/data.gd`. Kartu menu
    menampilkan "Butuh peti: ..." kalau peti bahannya belum ada.
  - **Peti Bahan**: beli peti Biji Kopi, Lemon, atau Kelapa (harga `crate_cost` di `common/data.gd`). Peti dipasang
    otomatis di titik kosong dengan isi awal; pindahkan lewat Mode Bangun. Pelanggan hanya memesan minuman yang semua
    bahannya sudah punya peti, dan "Belanja stok" serta peringatan stok hanya menampilkan bahan yang punya peti.
- Menu yang sudah dimiliki bisa dimatikan di Atur Menu.
- **Keramaian** (stat "Ramai" di panel kanan atas, rinciannya di ringkasan akhir shift): naik seiring waktu
  (hari demi hari), jumlah menu, kenyamanan furnitur, level upgrade, Promosi Kafe, dan rating. Tingkatnya:
  Sepi, Biasa, Ramai, Padat. Rumusnya di `restaurant/popularity_manager.gd`.
- **Kepuasan:** furnitur (tiap dekorasi punya nilai "Nyaman" di katalog), upgrade, dan jumlah menu menambah peluang
  pelanggan memberi bintang 5, jadi rating naik kalau kafe lengkap dan nyaman.

## Mode Bangun (tata letak dan dekorasi)
Tombol palu di kanan atas (atau tombol di panel akhir shift) membuka **Mode Bangun**; permainan dijeda.
- Ketuk perabot untuk memilih: **Pindah**, **Putar**, **Jual** (dekorasi dijual separuh harga), atau Tutup.
  Peti bahan dan mesin bisa dipindah dan diputar tapi tidak dijual; meja saji tetap di jendela.
- Pilih dari katalog di bawah (meja bulat/kotak, sofa, meja kopi, rak buku, lampu lantai, tanaman, karpet)
  lalu seret atau ketuk lantai untuk menaruh. Hijau = muat, merah = tidak muat. **Putar** memutar 90 derajat,
  **Taruh** membeli dan memasang, **Batal** membatalkan.
- Perabot tidak boleh keluar dari kafe, bertabrakan dengan perabot lain (karpet boleh di bawah perabot),
  atau menutupi depan jendela saji dan pintu staf.
- Kamera tetap bisa digeser dan di-zoom saat mode bangun. Tata letak tersimpan otomatis saat keluar.
- Upgrade **Perluas Kafe** (3 level) memperbesar lantai ke timur dan selatan, lengkap dengan tembok, jendela,
  dan taman yang ikut bergeser. Ukuran tiap level ada di `EXPANSIONS` di `world/navigation.gd`.
- Nama bahan, stok, dan status mesin tidak lagi tampil terus: hanya label stasiun **terdekat** dengan chef yang
  muncul (jarak di `REVEAL_DIST` di `cooking/cooking_station.gd`), jadi label tetangga tidak menumpuk. Di mode
  bangun, label muncul untuk perabot yang dipilih. Tiap peti punya pelat warna di depan dan isi yang khas
  (boba = tumpukan mutiara gelap, lemon = lemon kuning dengan daun) supaya mudah dibedakan.
  Lampu status di mesin (abu, kuning, hijau) tetap terlihat dari jauh.

## Upgrade restoran
Tombol panah hijau di kanan atas (dan tombol di panel akhir shift) membuka layar **Upgrade Restoran**.
Tiap upgrade punya level (maks 5; "Nampan Besar" maks 2; "Perluas Kafe" maks 3), harga naik tiap level, dan efek yang
langsung terasa:
- Perluas Kafe: lantai makin luas (lihat Mode Bangun)
- Sepatu Lari Chef: staf berjalan lebih cepat (+8% per level)
- Nampan Besar: kapasitas tangan 4 menjadi 5 lalu 6 item
- Mesin Kopi Pro, Teko Teh Cepat, Blender Turbo: waktu seduh -12% per level (mesin level 3 ke atas berhias emas)
- Kursi Antre Nyaman: pelanggan lebih sabar (+8% per level)
- Resep Premium: harga jual naik (+6% per level)
- Kontrak Supplier: harga stok turun (-7% per level)
- Promosi Kafe: pelanggan lebih sering datang (-7% jeda kedatangan per level)
Semua data ada di `DEFS` di `restaurant/upgrade_manager.gd`; level tersimpan bersama progres.

## Rating restoran
Tiap pelanggan yang selesai dilayani memberi 1 sampai 5 bintang menurut seberapa lama ia menunggu
(cepat = tinggi, lama = rendah, dengan sedikit acak); pelanggan yang pergi karena kesal memberi 1 bintang.
Rating harian = rata-rata ulasan hari itu (tampil di panel kanan atas dan di ringkasan akhir shift beserta
sebaran bintangnya). Rating restoran = rata-rata ulasan 7 hari terakhir; makin tinggi, makin sering pelanggan
datang. Dialog pelanggan saat pergi menyesuaikan bintangnya. Pengaturan ada di `restaurant/rating_manager.gd`.

## Atmosfer cozy
Cahaya hangat dan redup yang berubah sepanjang hari (pagi peach, siang hangat, sore oranye),
lampu hias, lampu meja, jam dinding yang jarumnya ikut waktu game, kotak bunga di jendela,
dan tepi layar yang sedikit digelapkan (vinyet). Pengaturannya di `world/environment.gd`.

## Alur main
Pelanggan datang dari jalan, antre di trotoar depan jendela saji, lalu memesan. Ambil bahan
dari peti (maks 4 item), olah di mesin yang cocok, ambil minumannya, dan antar ke meja
saji. Makin cepat, makin besar tip dan bintang. Jam 17:00 shift selesai: belanja stok,
rekrut staf, lalu hari berikutnya. Progres tersimpan otomatis (`user://kafe_save.json`).

## Yang gampang diubah
- `common/data.gd`: bahan, mesin, resep, harga, waktu proses
- `world/npc_dialogue.gd`: semua kalimat NPC (tinggal tambah teks di daftar)
- `world/camera_rig.gd`: posisi awal kamera (`DEFAULT_FOCUS`, `DEFAULT_ZOOM`). `world/environment.gd`: cahaya, toko, mobil, trotoar
- `world/navigation.gd`: batas area staf, titik antrean, jalur pejalan kaki
- `ui/ui_style.gd`: warna tema HUD
- Kalau berat di HP: set `USE_SHADOWS := false` di `world/environment.gd`

## Ganti karakter dengan model 3D sendiri
Taruh file `.glb` di `models/` dengan nama `chef.glb`, `customer_f.glb`, `pedestrian.glb`,
`mailman.glb`, `police.glb`, `office.glb`. Kalau ada, otomatis dipakai menggantikan model
buatan kode (animasi jalan buatan kode tidak berlaku untuk model luar).
