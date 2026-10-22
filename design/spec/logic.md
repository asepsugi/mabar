# Logika yang berubah di desain v2

Ditulis tangan (bukan hasil `tool/hifi_extract.py`). Setiap butir mengubah `lib/services/**` atau model, jadi
**wajib test** sesuai aturan `CLAUDE.md`. Angka di "data test" sama dengan angka di frame hi-fi, jadi test dan golden
saling menguatkan.

**Status: semua butir sudah diimplementasi di model/service dan ter-test** (langkah 2). Layar tinggal memakainya;
jangan menulis ulang aturannya di widget. Lokasi implementasi ditulis di tiap bagian.

## 1. Format skor

Implementasi: `ScoringMethod` + `ScoreFormat` (`lib/models/models.dart`), aturan sah `ScoreRules.judge`
(`lib/services/scoring/score_entry.dart`); test `test/services/score_format_test.dart`.

| Format | Parameter | Default | Skor sah | Seri |
|---|---|---|---|---|
| Race to N game | N = 2–9 | 6 (kedua olahraga) | N lawan 0..N−1, atau N+1 lawan N−1 / N (7–5, 7–6) | tidak pernah |
| Best of N game | N = 1–15 | 5 | a + b = N | kalau N genap dan a = b |
| Americano N poin | N = 2–99 | 21 | a + b = N | kalau N genap dan a = b |

- Disimpan sebagai satu `SetScore` per match, jadi ranking/share/codec tidak bercabang.
- **Data lama tidak dimuat** (keputusan host 2026-10-22, menggantikan "data lama harus tetap terbaca"): turnamen dari
  app lama (skor per set, `schemaVersion` 1) diabaikan saat app v2 dibuka. Simpanan v2 = `schemaVersion` 2 + `appVersion`
  (versi app yang menulisnya).
- Konfigurasi: durasi match stepper ±5, **selalu kelipatan 5** (minimal 5); ketikan dibulatkan ke kelipatan 5 terdekat.

## 2. Batas angka di keypad Input Skor

Implementasi: `ScoreEntry` (`score_entry.dart`).

- Isi satu kotak tidak bisa melebihi: Race to N → N+1 · Best of N → N · Americano → total. Tombol angka yang
  akan melewatinya mati.
- Digit ditambahkan di belakang isi kotak selama masih ada digit yang muat. **Kotak yang sudah penuh** (tidak ada digit
  lagi yang bisa ditambahkan; 0 selalu penuh) **atau baru dipilih** (ketuk kotak, →, pindah otomatis) menerima ketikan
  berikutnya sebagai **pengganti** isinya. Jadi yang mati hanya angka di atas batas (keputusan host 2026-10-22).
  Setelah digit membuat kotak penuh, kursor pindah ke kotak lawan kalau kotak itu kosong.
- Belum ada kotak aktif (skor tersimpan dibuka, 07i): semua angka mati sampai salah satu kotak diketuk (atau →).
- Kombinasi dicek setelah dua kotak terisi (pesan di frame 07d/07e/07h). **Tombol tidak dimatikan berdasarkan
  isi kotak lawan** (koreksi 6–4 → 7–5 harus bisa tanpa mengubah lawan dulu).
- Best of dan Americano: mengisi satu sisi mengisi sisi lain dengan N − x.

Data test: Race to 6 → kosong: 8 dan 9 mati; "1" di Race to 9 → hanya 0 aktif; Americano 21 → setelah "2" hanya 0 dan 1;
Race to 6 berisi "4" (07b) → 8 dan 9 mati; Best of 5 berisi "3" (07e) → 6–9 mati; Americano 21 berisi "13" (07g) → semua
aktif; 07i → semua mati.
Diterima: 6–0, 6–5, 7–5, 7–6. Ditolak: 6–6 ("belum selesai"), 5–3 ("belum ada yang sampai 6"), 7–3, 7–4.

## 3. Walkover (menggantikan "games WO tidak dihitung", PRD 4.4)

Implementasi: `ScoreFormat.woWinnerScore` + `RankingCalculator.rank` (nilai WO masuk `woPoints` → `totalPoint`, tidak
ke selisih); test `test/services/ranking_v2_test.dart`.

| Format | Pemenang WO dapat | Yang kalah |
|---|---|---|
| Race to N | N game | 0 |
| Best of N / Americano | max(rata-rata game/poin dari match yang dia **mainkan**, ⌊total ÷ 2⌋ + 1) | 0 |

