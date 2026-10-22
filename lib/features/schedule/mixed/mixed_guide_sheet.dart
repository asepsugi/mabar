import 'package:flutter/material.dart';

import '../../../core/theme/mabar_icons.dart';
import '../../../core/theme/mabar_theme.dart';
import '../../../core/widgets/mabar_controls.dart';
import '../../../core/widgets/mabar_group.dart';
import '../../../core/widgets/mabar_layers.dart';
import '../../../models/models.dart';

/// Sheet 06k "Cara kerja Mixed" — pengganti layar konfirmasi Mixed lama. Teks Aturan Fairness dan label
/// Estimasi sesuai permintaan host. Muncul sekali saat R1 dibuat, setelah itu lewat menu ⋯.
Future<void> showMixedGuideSheet(BuildContext context, ActiveTournament active) {
  final config = active.config;
  final total = config.maxRounds * config.courtCount;
  final players = active.activePlayers.length;
  Widget value(String text) => Text(text, style: MabarType.numM.copyWith(fontSize: 20, color: MabarColors.ink));

  return showMabarSheet<void>(
    context,
    title: 'Cara kerja Mixed',
    subtitle: 'Round dibuat satu per satu. Isi semua skor, lalu tekan Buat R${active.roundCount + 1}. Berhenti kapan saja.',
    footer: (context) => MabarButton(label: 'Mengerti', onPressed: () => Navigator.pop(context)),
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MabarSection(
          header: const MabarGroupLabel('Aturan Fairness'),
          child: MabarGroup(
            color: MabarColors.paper,
            children: [
              for (final rule in const [
                'Pemain paling jarang main diprioritaskan',
                'Pasangan baru diprioritaskan',
                'Selisih match antar pemain ≤ 1',
              ])
                MabarRow(
                  leading: const Icon(MabarIcons.check, size: MabarSize.iconInButton, color: MabarColors.ink2),
                  title: rule,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MabarSection(
          header: const MabarGroupLabel('Estimasi'),
          child: MabarGroup(
            color: MabarColors.paper,
            children: [
              MabarRow(title: 'Max Round', trailing: value('${config.maxRounds}')),
              MabarRow(title: 'Match/Pemain', trailing: value('±${players == 0 ? 0 : total * 4 ~/ players}')),
              MabarRow(title: 'Court Aktif', trailing: value('${config.courtCount}')),
              MabarRow(title: 'Total Match', trailing: value('$total')),
            ],
          ),
        ),
      ],
    ),
  );
}
