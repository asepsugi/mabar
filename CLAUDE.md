# Mabar — konteks proyek

App Flutter untuk host turnamen mabar tennis/padel (klub, 4–20 pemain, 1 device host, offline).

**Sumber kebenaran, baca sebelum mengubah UI/logika:**
- `PRD.md` — produk, algoritma, aturan skor & ranking, **versi 2.0 sejalan dengan hi-fi v2** (diselaraskan 2026-10-22).
  Kalau keputusan host mengubah perilaku, perbarui PRD + hi-fi (`design/hifi.html` dan artifact online
  `H9ZVDUfYvEBXsoBqih4iov`, publish file yang sama) dalam perubahan yang sama.
- `design/hifi.html` — **hi-fi v2 final** (disetujui host 2026-10-21): Fondasi, Komponen, 73 frame 390×844 +
  catatan perilaku, Cakupan. Acuan visual dan perilaku untuk semua pekerjaan UI berikutnya.
- `design/spec/` — paket implementasi v2. **Mulai dari `design/spec/README.md`** (urutan kerja, aturan golden), lalu
  `tokens.json`, `components.md`, `logic.md` (aturan logika yang berubah + data test), `screens/*.md` (per alur).
Fondasi, logika, komponen, dan painter lapangan v2 sudah ada di `lib/`; tata letak layar masih desain lama yang
warnanya dipetakan ke token baru (langkah 5 belum). Hi-fi lama (11 layar, Inter, hijau) ada di git: `git show dae32c9:hifi.html`.
Bagian "Status" di bawah menggambarkan app yang berjalan sekarang, bukan desain v2.

## Redesain v2 (final, implementasi bertahap)

Tujuannya tampilan yang tidak terkesan AI-generated: arah "papan skor pinggir lapangan" — biru court + tinta +
kuning bola, Archivo variabel (`assets/fonts/Archivo[wdth,wght].ttf`, sumbu `wdth` untuk angka condensed), ikon
Phosphor Bold, banner Beranda berupa sudut lapangan tampak atas (padel terracotta), ikon app dari painter yang sama.

- Semua keputusan sudah disetujui host; daftar lengkapnya di hi-fi → Cakupan. Jangan buka ulang keputusan itu.
- Perubahan logika (format skor Race to / Best of / Americano dengan data lama tetap terbaca, batas keypad, WO per
  format, status Final Mixed, undian seri dikunci per round, daftar prioritas istirahat, bug estimasi Lanjutkan)
  ada di `design/spec/logic.md`, lengkap dengan data test yang sama dengan angka di frame. **Sudah diimplementasi**
  (langkah 2) di service/model, belum di layar — lihat Status. Turnamen dari app lama (skor per set) **tidak dimuat**
  di app v2 (keputusan host 2026-10-22): format per set sudah dihapus dari kode, lihat Persistensi lokal.
- Verifikasi visual: `expectMatchesHifi(tester, layar, '<id frame>')` di `test/hifi/hifi_golden.dart` membandingkan
  render Flutter dengan `design/frames/<id>.png` (2x, Archivo dimuat; gagal → `build/hifi_diff/`). Jangan klaim
  layar sudah sesuai tanpa golden lolos.
- **Fondasi selesai** (langkah 1 di `design/spec/README.md`), semuanya di `lib/core/theme/`:
  - `mabar_theme.dart` — `MabarColors` (token v2 saja; token lama sudah dipetakan lewat tabel "Token lama → baru"
    di hi-fi dan dihapus), `MabarSpacing`, `MabarRadius`, `MabarSize` (tinggi sentuh, ukuran ikon), `MabarShadows`
    (hanya panel Beranda & menu ⋯; blur CSS dikonversi ke sigma Flutter), `MabarType` (skala huruf; angka besar =
    `numVariations` wdth 72 + `tabular`), dan `MabarTheme.light()`. Setiap `MabarType` membawa `fontFamily` sendiri:
    `ButtonStyle.textStyle`, judul dialog, dan isi snackbar **mengganti** gaya tema (tidak di-merge), jadi `TextStyle`
    tanpa keluarga di situ jatuh ke Roboto/SF. Semua slot `TextTheme` menulis `letterSpacing: 0` + `height`, kalau
    tidak geometri Material 3 ikut masuk.
  - `mabar_icons.dart` — `MabarIcons`, 31 ikon Phosphor Bold hi-fi sebagai `IconData` konstan dari
    `assets/fonts/Phosphor-Bold.ttf` (`@phosphor-icons/web@2.1.1`, MIT; codepoint dari `style.css`-nya). Paket
    `phosphor_flutter` **tidak** dipakai: tidak dirawat sejak 2024 dan gagal dikompilasi karena `IconData` sekarang
    `final class`. Jangan menambah `Icons.*` Material; ikon baru = konstanta baru di sini.
  - Inter dan `design-tokens.json` lama sudah dihapus. Warna PWA (`web/manifest.json`, `flutter_launcher_icons`) =
    `paper`; ikon app-nya baru diganti di langkah painter.