- Rata-rata dibulatkan ke bilangan bulat terdekat (,5 ke atas). Belum pernah main → ⌊total ÷ 2⌋ + 1.
- Dihitung ulang tiap kali klasemen dihitung (rata-rata berubah kalau dia main lagi).
- Menang/kalah tetap masuk W–L–D dan Win %. **Selisih tidak berubah** untuk kedua tim.
- Skor menang terkecil: Americano 21 → 11 · Americano 24 → 13 · Best of 5 → 3 · Best of 6 → 4.

Data test: lihat data set 2 di bawah (Budi rata-rata 14 ≥ 13 → +14; Joko rata-rata 8,5 < 13 → +13) dan Fixed 09c
(Race to 6: Gina · Hana menang WO di R2 → +6, total 17 → 23, selisih tetap +7).

## 4. Peringkat

- Statistik identik → **nomor sama** (1, 1, 3). Identik = poin, selisih, M, K, S sama. Urutan baris tetap tie-break:
  metode → Total Point → head-to-head → selisih → nama.
- Kolom W–L–D di **kedua** metode; kolom terakhir = nilai metode. **D hanya ada kalau format bisa seri**
  (Best of genap, Americano genap); selain itu W–L. Win % dibulatkan tanpa desimal di tabel, 1 desimal di Detail.
- Label satuan mengikuti format: "Poin" (Americano) / "Game" (Race to, Best of).
- **Status Mixed**: Final kalau `isFinished || (courtsAvailableForRound(n+1).isEmpty && isRoundComplete(n))`;
  kembali Sementara setelah Lanjutkan/tambah jam. Fixed: Final kalau diakhiri atau semua match selesai.
- Subjudul sementara "Padel · Mixed · Sementara · R3 · 6 dari 6 match"; final "Padel · Mixed · Final · 4 round · 7 match"
  (round & match yang dimainkan; match "Tidak dimainkan" tidak dihitung, ditulis di catatan bawah).

### Data set 1 — frame 09a/09b, Detail 10a, Bagikan 11a (Americano 24, R1–R3, 6 match, Gilang masuk belakangan)

| Match | Tim 1 | Tim 2 | Skor |
|---|---|---|---|
| R1 M1 | Andi · Hana | Budi · Eko | 14–10 |
| R1 M2 | Dewant · Citra | Fajar · Joko | 15–9 |
| R2 M1 | Andi · Gina | Fajar · Indra | 15–9 |
| R2 M2 | Dewant · Joko | Budi · Hana | 14–10 |
| R3 M1 | Andi · Dewant | Citra · Indra | 13–11 |
| R3 M2 | Eko · Gina | Fajar · Hana | 12–12 |

Total Point: 1 Andi 42 (3–0–0) · 1 Dewant 42 · 3 Hana 36 (1–1–1) · 4 Fajar 30 · 5 Gina 27 · 6 Citra 26 · 7 Joko 23 ·
8 Eko 22 · 9 Budi 20 · 9 Indra 20 · belum main: Gilang.
Win %: 1 Andi 100 · 1 Dewant 100 · 3 Gina 75 · 4 Hana 50 · 5 Citra 50 · 6 Joko 50 · 7 Eko 25 · 8 Fajar 17 · 9 Budi 0 · 9 Indra 0.
Detail Andi: 42 poin · 100% · 3–0–0 · +12; beda partner 3/10, beda lawan 5/10.

### Data set 2 — frame 09d/09e/09f (Americano 24, R1–R4, 7 dari 8 match, 1 WO, 1 seri)

| Match | Tim 1 | Tim 2 | Skor |
|---|---|---|---|
| R1 M1 | Andi · Budi | Citra · Dewant | 16–8 |
| R1 M2 | Eko · Fajar | Gina · Hana | 13–11 |
| R2 M1 | Andi · Citra | Eko · Indra | 11–13 |
| R2 M2 | Budi · Joko | Dewant · Gina | WO (Dewant · Gina tidak main) |
| R3 M1 | Andi · Fajar | Hana · Joko | 14–10 |
| R3 M2 | Budi · Indra | Citra · Gina | 12–12 |
| R4 M1 | Dewant · Eko | Fajar · Joko | 17–7 |
| R4 M2 | Andi · Hana | Budi · Gina | belum dimainkan (09f: "Tidak dimainkan" setelah Akhiri) |

