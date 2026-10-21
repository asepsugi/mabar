# PRD — Aplikasi Mabar Tennis/Padel (Klub/Komunitas)

**Versi:** 1.0 (MVP)
**Platform:** Android + iOS (1 codebase — Flutter)
**Target user:** Klub/komunitas tennis & padel, 4–20 peserta per turnamen

---

## 1. Ringkasan Eksekutif

Aplikasi mobile untuk host turnamen mabar (round-robin) yang:

- Mengundikan pasangan (mode Fixed & Mixed)
- Membuat jadwal pertandingan adil (setiap orang main sama banyak, lawan merata)
- Mencatat skor pertandingan (game score: `6-4, 6-3` dst)
- Menentukan ranking berdasarkan win% / total skor / kombinasi
- Handling skip/WO (walkover)
- Export & share hasil akhir (text / image)

---

## 2. Rekomendasi Teknologi

**Flutter** — 1 codebase Android + iOS.

Alasan:
- Performa UI interaktif (kartu pasangan, tabel jadwal, leaderboard) lebih mudah tanpa native bridge
- Paket `fl_chart` untuk statistik, `share_plus` + `screenshot` untuk export
- Dart untuk algoritma pairing cukup matang, tanpa overhead JS bridge

---

## 3. Alur Fitur Utama

### 3.1 User Flow

```
[Home] → [Input Peserta] → [Konfigurasi Turnamen]
                             (Mode + Court + Target Match)
    ↓                        ↓
[Jadwal] ← [Generate]    [Fixed: buat pair / Mixed: langsung generate]
    ↓
[Input Skor per pertandingan] ←→ [Skip/WO]
    ↓
[Leaderboard Live] → [Share Hasil]
```

### 3.0 Terminologi

- **Match** = 1 laga antar 2 sisi (misal `Andi+Citra vs Budi+Dewant`).
- **Round** = 1 batch dimana semua court dipakai sekali paralel. Total round = `ceil(total_match / jumlah_court)`.
- **Court** = lapangan fisik. Setiap match berjalan di 1 court. Jumlah court = kapasitas paralel per round.

### 3.2 Mode Partner

#### A. Fixed Partner (Pasangan Tetap)

- User input N peserta, lalu buat pair manual (misal A+B, C+D, dst).
- Sistem jalankan round-robin antar pair: setiap pair bertemu semua pair lain.
- Jika jumlah pair ganjil, ada 1 pair *bye* per round.

Keterbatasan: dalam fixed mode, "setiap orang bertemu semua orang" secara individu **tidak tercapai** — A hanya bertemu lawan-lawan yang dipasangkan dengan B. Fairness di sini adalah fairness antar pasangan, bukan individu.

#### B. Mixed Partner (Pasangan Berganti)

- Sistem mengacak pasangan setiap round dengan constraint:
  - (a) Tidak ada pair yang bertemu lagi (dari history)
  - (b) Tidak ada orang yang bertemu partner yang sama berulang
  - (c) Distribusi lawan merata
- Untuk n <= 12: bisa generate dengan backtracking sederhana.
- Untuk n > 12: pakai greedy + constraint check, reject & retry.
- User tentukan jumlah round (misal 5, 7, 10) atau pilih "auto-max".

**Realistis untuk n=16–20:**
- 5 round → ~5 partner unik per orang (dari 19 kemungkinan)
- 7 round → ~7 partner unik, ~11 lawan unik
- 10 round → semakin dekat ke coverage lengkap, tapi total pertandingan = N×round/2 = 100 pertandingan untuk n=20

### 3.3 Algoritma Round-Robin (Fixed Mode)

Standar circle method — total match & round dihitung di awal, tapi host bisa stop kapan saja.

