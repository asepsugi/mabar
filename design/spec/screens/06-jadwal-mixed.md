# Jadwal Mixed

> Dihasilkan `tool/hifi_extract.py` dari `design/hifi.html`. Jangan diedit langsung.

Round dibuat satu per satu. Contoh: Padel, Americano 21, 10 pemain, 2 court, jadi tiap round dua orang istirahat. Kotak kuning "R… dibuat setelah skor R… lengkap" dihapus; alasannya ada di tombol.

## 06f · Round berjalan

![06f](../../frames/06f.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarActionBar`, `MabarGroup / MabarRow`, `MabarGroupHeader`, `RoundTabs`, `MatchScoreRow`, `RestingList`

- Tab default = round terakhir; kembali ke round terakhir setelah Buat/Batalkan. Titik bola di round terakhir selama belum lengkap. Placeholder "R4 ?" dihapus.
- Badge LIVE dihapus. Istirahat: label lalu nama lengkap dalam dua kolom rata (banyak nama: 06o); judulnya "Istirahat · Prioritas main di R4" (bagian prioritas biru court), hanya saat melihat round terakhir. Nama seukuran judul (13). Kalau tidak semua kebagian slot R4, daftar dibagi dua (06o).
- Round terakhir: daftar dihitung dari pemain aktif sekarang (yang keluar tidak tampil, yang baru ditambahkan langsung masuk). Round yang sudah lewat: catatan saat round itu dibuat (06n).
- Action bar: Peringkat (ikon), Pemain (ikon + jumlah aktif → sheet 08a), Buat R4. Tombol akhiri pindah ke menu ⋯.

## 06g · Round lengkap · siap buat berikutnya

![06g](../../frames/06g.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarActionBar`, `MabarGroup / MabarRow`, `MabarGroupHeader`, `RoundTabs`, `MatchScoreRow`, `RestingList`

- Aktif kalau round terakhir lengkap (selesai atau WO) dan masih ada court dengan waktu. Kalau court berkurang di round berikutnya: "Buat R4 · 1 court" (menggantikan "Sisa waktu booking: 1 dari 2 court").
- WO: pasangan yang kalah ditandai "WO" plus alasannya kalau diisi. Baru: alasan WO sekarang tampil (dulu disimpan tapi tidak pernah terlihat).
- Kalimat "Pemain yang istirahat diprioritaskan…" dihapus; baris Istirahat sudah menyatakannya.

## 06h · Round baru · masih bisa dibatalkan

![06h](../../frames/06h.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarActionBar`, `MabarGroup / MabarRow`, `MabarGroupHeader`, `RoundTabs`, `MatchScoreRow`, `RestingList`

- "Batalkan R4" tampil kalau R4 belum ada skor sama sekali, turnamen belum diakhiri, dan bukan R1 (R1 tidak bisa dibatalkan). Hanya di tab round terakhir, dan hanya di sini (tidak di menu ⋯). Di tab lain tombol ini bisa terbaca membatalkan round yang sedang dilihat.
- Dipakai saat ada pemain baru datang: batalkan, tambah lewat Kelola pemain, lalu Buat R4 lagi. Tidak dibuat ulang otomatis.
- Semua label round di layar ini dinamis dari n = `roundCount`: "Batalkan R*n*", "Buat R*n+1*", "Prioritas main di R*n+1*". Daftar lengkapnya di tabel Label round (Fondasi).

## 06i · Menu ⋯ · Mixed

![06i](../../frames/06i.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarActionBar`, `RoundTabs`, `MatchScoreRow`, `MabarMenu`

- Isi menu Mixed: "Cara kerja Mixed" → sheet 06k dan "Akhiri turnamen" → dialog 06e.
- "Batalkan Rn" sengaja tidak ada di menu: syaratnya sama persis dengan tombol di layar (06h), jadi item menu tidak pernah menolong saat tombolnya tidak ada. Satu aksi, satu tempat.

## 06j · Dialog · batalkan round

![06j](../../frames/06j.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `MabarActionBar`, `RoundTabs`, `MatchScoreRow`, `showMabarSheet`, `showMabarConfirm`

- Setelah dibatalkan, layar pindah ke R3. Kredit pemain yang tidak ada di R4 dihitung ulang dari riwayat tanpa R4.
- Judul, isi ("tekan Buat R*n* lagi"), dan tombol memakai n yang sama: setelah dibatalkan, tombol bawah memang kembali jadi "Buat R*n*".

## 06k · Sheet · cara kerja Mixed

![06k](../../frames/06k.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarGroup / MabarRow`, `RoundTabs`, `showMabarSheet`

- Pengganti layar 05 "Cara Kerja Mixed". Teks Aturan Fairness dan label Estimasi tetap sesuai permintaan host.
- Baru: muncul otomatis sekali saat R1 pertama kali dibuat, setelah itu lewat menu ⋯.
- Rumus tetap: Max Round = booking terpendek ÷ durasi; Match/Pemain = ⌊total match × 4 ÷ pemain⌋; Total Match = Max Round × court.

## 06l · Waktu booking habis

![06l](../../frames/06l.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarActionBar`, `MabarGroup / MabarRow`, `MabarGroupHeader`, `RoundTabs`, `MatchScoreRow`, `RestingList`

- `canResume` tanpa "Akhiri": semua court sudah tidak muat round berikutnya. "Buat R9" diganti "Tambah jam" → sheet 08c.
- Begitu round terakhir di sini lengkap, Peringkat dan Bagikan menyebutnya Final / "Peringkat akhir" (09f), tanpa perlu Akhiri.
- Baru: tab menulis "Waktu habis" (clay). Kotak kuning lama yang tetap menulis "0 dari 2 court" tidak muncul lagi.
- 8 tab tidak muat: baris tab digeser sampai round terakhir rapat di kanan, dan tab yang terpotong di kiri dipudarkan sebagai tanda masih ada round sebelumnya. Interaksi lengkapnya di 06n.

## 06m · Diakhiri · bisa dilanjutkan

![06m](../../frames/06m.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarActionBar`, `MabarGroup / MabarRow`, `MabarGroupHeader`, `RoundTabs`, `MatchScoreRow`, `RestingList`

- Mixed yang sudah diakhiri bisa dilanjutkan: "Lanjutkan turnamen" → sheet 08c. Match "Tidak dimainkan" kembali bisa diisi setelah dilanjutkan.
- Tombol Pemain disembunyikan setelah diakhiri. Menu ⋯ hanya berisi "Cara kerja Mixed".
- Kalimat "Turnamen sudah diakhiri · tambah jam court untuk main lagi" diringkas ke subjudul "diakhiri".

## 06n · Banyak round · melihat round awal

![06n](../../frames/06n.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarActionBar`, `MabarGroup / MabarRow`, `MabarGroupHeader`, `RoundTabs`, `MatchScoreRow`, `RestingList`

- Tab muat ±6 dengan label kanan. Mixed bisa lebih dari 20 round (booking panjang, durasi pendek), Fixed sampai 45 round (10 pasangan, 1 court), jadi baris tab harus bisa digeser.
- Hanya baris tab yang digeser horizontal dengan jari; label kanan ("2/2 match", "Waktu habis") tetap di tempat. Kalau semua tab muat, tidak ada fade dan baris tidak bisa digeser.
- Tepi yang menyembunyikan tab dipudarkan 36 pt: kiri (06l), kanan (frame ini), atau keduanya saat di tengah. Tab yang terpotong di tepi adalah tanda utama bahwa masih ada round di baliknya.
- Saat layar dibuka, setelah Buat R*n*, dan setelah Batalkan R*n*, tab terpilih otomatis digeser masuk tampilan (round terakhir rapat kanan). Mengetuk tab yang terpotong menggesernya sampai utuh.
- Ganti round hanya lewat tab; daftar match tidak bisa digeser kiri-kanan, supaya geser tak sengaja saat mengisi skor tidak memindahkan round.
- Round yang sudah lewat menampilkan siapa yang benar-benar istirahat di round itu: catatan saat round dibuat (`restingPlayerIdsByRound`), tidak berubah oleh tambah atau keluar pemain sesudahnya. Pemain yang kemudian keluar tetap tampil tanpa penanda, sama seperti di Peringkat.
- Di round lewat tidak ada "Prioritas main di R…", daftar kedua, maupun "Batalkan R…"; semuanya hanya untuk round terakhir. Tombol bawah tetap untuk round berikutnya (Buat R13).
- Flutter: komponen `RoundTabs` (baris tab yang digeser + `ShaderMask` di tepi); tidak pakai `TabBarView`.

## 06o · Banyak yang istirahat · 20 pemain, 2 court

![06o](../../frames/06o.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarIconButton`, `MabarActionBar`, `MabarGroup / MabarRow`, `MabarGroupHeader`, `RoundTabs`, `MatchScoreRow`, `RestingList`

- Kondisi terpadat Mixed: 20 pemain aktif. Dengan 2 court, 12 istirahat (6 baris); dengan 1 court 16 istirahat (8 baris) tapi hanya 1 match, jadi isi layar tetap muat. Makin banyak court, makin sedikit yang istirahat.
- Nama dalam dua kolom rata, urut seperti daftar pemain, terpotong elipsis kalau panjang; sama dengan daftar di layar Pemain dan Pasangan, bukan kalimat yang membungkus tidak rata.
- Yang istirahat lebih banyak dari slot round berikutnya (12 orang, R4 hanya 8 slot = 4 × court), jadi daftarnya dibagi dua: yang pasti main di R4 di bawah judul "Istirahat · Prioritas main di R4" (bagian prioritas biru court), dan sisanya di daftar kedua "Istirahat lagi di R4" yang lebih pudar. Kalau semua yang istirahat kebagian slot, hanya daftar pertama yang tampil (06f–06h).
- Isi kedua daftar dihitung dengan urutan yang sama persis dengan generator: jumlah main (termasuk kredit), lalu yang paling lama istirahat. Pemain yang seri diundi dengan undian yang dikunci per round (seed turnamen + nomor round), bukan diacak saat "Buat R4" ditekan. Jadi hasil Buat R4 selalu sama dengan daftar ini.
- Daftar dihitung ulang langsung kalau host menambah/mengeluarkan pemain (sheet 08a) atau jumlah court yang masih punya waktu berubah. Pemain yang baru ditambahkan langsung masuk salah satu daftar; yang keluar hilang dari keduanya.
