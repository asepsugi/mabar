import 'package:flutter/foundation.dart';

import '../../models/models.dart';

/// Hasil pemeriksaan skor satu match (pesan di bawah papan skor Input Skor, frame 07b–07h).
sealed class ScoreVerdict {
  const ScoreVerdict();
}

/// Skor sah dengan pemenang. Sisi 1 = `pair1`, 2 = `pair2`.
class ScoreWin extends ScoreVerdict {
  final int winnerSide;
  final int winnerScore;
  final int loserScore;

  /// Race to N yang berakhir N+1 lawan N (7–6): ditulis "(tie-break)".
  final bool tieBreak;

  const ScoreWin({required this.winnerSide, required this.winnerScore, required this.loserScore, this.tieBreak = false});
}

/// Skor sah dan seri — hanya mungkin di format yang [ScoreFormat.canDraw].
class ScoreDraw extends ScoreVerdict {
  const ScoreDraw();
}

/// Skor tidak sah; Simpan mati dan [message] ditampilkan.
class ScoreInvalid extends ScoreVerdict {
  final String message;
  const ScoreInvalid(this.message);
}

/// Aturan skor akhir per format (`design/spec/logic.md` §1).
class ScoreRules {
  /// Memeriksa skor [side1]–[side2] satu match. Untuk format lama ([ScoringMethod.legacySets]) yang
  /// diperiksa satu set: harus ada pemenang.
  static ScoreVerdict judge(ScoreFormat format, int side1, int side2) {
    final n = format.target;
    switch (format.method) {
      case ScoringMethod.raceTo:
        final high = side1 > side2 ? side1 : side2;
        final low = side1 > side2 ? side2 : side1;
        if (side1 == side2 && side1 == n) return ScoreInvalid('$n–$n belum selesai. Isi skor akhir, mis. ${n + 1}–$n');
        if (high < n) return ScoreInvalid('Belum ada yang sampai $n');
        final valid = (high == n && low < n) || (high == n + 1 && (low == n - 1 || low == n));
        if (!valid) {
          return ScoreInvalid('Skor akhir race to $n: $n–0 sampai $n–${n - 1}, atau ${n + 1}–${n - 1} / ${n + 1}–$n');
        }
        return _win(side1, side2, tieBreak: high == n + 1 && low == n);
      case ScoringMethod.bestOf:
      case ScoringMethod.americano:
        if (side1 + side2 != n) return ScoreInvalid('Total ${format.unit} harus $n');
        return side1 == side2 ? const ScoreDraw() : _win(side1, side2);
      case ScoringMethod.legacySets:
        return side1 == side2 ? const ScoreInvalid('Skor seri, harus ada pemenang') : _win(side1, side2);
    }
  }

  static ScoreWin _win(int side1, int side2, {bool tieBreak = false}) => side1 > side2
      ? ScoreWin(winnerSide: 1, winnerScore: side1, loserScore: side2, tieBreak: tieBreak)
      : ScoreWin(winnerSide: 2, winnerScore: side2, loserScore: side1, tieBreak: tieBreak);
}

/// Isi papan skor Input Skor: dua kotak (sisi 1 = `pair1`, 2 = `pair2`), kotak aktif, dan aturan keypad
/// (`design/spec/logic.md` §2, frame 07a–07k). Hanya untuk format satu skor per match; format lama
/// tidak diisi lewat keypad ini.
@immutable
class ScoreEntry {
  final ScoreFormat format;
  final int? side1;
  final int? side2;

  /// Kotak yang menerima ketikan; null = belum ada (skor tersimpan dibuka, 07i).
  final int? active;

  /// Sisi yang diisi otomatis `N − x` (Best of, Americano), ditampilkan pudar.
  final int? autoSide;

