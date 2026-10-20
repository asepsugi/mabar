# Mabar — konteks proyek

App Flutter untuk host turnamen mabar tennis/padel (klub, 4–20 pemain, 1 device host, offline).

**Sumber kebenaran, baca sebelum mengubah UI/logika:**
- `PRD.md` — produk, algoritma, aturan skor & ranking.
- `hifi.html` — mockup hi-fi 11 layar + seluruh CSS design system. Ini acuan visual final.
- `design-tokens.json` — token yang sudah dikonversi ke `lib/core/theme/mabar_theme.dart`.

## Cara membaca hifi.html

File 326KB berisi base64 besar dan HTML yang sering dipangkas tool. Yang terbukti jalan:

```bash
sed -n 'AWAL,AKHIRp' hifi.html | sed -E 's/base64,[A-Za-z0-9+/=]{20,}/base64,IMG/g' | tr '<>' '[]'
```

`tr '<>' '[]'` wajib — tanpa itu markup-nya dibuang. **Jangan strip tag `<svg>`**: ikon (mis. piala di judul "Peringkat") ada di dalamnya dan pernah hilang gara-gara itu.

Baris per layar: 01 Home 1186, 02 Peserta 1251, 03 Konfigurasi 1317, 04 Pasangan 1410, 05 Mixed Confirm 1475, 06a Jadwal Fixed 1534, 06b Jadwal Mixed 1634, 07 Input Skor 1738, 07b WO 1801, 08 Leaderboard 1894, 09 Detail 1997, 10 Share 2100. CSS di baris 1–1185.

## Arsitektur

- `lib/models/models.dart` — seluruh model domain, immutable. Termasuk `ActiveTournament`
  (turnamen + bye/resting per round); dia ada di sini, bukan di controller, supaya
  `services/storage/` bisa menyerialisasinya tanpa services meng-import features.
- `lib/services/**` — logika murni Dart, **wajib ada test**; tidak boleh diduplikasi di widget.
- `lib/features/<screen>/` — satu folder per layar.
- `lib/core/widgets/mabar_widgets.dart` — komponen lintas layar (header, chip, info box, status badge, tombol primer, dashed border, stat box).
- `lib/core/widgets/mabar_brand_mark.dart` — lapangan biru + garis court + bola tennis. Dipakai hero Home **dan** generator icon aplikasi; jangan bikin salinan bola kedua.
- `lib/features/schedule/schedule_widgets.dart` — komponen khusus jadwal, dipakai bareng 6a/6b/7.
- State turnamen: Riverpod `tournamentProvider` (`features/schedule/tournament_controller.dart`) — satu-satunya sumber kebenaran sejak layar jadwal. Sebelum itu data dioper lewat `extra` router.

Konvensi: komentar seperlunya dan dalam bahasa Indonesia, menjelaskan *kenapa*. Nama komponen merujuk kelas CSS mockup (mis. `// .info` / `.share-card`) supaya mudah dicocokkan.

## Status: 11 layar selesai + persistensi lokal

Alur penuh jalan: Home → Peserta → Konfigurasi → Pasangan (Fixed) / Mode Endless (Mixed) → Jadwal 6a/6b → Input Skor + sheet WO → Peringkat → Detail Pemain → Share.