- **Komponen selesai** (langkah 3; 60+ golden per wilayah frame di `test/hifi/components/`). Generik di
  `lib/core/widgets/`: `mabar_controls` (MabarButton, MabarTextButton, MabarIconButton, MabarRowAction,
  MabarActionBar, MabarAppBar), `mabar_group` (MabarGroup/MabarRow, MabarSection, MabarGroupLabel/Note/Header),
  `mabar_inputs` (MabarSegmented, MabarStepper, MabarField, MabarChip/Wrap/Grid), `mabar_layers` (showMabarSheet,
  MabarOption, showMabarConfirm, showMabarMenu, showMabarToast), `match_score_row`, `numbered_lists` (RosterPreview,
  PairList), `mabar_ball`. Khusus layar di `features/<layar>/widgets/`: RoundTabs, RestingList, ScoreBoard/ScoreKeypad
  (di atas `ScoreEntry`), StandingTable, StatLine, NameListField, ModePicker/CourtSwatch/CourtColorGrid,
  HomePanel/HomeRowIcon/InstallStep, SharePoster (`share/widgets/`, preset pratinjau/Feed/Story, diekspor lewat
  `SharePosterTarget.exportPixelRatio`). Widget lama yang namanya bentrok jadi `LegacyChip`/`LegacyStepper`.
- **Painter lapangan selesai** (langkah 4): `core/widgets/court_painter.dart` — `CourtPainter(t, toward, layout)`, satu
  gambar sudut lapangan untuk banner Beranda **dan** ikon app (jangan bikin gambar lapangan kedua). `t` = posisi garis
  tennis (0) → padel (1); warna `toward` menyapu dari dinding belakang dengan tepi tegas, tidak dicampur.
  `CourtLayout.banner` (60 pt/m, garis dipudarkan 35% lewat satu `saveLayer`) dan `CourtLayout.icon` (kanvas 1024, garis
  penuh). `features/home/widgets/court_banner.dart` — `CourtBanner(sport, live)`: wordmark, nama olahraga / `.liveblock`,
  animasi 01g (controller = posisi garis + `animateTo`, jadi berbalik di tengah jalan tidak meloncat; kurva
  `easeInOutCubic` Flutter tidak simetris). Gambarnya ikut safe area (frame: status bar 47 → baseline y 104).
  Golden 01b/01c/01e/01f di `test/hifi/components/court_banner_test.dart`.
- Golden per komponen: `hifiRect(frame, kelas, text:)` membaca `design/spec/rects.json` (posisi elemen yang diukur
  Chrome, ditulis `tool/hifi_extract.py`), `hifiStage` menaruh widget di posisi itu, `expectRegionMatchesHifi`
  membandingkan wilayahnya saja. Pembanding menyerap geseran 1 piksel perangkat (Chrome men-snap baseline, Flutter
  tidak); geseran 2 pt tetap gagal — sudah dibuktikan di `hifi_harness_test`. Gambar aset: `precacheHifiAssets`.
