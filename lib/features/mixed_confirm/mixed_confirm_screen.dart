import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';

/// Screen 5 · Mode Endless (Mixed) — konfirmasi aturan + estimasi sebelum mulai.
class MixedConfirmScreen extends StatelessWidget {
  final TournamentConfig config;
  const MixedConfirmScreen({super.key, required this.config});

  static const _rules = [
    'Pemain paling jarang main diprioritaskan',
    'Pasangan baru diprioritaskan',
    'Selisih match antar pemain ≤ 1',
  ];

  /// Kapasitas total match = round maksimum × jumlah court.
  int get _totalMatches => config.maxRounds * config.courtCount;

  /// Tiap match memakai 4 pemain (ganda), dibagi rata ke semua peserta.
  int get _matchesPerPlayer => config.players.isEmpty ? 0 : _totalMatches * 4 ~/ config.players.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabarColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x2, MabarSpacing.x5, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MabarScreenHeader(
                leading: MabarBackButton(label: 'Konfigurasi', onTap: () => context.pop()),
                trailing: const MabarStepIndicator(step: 4),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MabarPageTitle(
                        title: 'Cara Kerja Mixed',
                        subtitle: 'Round dibuat satu per satu. Berhenti kapan saja.',
                      ),
                      const MabarInfoBox(
                        variant: MabarInfoVariant.warning,
                        icon: Icons.all_inclusive,
                        title: 'Round 1 dibuat dulu.',
                        caption: 'Isi semua skor, lalu tekan Buat R2.',
                      ),
                      const SizedBox(height: MabarSpacing.x4),
                      const MabarFieldLabel('Aturan Fairness'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MabarColors.raised,
                          borderRadius: BorderRadius.circular(MabarRadius.xl),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final rule in _rules)
                              Padding(
                                padding: EdgeInsets.only(bottom: rule == _rules.last ? 0 : 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 1),
                                      child: Icon(Icons.check, size: 16, color: MabarColors.brand),
                                    ),
                                    const SizedBox(width: MabarSpacing.x2),
                                    Expanded(
                                      child: Text(
                                        rule,
                                        style: const TextStyle(fontSize: 13, color: MabarColors.text2, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MabarSpacing.x4),
                      const MabarFieldLabel('Estimasi'),
                      Row(
                        children: [
                          Expanded(
                            child: MabarStatBox(value: '${config.maxRounds}', label: 'Max Round'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MabarStatBox(value: '±$_matchesPerPlayer', label: 'Match/Pemain'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: MabarStatBox(value: '${config.courtCount}', label: 'Court Aktif'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MabarStatBox(value: '$_totalMatches', label: 'Total Match'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              MabarPrimaryButton(
                label: 'Mulai Round 1',
                icon: Icons.play_arrow,
                onPressed: () => context.push('/schedule', extra: config),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
