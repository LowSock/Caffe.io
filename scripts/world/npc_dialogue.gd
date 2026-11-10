extends RefCounted
# Bank kalimat NPC. Tiap situasi punya daftar "any" (umum) dan daftar khusus
# per jenis karakter. {drink} diganti nama minuman pesanannya.
#
# Situasi pelanggan : arrive, wait, impatient, happy, angry
# Situasi jalanan   : street, greet, reply
# Situasi chef      : chef_brew, chef_serve
#
# Tambah kalimat baru tinggal menambah teks di daftar.

const LINES := {
	"arrive": {
		"any": [
			"Permisi, masih buka kan?",
			"Wah, wangi banget dari luar!",
			"Satu {drink}, tolong ya.",
			"Halo! Saya mau pesan {drink}.",
			"Ramai ya hari ini!",
			"Boleh pesan {drink}?",
			"Katanya kafe ini enak, saya mau coba.",
			"Selamat datang... eh, saya yang datang ya. Satu {drink}!",
		],
		"customer_f": [
			"Aku mau {drink} yang dingin ya.",
			"Lucu banget kafenya!",
			"Kak, {drink} satu, jangan terlalu manis ya.",
			"Duh, panas di luar. {drink} dong.",
		],
		"pedestrian": [
			"Bro, {drink} satu dong.",
			"Numpang pesan, lagi buru-buru dikit.",
			"Yang paling seger apa ya? Ya udah, {drink}.",
			"Dari tadi lewat sini, penasaran akhirnya mampir.",
		],
		"mailman": [
			"Paket aman, sekarang waktunya {drink}.",
			"Istirahat dulu ah. {drink} satu!",
			"Kiriman hari ini banyak banget, butuh {drink}.",
			"Permisi, ada {drink}? Saya habis keliling komplek.",
		],
		"police": [
			"Selamat siang. Saya pesan {drink}.",
			"Sedang patroli, mampir sebentar. {drink} ya.",
			"Tenang, saya cuma mau beli {drink}.",
			"Satu {drink}, Bu, Pak. Sambil istirahat sebentar.",
		],
		"office": [
			"Cepat ya, jam istirahat cuma sebentar.",
			"{drink} satu, dibawa balik ke kantor.",
			"Meeting jam dua, saya butuh {drink} sekarang.",
			"Pesan {drink}. Tolong jangan pakai lama ya.",
		],
	},
	"wait": {
		"any": [
			"Hmm, wangi banget di sini...",
			"Lagi ramai ya, nggak apa-apa.",
			"Wah, chef-nya gesit juga.",
			"Sambil nunggu, lihat-lihat dulu ah.",
			"Tadi di jalan macet banget...",
			"Dekorasinya hangat ya, betah.",
			"Semoga {drink}-nya cepat jadi.",
		],
		"customer_f": [
			"Aku kepikiran {drink} dari tadi pagi.",
			"Boleh foto kafenya nggak ya?",
			"Tanamannya cantik-cantik.",
		],
		"pedestrian": [
			"Sambil nunggu cek HP dulu.",
			"Lapar juga jadinya.",
			"Duh, jam segini enaknya ngopi.",
		],
		"mailman": [
			"Tas ini berat banget, hehe.",
			"Rute hari ini jauh juga.",
			"Kaki pegal, semoga {drink}-nya manjur.",
		],
		"police": [
			"Daerah sini aman terkendali.",
			"Kafenya rapi, saya suka.",
			"Lalu lintas lancar hari ini.",
		],
		"office": [
			"Sambil nunggu balas email dulu.",
			"Duh, deadline...",
			"Kapan ya jatah cuti turun...",
		],
	},
	"impatient": {
		"any": [
			"Masih lama ya?",
			"Hmm... sudah agak lama nih.",
			"Permisi, pesanan saya sudah belum?",
			"Aduh, waktu saya mepet...",
			"Kok belum jadi ya...",
		],
		"customer_f": ["Aku udah haus banget nih...", "Kakak, tolong dicek ya pesananku."],
		"pedestrian": ["Bro, lama amat.", "Ayo dong, ayo dong."],
		"mailman": ["Paket lain menunggu nih...", "Waktu istirahat saya hampir habis."],
		"police": ["Saya harus kembali bertugas sebentar lagi.", "Mohon dipercepat ya."],
		"office": ["Meeting saya mulai lima menit lagi!", "Tolong ya, saya buru-buru."],
	},
	"happy": {
		"any": [
			"Mantap, makasih ya!",
			"Enak banget, sukses terus!",
			"Wah, pas banget rasanya!",
			"Besok mampir lagi deh!",
			"Kerja bagus, chef!",
			"Persis seperti yang saya mau.",
		],
		"customer_f": ["Duh, lucu banget gelasnya!", "Aku kasih bintang lima!"],
		"pedestrian": ["Nah, ini baru hidup!", "Mantul, bro."],
		"mailman": ["Pas banget buat lanjut ngantar paket!", "Tenaga terisi penuh!"],
		"police": ["Pelayanan yang baik. Terima kasih.", "Warga dilayani dengan baik, bagus."],
		"office": ["Tepat waktu, saya suka.", "Oke, balik ke kantor dengan semangat!"],
	},
	"neutral": {
		"any": [
			"Lumayan lah. Makasih ya.",
			"Oke, cukup. Terima kasih.",
			"Hmm, biasa aja, tapi boleh.",
			"Terima kasih. Semoga lain kali lebih cepat.",
		],
		"customer_f": ["Enak sih, cuma agak lama ya."],
		"pedestrian": ["Ya udah lah, makasih."],
		"mailman": ["Cukup buat lanjut keliling."],
		"police": ["Cukup memadai. Terima kasih."],
		"office": ["Oke. Lain kali tolong lebih cepat."],
	},
	"unhappy": {
		"any": [
			"Hmm, agak kelamaan tadi.",
			"Rasanya oke, tapi lama banget.",
			"Lain kali lebih cepat ya.",
			"Yah, nunggunya capek.",
		],
		"customer_f": ["Padahal aku udah semangat, kok lama ya..."],
		"pedestrian": ["Parah, lama amat, bro."],
		"mailman": ["Waktu istirahat saya habis buat nunggu."],
		"police": ["Pelayanan perlu diperbaiki."],
		"office": ["Saya terlambat gara-gara menunggu."],
	},
	"angry": {
		"any": [
			"Aku pergi aja deh!",
			"Kelamaan! Cari tempat lain.",
			"Waduh, nggak sabar lagi.",
			"Huh, lain kali deh.",
		],
		"customer_f": ["Yah... padahal tadi semangat."],
		"pedestrian": ["Yaelah, lama amat."],
		"mailman": ["Paket lain menunggu, saya berangkat."],
		"police": ["Maaf, saya harus kembali bertugas."],
		"office": ["Jam istirahat habis. Permisi."],
	},
	"street": {
		"any": [
			"Cuacanya enak ya hari ini.",
			"Eh, ada kafe wangi banget di situ.",
			"Duh, panasnya...",
			"Mau ke mana ya enaknya?",
			"Ramai banget kafenya!",
			"Jalanan hari ini lancar.",
			"Kapan ya gajian...",
			"Roti dari toko itu enak lho.",
			"Besok hujan nggak ya?",
		],
		"customer_f": [
			"Lucu ya toko bunganya.",
			"Mau beli bunga buat di rumah.",
			"Katanya ada diskon di toko buku.",
		],
		"pedestrian": [
			"Lagi nunggu ojol nih.",
			"Capek jalan kaki, tapi sehat.",
			"Dompet tipis, jalan-jalan aja.",
		],
		"mailman": [
			"Satu paket lagi, selesai!",
			"Alamatnya di mana ya...",
			"Permisi, ada kiriman!",
		],
		"police": [
			"Tertib berlalu lintas ya, semuanya.",
			"Hati-hati menyeberang.",
			"Situasi aman terkendali.",
		],
		"office": [
			"Telat meeting nih!",
			"Kopi, kopi, kopi...",
			"Kapan weekend...",
		],
	},
	"greet": {
		"any": [
			"Eh, apa kabar?",
			"Wah, lama nggak ketemu!",
			"Halo, mau ke mana?",
			"Lho, kamu juga lewat sini!",
			"Hei! Sehat?",
		],
	},
	"reply": {
		"any": [
			"Baik! Kamu sendiri?",
			"Lagi jalan-jalan aja nih.",
			"Hehe, iya nih, sibuk terus.",
			"Mampir ke kafe itu yuk!",
			"Alhamdulillah sehat. Duluan ya!",
		],
	},
	"chef_brew": {
		"any": [
			"Siap, meluncur!",
			"Sebentar ya, lagi diseduh~",
			"Resep rahasia, jangan bilang-bilang.",
			"Wangi banget!",
			"Satu, dua, tiga... aduk!",
		],
	},
	"chef_serve": {
		"any": [
			"Pesanan datang!",
			"Silakan, masih hangat!",
			"Satu lagi beres!",
			"Selamat menikmati!",
			"Spesial dari dapur kami!",
		],
	},
}

static var _last := {}
static var _rng := RandomNumberGenerator.new()
static var _inited := false


static func pick(kind: String, situation: String, drink: String = "") -> String:
	if not _inited:
		_rng.randomize()
		_inited = true
	var table: Dictionary = LINES.get(situation, {})
	if table.is_empty():
		return ""
	var specific: Array = table.get(kind, [])
	var generic: Array = table.get("any", [])
	var pool: Array = generic
	if not specific.is_empty() and (generic.is_empty() or _rng.randf() < 0.65):
		pool = specific
	if pool.is_empty():
		return ""
	var key := situation + kind
	var line: String = str(pool[_rng.randi() % pool.size()])
	var tries := 0
	while tries < 4 and pool.size() > 1 and str(_last.get(key, "")) == line:
		line = str(pool[_rng.randi() % pool.size()])
		tries += 1
	_last[key] = line
	return line.replace("{drink}", drink)
