import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/models/models.dart';
import 'package:mabar/services/ranking/ranking_calculator.dart';
import 'package:mabar/services/storage/tournament_codec.dart';

/// Metode skor Americano (total poin bisa diatur, default 21) di samping skor tennis.

const _players = [
  Player(id: 'a', name: 'Andi'),
  Player(id: 'b', name: 'Budi'),
  Player(id: 'c', name: 'Citra'),
  Player(id: 'd', name: 'Dewi'),
];

TournamentConfig _config(ScoringMethod scoring, {int points = 21}) => TournamentConfig(
      sport: SportType.padel,
      mode: PartnerMode.mixed,
      matchDurationMinutes: 15,
      courts: const [Court(id: 'c1', name: 'Court 1', colorIndex: 0, bookingDurationMinutes: 60)],
      players: _players,
      scoring: scoring,
      americanoPoints: points,
    );

void main() {
  test('poin lawan = total dikurangi poin yang diisi', () {
    expect(ScoringMethodX.americanoComplement(13, total: 21), 8);
    expect(ScoringMethodX.americanoComplement(0, total: 21), 21);
    expect(ScoringMethodX.americanoComplement(21, total: 21), 0);
    expect(ScoringMethodX.americanoComplement(22, total: 21), isNull);
    expect(ScoringMethodX.americanoComplement(-1, total: 21), isNull);
    expect(ScoringMethodX.americanoComplement(10, total: 24), 14);
  });

  test('total poin Americano harus 2–99', () {
    expect(_config(ScoringMethod.americano, points: 32).hasValidScoring, isTrue);
    expect(_config(ScoringMethod.americano, points: 1).hasValidScoring, isFalse);
    expect(_config(ScoringMethod.americano, points: 100).hasValidScoring, isFalse);
    // Skor tennis tidak peduli angka Americano.
    expect(_config(ScoringMethod.tennis, points: 0).hasValidScoring, isTrue);
  });

  test('Americano total genap: skor seri dihitung seri, bukan menang/kalah', () {
    const match = MatchGame(
      id: 'm1',
      roundNumber: 1,
      matchNumberInRound: 1,
      courtId: 'c1',
      pair1: Pair(id: 'p1', player1Id: 'a', player2Id: 'b'),
      pair2: Pair(id: 'p2', player1Id: 'c', player2Id: 'd'),
      sets: [SetScore(side1: 12, side2: 12)],
      status: MatchStatus.done,
    );
    final a = RankingCalculator.rank(players: _players, matches: const [match], method: RankingMethod.winPercent)
        .firstWhere((s) => s.player.id == 'a');
    expect(a.draws, 1);
    expect(a.totalPoint, 12);
    expect(a.winPercent, 50);
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
    final config = _config(ScoringMethod.americano, points: 24);
    expect(config.copyWith(fixedPairs: const []).scoring, ScoringMethod.americano);
    expect(config.copyWith(fixedPairs: const []).americanoPoints, 24);
    expect(config.copyWith(players: _players.take(3).toList()).scoring, ScoringMethod.americano);
  });

  test('metode skor ikut tersimpan; simpanan lama terbaca sebagai skor tennis', () {
    final active = ActiveTournament(
      tournament: Tournament(
        id: 't',
        createdAt: DateTime(2026, 10, 20),
        config: _config(ScoringMethod.americano, points: 32),
        matches: const [],
      ),
    );
    final encoded = TournamentCodec.encode(active);
    expect(TournamentCodec.decode(encoded)!.config.scoring, ScoringMethod.americano);
    expect(TournamentCodec.decode(encoded)!.config.americanoPoints, 32);

    final legacy = encoded.replaceFirst('"scoring":"americano","americanoPoints":32,', '');
    expect(legacy, isNot(contains('scoring')));
    expect(TournamentCodec.decode(legacy)!.config.scoring, ScoringMethod.tennis);
    expect(TournamentCodec.decode(legacy)!.config.americanoPoints, 21);
  });
}
