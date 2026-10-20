import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/features/schedule/tournament_controller.dart';
import 'package:mabar/models/models.dart';
import 'package:mabar/services/storage/tournament_codec.dart';

/// Tambah/keluarkan pemain di tengah turnamen Mixed.

TournamentConfig _mixedConfig(int players) => TournamentConfig(
      sport: SportType.padel,
      mode: PartnerMode.mixed,
      matchDurationMinutes: 10,
      courts: const [
        Court(id: 'c1', name: 'Court 1', colorIndex: 0, bookingDurationMinutes: 300),
        Court(id: 'c2', name: 'Court 2', colorIndex: 1, bookingDurationMinutes: 300),
      ],
      players: [for (var i = 0; i < players; i++) Player(id: 'p$i', name: 'Pemain $i')],
    );

/// Isi skor semua match round berjalan lalu generate round berikutnya.
void _playRound(TournamentController c, ActiveTournament Function() read) {
  for (final m in read().matchesOfRound(read().roundCount)) {
    c.submitScore(m.id, const [SetScore(side1: 6, side2: 4)]);
  }
  c.generateNextRound();
}

Map<String, int> _scheduledCounts(ActiveTournament a) {
  final counts = <String, int>{};
  for (final m in a.matches) {
    for (final id in [...m.pair1.playerIds, ...m.pair2.playerIds]) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
}

void main() {
  late ProviderContainer container;
  late TournamentController controller;
  ActiveTournament read() => container.read(tournamentProvider)!;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(tournamentProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('pemain baru ikut round berikutnya tanpa mengulang turnamen', () {
    final config = _mixedConfig(9);
    controller.startIfNeeded(config);
    for (var i = 0; i < 3; i++) {
      _playRound(controller, read);
    }
    final before = read();

    expect(controller.addPlayer('  Zaki  '), isNull);

    final after = read();
    expect(after.tournament.id, before.tournament.id);
    expect(after.matches, hasLength(before.matches.length), reason: 'match lama utuh');
    final zaki = after.config.players.last;
    expect(zaki.name, 'Zaki');
    expect(after.activePlayers, hasLength(10));

    // Layar konfirmasi Mixed masih memegang config awal; masuk lagi lewat sana
    // tidak boleh membuat turnamen baru.
    controller.startIfNeeded(config);
    expect(read().tournament.id, before.tournament.id);
    expect(read().config.players, contains(zaki));
  });

  test('pemain baru disejajarkan, bukan main terus sampai menyusul', () {
    controller.startIfNeeded(_mixedConfig(9));
    for (var i = 0; i < 5; i++) {
      _playRound(controller, read);
    }
    controller.addPlayer('Zaki');
    final zakiId = read().config.players.last.id;
    final credit = read().matchCredits[zakiId]!;
    expect(credit, greaterThan(0));

    for (var i = 0; i < 8; i++) {
      _playRound(controller, read);
      final counts = _scheduledCounts(read());
      final effective = [
        for (final p in read().activePlayers) (counts[p.id] ?? 0) + (read().matchCredits[p.id] ?? 0),
      ]..sort();
      expect(effective.last - effective.first, lessThanOrEqualTo(1), reason: 'setelah round ${read().roundCount}');
    }

    // Tanpa kredit Zaki akan main di tiap round berturut-turut sejak masuk.
    final zakiRounds = read().matches.where((m) => m.pair1.contains(zakiId) || m.pair2.contains(zakiId));
    expect(zakiRounds.length, lessThan(9));
  });

  test('pemain keluar tidak dijadwalkan lagi tapi tetap ada di peringkat', () {
    controller.startIfNeeded(_mixedConfig(10));
    _playRound(controller, read);
    final playedP0 = _scheduledCounts(read())['p0'] ?? 0;

    expect(controller.withdrawPlayer('p0'), isTrue);
    for (var i = 0; i < 4; i++) {
      _playRound(controller, read);
    }

    expect(_scheduledCounts(read())['p0'] ?? 0, playedP0);
    expect(container.read(standingsProvider).map((s) => s.player.id), contains('p0'));
  });

  test('tidak bisa mengeluarkan pemain kalau sisa kurang dari 4', () {
    controller.startIfNeeded(_mixedConfig(5));
    expect(controller.withdrawPlayer('p0'), isTrue);
    expect(controller.withdrawPlayer('p1'), isFalse);
    expect(read().activePlayers, hasLength(4));
  });

  test('pemain yang kembali dapat kredit dan ikut rotasi lagi', () {
    controller.startIfNeeded(_mixedConfig(9));
    controller.withdrawPlayer('p0');
    for (var i = 0; i < 4; i++) {
      _playRound(controller, read);
    }

    expect(controller.reinstatePlayer('p0'), isNull);
    expect(read().withdrawnPlayerIds, isNot(contains('p0')));
    expect(read().matchCredits['p0'], greaterThan(0));
  });

  test('nama duplikat ditolak, termasuk milik pemain yang sudah keluar', () {
    controller.startIfNeeded(_mixedConfig(6));
    expect(controller.addPlayer('pemain 1'), contains('sudah ada'));
    controller.withdrawPlayer('p2');
    expect(controller.addPlayer('Pemain 2'), contains('Kembalikan'));
    expect(controller.addPlayer('   '), isNotNull);
    expect(read().config.players, hasLength(6));
  });

  test('maksimal 20 pemain aktif', () {
    controller.startIfNeeded(_mixedConfig(20));
    expect(controller.addPlayer('Zaki'), contains('Maksimal'));
  });

  test('daftar keluar & kredit ikut tersimpan, payload lama tetap terbaca', () {
    controller.startIfNeeded(_mixedConfig(9));
    _playRound(controller, read);
    controller.addPlayer('Zaki');
    controller.withdrawPlayer('p3');

    final decoded = TournamentCodec.decode(TournamentCodec.encode(read()))!;
    expect(decoded.withdrawnPlayerIds, {'p3'});
    expect(decoded.matchCredits, read().matchCredits);
    expect(decoded.config.players.last.name, 'Zaki');

    // Simpanan dari versi sebelum fitur ini tidak punya kedua kunci tersebut.
    final legacy = TournamentCodec.encode(read())
        .replaceFirst(RegExp(r',"withdrawn":\[[^\]]*\],"credits":\{[^}]*\}'), '');
    expect(legacy, isNot(contains('withdrawn')));
    final old = TournamentCodec.decode(legacy)!;
    expect(old.withdrawnPlayerIds, isEmpty);
    expect(old.matchCredits, isEmpty);
  });
}