- Jebakan CSS→Flutter yang sudah makan korban: border CSS memakan tempat (border-box), `inset box-shadow` tidak;
  `Container` dengan border dekorasi otomatis menambah tebal border ke padding; mesin teks membulatkan tinggi tiap
  baris ke pt bulat (22,4 → 22, 25,6 → 26), jadi kotak yang tingginya dari jumlah baris perlu dikompensasi
  (NameListField, baris poster); `OutlineInputBorder` menggeser isi 4 pt kecuali `gapPadding: 0`; `ButtonStyle.textStyle`
  mengganti gaya tema (makanya `MabarType` membawa `fontFamily`); `ThemeData` mengunci platform saat dibuat.
- Frame yang tidak konsisten dengan aturannya (aturan yang diikuti): tombol keypad mati hanya digambar di 07h/07k
  (07a–07g harus mematikan tombol juga); tombol "Tambah" di 08a 52 pt karena `min-height` `.btn`; tombol
  Lanjutkan banner 01e/01f 52 pt (bukan 46, `min-height` lagi); keyframe 200 ms di 01g hanya ilustrasi (garis sudah
  ±50% dan kaca sudah tampak saat sapuan warna baru 35%) — kode mengikuti teksnya: garis & sapuan satu kurva, kaca
  muncul di 60% terakhir.
- Kalau hi-fi diubah: `python3 tool/hifi_extract.py` me-render ulang `design/frames/` dan menulis ulang
  `design/spec/screens/` + `components.md` (butuh Google Chrome + internet untuk font). Jangan edit hasilnya dengan tangan.
  Hi-fi diubah hanya untuk keputusan host, bukan untuk menyamakan kode. Sejauh ini sekali (2026-10-22): `.poster-pair`
  (gambar Feed/Story 11d/11f/11g) diberi line-height 1,4 seperti kartu pratinjau, dulu mewarisi 1,55 dan kaki Feed
  Ringkas meluber dari padding.
- Membaca hi-fi: file ±320 KB tanpa base64 besar, aman dibaca per bagian (`<section class="flow" id="beranda">`,
  dst.). Untuk satu layar lebih ringkas baca `design/spec/screens/<alur>.md` + PNG frame-nya.

## Versioning app (PRD §12)

Semver `MAJOR.MINOR.PATCH+BUILD` di `pubspec.yaml`; `lib/core/app_version.dart` (`appVersion`) = `MAJOR.MINOR.PATCH`
(dijaga test) dan ikut tertulis di tiap simpanan turnamen. **Setiap perubahan dikategorikan:** MAJOR = perubahan besar
logika/desain atau data lama tidak kompatibel (`schemaVersion` naik → selalu MAJOR); MINOR = fitur/perilaku baru yang
kompatibel; PATCH = perbaikan bug/teks/visual kecil tanpa mengubah perilaku yang disepakati. Versi + `appVersion`
dinaikkan di commit yang membawa perubahan ke `main` (tiap push = deploy web), kategori tertinggi yang menang, `BUILD`
naik tiap rilis. Sebut kategorinya di pesan commit/PR (`[minor]`). Branch `redesain-v2-spec` = 2.0.0 (MAJOR: redesain +
format skor + data app lama tidak dimuat).

## Arsitektur

- `lib/models/models.dart` — seluruh model domain, immutable. Termasuk `ActiveTournament`
  (turnamen + bye/resting per round); dia ada di sini, bukan di controller, supaya
  `services/storage/` bisa menyerialisasinya tanpa services meng-import features.
- `lib/services/**` — logika murni Dart, **wajib ada test**; tidak boleh diduplikasi di widget.
- `lib/features/<screen>/` — satu folder per layar.
- `lib/core/widgets/mabar_widgets.dart` — komponen lintas layar (header, chip, info box, status badge, tombol primer, dashed border, stat box).
- `lib/core/widgets/court_painter.dart` + `mabar_ball.dart` — lapangan + bola brand. Dipakai banner Beranda **dan** generator icon aplikasi; jangan bikin salinan kedua.
- `lib/features/schedule/schedule_widgets.dart` — komponen khusus jadwal, dipakai bareng 6a/6b/7.
- State turnamen: Riverpod `tournamentProvider` (`features/schedule/tournament_controller.dart`) — satu-satunya sumber kebenaran sejak layar jadwal. Sebelum itu data dioper lewat `extra` router.