Mesin domain yang sudah ada + ter-test (64 test lulus, `flutter analyze` bersih kecuali 2 info lint lama di `models.dart`):
- `pairing/player_name_parser.dart` — parser textarea nama.
- `pairing/pair_generator.dart` — pasangan Fixed (acak/manual), sisa pemain ganjil.
- `schedule/round_robin_generator.dart` — circle method. **Invariant:** satu putaran circle dipotong jadi beberapa round sebesar jumlah court, tidak pernah menggabungkan dua putaran (kalau digabung, satu pair bisa main di dua lapangan bersamaan).
- `schedule/endless_round_generator.dart` — round Mixed. Constraint direlaksasi lewat bobot penalti: ulang match persis 1000, ulang partner 10, ulang lawan 3; ambil terbaik dari 400 percobaan. Invariant: selisih match antar pemain ≤ 1 (dihitung dengan kredit, lihat bawah).
- Peserta Mixed bisa berubah di tengah turnamen (sheet "Kelola Peserta", `features/schedule/mixed/manage_players_sheet.dart`; tes di `test/services/mixed_roster_test.dart`). Pemain keluar **tidak dihapus** dari `config.players`, hanya masuk `ActiveTournament.withdrawnPlayerIds`, supaya nama di match lama & peringkatnya tetap ada (tampil di Peringkat/Detail/Share tanpa penanda "keluar" — keputusan host 2026-10-20); generator hanya menerima `activePlayers`. Pemain baru/kembali dapat `matchCredits` (`EndlessRoundGenerator.catchUpCredit`) = disejajarkan dengan pemain aktif yang paling sedikit main — tanpa itu dia main terus sampai menyusul. Kredit hanya untuk prioritas jadwal, tidak ikut ranking (di Total Point pemain telat memang tertinggal; ini keputusan host). Minimal 4, maksimal 20 pemain aktif.
- Mixed: round terakhir yang belum ada satu skor pun bisa dibatalkan & dibuat ulang (`TournamentController.redoLastRound`, syaratnya `ActiveTournament.canRedoLastRound`; tombol di bawah "Buat R…"), untuk pemain yang baru datang dan ingin langsung main. Nomor round tetap, round lama utuh. Kredit pemain yang **tidak ada** di round itu (masuk/kembali setelah round dibuat) dihitung ulang dari history tanpa round tersebut — match pending ikut dihitung di `catchUpCredit`, jadi tanpa itu kreditnya kelebihan satu dan dia malah istirahat (paling kelihatan di 12 pemain/2 court, lihat test).
- `ranking/ranking_calculator.dart` — dua metode: Win % dan **Total Point** (`gamesWon`, yaitu jumlah game yang dimenangkan lintas match: 6-5, 4-6, 3-6 → 13). Default app = Total Point, sesuai keputusan host bahwa total point dihitung lebih dulu; metode "Kombinasi" sudah dihapus karena isinya identik dengan Win %. Tie-break: metode → total point → head-to-head → selisih game → nama (PRD bilang undian; dipakai nama supaya stabil). WO: menang/kalah dihitung, games tidak. `cancelled` & `pending` diabaikan total.
- `ranking/ranking_calculator.dart` → `standingEntries()` — mengubah klasemen per pemain jadi baris tampilan. Mode Fixed: pasangan tidak pernah berganti sehingga statistik kedua anggotanya identik, jadi dua baris kembar digabung jadi satu baris "Andi + Budi" yang mengambil posisi anggota terbaiknya. Mode Mixed: satu baris per pemain, urutan `rank()` tidak diubah. Pemain sisa (jumlah ganjil) tetap tampil sendiri.
- `share/result_text_builder.dart` — teks share ringkas/lengkap (tiap baris memuat total point).
- `storage/tournament_codec.dart` + `storage/tournament_store.dart` — persistensi lokal (lihat bawah).

Metode peringkat yang dipilih host hidup di `rankingMethodProvider`, klasemennya di `standingsProvider`, dan baris siap tampilnya di `standingEntriesProvider` (semuanya di `features/schedule/tournament_controller.dart`) — layar Peringkat, Detail Pemain, dan Share membaca `standingEntriesProvider` yang sama, jadi nomor urutnya tidak pernah berbeda antar layar. Di layar Detail, nama yang ditampilkan diambil dari `config.players` memakai `playerId`, **bukan** dari `entry.standing.player`: satu baris Fixed memuat dua pemain, dan `standing` itu milik anggota yang peringkatnya lebih tinggi.

Tombol kirim di layar Share memakai share sheet sistem (`Icons.share`, label "Bagikan Hasil"), bukan lagi tombol hijau khusus WhatsApp — tujuannya ditentukan host di share sheet, jadi logo WhatsApp-nya dihapus.

Share (`features/share/share_card.dart`) mengirim **gambar**, bukan cuma teks: poster 1080×1080 (IG Feed) dan 1080×1920 (IG Story) di-render lewat `screenshot` lalu dibagikan dengan `Share.shareXFiles`, teks hasil jadi caption. `ShareSelection` menentukan isi kartu/poster: Ringkas = 5 teratas + "+n pemain lainnya", Lengkap = semua pemain. Judul kartunya memakai `Icons.emoji_events_outlined` (piala yang sama dengan header layar Peringkat), bukan emoji 🏆 — emoji ikut font tiap device dan tidak ikut ter-render saat poster dibuat. Warna latarnya dipilih host lewat selector di bawah banner dan dipakai kartu preview sekaligus kedua gambar. `ShareTheme` punya 10 gradien: 6 gelap (tinta putih) + 4 lembut/nude (peach, nude, sage, lilac) yang tintanya gelap. Semua warna teks, garis pemisah, kilau, watermark, dan ikon piala diturunkan dari `theme.ink` — jangan menaruh `Colors.white` langsung di kartu, nanti hilang di tema terang. Catatan layout: tema memberi `height: 1.5` ke body text — baris poster memakai `height: 1.1` supaya `FittedBox` tidak mengecilkannya tanpa perlu. Tiap ukuran punya `typeScale` sendiri (Feed 1.15, Story 1.5) karena kanvas 1:1 jauh lebih pendek; margin tepinya di `SharePosterSize.padding`.

