# Paket implementasi desain v2

Desain v2 ("papan skor pinggir lapangan") sudah final dan disetujui host per 2026-10-21. Langkah 1–4 (fondasi,
logika, komponen, painter) sudah diimplementasi; **langkah 5 (layar) berjalan** — lihat daftar di bawah; layar yang
belum masih tata letak lama. Folder ini mengubah hi-fi jadi tugas yang bisa dikerjakan dan dicek secara objektif. Aturan produk: `PRD.md`
(v2, sejalan dengan hi-fi).

| Berkas | Isi | Cara diperbarui |
|---|---|---|
| `../hifi.html` | Hi-fi final: Fondasi, Komponen, 73 frame 390×844 + catatan perilaku, Cakupan. **Sumber kebenaran.** | Edit di repo hanya untuk keputusan host, catat di Cakupan, lalu publish file yang sama ke artifact `H9ZVDUfYvEBXsoBqih4iov` |
| `../frames/<id>.png` | Render tiap frame pada 2x (layar app 780×1688 px, tanpa sudut/bayangan HP) | `python3 tool/hifi_extract.py` |
| `screens/*.md` | Per alur: catatan perilaku tiap frame + komponen yang dipakai | idem (jangan diedit tangan) |
| `components.md` | Per komponen: nama widget, frame pemakai, aturan CSS asli | idem |
| `tokens.json` | Warna, palet court, tema poster, tipografi (Archivo + sumbu), ruang, radius, tinggi | tangan |
| `logic.md` | Aturan logika yang berubah + data test yang sama dengan angka di frame | tangan |

Kalau hi-fi berubah: jalankan `python3 tool/hifi_extract.py` (butuh Google Chrome + internet untuk font), commit
`design/` bersama perubahannya.

## Urutan kerja

1. **Fondasi** — `tokens.json` → `MabarColors`/`MabarTheme` baru; font `assets/fonts/Archivo[wdth,wght].ttf`
   (daftarkan di `pubspec.yaml`, hapus Inter setelah tidak dipakai); ikon Phosphor Bold menggantikan `Icons.*`.
   **Selesai** (2026-10-21): `lib/core/theme/mabar_theme.dart` + `mabar_icons.dart`. Ikon memakai cadangan di hi-fi —
   font Phosphor Bold resmi sebagai `MabarIcons`, karena `phosphor_flutter` gagal dikompilasi di Flutter 3.47.
2. **Logika** — semua butir `logic.md`, test dulu. Data test di sana = angka di frame.
   **Selesai** (2026-10-21) untuk model/service; label round (§8) dan tampilan Bagikan (§9) dikerjakan di layarnya.
   Keputusan host 2026-10-22: turnamen app lama (skor per set) tidak dimuat di v2; format itu dihapus dari kode.
3. **Komponen** — semua widget di `components.md`, masing-masing di `lib/core/widgets/` (atau folder fiturnya kalau
   khusus satu layar), dengan golden minimal satu frame yang memakainya.
   **Selesai** (2026-10-22). Golden per wilayah: `hifiRect` + `hifiStage` +
   `expectRegionMatchesHifi` (contoh di `test/hifi/components/`); posisi elemen di `rects.json`.
4. **Painter lapangan** — satu `CustomPainter` dengan parameter olahraga/transisi `t` (01g) untuk banner Beranda
   dan `tool/generate_app_icon.dart` (ikon opsi A di 01j). Ganti `mabar_brand_mark.dart`.
   **Selesai** (2026-10-22): `lib/core/widgets/court_painter.dart`, `features/home/widgets/court_banner.dart`.
5. **Layar** — satu alur per tugas, urut `screens/01-…` sampai `11-…`.
   Selesai: 01 Beranda, 02 Pemain, 03 Konfigurasi, 04 Pasangan (2026-10-22, `test/hifi/screens/`). Berikutnya 05 Jadwal Fixed.

Langkah 1–4 paling berisiko (logika + terjemahan CSS→Flutter) dan sebaiknya dikerjakan model yang lebih kuat.
Langkah 5 bisa dikerjakan model yang lebih murah karena tinggal merakit komponen jadi dan dicek golden.

## Satu tugas layar

1. Baca `screens/<alur>.md` dan frame PNG-nya. Semua catatan perilaku di sana adalah kriteria selesai.
2. Rakit layar dari komponen yang sudah ada. Kalau butuh ukuran yang tidak ada di komponen, ambil dari aturan CSS
   di `components.md` atau `style="…"` frame itu di `hifi.html` — jangan menebak.
3. Buat golden per frame di `test/hifi/screens/<alur>_test.dart` dengan data yang sama persis dengan frame
   (nama, skor, round, jam). Riverpod: override `tournamentProvider` dengan `ActiveTournament` buatan; teks yang
   bergantung jam (mis. "40m dari 2 jam") harus dari jam yang bisa disuntik. Belum ada: buat satu `clockProvider`
   (`Provider<DateTime Function()>`, default `DateTime.now`) dan pakai di semua tempat yang membaca jam sekarang
   (header Jadwal memakai `DateTime.now()` langsung di `schedule_widgets.dart`, controller saat membuat turnamen).

   ```dart
   testWidgets('06f round berjalan', (tester) async {
     await expectMatchesHifi(tester, buildScreen(fixture06f), '06f');
   });
   ```
4. Iterasi sampai lolos. Gagal → lihat `build/hifi_diff/<id>.png` (merah = beda) dan `<id>_flutter.png`.
5. Selesai kalau: golden semua frame alur lolos, `flutter test` lulus, `flutter analyze` tidak menambah peringatan,
   dan tiap butir catatan perilaku terpenuhi (sebut di pesan commit kalau ada yang ditunda).

## Aturan golden (`test/hifi/hifi_golden.dart`)

- Layar 390×844 pt pada rasio 2, font Archivo dimuat dari file (tanpa itu `flutter test` memakai Ahem).
- Piksel beda kalau salah satu kanal selisih > 32/255; lolos kalau ≤ 2% piksel beda. Toleransi ini menyerap anti-alias
  teks Chrome vs Skia, tapi tidak menyerap pergeseran beberapa pt atau warna yang salah. **Jangan menaikkan toleransi
  untuk meloloskan layar**; kalau memang ada beda yang disengaja, tulis alasannya di test.
- Frame menggambar status bar sebagai ruang kosong: app bar mulai di y = 54 dan action bar menyisakan 34 pt di
  bawah. Di golden pakai `MediaQuery(padding: EdgeInsets.only(top: 47, bottom: 34))`; jadi app bar = 7 pt di bawah
  safe area. Indikator status bar tidak digambar.
- `font-stretch: n%` = `FontVariation('wdth', n)`; `font-weight` cukup lewat `fontWeight` (Flutter meneruskannya ke
  sumbu `wght`, sudah dicek di `hifi_harness_test.dart`). `line-height` CSS = `TextStyle.height`.
- Gambar kecil di frame non-layar (01g, 01j, 11d, 11f, 11g, 11j) adalah lembar pembanding, bukan layar; bandingkan
  posternya lewat widget poster pada ukuran 1:3 bila perlu.

## Yang tidak boleh

- Mengubah `hifi.html` atau frame untuk menyamakan dengan hasil implementasi. Kalau spesifikasi bertentangan atau
  tidak jelas, berhenti dan tanyakan host.
- Menambah perilaku yang tidak ada di catatan frame atau `logic.md`.
- Menyalin nilai dari desain lama (`MabarColors` sekarang, Inter, Material Icons).