Konvensi: komentar seperlunya dan dalam bahasa Indonesia, menjelaskan *kenapa*. Nama komponen merujuk kelas CSS mockup (mis. `// .info` / `.share-card`) supaya mudah dicocokkan; untuk kode desain v2 pakai kelas di `design/hifi.html` (mis. `// .bug`, `.rest`) dan nama widget di `design/spec/components.md`.

## Status: 11 layar selesai + persistensi lokal

Alur penuh jalan: Home → Peserta → Konfigurasi → Pasangan (Fixed) / Mode Endless (Mixed) → Jadwal 6a/6b → Input Skor + sheet WO → Peringkat → Detail Pemain → Share.

Mesin domain yang sudah ada + ter-test (124 test lulus — 120 domain/widget + 4 alat pembanding hi-fi di `test/hifi/`; `flutter analyze` bersih kecuali 2 info lint lama di `models.dart`):
- `pairing/player_name_parser.dart` — parser textarea nama.
- `pairing/pair_generator.dart` — pasangan Fixed (acak/manual), sisa pemain ganjil.
- `schedule/round_robin_generator.dart` — circle method. **Invariant:** satu putaran circle dipotong jadi beberapa round sebesar jumlah court, tidak pernah menggabungkan dua putaran (kalau digabung, satu pair bisa main di dua lapangan bersamaan).
- `schedule/endless_round_generator.dart` — round Mixed. Constraint direlaksasi lewat bobot penalti: ulang match persis 1000, ulang partner 10, ulang lawan 3; ambil terbaik dari 400 percobaan. Invariant: selisih match antar pemain ≤ 1 (dihitung dengan kredit, lihat bawah).
  Siapa yang main = `priorityOrder` (jumlah main + kredit → paling lama istirahat → undian → id). Undiannya **dikunci
  per round**: `Random(drawSeed + nomor round)` dibagikan ke pemain urut id, `drawSeed` = FNV-1a dari id turnamen
  (`ActiveTournament.drawSeed`, tanpa kunci simpanan baru; perkaliannya dipecah supaya sama di web). Jadi
  `restingAfterLastRound` (baris "Istirahat · Prioritas main di R…" / "Istirahat lagi di R…", dari pemain aktif
  sekarang) selalu sama dengan hasil "Buat R…". Waktu habis (tidak ada court untuk R(n+1)) → slot dihitung dari semua
  court, sesuai frame 06l. Tes: `test/services/mixed_priority_test.dart`.
- Peserta Mixed bisa berubah di tengah turnamen (sheet "Kelola Peserta", `features/schedule/mixed/manage_players_sheet.dart`; tes di `test/services/mixed_roster_test.dart`). Pemain keluar **tidak dihapus** dari `config.players`, hanya masuk `ActiveTournament.withdrawnPlayerIds`, supaya nama di match lama & peringkatnya tetap ada (tampil di Peringkat/Detail/Share tanpa penanda "keluar" — keputusan host 2026-10-20); generator hanya menerima `activePlayers`. Pemain baru/kembali dapat `matchCredits` (`EndlessRoundGenerator.catchUpCredit`) = disejajarkan dengan pemain aktif yang paling sedikit main — tanpa itu dia main terus sampai menyusul. Kredit hanya untuk prioritas jadwal, tidak ikut ranking (di Total Point pemain telat memang tertinggal; ini keputusan host). Minimal 4, maksimal 20 pemain aktif.
- Mixed: round terakhir yang belum ada satu skor pun bisa **dibatalkan = dihapus** ("Batalkan Rn",
  `TournamentController.cancelLastRound`, syaratnya `ActiveTournament.canCancelLastRound`; tombol di bawah "Buat R…"),
  untuk pemain yang baru datang: host tambah pemain lewat Peserta lalu "Buat Rn" lagi. Tidak dibuat ulang otomatis —
  keputusan host. **R1 tidak bisa dibatalkan** (`roundCount > 1`), karena layar jadwal tanpa round tidak punya isi.
  Setelah dibatalkan layar pindah ke round sebelumnya. Kredit pemain yang **tidak ada** di round itu (masuk/kembali
  setelah round dibuat) dihitung ulang dari history tanpa round tersebut — match pending ikut dihitung di
  `catchUpCredit`, jadi tanpa itu kreditnya kelebihan satu dan dia istirahat di round berikutnya (paling kelihatan di
  12 pemain/2 court, lihat test).