```
function generateRoundRobin(pairs):
    n = pairs.length
    if n ganjil: tambah dummy "bye" pair
    fixed = pairs[0]
    rotate = pairs[1..n-1]
    
    for round in 0..n-2:
        matches = []
        matches.append(fixed vs rotate[last])
        for i in 0..(n/2 - 2):
            matches.append(rotate[i] vs rotate[n-2-i])
        rotate = [rotate[last]] + rotate[0..last-1]
        yield matches
```

### 3.4 Algoritma Endless Mode (Mixed) — Fair Generation

Tidak ada target match di setup. Sistem generate 1 round awal, host tekan "Generate Round Berikutnya" untuk lanjut.

**Setiap generate round baru:**

```
function generateNextRound(players, history, courts):
    capacity = courts.length × 4  // doubles = 4 pemain per match
    
    // STEP 1: pilih pemain prioritas
    sorted = players.sortBy(
        matchCount ASC,        // paling sedikit main = prioritas tertinggi
        lastRoundPlayed ASC,   // paling lama istirahat = tie-breaker
        random()               // tie-breaker terakhir
    )
    active = sorted.take(capacity)
    resting = sorted.skip(capacity)  // bye di round ini
    
    // STEP 2: generate pairing dari pemain aktif
    for attempt in 0..maxAttempts:
        pairs = shuffleAndPair(active)
        if isValid(pairs, history):
            break
    if !valid: relaxConstraint & retry
    
    // STEP 3: assign match ke court
    matches = []
    for i, matchPair in pairs.chunked(2):
        matches.append({
            pair1: matchPair[0],
            pair2: matchPair[1],
            court: courts[i % courts.length]
        })
    
    return { matches, resting }
```

**Properti fairness:**
- Selisih match count antar pemain **≤ 1 setiap saat**
- Pemain bye di round ini otomatis prioritas #1 di round berikutnya
- Rest time seimbang (delta max 1 round juga)

**Constraint pairing (relax berurutan kalau tidak ada solusi):**
1. Hard: pair yang persis sama tidak muncul lagi
2. Soft: hindari partner yang sudah pernah berpasangan
3. Soft: hindari lawan yang sudah pernah dihadapi

---

## 4. Definisi Skor & Sistem Penilaian

### 4.1 Format Skor

Input: skor per set, dipisahkan koma.

Contoh:
- `6-4, 6-3` → 2 set, pemain menang
- `6-3` → 1 set
- `6-7, 6-4, 6-3` → 3 set

### 4.2 Metode Ranking

| Metode | Cara Hitung | Kapan Cocok |
|--------|-------------|-------------|
| **Win%** | Menang = 1, Seri = 0.5, Kalah = 0 | Jumlah pertandingan tidak sama |
| **Total Games Won** | Total games dimenangkan | Semua main sama banyak |
| **Kombinasi (rekomendasi)** | Win% utama, total games tie-breaker | Paling adil untuk klub |

### 4.3 Tie-Breaker Hierarchy

1. Metode utama
2. Total games won
3. Head-to-head
4. Game differential
5. Random / draw

### 4.4 Skip / Walkover (WO)

**Alur:**
1. Host tap tombol WO di halaman Input Skor
2. Muncul modal bottom-sheet "Tandai Walkover"
3. Host pilih pasangan mana yang WO (radio button, salah satu pair)
4. Pair sebelah otomatis ditandai sebagai pemenang
5. (Opsional) pilih alasan: Absen / Injury / Waktu habis / Lainnya
6. Konfirmasi → match tercatat sebagai `WO — {pemenang} menang` di jadwal & leaderboard

