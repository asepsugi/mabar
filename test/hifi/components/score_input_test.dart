import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/core/theme/mabar_theme.dart';
import 'package:mabar/features/score_input/widgets/score_board.dart';
import 'package:mabar/models/models.dart';
import 'package:mabar/services/scoring/score_entry.dart';

import '../hifi_golden.dart';

/// Golden ScoreBoard + ScoreKeypad. Isi papan dibuat lewat ketikan [ScoreEntry] yang sama dengan yang
/// dilakukan host, bukan disusun tangan.
///
/// Keypad hanya dibandingkan di 07h dan 07k: frame Input Skor lain (07a–07g) tidak menggambar tombol
/// mati, padahal aturannya (catatan 07k, logic.md §2) mematikan 8 dan 9 di Race to 6 kosong.
void main() {
  final theme = MabarTheme.light();
  const race6 = ScoreFormat(ScoringMethod.raceTo, 6);
  const americano21 = ScoreFormat(ScoringMethod.americano, 21);

  ScoreEntry typed(ScoreFormat f, List<int> digits) => digits.fold(ScoreEntry.start(f), (e, d) => e.type(d));

  for (final (frame, entry, names) in [
    // 07b: 6 lalu 4 — kursor tetap di kotak kedua.
    ('07b', typed(race6, [6, 4]), ('Eko\nFajar', 'Gina\nHana')),
    // 07k: "4" penuh di Race to 6, kursor pindah ke kotak kedua yang kosong.
    ('07k', typed(race6, [4]), ('Eko\nFajar', 'Gina\nHana')),
    // 07h: "2" di Americano 21, lawan terisi 19 dan menang.
    ('07h', typed(americano21, [2]), ('Andi\nDewant', 'Citra\nFajar')),
  ]) {
    testWidgets('ScoreBoard ($frame)', (tester) async {
      final at = hifiRect(frame, 'board');
      await expectRegionMatchesHifi(
        tester,
        hifiStage(theme: theme, at: at, child: ScoreBoard(entry: entry, names: names, onSelect: (_) {})),
        frame,
        at,
        label: 'board',
      );
    });
  }

  for (final (frame, entry) in [('07k', typed(race6, [4])), ('07h', typed(americano21, [2]))]) {
    testWidgets('ScoreKeypad: tombol di atas batas mati ($frame)', (tester) async {
      final at = hifiRect(frame, 'keypad');
      await expectRegionMatchesHifi(
        tester,
        hifiStage(theme: theme, at: at, child: ScoreKeypad(entry: entry, onChanged: (_) {})),
        frame,
        at,
        label: 'keypad',
      );
    });
  }
}
