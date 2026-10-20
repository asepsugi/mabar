import '../../models/models.dart';

/// Hasil generate jadwal mode Fixed.
class FixedSchedule {
  final List<MatchGame> matches;

  /// Pair yang bye, per nomor round. Kosong kalau jumlah pair genap.
  final Map<int, String> byePairIdByRound;

  const FixedSchedule({required this.matches, required this.byePairIdByRound});

  int get roundCount => matches.isEmpty ? 0 : matches.last.roundNumber;
}

/// Round-robin mode Fixed dengan circle method.
///
/// Circle method menghasilkan "putaran" berisi `pairs/2` pertandingan yang
/// semuanya bisa jalan bersamaan. Karena jumlah court biasanya lebih sedikit,
/// tiap putaran dipotong lagi menjadi beberapa round jadwal sebesar jumlah
/// court — sesuai definisi round di PRD: satu batch yang memakai semua court
/// sekali. Pemotongan tidak pernah menggabungkan dua putaran, jadi satu pair
/// tidak mungkin dijadwalkan di dua lapangan pada round yang sama.
class RoundRobinGenerator {
  static FixedSchedule generate({required List<Pair> pairs, required List<Court> courts}) {
    if (pairs.length < 2 || courts.isEmpty) {
      return const FixedSchedule(matches: [], byePairIdByRound: {});
    }

    final matches = <MatchGame>[];
    final byeByRound = <int, String>{};
    var roundNumber = 0;

    for (final circleRound in _circleRounds(pairs)) {
      for (var i = 0; i < circleRound.games.length; i += courts.length) {
        final slice = circleRound.games.skip(i).take(courts.length).toList();
        roundNumber++;
        if (circleRound.bye != null) byeByRound[roundNumber] = circleRound.bye!.id;

        for (var j = 0; j < slice.length; j++) {
          matches.add(
            MatchGame(
              id: 'm-r$roundNumber-${j + 1}',
              roundNumber: roundNumber,
              matchNumberInRound: j + 1,
              courtId: courts[j].id,
              pair1: slice[j].$1,
              pair2: slice[j].$2,
            ),
          );
        }
      }
    }

    return FixedSchedule(matches: matches, byePairIdByRound: byeByRound);
  }

  /// Putaran circle method: tiap putaran berisi pertandingan yang saling lepas.
  static Iterable<_CircleRound> _circleRounds(List<Pair> pairs) sync* {
    // Pair dummy (null) dipakai kalau jumlahnya ganjil — lawannya berarti bye.
    final slots = <Pair?>[...pairs];
    if (slots.length.isOdd) slots.add(null);
    final n = slots.length;

    var arrangement = [...slots];
    for (var round = 0; round < n - 1; round++) {
      final games = <(Pair, Pair)>[];
      Pair? bye;

      for (var i = 0; i < n ~/ 2; i++) {
        final a = arrangement[i];
        final b = arrangement[n - 1 - i];
        if (a == null || b == null) {
          bye = a ?? b;
          continue;
        }
        games.add((a, b));
      }
      yield _CircleRound(games, bye);

      // Putar semua kecuali elemen pertama.
      arrangement = [arrangement.first, arrangement.last, ...arrangement.sublist(1, n - 1)];
    }
  }
}

class _CircleRound {
  final List<(Pair, Pair)> games;
  final Pair? bye;
  const _CircleRound(this.games, this.bye);
}