**Impact:**
- Lawan (pair yang tetap main) → menang, +1 match count, +1 W di record
- Pair WO → kalah, +1 match count, +1 L di record
- Total Point pemenang WO ikut format skor (keputusan host 2026-10-21; dulu "games WO tidak dihitung",
  yang merugikan pemenang WO sejak Total Point jadi metode default):
  - Race to N → pemenang dapat N game (sama dengan hasil menang biasa, yang selalu N)
  - Best of N & Americano → rata-rata game/poin dari match yang benar-benar dia mainkan, dibulatkan ke
    bilangan bulat terdekat (,5 ke atas), tapi tidak pernah di bawah skor menang terkecil = ⌊total ÷ 2⌋ + 1
    (Americano 21 → 11, Americano 24 → 13, Best of 5 → 3, Best of 6 → 4); belum pernah main → skor menang terkecil.
    Batas bawah ini supaya "menang" WO tidak bernilai skor yang di Input Skor dianggap kalah.
    Bukan skor penuh, karena di format bertotal tetap skor penuh = hasil maksimal (menang WO jadi lebih untung daripada main)
- Pair WO → 0 game/poin
- Selisih game/poin tidak berubah untuk kedua pair (tidak ada skor yang dimainkan)
- Alasan WO tersimpan di detail match (opsional, hanya untuk histori)

### 4.5 Late Entry

- Peserta baru main dari round berikutnya
- Jumlah pertandingan lebih sedikit → otomatis fair di win%

---

## 5. Feature List — MVP

### Setup
- [ ] **Pilih Jenis Permainan** (Home screen): Tennis atau Padel — tidak ada default, wajib pilih untuk lanjut ke setup
  - Ditampilkan sebagai 2 tombol besar dengan siluet raket masing-masing
  - Jenis permainan menentukan **default durasi per match**: Tennis 20 menit, Padel 15 menit
  - Badge jenis permainan tampil di setiap match card di halaman jadwal
  - Siluet raket ditampilkan sebagai watermark di share card (kanan bawah)
- [ ] Input nama peserta via textarea (multiline, 1 baris = 1 pemain)
  - Parser otomatis trim: hapus nomor urut (`1.`, `2)`, `03 -`), bullet (`-`, `*`, `•`), whitespace
  - Paste dari clipboard langsung
  - Preview live: jumlah pemain terdeteksi + nama-nama tervalidasi
  - Validasi: min 4, maks 20, tolak duplikat
- [ ] Pilih mode Fixed / Mixed
- [ ] **Konfigurasi court & durasi:**
  - Durasi per match (menit, wajib, default: **Tennis 20** / **Padel 15** — otomatis mengikuti jenis permainan yang dipilih di Home)
  - Jumlah court (1–10, default 2)
  - Per court: nama (placeholder "Court N", bisa diisi bebas) + durasi booking (jam, wajib, default 2) + **warna** (dipilih dari 10 warna preset, default sesuai urutan court)
  - Warna court dipakai untuk badge di jadwal & input skor supaya mudah dibedakan visual
- [ ] Sistem hitung otomatis dari input di atas:
  - Match per round = jumlah court
  - Max round = `min(durasi_booking_per_court) / durasi_per_match` × 60 (menit)
  - Estimasi match per pemain (mixed): `max_round × jumlah_court × 4 / total_pemain`
- [ ] Fixed: 2 opsi buat pair
  - **Acak Otomatis:** sistem randomize pairing (bisa acak ulang sebelum dikunci)
  - **Manual:** tap-to-assign (ketuk 2 pemain per slot)
  - Setelah tombol "Kunci Pasangan" ditekan → pairing tidak bisa diubah
- [ ] Mixed: konfirmasi mode Endless + estimasi otomatis (tidak ada input tambahan)
- [ ] Metode ranking **tidak dipilih di setup** — bisa diubah kapan saja di leaderboard (default: Kombinasi)

### Jadwal — 2 Layout Terpisah (Fixed & Mixed)

**Common (kedua mode):**
- Header: `R X/Max · ⏱ waktu_berjalan/durasi_booking` (misal "R 2/6 · 45m/2j")
- **Horizontal scroll tab** navigasi round (R1 ✓ / R2 ● / R3 / R4 ...)
- Match card dengan court badge
- Status match: kosong / selesai / WO / tidak dimainkan
- Info bye/resting players di bawah match list
- Tombol **"Selesaikan Turnamen Sekarang"** — konfirmasi → match belum dimain jadi "Tidak Dimainkan" → langsung ke leaderboard final
- Warning otomatis kalau realisasi waktu > estimasi