Kredit WO: Budi (16 + 12) ÷ 2 = 14 → +14; Joko (10 + 7) ÷ 2 = 8,5 → di bawah 13 → +13.
Total Point: 1 Eko 43 · 2 Budi 42 (2–0–1) · 3 Andi 41 · 4 Fajar 34 · 5 Citra 31 · 6 Joko 30 · 7 Dewant 25 · 8 Indra 25 ·
9 Gina 23 · 10 Hana 21 (Dewant di atas Indra: poin dan selisih sama, tanpa head-to-head → nama).
Win %: 1 Eko 100 · 2 Budi 83 · 3 Indra 75 · 4 Andi 67 · 5 Fajar 67 · 6 Joko 33 · 7 Dewant 33 · 8 Citra 17 · 9 Gina 17 · 10 Hana 0.

## 5. Generator Mixed: undian seri dikunci per round

Implementasi: `EndlessRoundGenerator.priorityOrder` / `generateRound(seed:)`. Urutan pemilihan = (jumlah main + kredit,
round terakhir main, kunci undian, id). Kunci undian: `Random(drawSeed + nomorRound)` dibagikan ke pemain yang diurut
id. `drawSeed` = FNV-1a dari id turnamen (`ActiveTournament.drawSeed`), **tidak** disimpan sebagai kunci baru; perkaliannya
dipecah supaya hasilnya sama di web. Test `test/services/mixed_priority_test.dart`: urutan dua kali hitung untuk round
yang sama identik; round berbeda memberi undian berbeda; hasil `generateRound` = daftar prioritas yang ditampilkan.

## 6. Daftar istirahat (Jadwal Mixed)

- Round terakhir (tab = n): yang tidak main di round n, dihitung dari **pemain aktif sekarang** (yang keluar tidak
  tampil, yang baru ditambah langsung masuk). Dibagi dua memakai urutan generator untuk round n+1 dengan slot
  K = 4 × court yang masih muat round n+1: masuk K teratas → "Istirahat · Prioritas main di R(n+1)", sisanya →
  "Istirahat lagi di R(n+1)". Kalau semua kebagian slot, hanya daftar pertama.
- Waktu habis (tidak ada court yang muat round n+1): K dihitung dari **semua** court, seperti frame 06l — daftar tetap
  menunjukkan siapa yang main duluan kalau host menambah jam. Implementasi `ActiveTournament.restingAfterLastRound`.
- Round lewat: `restingPlayerIdsByRound[k]` apa adanya, tanpa tag prioritas.
- Fixed: hanya pasangan bye (`byePairIdByRound`), maksimal satu.

## 7. Estimasi Lanjutkan turnamen (sheet 08c)

Implementasi `ActiveTournament.capacityAhead` (test `test/services/resume_tournament_test.dart`): sisa = max(0, booking − n × durasi); k per court = ⌊(sisa + tambahan) ÷ durasi⌋;
round = k terbesar; match = Σ min(court dengan k ≥ r, ⌊aktif ÷ 4⌋). "Court berkurang mulai R…" (`fewerCourtsFrom`)
hanya untuk court yang main di R(n+1) lalu habis di tengah; court yang sejak awal tidak dapat tambahan bukan "berkurang"
(bug kode lama, sudah diperbaiki).
Data test 08c: durasi 15, n = 8, Court 1 +1 jam, Court VIP +0, 10 pemain → 4 round (R9–R12), 1 court, 4 match.

## 8. Label round

Tidak ada nomor round yang ditulis tetap. Tabel lengkap (n = `roundCount`, c = `currentRound`, k = tab, m =
`match.roundNumber`, p = round yang punya match selesai/WO) ada di hi-fi → Fondasi → "Label round: selalu dinamis".

## 9. Bagikan

- Nomor "#n". Peringkat 1 (semua yang bernomor 1) diberi lencana emas `#E3B341` bertulisan ink.
- Lengkap: Feed 1:1 sampai 10 baris satu kolom; 11–20 dua kolom rata, ⌈n/2⌉ kiri, urut ke bawah dulu, baris kiri-kanan
  sejajar (grid ⌈n/2⌉ baris tetap). Dua kolom: baris hanya nama + nilai. Story 9:16 satu kolom sampai 20 baris.
- Fixed menghitung "pasangan" ("Semua 10 pasangan", "+n pasangan lainnya").