Cara melihat hasil poster tanpa build web: test sekali pakai yang me-render `ShareResultPoster` di `RepaintBoundary` lalu `toImage(pixelRatio: 3)` di dalam `tester.runAsync`, dan simpan PNG-nya. Wajib `FontLoader('Inter')` + `DefaultTextStyle(fontFamily: 'Inter')` — tanpa itu `flutter test` memakai font Ahem dan proporsinya menyesatkan. `Image.asset` dan font ikon memang tidak ikut ter-render di test.

## Persistensi lokal

Seluruh MVP PRD sudah jalan, termasuk bagian 5 (Penyimpanan Data).

- `services/storage/tournament_codec.dart` — `ActiveTournament` ↔ JSON, Dart murni, ter-test.
  Sengaja **bukan** TypeAdapter Hive: model domain jadi bebas anotasi/codegen dan tidak perlu
  mengelola nomor `typeId`. `schemaVersion` dinaikkan kalau bentuk JSON berubah tidak kompatibel;
  payload beda versi atau rusak (app di-kill di tengah tulis) di-`decode` jadi `null`, bukan
  melempar — turnamennya saja yang hilang, app tetap bisa dibuka.
- `services/storage/tournament_store.dart` — box Hive `tournament` berisi 2 key: `active` dan
  `lastFinished`. `TournamentStore.memory()` dipakai test dan sebagai penyelamat kalau box gagal
  dibuka (disk penuh, browser mode private).
- Auto-save-nya satu `listenSelf` di `TournamentController.build()`. Semua mutasi controller
  berakhir di `state =`, jadi tidak ada call site yang bisa lupa menyimpan — **jangan** menambah
  pemanggilan `saveActive` manual di mutator baru.
- Resume: `build()` mengembalikan `_store.loadActive()`. Kartu "Lanjutkan turnamen" di Home adalah
  satu-satunya jalan masuknya, dan dia mengoper `active.config` apa adanya karena `startIfNeeded`
  membandingkan config dengan `identical` — kalau config-nya disalin, jadwalnya akan diregenerate.
  Karena menambah pemain mengganti `state.config`, controller juga mengingat `_startedFrom` (config
  awal yang masih dipegang layar konfirmasi Mixed di belakang jadwal); dua-duanya dianggap turnamen yang sama.
- `close()` (tombol "Selesai" di layar Share) memindahkan turnamen ke slot `lastFinished`,
  tidak menghapusnya, sesuai PRD. Future-nya dikembalikan supaya test bisa menunggu tulisannya.
- Slot aktif cuma satu, jadi memilih jenis permainan di Home saat ada turnamen berjalan memunculkan
  konfirmasi dulu ("Buang & Mulai Baru").
- Belum ikut disimpan: `rankingMethodProvider` — setelah resume, metode peringkat kembali ke
  default Total Point.

Wording UI sudah direview host (2026-10-20) dan sengaja menyimpang dari mockup: istilah olahraga tetap
Inggris (court, round, match, set, WO, Win %, Total Point), istilah teknis diganti (generate → buat,
device → HP, Ranking/Share/Home → Peringkat/Bagikan/Beranda, "Endless" tidak muncul lagi di UI). Yang
dipertahankan atas permintaan host: "Aturan Fairness", "Selisih match antar pemain ≤ 1", label Estimasi
(Max Round · Match/Pemain · Court Aktif · Total Match), "→ Prioritas main di R…". Pakai "duplikat" (bukan
"dobel") dan "diprioritaskan" (bukan "didahulukan").

## Aset ilustrasi