**Jadwal Fixed (Screen 6a):**
- Semua round di-generate sekaligus di awal (deterministik, circle method)
- Horizontal tab: semua round terlihat (R1–R7 misal), user bisa lihat preview jadwal kedepan
- Navigasi **linier/urut** — user tidak bisa main round 3 sebelum round 2 selesai (validasi di UI)
- Bye pair (kalau jumlah pair ganjil) ditampilkan per round
- **Tidak ada** tombol "Generate Round Berikutnya"

**Jadwal Mixed / Endless (Screen 6b):**
- Round digenerate on-demand
- Horizontal tab: hanya round yang sudah dijalanin (R1 ✓, R2 ●) + placeholder "R3 ?" untuk yang belum
- Round history readonly (skor bisa diedit)
- Resting players ditampilkan + info "→ Prioritas main di R berikutnya"
- Tombol **"Generate Round Berikutnya"** muncul di footer
  - Disabled kalau skor round berjalan belum lengkap
  - Disabled kalau semua court sudah habis waktu booking
- Court yang habis booking-nya di-drop dari round berikutnya

### Status Match
| Status | Definisi | Impact Ranking |
|--------|----------|----------------|
| Belum | Belum dimain, bisa diinput | — |
| Selesai | Skor sudah masuk | Masuk hitungan normal |
| WO | Pemain skip / tidak hadir | Lawan menang, pemain kalah. Masuk hitungan. |
| Tidak Dimainkan | Turnamen dihentikan sebelum match dimainkan | **Tidak dihitung sama sekali** — win% otomatis fair |

### Input Skor
- [ ] 2 kolom besar (games pemenang, games lawan)
- [ ] Add set 2, set 3
- [ ] WO button
- [ ] Undo/edit skor

### Leaderboard
- [ ] Ranking live (win%, games, record W-L, diff) — **bisa diakses kapan saja**, termasuk saat pertandingan belum selesai (leaderboard sementara)
- [ ] Indikator status: "⏱ Sementara" (belum semua match selesai) vs "🏆 Final"
- [ ] Progress bar: X dari Y pertandingan selesai
- [ ] Toggle metode ranking (Win % / Total Games / Kombinasi) langsung di halaman — ranking re-sort real-time
- [ ] Flag WO
- [ ] Detail per peserta (partner unik, lawan unik, daftar match)

### Share
- [ ] Preview teks/gambar
- [ ] Share WA / Telegram / clipboard
- [ ] Format ringkas / lengkap
- [ ] Tombol "Selesai · Kembali ke Beranda" — menutup turnamen aktif & kembali ke Home. Hasil turnamen tetap tersimpan di local storage (bisa dilihat di history pada fase mendatang)
- [ ] Hint di bawah tombol: "Hasil turnamen ini tersimpan otomatis di device"

### Penyimpanan Data
- [ ] Hasil turnamen (ranking + jadwal + skor + konfigurasi) disimpan di **local storage device** (Hive / SQLite via `sqflite`)
- [ ] Data **tidak** disinkronisasi ke cloud / server — MVP full offline
- [ ] Data akan **terhapus** hanya jika:
  - User clear cache/storage aplikasi via setting device
  - User uninstall & install ulang aplikasi
- [ ] Tombol "Selesai · Kembali ke Beranda" di halaman share **tidak** menghapus data — hanya menutup turnamen aktif; hasil tetap tersimpan sebagai turnamen terakhir
- [ ] Turnamen berjalan auto-save setiap ada perubahan (skor, pairing, round baru) — kalau app di-kill mendadak, resume dari state terakhir saat dibuka lagi
- [ ] MVP: cukup simpan 1 turnamen aktif + 1 turnamen terakhir yang selesai. History multiple turnamen = Fase 3+

