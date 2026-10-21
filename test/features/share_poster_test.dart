import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mabar/features/share/share_card.dart';
import 'package:mabar/models/models.dart';
import 'package:mabar/services/ranking/ranking_calculator.dart';
import 'package:mabar/services/share/result_text_builder.dart';
import 'package:mabar/features/share/share_theme.dart';

/// Turnamen dengan [count] pemain, satu round yang seluruh match-nya selesai.
ActiveTournament _active(int count) {
  final players = [
    for (var i = 0; i < count; i++)
      Player(id: 'p$i', name: 'Pemain Nomor ${i + 1}'),
  ];
  final matches = <MatchGame>[
    for (var i = 0; i + 3 < count; i += 4)
      MatchGame(
        id: 'm$i',
        roundNumber: 1,
        matchNumberInRound: i ~/ 4 + 1,
        courtId: 'c1',
        pair1: Pair(id: 'x$i', player1Id: 'p$i', player2Id: 'p${i + 1}'),
        pair2: Pair(id: 'y$i', player1Id: 'p${i + 2}', player2Id: 'p${i + 3}'),
        sets: const [SetScore(side1: 6, side2: 3)],
        status: MatchStatus.done,
      ),
  ];

  return ActiveTournament(
    tournament: Tournament(
      id: 't1',
      createdAt: DateTime(2026, 9, 16),
      config: TournamentConfig(
        sport: SportType.padel,
        mode: PartnerMode.mixed,
        matchDurationMinutes: 15,
        courts: const [
          Court(id: 'c1', name: 'Court 1', colorIndex: 0, bookingDurationMinutes: 120),
        ],
        players: players,
      ),
      matches: matches,
    ),
  );
}

List<StandingEntry> _standings(ActiveTournament active) => standingEntries(
      standings: RankingCalculator.rank(
        players: active.config.players,
        matches: active.matches,
        method: RankingMethod.winPercent,
        format: active.config.format,
      ),
    );

/// Surface test default (800x600) lebih pendek dari poster Story, jadi ukuran
/// surface disamakan dulu supaya poster tidak ikut terpotong.
Future<void> _useSurface(WidgetTester tester, SharePosterSize size) async {
  await tester.binding.setSurfaceSize(size.logicalSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  group('ShareSelection', () {
    test('Ringkas hanya 5 teratas, sisanya dihitung sebagai tersembunyi', () {
      final active = _active(8);
      final selection = ShareSelection(
        all: _standings(active),
        method: RankingMethod.totalGames,
        format: ShareFormat.ringkas,
      );

      expect(selection.visible, hasLength(ShareSelection.previewCount));
      expect(selection.hiddenCount, 3);
    });

    test('Lengkap menampilkan semua pemain', () {
      final active = _active(8);
      final selection = ShareSelection(
        all: _standings(active),
        method: RankingMethod.totalGames,
        format: ShareFormat.lengkap,
      );

      expect(selection.visible, hasLength(8));
      expect(selection.hiddenCount, 0);
    });
  });

  group('ShareResultPoster', () {
    for (final size in SharePosterSize.values) {
      final px = '${size.pixelWidth.toInt()}x${size.pixelHeight.toInt()}';

      testWidgets('${size.name} menghasilkan gambar $px px', (tester) async {
        await _useSurface(tester, size);
        final active = _active(8);
        final key = GlobalKey();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: ShareResultPoster(
                    active: active,
                    standings: _standings(active),
                    hiddenCount: 0,
                    method: RankingMethod.totalGames,
                    theme: ShareTheme.hijau,
                    size: size,
                  ),
                ),
              ),
            ),
          ),
        );

        // Jalur yang sama dipakai ScreenshotController saat share.
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        late ui.Image image;
        await tester.runAsync(() async {
          image = await boundary.toImage(pixelRatio: SharePosterSize.pixelRatio);
        });
        addTearDown(image.dispose);

        expect(image.width, size.pixelWidth.toInt());
        expect(image.height, size.pixelHeight.toInt());
      });

      testWidgets('daftar 20 pemain tetap muat di ${size.name}', (tester) async {
        await _useSurface(tester, size);
        final active = _active(20);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: ShareResultPoster(
                  active: active,
                  standings: _standings(active),
                  hiddenCount: 0,
                  method: RankingMethod.totalGames,
                  theme: ShareTheme.hijau,
                  size: size,
                ),
              ),
            ),
          ),
        );

        // FittedBox mengecilkan isi; kalau meluber, pump melempar overflow.
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(ShareResultPoster)), size.logicalSize);
      });
    }
  });
}
