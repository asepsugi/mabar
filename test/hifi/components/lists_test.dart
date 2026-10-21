import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/core/theme/mabar_icons.dart';
import 'package:mabar/core/theme/mabar_theme.dart';
import 'package:mabar/core/widgets/mabar_controls.dart';
import 'package:mabar/core/widgets/numbered_lists.dart';
import 'package:mabar/features/setup_peserta/widgets/name_list_field.dart';

import '../hifi_golden.dart';

/// Golden NameListField, RosterPreview, PairList (layar Pemain dan Pasangan).
void main() {
  final theme = MabarTheme.light();
  const sample = ['Andi P', 'Budi S', 'Citra L', 'Dewant R', 'Eko M', 'Fajar K', 'Gina R', 'Hana T'];

  testWidgets('NameListField kosong: contoh pudar, Tempel + Contoh (02a)', (tester) async {
    final at = hifiRect('02a', 'compose');
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: at,
        child: NameListField(
          controller: TextEditingController(),
          hint: '1. Andi P\n2. Budi S\n3) Citra L',
          tools: [
            MabarTextButton(label: 'Tempel', icon: MabarIcons.clipboardText, onPressed: () {}),
            MabarTextButton(label: 'Contoh', icon: MabarIcons.userList, onPressed: () {}),
          ],
        ),
      ),
      '02a',
      at,
      label: 'compose',
    );
  });

  testWidgets('NameListField berisi: 6 baris + penanda gulir, Hapus semua di kanan (02b)', (tester) async {
    final at = hifiRect('02b', 'compose');
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: at,
        child: NameListField(
          controller: TextEditingController(text: [for (var i = 0; i < 9; i++) '${i + 1}. ${[...sample, 'andi p'][i]}'].join('\n')),
          tools: [MabarTextButton(label: 'Tempel', icon: MabarIcons.clipboardText, onPressed: () {})],
          trailingTool: MabarTextButton(label: 'Hapus semua', icon: MabarIcons.trash, tone: MabarTextTone.danger, onPressed: () {}),
        ),
      ),
      '02b',
      at,
      label: 'compose',
    );
  });

  testWidgets('RosterPreview 8 pemain (02b)', (tester) async {
    final at = hifiRect('02b', 'roster');
    await expectRegionMatchesHifi(tester, hifiStage(theme: theme, at: at, child: const RosterPreview(names: sample)), '02b', at, label: 'roster');
  });

  testWidgets('RosterPreview 21 pemain: 11 kiri, 10 kanan (02d)', (tester) async {
    final at = hifiRect('02d', 'roster');
    const names = [
      ...sample,
      'Indra W', 'Joko S', 'Kiki A', 'Lina M', 'Maya P', 'Nanda R', 'Oki S', 'Putri A', 'Rizky H', 'Sari D', 'Tono B',
      'Umar F', 'Vina K',
    ];
    await expectRegionMatchesHifi(tester, hifiStage(theme: theme, at: at, child: const RosterPreview(names: names)), '02d', at, label: 'roster');
  });

  testWidgets('PairList (04a)', (tester) async {
    final at = hifiRect('04a', 'pairlist');
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: at,
        child: const PairList(pairs: [('Gina R', 'Citra L'), ('Andi P', 'Hana T'), ('Eko M', 'Fajar K'), ('Dewant R', 'Budi S')]),
      ),
      '04a',
      at,
      label: 'pairlist',
    );
  });

  testWidgets('PairList dengan pemain sisa ganjil (04c)', (tester) async {
    final at = hifiRect('04c', 'pairlist');
    await expectRegionMatchesHifi(
      tester,
      hifiStage(
        theme: theme,
        at: at,
        child: const PairList(
          pairs: [('Gina R', 'Citra L'), ('Andi P', 'Indra W'), ('Eko M', 'Fajar K'), ('Dewant R', 'Budi S')],
          leftover: 'Hana T',
        ),
      ),
      '04c',
      at,
      label: 'pairlist',
    );
  });
}