- `ranking/ranking_calculator.dart` — dua metode: Win % dan **Total Point** (`gamesWon`, yaitu jumlah game yang dimenangkan lintas match: 6-5, 4-6, 3-6 → 13). Default app = Total Point, sesuai keputusan host bahwa total point dihitung lebih dulu; metode "Kombinasi" sudah dihapus karena isinya identik dengan Win %. Tie-break: metode → total point → head-to-head → selisih game → nama (PRD bilang undian; dipakai nama supaya stabil). WO (PRD 4.4, `ScoreFormat.woWinnerScore`): menang/kalah dihitung; pemenang dapat N game di Race to, di Best of/Americano rata-rata skornya sendiri dari match yang dia mainkan (bulat ,5 ke atas) tapi minimal ⌊N÷2⌋+1; yang kalah 0. Nilai itu masuk `woPoints` → `totalPoint`, **tidak** ke `gameDiff`. Format lama tetap: WO tanpa game. `cancelled` & `pending` diabaikan total. Tes dengan data frame 09a–09f/10b: `test/services/ranking_v2_test.dart`.
- `ranking/ranking_calculator.dart` → `standingEntries()` — mengubah klasemen per pemain jadi baris tampilan. Mode Fixed: pasangan tidak pernah berganti sehingga statistik kedua anggotanya identik, jadi dua baris kembar digabung jadi satu baris "Andi + Budi" yang mengambil posisi anggota terbaiknya. Mode Mixed: satu baris per pemain, urutan `rank()` tidak diubah. Pemain sisa (jumlah ganjil) tetap tampil sendiri. `StandingEntry.position`: statistik identik (poin, selisih, M–K–S) → nomor sama (1, 1, 3); baris yang belum main dipindah ke belakang dengan `position == null` (grup "Belum main"). Peringkat, Detail, Bagikan, dan caption memakai nomor ini — jangan menomori dengan indeks.
- `ActiveTournament.isFinal` — status Final/Sementara: diakhiri, Fixed semua match terisi, Mixed waktu booking habis + round terakhir lengkap (bukan tiap round lengkap). `playedRoundCount` = jumlah round yang punya match selesai/WO ("5 round · 10 match").
- **Format skor** (`TournamentConfig.format` = `ScoreFormat(method, target)`; tes `test/services/score_format_test.dart`):
  Race to N (2–9, default 6 — default kedua olahraga), Best of N (1–15, default 5), Americano N (2–99, default 21).
  Semua disimpan sebagai **satu `SetScore`**, jadi ranking/share/codec tidak bercabang; Best of & Americano mengisi
  lawan `N − x`; seri hanya kalau N genap (`canDraw`, juga penentu kolom S). Aturan sah + pesan frame 07d/07h di
  `services/scoring/score_entry.dart` (`ScoreRules.judge`), begitu juga keypad v2 (`ScoreEntry`: batas per kotak
  `maxPerSide`, ketikan pertama setelah kotak dipilih mengganti isi, digit penuh → pindah ke kotak lawan yang kosong,
  tombol tidak melihat isi lawan). Durasi match selalu kelipatan 5 (`TournamentConfig.roundDuration`). Config yang disalin wajib lewat
  `copyWith` supaya `format` tidak hilang.
- `MatchGame.withScore` / `asWalkover` menimpa match sepenuhnya: skor di match WO membuang sisa WO, dan alasan WO yang
  dilepas benar-benar hilang (`copyWith` tidak bisa mengosongkan field).
- `ActiveTournament.capacityAhead` (sheet Lanjutkan) mengembalikan `fewerCourtsFrom` = round tambahan saat court yang
  main di round pertamanya habis; court yang sejak awal tidak dapat tambahan bukan "berkurang" (bug lama).
- `share/result_text_builder.dart` — teks share ringkas/lengkap (tiap baris memuat total point, satuan ikut format, "Peringkat Akhir"/"Sementara" dari `isFinal`).
- `storage/tournament_codec.dart` + `storage/tournament_store.dart` — persistensi lokal (lihat bawah).

