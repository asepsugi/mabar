import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mabar/models/models.dart';
import 'package:mabar/services/ranking/ranking_calculator.dart';
import 'package:mabar/services/share/result_text_builder.dart';

const _players = [
  Player(id: 'a', name: 'Andi P'),
  Player(id: 'b', name: 'Budi S'),
  Player(id: 'c', name: 'Citra L'),
  Player(id: 'd', name: 'Dewi R'),
];

const _ab = Pair(id: 'ab', player1Id: 'a', player2Id: 'b');
const _cd = Pair(id: 'cd', player1Id: 'c', player2Id: 'd');

Tournament _tournament(List<MatchGame> matches) => Tournament(
      id: 't1',
      createdAt: DateTime(2026, 9, 14),
      config: const TournamentConfig(
        sport: SportType.padel,
        mode: PartnerMode.fixed,
        matchDurationMinutes: 15,
        courts: [Court(id: 'c1', name: 'Court 1', colorIndex: 0, bookingDurationMinutes: 120)],
        players: _players,
        fixedPairs: [_ab, _cd],
      ),
      matches: matches,
    );

MatchGame _match({
  required MatchStatus status,
  List<SetScore> sets = const [],
  String? woLoser,
  int round = 1,
}) =>
    MatchGame(
      id: 'm$round',
      roundNumber: round,
      matchNumberInRound: 1,
      courtId: 'c1',
      pair1: _ab,
      pair2: _cd,
      sets: sets,
      status: status,
      woLoserPairId: woLoser,
    );

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  group('ResultTextBuilder', () {
    final matches = [
      _match(status: MatchStatus.done, sets: const [SetScore(side1: 6, side2: 4)]),
      _match(status: MatchStatus.wo, woLoser: 'cd', round: 2),
      _match(status: MatchStatus.pending, round: 3),
    ];
    final tournament = _tournament(matches);
    final standings = standingEntries(
      standings: RankingCalculator.rank(
        players: _players,
        matches: matches,
        method: RankingMethod.winPercent,
      ),
    );

    test('ringkas lists every player once, without per-round detail', () {
      final text = ResultTextBuilder.build(
        tournament: tournament,
        standings: standings,
        format: ShareFormat.ringkas,
      );

      expect(text, contains('Mabar Turnamen · Padel'));
      expect(text, contains('Peringkat Akhir'));
      for (final p in _players) {
        expect(text, contains(p.name));
      }
      expect(text, isNot(contains('Hasil per Round')));
      // Total point ikut dibagikan, bukan cuma win%.
      expect(text, contains('${standings.first.standing.totalPoint} poin'));
    });

    test('lengkap adds per-round results and skips unplayed matches', () {
      final text = ResultTextBuilder.build(
        tournament: tournament,
        standings: standings,
        format: ShareFormat.lengkap,
      );

      expect(text, contains('Hasil per Round'));
      expect(text, contains('· Round 1'));
      expect(text, contains('6-4'));
      expect(text, contains('WO'));
      expect(text, isNot(contains('· Round 3')));
    });

    test('summary line counts rounds, played matches and WO', () {
      expect(
        ResultTextBuilder.summaryLine(tournament),
        '3 round · 2 match · 1 WO · 14 Sep 2026',
      );
    });

    test('summary line omits WO when there is none', () {
      final clean = _tournament([
        _match(status: MatchStatus.done, sets: const [SetScore(side1: 6, side2: 0)]),
      ]);
      expect(ResultTextBuilder.summaryLine(clean), '1 round · 1 match · 14 Sep 2026');
    });
  });
}
