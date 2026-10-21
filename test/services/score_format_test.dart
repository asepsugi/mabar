import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/core/app_version.dart';
import 'package:mabar/models/models.dart';
import 'package:mabar/services/scoring/score_entry.dart';
import 'package:mabar/services/storage/tournament_codec.dart';

/// Format skor desain v2 (design/spec/logic.md §1–§2): Race to N, Best of N, Americano N, dan
/// simpanan app lama yang tidak dimuat. Angka = frame 07a–07k.

const race6 = ScoreFormat(ScoringMethod.raceTo, 6);
const race9 = ScoreFormat(ScoringMethod.raceTo, 9);
const bestOf5 = ScoreFormat(ScoringMethod.bestOf, 5);
const bestOf6 = ScoreFormat(ScoringMethod.bestOf, 6);
const americano21 = ScoreFormat(ScoringMethod.americano, 21);
const americano24 = ScoreFormat(ScoringMethod.americano, 24);

String? _message(ScoreFormat f, int a, int b) => switch (ScoreRules.judge(f, a, b)) {
  ScoreInvalid(:final message) => message,
  _ => null,
};

/// Tombol angka yang aktif.
List<int> _keys(ScoreEntry e) => [for (var d = 0; d <= 9; d++) if (e.canType(d)) d];

ScoreEntry _typeAll(ScoreEntry e, List<int> digits) => digits.fold(e, (e, d) => e.type(d));

TournamentConfig _config(ScoreFormat format) => TournamentConfig(
  sport: SportType.padel,
  mode: PartnerMode.mixed,
  matchDurationMinutes: 15,
  courts: const [Court(id: 'c1', name: 'Court 1', colorIndex: 0, bookingDurationMinutes: 60)],
  players: const [Player(id: 'a', name: 'Andi')],
  format: format,
);