Metode peringkat yang dipilih host hidup di `rankingMethodProvider`, klasemennya di `standingsProvider`, dan baris siap tampilnya di `standingEntriesProvider` (semuanya di `features/schedule/tournament_controller.dart`) — layar Peringkat, Detail Pemain, dan Share membaca `standingEntriesProvider` yang sama, jadi nomor urutnya tidak pernah berbeda antar layar. Di layar Detail, nama yang ditampilkan diambil dari `config.players` memakai `playerId`, **bukan** dari `entry.standing.player`: satu baris Fixed memuat dua pemain, dan `standing` itu milik anggota yang peringkatnya lebih tinggi.

Tombol kirim di layar Share memakai share sheet sistem (`Icons.share`, label "Bagikan Hasil"), bukan lagi tombol hijau khusus WhatsApp — tujuannya ditentukan host di share sheet, jadi logo WhatsApp-nya dihapus.

Share (`features/share/share_card.dart`) mengirim **gambar**, bukan cuma teks: poster 1080×1080 (IG Feed) dan 1080×1920 (IG Story) di-render lewat `screenshot` lalu dibagikan dengan `Share.shareXFiles`, teks hasil jadi caption. `ShareSelection` menentukan isi kartu/poster: Ringkas = 5 teratas + "+n pemain lainnya", Lengkap = semua pemain. Judul kartunya memakai `Icons.emoji_events_outlined` (piala yang sama dengan header layar Peringkat), bukan emoji 🏆 — emoji ikut font tiap device dan tidak ikut ter-render saat poster dibuat. Warna latarnya dipilih host lewat selector di bawah banner dan dipakai kartu preview sekaligus kedua gambar. `ShareTheme` punya 10 gradien: 6 gelap (tinta putih) + 4 lembut/nude (peach, nude, sage, lilac) yang tintanya gelap. Semua warna teks, garis pemisah, kilau, watermark, dan ikon piala diturunkan dari `theme.ink` — jangan menaruh `Colors.white` langsung di kartu, nanti hilang di tema terang. Catatan layout: tema memberi `height: 1.5` ke body text — baris poster memakai `height: 1.1` supaya `FittedBox` tidak mengecilkannya tanpa perlu. Tiap ukuran punya `typeScale` sendiri (Feed 1.15, Story 1.5) karena kanvas 1:1 jauh lebih pendek; margin tepinya di `SharePosterSize.padding`.

Cara melihat hasil poster tanpa build web: test sekali pakai yang me-render `ShareResultPoster` di `RepaintBoundary` lalu `toImage(pixelRatio: 3)` di dalam `tester.runAsync`, dan simpan PNG-nya. Wajib `loadHifiFonts()` (`test/hifi/hifi_golden.dart`, memuat Archivo + font ikon `PhosphorBold`) dan tema `MabarTheme.light()` — tanpa itu `flutter test` memakai font Ahem dan proporsinya menyesatkan. `Image.asset` memang tidak ikut ter-render di test.

## Persistensi lokal

Seluruh MVP PRD sudah jalan, termasuk bagian 5 (Penyimpanan Data).