`assets/images/` — raket tennis/padel (`SportTypeX.assetPath`) dan ilustrasi mode Fixed/Mixed (`PartnerModeX.assetPath`). Semuanya PNG transparan dengan garis berwarna **satu token yang sama, `MabarColors.text3` (#6B7280)**; kalau menambah aset baru, samakan warnanya — beberapa tempat menampilkan aset apa adanya (kartu Home, chip Jadwal) sehingga beda warna langsung kelihatan. Tempat lain mewarnai ulang lewat `ColorFiltered(BlendMode.srcIn)` (watermark share ikut tema, ilustrasi mode ikut status terpilih), dan itu hanya bekerja kalau latar aset benar-benar transparan.

Sumber aslinya JPEG berlatar putih; konversinya: potong bingkai tipis 1-2px di tepi file, putih → transparan dengan alpha bertingkat (biar tepi anti-alias tidak bergerigi), pangkas ke isi, lalu beri padding mengikuti rasio isi:kanvas aset lama supaya ukuran tampilnya tidak bergeser.

## Target platform

`android/`, `ios/`, dan `web/` semuanya ada. Bundle id / applicationId: **`id.mabar.app`** (label `Mabar`),
minSdk 24, iOS minimum 15. Orientasi dikunci portrait di dua tempat — `SystemChrome` di `lib/main.dart`
dan `UISupportedInterfaceOrientations` di `ios/Runner/Info.plist`; kalau menambah layar landscape,
keduanya harus diubah bareng.

Kode Dart-nya bebas platform (nol `kIsWeb`/`dart:html`/`Platform.*`). Satu-satunya titik sentuh platform
adalah share sheet di `features/share/share_result_screen.dart` — `XFile.fromData` in-memory, jadi tidak ada
permission/Info.plist yang perlu ditambah. Konsekuensinya share **wajib diuji di HP fisik**, bukan simulator.

Toolchain (per 2026-10-20): Android SDK di `~/Library/Android/sdk` dan Xcode 16.4 sudah terpasang (Mac Intel,
Xcode 27 Apple Silicon saja). `app-release.apk` pernah di-build, tapi release masih ditandatangani **debug key**
(`android/app/build.gradle.kts`) — perlu keystore sendiri sebelum dibagikan rutin / ke Play Store.

App icon Android/iOS digenerate dari brand mark, bukan digambar terpisah:

```bash
flutter test tool/generate_app_icon.dart   # 3 PNG 1024×1024 ke assets/icon/
dart run flutter_launcher_icons             # sebar ke android/ + ios/ + web/icons + favicon
```

`tool/` sengaja di luar `test/` supaya generator tidak ikut `flutter test` biasa. Ulangi kedua perintah itu setiap kali `mabar_brand_mark.dart` berubah. Foreground adaptive icon dibuat lebih kecil (0.40 kanvas) karena Android memangkas ~25% tiap sisi.

## Deploy web

Repo public `github.com/asepsugi/mabar`; tiap push ke `main` → `.github/workflows/deploy-web.yml` (flutter test →
`tool/build_web.sh --base-href /mabar/` → GitHub Pages) → **https://asepsugi.github.io/mabar/**. Sub-path itu
alasan `sw.js` didaftarkan relatif dan `start_url: "."` — jangan diganti jadi path absolut `/...`. Pages memberi
`max-age=600` yang tidak bisa diatur, jadi update baru terlihat paling lambat ~10 menit + reload kedua (lihat SW di bawah).
Versi Flutter di workflow dipatok (3.47.4); naikkan bareng kalau toolchain lokal naik.

## Cara menjalankan & verifikasi visual

`flutter run` biasa untuk device. Untuk cek cepat di browser (dipakai selama ini):

```bash
tool/build_web.sh
cd build/web && python3 -m http.server 8897 --bind 127.0.0.1
```

PWA/offline: **jangan** `flutter build web` langsung. Di Flutter 3.47 `flutter_service_worker.js` cuma
meng-unregister dirinya, jadi offline ditangani `web/sw.js` sendiri (cache-first, didaftarkan di `index.html`).
`tool/build_web.sh` membangun dengan `--no-web-resources-cdn` (CanvasKit dari server sendiri, bukan gstatic) lalu
mengisi daftar precache + versi di `sw.js`; `canvaskit/` sengaja tidak di-precache (beberapa varian ~5MB) dan
ter-cache saat dipakai. `web/flutter_bootstrap.js` memanggil `load()` tanpa `serviceWorkerSettings` — kalau
SW Flutter didaftarkan, scope-nya sama dan ia mencopot `sw.js`. Offline sudah diuji: server dimatikan, reload, app tetap jalan.
Update: `sw.js` baru terunduh di background saat app dibuka; pada pembukaan **berikutnya** `index.html` mengaktifkannya
(`skipWaiting` via pesan) lalu reload sekali. Jadi setelah rebuild, versi baru baru terlihat di reload ke-2 —
ini pernah bikin fitur baru "tidak muncul". Saat testing lokal pakai DevTools → Application → "Update on reload".

Catatan penting:
- Setelah rebuild, **restart server**-nya — `flutter build web` mengganti direktori, server lama menyajikan isi lama.
- Di browser harus **hard reload** (⇧⌘R); Chrome meng-cache `main.dart.js`.
- `flutter run -d web-server` sempat dipakai tapi koneksi debug-nya putus tiap reload; build statis lebih stabil.
- Bandingkan dengan mockup: `python3 -m http.server 8898` di root proyek lalu buka `hifi.html`.