void main() {
  group('format', () {
    test('default Race to 6 untuk kedua olahraga', () {
      expect(ScoreFormat.standard, race6);
      expect(_config(ScoreFormat.standard).format.label, 'Race to 6');
    });

    test('batas N per format; ketikan di luar batas dikembalikan ke batas terdekat', () {
      expect((ScoringMethod.raceTo.minTarget, ScoringMethod.raceTo.maxTarget, ScoringMethod.raceTo.defaultTarget), (2, 9, 6));
      expect((ScoringMethod.bestOf.minTarget, ScoringMethod.bestOf.maxTarget, ScoringMethod.bestOf.defaultTarget), (1, 15, 5));
      expect(
        (ScoringMethod.americano.minTarget, ScoringMethod.americano.maxTarget, ScoringMethod.americano.defaultTarget),
        (2, 99, 21),
      );
      expect(race6.withTarget(12), race9);
      expect(americano21.withTarget(1).target, 2);
      expect(const ScoreFormat(ScoringMethod.americano, 100).isValid, isFalse);
    });

    test('label, satuan, dan kemungkinan seri', () {
      expect([race6.label, bestOf5.label, americano21.label], ['Race to 6', 'Best of 5', 'Americano 21']);
      expect([race6.unit, bestOf5.unit, americano21.unit], ['game', 'game', 'poin']);
      expect([race6.canDraw, bestOf5.canDraw, bestOf6.canDraw, americano21.canDraw, americano24.canDraw], [
        false,
        false,
        true,
        false,
        true,
      ]);
    });

    test('skor menang terkecil ⌊N ÷ 2⌋ + 1', () {
      expect([americano21.minWinningScore, americano24.minWinningScore, bestOf5.minWinningScore, bestOf6.minWinningScore], [
        11,
        13,
        3,
        4,
      ]);
    });

    test('durasi match selalu kelipatan 5, minimal 5', () {
      expect([22, 23, 20, 2, 0, 47, 48].map(TournamentConfig.roundDuration), [20, 25, 20, 5, 5, 45, 50]);
    });

    test('format tidak hilang saat config disalin (pasangan Fixed, tambah pemain)', () {
      final config = _config(americano24);
      expect(config.copyWith(fixedPairs: const []).format, americano24);
      expect(config.copyWith(players: const []).format, americano24);
    });
  });

  group('codec', () {
    ActiveTournament active(ScoreFormat format) =>
        ActiveTournament(tournament: Tournament(id: 't', createdAt: DateTime(2026, 10, 21), config: _config(format)));

    test('format baru tersimpan dan terbaca lagi', () {
      for (final f in [race6, bestOf6, americano24]) {
        expect(TournamentCodec.decode(TournamentCodec.encode(active(f)))!.config.format, f);
      }
    });

    test('simpanan app lama (skema 1, tanpa versi app) tidak dimuat', () {
      final encoded = TournamentCodec.encode(active(americano24));
      expect(encoded, contains('"schema":2,"appVersion":"$appVersion"'));

      final v1 = encoded.replaceFirst('"schema":2,"appVersion":"$appVersion"', '"schema":1');
      expect(TournamentCodec.decode(v1), isNull);
      final noVersion = encoded.replaceFirst(',"appVersion":"$appVersion"', '');
      expect(TournamentCodec.decode(noVersion), isNull);
    });

    test('appVersion sama dengan version di pubspec.yaml', () {
      final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
      expect(line.substring('version:'.length).trim().split('+').first, appVersion);
    });
  });

  group('skor akhir', () {
    test('Race to 6: diterima 6–0, 6–5, 7–5, 7–6 (7–6 = tie-break), di kedua sisi', () {
      for (final (a, b) in [(6, 0), (6, 5), (7, 5), (7, 6), (0, 6), (5, 7)]) {
        expect(ScoreRules.judge(race6, a, b), isA<ScoreWin>(), reason: '$a–$b');
      }
      expect((ScoreRules.judge(race6, 7, 6) as ScoreWin).tieBreak, isTrue);
      expect((ScoreRules.judge(race6, 7, 5) as ScoreWin).tieBreak, isFalse);
      final win = ScoreRules.judge(race6, 4, 6) as ScoreWin;
      expect((win.winnerSide, win.winnerScore, win.loserScore), (2, 6, 4));
    });

    test('Race to 6: ditolak dengan pesan frame 07d', () {
      expect(_message(race6, 6, 6), '6–6 belum selesai. Isi skor akhir, mis. 7–6');
      expect(_message(race6, 5, 3), 'Belum ada yang sampai 6');
      for (final (a, b) in [(7, 3), (7, 4), (7, 7)]) {
        expect(_message(race6, a, b), 'Skor akhir race to 6: 6–0 sampai 6–5, atau 7–5 / 7–6', reason: '$a–$b');
      }
    });

    test('Best of / Americano: total harus pas, seri hanya kalau genap', () {
      expect(ScoreRules.judge(bestOf5, 3, 2), isA<ScoreWin>());
      expect(ScoreRules.judge(bestOf6, 3, 3), isA<ScoreDraw>());
      expect(ScoreRules.judge(americano24, 12, 12), isA<ScoreDraw>());
      expect(ScoreRules.judge(americano21, 13, 8), isA<ScoreWin>());
      expect(_message(americano21, 13, 9), 'Total poin harus 21');
      expect(_message(bestOf5, 3, 3), 'Total game harus 5');
    });
  });

  group('keypad', () {
    test('Race to 6 kosong: 8 dan 9 mati (07a, 07k)', () {
      expect(_keys(ScoreEntry.start(race6)), [0, 1, 2, 3, 4, 5, 6, 7]);
    });

    test('Race to 9: setelah "1" hanya 0 yang aktif', () {
      expect(_keys(ScoreEntry.start(race9).type(1)), [0]);
    });

    test('Americano 21: setelah "2" hanya 0 dan 1, lawan terisi otomatis (07h)', () {
      final e = ScoreEntry.start(americano21).type(2);
      expect(_keys(e), [0, 1]);
      expect((e.side1, e.side2, e.autoSide), (2, 19, 2));
      expect((e.score?.side1, e.score?.side2), (2, 19), reason: 'satu sisi diketik sudah sah');
      final e21 = e.type(1);
      expect((e21.side1, e21.side2), (21, 0));
      expect(_keys(e21), isEmpty);
    });

    test('Race to: digit penuh → kursor pindah ke kotak lawan yang kosong; 0 tidak diberi digit kedua', () {
      final afterSeven = ScoreEntry.start(race6).type(7);
      expect((afterSeven.side1, afterSeven.active), (7, 2));
      final afterZero = ScoreEntry.start(race6).type(0);
      expect((afterZero.side1, afterZero.active), (0, 2));
      // Race to 9 (maks 10): setelah "4" tidak ada digit lagi, setelah "1" masih bisa jadi 10.
      expect(ScoreEntry.start(race9).type(4).active, 2);
      expect(ScoreEntry.start(race9).type(1).active, 1);
    });

    test('Race to tidak mengisi otomatis; kombinasi dicek setelah dua kotak terisi', () {
      final one = ScoreEntry.start(race6).type(6);
      expect(one.side2, isNull);
      expect(one.verdict, isNull, reason: 'satu sisi kosong: Simpan mati tanpa pesan');
      final both = one.type(6);
      expect(both.verdict, isA<ScoreInvalid>());
      expect(both.score, isNull);
      expect(_typeAll(ScoreEntry.start(race6), [6, 4]).score?.side2, 4);
    });

    test('tombol tidak dimatikan karena isi lawan: 6–4 dikoreksi jadi 7–5 tanpa menghapus', () {
      var e = _typeAll(ScoreEntry.start(race6), [6, 4]);
      e = e.select(1);
      expect(e.canType(7), isTrue);
      e = e.type(7).select(2).type(5);
      expect((e.side1, e.side2), (7, 5));
      expect(e.verdict, isA<ScoreWin>());
    });

    test('Best of 5: tombol 6–9 mati; mengetik di sisi otomatis mengisi ulang sisi pertama (07e)', () {
      var e = ScoreEntry.start(bestOf5);
      expect(_keys(e), [0, 1, 2, 3, 4, 5]);
      e = e.type(3);
      expect((e.side1, e.side2, e.autoSide), (3, 2, 2));
      e = e.select(2).type(4);
      expect((e.side1, e.side2, e.autoSide), (1, 4, 1));
    });

    test('hapus: Best of/Americano mengosongkan sisi otomatis juga', () {
      var e = ScoreEntry.start(americano21).type(1).type(3);
      expect((e.side1, e.side2), (13, 8));
      e = e.backspace();
      expect((e.side1, e.side2), (1, 20));
      e = e.backspace();
      expect((e.side1, e.side2, e.autoSide), (null, null, null));
    });

    test('skor tersimpan dibuka: terisi, belum ada kotak aktif (07i)', () {
      final e = ScoreEntry.edit(race6, const SetScore(side1: 6, side2: 4));
      expect(e.active, isNull);
      expect(_keys(e), isEmpty);
      expect(e.score?.side1, 6);
      expect(e.next().active, 1);
    });
  });
}