- `services/storage/tournament_codec.dart` — `ActiveTournament` ↔ JSON, Dart murni, ter-test.
  Sengaja **bukan** TypeAdapter Hive: model domain jadi bebas anotasi/codegen dan tidak perlu
  mengelola nomor `typeId`. `schemaVersion` dinaikkan kalau bentuk JSON berubah tidak kompatibel
  (sekarang 2 = app v2), dan tiap simpanan membawa `appVersion` (`lib/core/app_version.dart`, harus sama dengan
  `version` di pubspec — dijaga test; tampil juga di Beranda). Simpanan app lama (skema 1, tanpa `appVersion`,
  skor per set) sengaja tidak dimuat. Payload beda versi atau rusak (app di-kill di tengah tulis) di-`decode` jadi `null`, bukan
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
- **Lanjutkan Turnamen** (Mixed saja; Fixed sengaja tidak — keputusan host): `TournamentController.resume`
  + sheet `features/schedule/mixed/resume_tournament_sheet.dart`, tes di `test/services/resume_tournament_test.dart`.
  Muncul kalau `ActiveTournament.canResume` (sudah "Akhiri" atau waktu booking semua court habis) di layar Jadwal,
  dan dari kartu "Turnamen terakhir" di Beranda untuk slot `lastFinished` (`lastFinishedProvider`, diset sinkron
  oleh `close()` supaya Beranda tidak menunggu tulisan ke device). Jam ditambah **per court** karena sering cuma
  sebagian court yang bisa diperpanjang, dan dihitung dari akhir round terakhir: `max(booking, round × durasi) + tambahan`
  — court yang waktunya sudah lama habis tetap dapat jam penuh. Match `cancelled` (hanya dibuat oleh "Akhiri")
  kembali `pending`. Estimasi di sheet = `ActiveTournament.capacityAhead` dalam **jumlah match** (bukan round: round jalan
  selama masih ada satu court, jadi cuma mengikuti court terpanjang dan tambahan di court lain tidak kelihatan). Header Jadwal menampilkan booking court **terpanjang** karena sesi baru selesai saat court terakhir habis.
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
Di desain v2 (keputusan host 2026-10-21) frasa itu menjadi judul "Istirahat · Prioritas main di R…", dan "peserta"
tidak dipakai lagi: semua orang disebut "pemain" (layar Pemain, Kelola pemain, Ubah pemain).

## Aset ilustrasi

`assets/images/` — raket tennis/padel (`SportTypeX.assetPath`) dan ilustrasi mode Fixed/Mixed (`PartnerModeX.assetPath`). Semuanya PNG transparan dengan garis berwarna **satu abu yang sama, #6B7280** (token `text3` desain lama; hi-fi v2 memakai raket apa adanya dan menggelapkannya saat terpilih, ilustrasi mode diganti ikon); kalau menambah aset baru, samakan warnanya — beberapa tempat menampilkan aset apa adanya (kartu Home, chip Jadwal) sehingga beda warna langsung kelihatan. Tempat lain mewarnai ulang lewat `ColorFiltered(BlendMode.srcIn)` (watermark share ikut tema, ilustrasi mode ikut status terpilih), dan itu hanya bekerja kalau latar aset benar-benar transparan.

Sumber aslinya JPEG berlatar putih; konversinya: potong bingkai tipis 1-2px di tepi file, putih → transparan dengan alpha bertingkat (biar tepi anti-alias tidak bergerigi), pangkas ke isi, lalu beri padding mengikuti rasio isi:kanvas aset lama supaya ukuran tampilnya tidak bergeser.

## Target platform

`android/`, `ios/`, dan `web/` semuanya ada. Bundle id / applicationId: **`id.mabar.app`** (label `Mabar`),
minSdk 24, iOS minimum 15. Beranda tanpa header: hero biru naik sampai di bawah status bar (`SafeArea(top: false)` + inset di hero) dengan
ikon status bar putih lewat `AnnotatedRegion` (`MabarTheme.statusBarLight`); default gelap dipasang di `builder`
`MaterialApp` supaya gaya putih tidak terbawa ke layar lain. Versi ("v1.0", hardcode) ada di teks bawah Beranda.
Orientasi dikunci portrait di dua tempat — `SystemChrome` di `lib/main.dart`
dan `UISupportedInterfaceOrientations` di `ios/Runner/Info.plist`; kalau menambah layar landscape,
keduanya harus diubah bareng.

Kode Dart-nya bebas platform (nol `kIsWeb`/`dart:html`/`Platform.*`). Titik sentuh platform cuma dua:

- Share sheet di `features/share/share_result_screen.dart` — `XFile.fromData` in-memory, jadi tidak ada
  permission/Info.plist yang perlu ditambah. Konsekuensinya share **wajib diuji di HP fisik**, bukan simulator.
