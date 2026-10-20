import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/features/schedule/tournament_controller.dart';
import 'package:mabar/models/models.dart';
import 'package:mabar/services/storage/tournament_store.dart';

/// Melanjutkan turnamen Mixed yang sudah diakhiri / kehabisan waktu booking.

/// Match 10 menit; Court 1 cuma 10 menit (1 round), Court 2 30 menit (3 round).
TournamentConfig _config() => TournamentConfig(
      sport: SportType.padel,
      mode: PartnerMode.mixed,
      matchDurationMinutes: 10,
      courts: const [
        Court(id: 'c1', name: 'Court 1', colorIndex: 0, bookingDurationMinutes: 10),
        Court(id: 'c2', name: 'Court 2', colorIndex: 1, bookingDurationMinutes: 30),
      ],
      players: [for (var i = 0; i < 8; i++) Player(id: 'p$i', name: 'Pemain $i')],
    );

void _scoreCurrentRound(TournamentController c, ActiveTournament a) {
  for (final m in a.matchesOfRound(a.roundCount)) {
    c.submitScore(m.id, const [SetScore(side1: 6, side2: 4)]);
  }
}

void main() {
  late TournamentStore store;
  late ProviderContainer container;
  late TournamentController controller;
  ActiveTournament read() => container.read(tournamentProvider)!;

  setUp(() {
    store = TournamentStore.memory();
    container = ProviderContainer(overrides: [tournamentStoreProvider.overrideWithValue(store)]);
    controller = container.read(tournamentProvider.notifier);
    controller.startIfNeeded(_config());
  });
  tearDown(() => container.dispose());

  /// Mainkan sampai waktu booking semua court habis (3 round).
  void playUntilTimeout() {
    while (true) {
      _scoreCurrentRound(controller, read());
      if (!read().canGenerateNextRound) break;
      controller.generateNextRound();
    }
  }

  test('waktu habis: jam ditambah per court, dihitung dari akhir round terakhir', () {
    playUntilTimeout();
    expect(read().roundCount, 3);
    expect(read().canResume, isTrue);

    // Court 1 sudah habis sejak R1; +1 jam tetap berarti 6 round lagi, bukan 4.
    controller.resume({'c1': 60});
    final courts = {for (final c in read().config.courts) c.id: c.bookingDurationMinutes};
    expect(courts, {'c1': 90, 'c2': 30});
    expect(read().canResume, isFalse);

    controller.generateNextRound();
    expect(read().roundCount, 4);
    expect(read().matchesOfRound(4).map((m) => m.courtId).toSet(), {'c1'}, reason: 'Court 2 tidak diperpanjang');
    expect(read().matchesOfRound(1).every((m) => m.status == MatchStatus.done), isTrue, reason: 'skor lama utuh');
  });

  test('diakhiri: match yang batal kembali menunggu skor, turnamen LIVE lagi', () {
    controller.finishNow();
    expect(read().tournament.isFinished, isTrue);
    expect(read().matchesOfRound(1).every((m) => m.status == MatchStatus.cancelled), isTrue);
    final id = read().tournament.id;

    controller.resume(const {});
    expect(read().tournament.isFinished, isFalse);
    expect(read().tournament.id, id);
    expect(read().matchesOfRound(1).every((m) => m.status == MatchStatus.pending), isTrue);
    expect(read().config.courts.map((c) => c.bookingDurationMinutes), [10, 30], reason: 'tanpa tambahan jam');
  });

  test('turnamen yang masih jalan tidak bisa "dilanjutkan"', () {
    final before = read();
    controller.resume({'c2': 60});
    expect(read(), same(before));
  });

  test('turnamen yang sudah ditutup bisa dibuka lagi dari Beranda', () async {
    playUntilTimeout();
    final id = read().tournament.id;
    await controller.close();
    expect(container.read(tournamentProvider), isNull);

    final last = container.read(lastFinishedProvider)!;
    expect(last.tournament.id, id);

    controller.resume({'c2': 60}, from: last);
    expect(read().tournament.id, id);
    expect(read().roundCount, 3);
    expect(read().canGenerateNextRound, isTrue);
    expect(store.loadActive()?.tournament.id, id, reason: 'langsung tersimpan sebagai turnamen aktif');
  });

  test('turnamen terakhir terbaca lagi setelah app dibuka ulang', () async {
    await controller.close();
    final reopened = ProviderContainer(overrides: [tournamentStoreProvider.overrideWithValue(store)]);
    addTearDown(reopened.dispose);
    expect(reopened.read(lastFinishedProvider), isNotNull);
  });

  test('mode Fixed tidak bisa dilanjutkan', () {
    final fixed = ActiveTournament(
      tournament: Tournament(
        id: 'f',
        createdAt: DateTime(2026),
        config: TournamentConfig(
          sport: SportType.padel,
          mode: PartnerMode.fixed,
          matchDurationMinutes: 10,
          courts: _config().courts,
          players: _config().players,
          fixedPairs: const [],
        ),
        matches: const [],
        isFinished: true,
      ),
    );
    expect(fixed.canResume, isFalse);
    controller.resume({'c1': 60}, from: fixed);
    expect(read().config.mode, PartnerMode.mixed, reason: 'state tidak berubah');
  });
}
