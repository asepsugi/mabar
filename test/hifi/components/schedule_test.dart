import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/core/theme/mabar_theme.dart';
import 'package:mabar/core/widgets/match_score_row.dart';
import 'package:mabar/core/widgets/mabar_controls.dart';
import 'package:mabar/features/schedule/widgets/resting_list.dart';
import 'package:mabar/features/schedule/widgets/round_tabs.dart';

import '../hifi_golden.dart';

/// Golden per komponen Jadwal (dan riwayat Detail): baris match, tab round, daftar istirahat.
void main() {
  final theme = MabarTheme.light();
  final court1 = MabarColors.courtPalette[0], court2 = MabarColors.courtPalette[1];

  Widget list(List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: 8), rows[i]],
    ],
  );

  testWidgets('MatchScoreRow: skor + WO beralasan (06g)', (tester) async {
    final at = hifiRect('06g', 'list');
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: at,
        child: list([
          MatchScoreRow(
            badge: '1',
            badgeColor: court1,
            badgeWidth: 42,
            countdown: '01:08',
            top: const MatchScoreSide(name: 'Andi · Dewant', scores: ['13'], win: true),
            bottom: const MatchScoreSide(name: 'Citra · Fajar', scores: ['8'], tone: MatchScoreTone.lost),
          ),
          MatchScoreRow(
            badge: '2',
            badgeColor: court2,
            badgeWidth: 42,
            countdown: '01:08',
            top: const MatchScoreSide(name: 'Hana · Gina', win: true),
            bottom: const MatchScoreSide(name: 'Eko · Budi', tag: 'WO · Absen'),
          ),
        ]),
      ),
      '06g',
      at,
      label: 'list',
    );
  });

  testWidgets('MatchScoreRow: belum diisi dengan tombol Isi skor (06a)', (tester) async {
    final at = hifiRect('06a', 'list');
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: at,
        child: list([
          MatchScoreRow(
            badge: '1',
            badgeColor: court1,
            badgeWidth: 42,
            countdown: '01:15',
            top: const MatchScoreSide(name: 'Andi · Budi', scores: ['6'], win: true),
            bottom: const MatchScoreSide(name: 'Citra · Dewant', scores: ['4'], tone: MatchScoreTone.lost),
          ),
          MatchScoreRow(
            badge: '2',
            badgeColor: court2,
            badgeWidth: 42,
            countdown: '01:15',
            top: const MatchScoreSide(name: 'Eko · Fajar'),
            bottom: const MatchScoreSide(name: 'Gina · Hana'),
            trailing: MabarButton(label: 'Isi skor', small: true, onPressed: () {}),
          ),
        ]),
      ),
      '06a',
      at,
      label: 'list',
    );
  });

  testWidgets('MatchScoreRow ringkas: riwayat Detail dengan label round dan nilai WO (10b)', (tester) async {
    final at = hifiRect('10b', 'list');
    MatchScoreRow history(String round, MatchScoreSide own, MatchScoreSide other) => MatchScoreRow(
      badge: round,
      badgeColor: MabarColors.ink,
      badgeFontSize: 14,
      compact: true,
      top: own,
      bottom: other,
    );
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: at,
        child: list([
          history(
            'R5',
            const MatchScoreSide(name: 'Gina · Hana', scores: ['5'], tone: MatchScoreTone.lost),
            const MatchScoreSide(name: 'vs Andi · Budi', scores: ['6'], win: true),
          ),
          history(
            'R3',
            const MatchScoreSide(name: 'Gina · Hana', scores: ['6'], win: true),
            const MatchScoreSide(name: 'vs Eko · Fajar', scores: ['1'], tone: MatchScoreTone.lost),
          ),
          history(
            'R2',
            const MatchScoreSide(name: 'Gina · Hana', scores: ['+6'], tone: MatchScoreTone.credit, win: true),
            const MatchScoreSide(name: 'vs Citra · Dewant', tag: 'WO'),
          ),
          history(
            'R1',
            const MatchScoreSide(name: 'Gina · Hana', scores: ['6'], win: true),
            const MatchScoreSide(name: 'vs Indra · Joko', scores: ['3'], tone: MatchScoreTone.lost),
          ),
        ]),
      ),
      '10b',
      at,
      label: 'list',
    );
  });

  for (final (frame, count, selected, live, future, meta, alert) in [
    ('06g', 3, 3, null, null, '2/2 match', false),
    ('06a', 5, 2, 2, 3, '1/2 match', false),
    ('06l', 8, 8, null, null, 'Waktu habis', true),
    ('06n', 12, 2, 12, null, '2/2 match', false),
  ]) {
    testWidgets('RoundTabs ($frame)', (tester) async {
      final at = hifiRect(frame, 'tabs');
      await expectRegionMatchesHifi(
        tester,
        hifiStage(
          theme: theme,
          at: at,
          child: RoundTabs(
            count: count,
            selected: selected,
            onSelect: (_) {},
            liveRound: live,
            isFuture: future == null ? null : (r) => r >= future,
            meta: meta,
            metaAlert: alert,
          ),
        ),
        frame,
        at,
        label: 'tabs',
      );
    });
  }

  testWidgets('RestingList: prioritas + istirahat lagi (06o)', (tester) async {
    final first = hifiRect('06o', 'rest'), second = hifiRect('06o', 'rest', index: 1);
    final region = first.expandToInclude(second);
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: region,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RestingList(
              names: ['Eko M', 'Fajar K', 'Gina R', 'Hana T', 'Kiki A', 'Maya P', 'Rizky H', 'Umar F'],
              priorityRound: 4,
            ),
            SizedBox(height: 16),
            RestingList.later(names: ['Indra W', 'Joko S', 'Nanda R', 'Tono B'], nextRound: 4),
          ],
        ),
      ),
      '06o',
      region,
      label: 'rest',
    );
  });

  testWidgets('RestingList: pasangan bye Fixed (06a)', (tester) async {
    final at = hifiRect('06a', 'rest');
    await expectRegionMatchesHifi(
      tester,
      hifiStage(theme: theme, at: at, child: const RestingList(names: ['Indra · Joko'])),
      '06a',
      at,
      label: 'rest',
    );
  });
}