- Kartu **"Pasang Mabar di HP"** di Beranda (PWA saja). `features/home/app_install.dart` memilih implementasi
  lewat conditional export: `app_install_web.dart` (`dart:js_interop`) atau stub (native/test → selalu `none`,
  kartu tidak muncul). Logikanya di `window.mabarInstall` (`web/index.html`): `beforeinstallprompt` harus
  ditangkap di sana karena sering datang sebelum Flutter selesai dimuat. Chrome/Edge/Samsung Internet →
  tombolnya langsung memunculkan dialog pasang bawaan (tetap butuh satu ketukan konfirmasi; pasang diam-diam
  memang tidak bisa). iPhone/iPad tidak punya API pasang → tombolnya membuka panduan Bagikan → Tambah ke Layar
  Utama (`ios_install_sheet.dart`). Deteksi "sudah terpasang": dibuka dalam mode standalone, atau Chrome tidak
  lagi mengirim event-nya. Di tab Safari iOS status terpasang **tidak bisa** diketahui, jadi kartunya tetap
  muncul di sana. Closure yang dioper ke `.toJS` harus mengembalikan tipe JS/void — `() => x.value = y`
  gagal compile di web (tidak ketahuan di `flutter test`, jadi cek dengan `tool/build_web.sh`).

Beranda dibungkus `CustomScrollView` + `SliverFillRemaining(hasScrollBody: false)`: `Spacer` tetap mendorong
pilihan permainan ke bawah, tapi di browser HP yang pendek (bar alamat + kartu lanjutkan + kartu pasang)
halamannya bisa digulir alih-alih meluber.

Toolchain (per 2026-10-20): Android SDK di `~/Library/Android/sdk` dan Xcode 16.4 sudah terpasang (Mac Intel,
Xcode 27 Apple Silicon saja). `app-release.apk` pernah di-build, tapi release masih ditandatangani **debug key**
(`android/app/build.gradle.kts`) — perlu keystore sendiri sebelum dibagikan rutin / ke Play Store.

App icon Android/iOS/web digenerate dari `CourtPainter` + `MabarBall` (opsi A, frame 01j), bukan digambar terpisah:

```bash
flutter test tool/generate_app_icon.dart   # 3 PNG 1024×1024 ke assets/icon/
dart run flutter_launcher_icons             # sebar ke android/ + ios/ + web/icons + favicon
```

`tool/` sengaja di luar `test/` supaya generator tidak ikut `flutter test` biasa. Ulangi kedua perintah itu setiap kali painter, `CourtLayout.icon`, atau bola berubah. Adaptive icon Android: komposisi ikon utuh dikecilkan ke 72/108 bagian tengah (yang terlihat di mask), lapangan & run-off tetap sampai tepi latar, bola di foreground — jadi mask bulat/squircle memotong gambar yang sama dengan ikon iOS.

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
ter-cache saat dipakai. Daftar precache berisi URL: nama aset yang di-encode Flutter di disk (`Archivo%5Bwdth,wght%5D.ttf`)
ditulis dengan `%25`; satu URL 404 saja menggagalkan `cache.addAll` dan service worker tidak pernah ter-install. Setelah
build, cek semua URL di `PRECACHE` mengembalikan 200. `web/flutter_bootstrap.js` memanggil `load()` tanpa `serviceWorkerSettings` — kalau
SW Flutter didaftarkan, scope-nya sama dan ia mencopot `sw.js`. Offline sudah diuji: server dimatikan, reload, app tetap jalan.
Update: `sw.js` baru terunduh di background saat app dibuka; pada pembukaan **berikutnya** `index.html` mengaktifkannya
(`skipWaiting` via pesan) lalu reload sekali. Jadi setelah rebuild, versi baru baru terlihat di reload ke-2 —
ini pernah bikin fitur baru "tidak muncul". Saat testing lokal pakai DevTools → Application → "Update on reload".

Catatan penting:
- Setelah rebuild, **restart server**-nya — `flutter build web` mengganti direktori, server lama menyajikan isi lama.
- Di browser harus **hard reload** (⇧⌘R); Chrome meng-cache `main.dart.js`.
- `flutter run -d web-server` sempat dipakai tapi koneksi debug-nya putus tiap reload; build statis lebih stabil.
- Bandingkan dengan hi-fi v2: `python3 -m http.server 8898` di root proyek lalu buka `design/hifi.html`
  (atau lihat PNG di `design/frames/`).