  /// Ketikan berikutnya mengganti isi kotak aktif, bukan menambah digit. Benar setelah kotak dipilih
  /// (ketuk, →, atau pindah otomatis), supaya salah ketik 6–4 bisa langsung diganti 7 tanpa menghapus.
  final bool _replaceNext;

  const ScoreEntry._(this.format, this.side1, this.side2, this.active, this.autoSide, this._replaceNext);

  /// Match baru: dua kotak kosong, kotak tim pertama aktif.
  factory ScoreEntry.start(ScoreFormat format) => ScoreEntry._(format, null, null, 1, null, true);

  /// Skor tersimpan dibuka lagi: terisi, belum ada kotak aktif sampai diketuk.
  factory ScoreEntry.edit(ScoreFormat format, SetScore score) =>
      ScoreEntry._(format, score.side1, score.side2, null, null, true);

  int? valueOf(int side) => side == 1 ? side1 : side2;

  static int _other(int side) => side == 1 ? 2 : 1;

  /// Tombol angka [digit] aktif kalau hasilnya tidak melewati [ScoreFormat.maxPerSide]. Sengaja tidak
  /// melihat isi kotak lawan (koreksi 6–4 → 7–5 harus bisa tanpa mengubah lawan dulu).
  bool canType(int digit) {
    final side = active;
    if (side == null) return false;
    final next = _typed(valueOf(side), digit);
    return next != null && next <= format.maxPerSide;
  }

  /// Nilai kotak setelah [digit] diketik; null kalau kotak sudah penuh (0 tidak diberi digit kedua).
  int? _typed(int? current, int digit) {
    if (_replaceNext || current == null) return digit;
    if (current == 0) return null;
    return current * 10 + digit;
  }

  ScoreEntry type(int digit) {
    final side = active;
    if (side == null || !canType(digit)) return this;
    final value = _typed(valueOf(side), digit)!;
    var entry = _set(side, value);

    // Tidak ada digit lagi yang mungkin → kursor pindah sendiri ke kotak lawan yang masih kosong.
    final full = !List.generate(10, (d) => d).any(entry.canType);
    if (full && entry.valueOf(_other(side)) == null) entry = entry.select(_other(side));
    return entry;
  }

  ScoreEntry backspace() {
    final side = active;
    final current = side == null ? null : valueOf(side);
    if (side == null || current == null) return this;
    return _set(side, current < 10 ? null : current ~/ 10);
  }

  /// Memilih kotak (ketuk kotak, atau → ke tim lawan).
  ScoreEntry select(int side) => ScoreEntry._(format, side1, side2, side, autoSide, true);

  ScoreEntry next() => select(_other(active ?? 2));

  /// Mengisi [side] dengan [value]; Best of & Americano sekalian mengisi lawan `N − x` (atau
  /// mengosongkannya kalau [value] dihapus dan lawan memang terisi otomatis).
  ScoreEntry _set(int side, int? value) {
    var one = side == 1 ? value : side1;
    var two = side == 2 ? value : side2;
    var auto = autoSide == side ? null : autoSide;
    if (format.fillsOpponent) {
      final other = _other(side);
      if (value != null) {
        final complement = format.target - value;
        if (other == 1) {
          one = complement;
        } else {
          two = complement;
        }
        auto = other;
      } else if (autoSide == other) {
        if (other == 1) {
          one = null;
        } else {
          two = null;
        }
        auto = null;
      }
    }
    return ScoreEntry._(format, one, two, active, auto, false);
  }

  /// Null selama salah satu kotak kosong: Simpan mati tanpa pesan (host sedang mengetik).
  ScoreVerdict? get verdict {
    final a = side1, b = side2;
    if (a == null || b == null) return null;
    return ScoreRules.judge(format, a, b);
  }

  /// Skor yang siap disimpan, atau null kalau belum lengkap/tidak sah.
  SetScore? get score => switch (verdict) {
    ScoreWin() || ScoreDraw() => SetScore(side1: side1!, side2: side2!),
    _ => null,
  };
}
