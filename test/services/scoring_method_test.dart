import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/models/models.dart';
import 'package:mabar/services/ranking/ranking_calculator.dart';
import 'package:mabar/services/storage/tournament_codec.dart';

/// Metode skor Americano (total 21 poin) di samping skor tennis.

const _players = [
  Player(id: 'a', name: 'Andi'),
  Player(id: 'b', name: 'Budi'),
  Player(id: 'c', name: 'Citra'),
  Player(id: 'd', name: 'Dewi'),
];

TournamentConfig _config(ScoringMethod scoring) => TournamentConfig(
      sport: SportType.padel,
      mode: PartnerMode.mixed,
      matchDurationMinutes: 15,
      courts: const [Court(id: 'c1', name: 'Court 1', colorIndex: 0, bookingDurationMinutes: 60)],
      players: _players,
      scoring: scoring,
    );

void main() {
  test('poin lawan = 21 dikurangi poin yang diisi', () {
    expect(ScoringMethodX.americanoComplement(13), 8);
    expect(ScoringMethodX.americanoComplement(0), 21);
    expect(ScoringMethodX.americanoComplement(21), 0);
    expect(ScoringMethodX.americanoComplement(22), isNull);
    expect(ScoringMethodX.americanoComplement(-1), isNull);
  });

  test('skor Americano masuk peringkat sebagai total poin', () {
    const match = MatchGame(
      id: 'm1',
      roundNumber: 1,
      matchNumberInRound: 1,
      courtId: 'c1',
      pair1: Pair(id: 'p1', player1Id: 'a', player2Id: 'b'),
      pair2: Pair(id: 'p2', player1Id: 'c', player2Id: 'd'),
      sets: [SetScore(side1: 13, side2: 8)],
      status: MatchStatus.done,
    );
    final standings = {
      for (final s in RankingCalculator.rank(players: _players, matches: const [match], method: RankingMethod.totalGames))
        s.player.id: s,
    };
    expect(standings['a']!.totalPoint, 13);
    expect(standings['a']!.wins, 1);
    expect(standings['c']!.totalPoint, 8);
    expect(standings['c']!.losses, 1);
  });

  test('metode skor tidak hilang saat config disalin (pasangan Fixed, tambah pemain)', () {
    final config = _config(ScoringMethod.americano);
    expect(config.copyWith(fixedPairs: const []).scoring, ScoringMethod.americano);
    expect(config.copyWith(players: _players.take(3).toList()).scoring, ScoringMethod.americano);
  });

  test('metode skor ikut tersimpan; simpanan lama terbaca sebagai skor tennis', () {
    final active = ActiveTournament(
      tournament: Tournament(
        id: 't',
        createdAt: DateTime(2026, 10, 20),
        config: _config(ScoringMethod.americano),
        matches: const [],
      ),
    );
    final encoded = TournamentCodec.encode(active);
    expect(TournamentCodec.decode(encoded)!.config.scoring, ScoringMethod.americano);

    final legacy = encoded.replaceFirst('"scoring":"americano",', '');
    expect(legacy, isNot(contains('scoring')));
    expect(TournamentCodec.decode(legacy)!.config.scoring, ScoringMethod.tennis);
  });
}
