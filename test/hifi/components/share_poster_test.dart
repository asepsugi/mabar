import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/core/theme/mabar_theme.dart';
import 'package:mabar/features/share/share_theme.dart';
import 'package:mabar/features/share/widgets/share_poster.dart';
import 'package:mabar/models/models.dart';

import '../hifi_golden.dart';
import 'share_poster_data.dart';

/// Golden SharePoster: pratinjau di layar Bagikan (11a, 11b, 11e, 11h, 11i) dan gambar Feed/Story
/// (11d, 11f, 11g; di frame Feed 360×360 di x 0, Story 203×360 di x 374).
void main() {
  final theme = MabarTheme.light();
  const feedAt = Rect.fromLTWH(0, 0, 360, 360), storyAt = Rect.fromLTWH(374, 0, 203, 360);

  Future<void> check(
    WidgetTester tester, {
    required String frame,
    int index = 0,
    required Rect at,
    required SharePosterTarget target,
    required ShareTheme shareTheme,
    required SportType sport,
    required String eyebrow,
    required bool isFinal,
    required String summary,
    String? more,
    bool complete = true,
  }) async {
    await precacheHifiAssets(tester, [sport.assetPath]);
    final data = SharePosterData(
      sport: sport,
      eyebrow: eyebrow,
      isFinal: isFinal,
      rows: posterRows[(frame, index)]!,
      summary: summary,
      more: more,
      complete: complete,
    );
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: at,
        height: at.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(target == SharePosterTarget.preview ? MabarRadius.poster : 4),
          child: SharePoster(data: data, theme: shareTheme, target: target),
        ),
      ),
      frame,
      at,
      label: '${target.name}$index',
    );
  }

  testWidgets('pratinjau Ringkas, tema biru, sementara (11a)', (tester) async {
    await check(
      tester,
      frame: '11a',
      at: hifiRect('11a', 'poster'),
      target: SharePosterTarget.preview,
      shareTheme: ShareTheme.biru,
      sport: SportType.padel,
      eyebrow: 'Mabar Jumat PB Garuda',
      isFinal: false,
      summary: '3 round · 6 match · 21 Okt 2026',
      more: '+6 pemain lainnya',
      complete: false,
    );
  });

  testWidgets('pratinjau Lengkap Fixed 10 pasangan, tema peach (11b)', (tester) async {
    await check(
      tester,
      frame: '11b',
      at: hifiRect('11b', 'poster'),
      target: SharePosterTarget.preview,
      shareTheme: ShareTheme.peach,
      sport: SportType.tennis,
      eyebrow: 'Tennis · Fixed · 21 Okt 2026',
      isFinal: true,
      summary: '9 round · 45 match',
    );
  });

  for (final (frame, summary) in [('11e', '8 round · 32 match'), ('11h', '6 round · 18 match'), ('11i', '6 round · 18 match')]) {
    testWidgets('pratinjau Lengkap dua kolom rata ($frame)', (tester) async {
      await check(
        tester,
        frame: frame,
        at: hifiRect(frame, 'poster'),
        target: SharePosterTarget.preview,
        shareTheme: ShareTheme.biru,
        sport: SportType.padel,
        eyebrow: 'Padel · Mixed · 21 Okt 2026',
        isFinal: true,
        summary: summary,
      );
    });
  }

  for (final (target, at, index) in [(SharePosterTarget.feed, feedAt, 0), (SharePosterTarget.story, storyAt, 1)]) {
    testWidgets('gambar Ringkas ${target.name} (11d)', (tester) async {
      await check(
        tester,
        frame: '11d',
        index: index,
        at: at,
        target: target,
        shareTheme: ShareTheme.biru,
        sport: SportType.padel,
        eyebrow: 'Mabar Jumat PB Garuda x Matcha Club 2026',
        isFinal: true,
        summary: '4 round · 8 match · 1 WO · 21 Okt 2026',
        more: '+5 pemain lainnya',
        complete: false,
      );
    });

    testWidgets('gambar Lengkap Mixed 20 ${target.name} (11f)', (tester) async {
      await check(
        tester,
        frame: '11f',
        index: index,
        at: at,
        target: target,
        shareTheme: ShareTheme.biru,
        sport: SportType.padel,
        eyebrow: 'Mabar Jumat PB Garuda x Matcha Club',
        isFinal: true,
        summary: '8 round · 32 match · 21 Okt 2026',
      );
    });

    testWidgets('gambar Lengkap Fixed 10 ${target.name} (11g)', (tester) async {
      await check(
        tester,
        frame: '11g',
        index: index,
        at: at,
        target: target,
        shareTheme: ShareTheme.peach,
        sport: SportType.tennis,
        eyebrow: 'Tennis · Fixed · 21 Okt 2026',
        isFinal: true,
        summary: '9 round · 45 match',
      );
    });
  }
}