---

## 6. Screen Breakdown

1. **HomeScreen** — CTA "Buat Turnamen"
2. **SetupPesertaScreen** — textarea multiline, parser auto-trim, preview live
3. **KonfigurasiScreen** — mode Fixed/Mixed + durasi per match + jumlah court + nama & durasi booking per court
4. **PairSetupScreen** (Fixed) — pool + slot pair, opsi Acak/Manual, tombol Kunci
5. **MixedConfirmScreen** (Mixed) — konfirmasi mode Endless + tabel estimasi
6a. **ScheduleFixedScreen** — horizontal tab semua round (deterministik), navigasi linier, bye pair
6b. **ScheduleMixedScreen** — horizontal tab round yang sudah dijalanin + placeholder, tombol Generate Round Berikutnya, resting players
7. **ScoreInputScreen** — input skor per match
8. **LeaderboardScreen** — ranking live dengan status "Sementara/Final" + toggle metode
9. **DetailPlayerScreen** — statistik per peserta
10. **ShareResultScreen** — preview + share

---

## 7. Design System

### Palet
```
Primary:      #16A34A  (hijau lapangan)
Primary Dark: #14532D
Surface:      #FAFAFA
Card:         #FFFFFF
Text Primary: #111827
Text Secondary: #6B7280
Border:       #E5E7EB
Danger (WO):  #EF4444
```

### Typography
- Sans-serif modern (SF Pro / Roboto)
- Heading bold, body regular

### Komponen
- **Card:** radius 12px, shadow soft, padding 16px
- **Primary Button:** #16A34A, radius 10px, height 48px
- **Secondary:** border 1.5px #E5E7EB
- **Player Chip:** #F3F4F6, radius 8px. Selected: #16A34A 15%
- **Status indicator match:**
  - Kosong: border dashed
  - Selesai: fill hijau 10%
  - WO: fill merah 10%

### Prinsip "Tanpa Petunjuk"
- No tooltip, no help icon
- Label jelas, action button self-explanatory
- State visual berbicara sendiri
- Contoh kontekstual muncul sesuai kebutuhan

---

## 8. Skala & Batasan

| Jumlah Orang | Fixed Single RR | Fixed Double RR | Mixed 7 round | Mixed 10 round |
|--------------|-----------------|-----------------|---------------|----------------|
| 4            | 1               | 2               | 2             | 2              |
| 8            | 6               | 12              | 8             | 12             |
| 12           | 15              | 30              | 12            | 18             |
| 16           | 28              | 56              | 16            | 24             |
| 20           | 45              | 90              | 20            | 30             |

Batas atas: 20 orang.

---

## 9. Fase Development

| Fase | Fitur |
|------|-------|
| MVP  | Setup + pairing + RR generation + input skor + leaderboard + share text |
| 2    | Share image + undo/edit + detail statistik |
| 3    | Save tournament + history klub |
| 4    | Double RR + tiebreak parse + late entry |

---

## 10. Keputusan Terbuka

1. Fixed: pairing sekali di awal (asumsi) atau bisa diganti per round?
2. Mixed: constraint "no repeat opponent" on/off?
3. Double round-robin untuk fixed?
4. Format share default: text (MVP) → image (Fase 2)
5. Timer per match? Skip untuk MVP.

---

## 11. Jawaban User (Dasar Keputusan)

1. Jumlah peserta maks: **16–20 orang**
2. Mode: **Fixed & Mixed sama-sama sering**
3. Skor besar = **skor pertandingan (`6-4, 6-3`)**
4. **Skip = WO** (lawan menang)
5. Device: **1 device host** (multi-device Fase 3+)
6. Save: **fitur share saja** (persistensi Fase 3)
7. Pairing berbasis skill: **tidak sekarang**, catat untuk pengembangan
8. Target user: **klub/komunitas**
