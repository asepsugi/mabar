# Input Skor

> Dihasilkan `tool/hifi_extract.py` dari `design/hifi.html`. Jangan diedit langsung.

Papan skor gelap dengan satu angka besar per tim untuk ketiga format, dan keypad sendiri. Ketuk kotak untuk memilih, ketik angka (maksimal 2 digit), → pindah ke tim lawan. Format dan targetnya ditulis di subjudul sebagai pengingat host.

## 07a · Race to 6 · kosong

![07a](../../frames/07a.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Header: nama court sebagai judul, subjudul round · format. "ROUND 1 · MATCH 1", badge court, ikon olahraga, dan chip metode skor dihapus.
- Race to tidak mengisi otomatis: skor lawan harus diketik karena bisa berapa saja di bawah target.
- WO di kanan atas → sheet 07j.

## 07b · Race to 6 · selesai

![07b](../../frames/07b.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Pemenang ditandai bola di kolom tetap di kiri nama (10 pt), sejajar tengah dengan dua baris nama. Kolom ini ada di kedua tim (kosong kalau belum/tidak menang), jadi dua baris nama selalu rata dan nama tidak bergeser saat bola muncul. Tim yang kalah dipudarkan, seperti baris Jadwal. Nama 20/700.
- Simpan → kembali ke Jadwal tanpa toast.

## 07c · Race to 6 · tie-break

![07c](../../frames/07c.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Untuk komunitas yang memakai aturan set standar (wajib selisih 2, tie-break di 6–6): 7–5 dan 7–6 diterima. Race to murni berhenti di 6–5; keduanya sah tanpa pengaturan tambahan.

## 07d · Race to 6 · belum selesai

![07d](../../frames/07d.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Pesan lain: "Belum ada yang sampai 6" (mis. 5–3), "Skor akhir race to 6: 6–0 sampai 6–5, atau 7–5 / 7–6" (mis. 7–3, 7–4). Angka 8 ke atas tidak bisa diketik sama sekali (07k).
- Yang sah di atas target hanya target + 1 dengan lawan target − 1 atau target (7–5, 7–6). 7–5 tetap sah walau selisihnya 2: di set biasa, dari 5–5 pemenang harus unggul 2 game.
- Satu sisi terisi, sisi lain kosong: Simpan mati tanpa pesan (sedang mengetik).

## 07e · Best of 5

![07e](../../frames/07e.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Isi satu sisi; sisi lain terisi `N − x` dan tampil pudar sebagai tanda otomatis. Mengetik di sisi lawan menimpa nilai otomatis dan mengisi ulang sisi pertama.
- Angka di atas N tidak bisa diketik: tombol 6–9 mati untuk Best of 5.

## 07f · Best of 6 · seri

![07f](../../frames/07f.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Hanya mungkin kalau N genap. Seri dihitung setengah menang di Win %. Americano dengan total genap (mis. 24 → 12–12) berperilaku sama.

## 07g · Americano

![07g](../../frames/07g.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Poin reli dengan total tetap. Isi satu sisi, sisi lain terisi `total − x`. Kalimat "Isi salah satu, skor lawan terisi otomatis" dihapus.

## 07h · Americano · batas total di keypad

![07h](../../frames/07h.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Isi kotak tidak bisa melebihi total (21). Setelah mengetik "2", hanya 0 dan 1 yang masih aktif (20, 21); tombol lain mati. Dulu angka seperti 25 bisa diketik lalu ditolak dengan pesan.
- Sisi lawan langsung terisi total − x, jadi skor selalu sah selama hanya satu sisi diketik; tombol Simpan aktif.
- Kalau sisi lawan diketik manual dan jumlahnya ≠ total: "Total poin harus 21", Simpan mati.

## 07i · Mengubah skor tersimpan

![07i](../../frames/07i.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Skor tersimpan diisi otomatis, belum ada kotak aktif sampai diketuk. Tombol jadi "Perbarui skor".
- Selama belum ada kotak aktif semua angka mati; ketuk salah satu kotak (atau →) untuk mulai mengubah (keputusan host 2026-10-22).
- Match WO dibuka di sini juga: skor lama (kalau ada) terisi; menyimpan skor mengubahnya dari WO jadi selesai.

## 07j · Sheet · walkover

![07j](../../frames/07j.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `MabarGroup / MabarRow`, `MabarChip`, `ScoreBoard / ScoreKeypad`, `showMabarSheet`

- Nilai menang WO ikut format: Race to N → pemenang N game ("…menang WO, dapat 6 game"); Best of N dan Americano → rata-rata game/poin dari match yang dia mainkan sendiri, tapi tidak pernah di bawah skor menang terkecil = ⌊total ÷ 2⌋ + 1 (Americano 21 → 11, Americano 24 → 13, Best of 5 → 3, Best of 6 → 4), supaya "menang" WO tidak bernilai skor kalah seperti yang ditolak di Input Skor ("…dapat poin rata-rata mereka, minimal 11"). Rata-rata dibulatkan ke terdekat; belum pernah main → skor menang terkecil. Yang kalah WO 0. Menang/kalah ikut M–K–S dan Win %; selisih tidak berubah untuk kedua tim. Skor penuh hanya untuk Race to karena di sana pemenang memang selalu dapat N; di Best of dan Americano skor penuh adalah hasil maksimal, jadi menang WO malah lebih untung daripada main.
- Keterangan "Tetap main" di pilihan yang tidak dipilih dihapus. Kalimat "Pilih pasangan yang tidak bisa main…" diganti label pertanyaan.
- Alasan opsional, ketuk lagi untuk melepas (baru: melepas benar-benar menghapus alasan lama). Alasan tampil di baris Jadwal (06g).
- Simpan WO mati sampai satu pasangan dipilih. Membuka WO yang sudah ada: pilihan dan alasan terisi.

## 07k · Race to 6 · batas di keypad

![07k](../../frames/07k.png)

Komponen: `MabarAppBar`, `MabarButton`, `MabarTextButton`, `MabarIconButton`, `ScoreBoard / ScoreKeypad`

- Isi satu kotak paling tinggi target + 1 (7), jadi tombol 8 dan 9 mati. Kalau tidak ada angka lagi yang mungkin (satu digit sudah penuh), kursor pindah sendiri ke kotak lawan yang masih kosong.
- Kotak yang sudah penuh (tidak ada digit lagi yang bisa ditambahkan di belakangnya) menerima ketikan berikutnya sebagai pengganti isinya, begitu juga kotak yang baru dipilih. Jadi yang mati hanya angka di atas batas: Race to 6 berisi "4" → 8 dan 9 mati (07b), Best of 5 berisi "3" → 6–9 mati (07e), Americano 21 berisi "13" → semua aktif (07g); "2" di Americano 21 belum penuh, jadi hanya 0 dan 1 (07h). Keputusan host 2026-10-22.
- Kombinasi baru dicek setelah dua kotak terisi, karena 7 sah atau tidak tergantung lawan (7–5 sah, 7–3 tidak; pesannya di 07d).
- Tombol sengaja tidak dimatikan berdasarkan isi kotak lawan. Contoh: host salah ketik 6–4 padahal 7–5; kalau 7 dimatikan karena lawan masih 4, host harus mengubah kotak lawan dulu baru bisa mengetik 7.
- Race to 9: batasnya 10, jadi setelah "1" hanya 0 yang aktif.
