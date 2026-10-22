import 'package:flutter/material.dart';

import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_layers.dart';
import '../../models/models.dart';

/// Dialog 06e "Akhiri turnamen?" — dipakai Jadwal Fixed dan Mixed.
Future<bool> confirmFinishTournament(BuildContext context) => showMabarConfirm(
  context,
  title: 'Akhiri turnamen?',
  message: 'Match yang belum main tidak dihitung.',
  confirmLabel: 'Akhiri',
  destructive: true,
);

// Sisa tata letak lama, masih dipakai Input Skor dan sheet Lanjutkan sampai alurnya dirakit ulang (07, 08).

/// Badge court — tingginya disamakan dengan badge sport (32px) supaya sejajar.
class CourtBadge extends StatelessWidget {
  final Court court;
  const CourtBadge({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x3),
      decoration: BoxDecoration(
        color: MabarColors.courtPalette[court.colorIndex],
        borderRadius: BorderRadius.circular(MabarRadius.chip),
      ),
      child: Text(
        court.name.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
      ),
    );
  }
}

class SportBadge extends StatelessWidget {
  final SportType sport;
  const SportBadge({super.key, required this.sport});

  @override
  Widget build(BuildContext context) {
    // `.sport-badge` 32×32 dengan ikon 22×22 di dalamnya.
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: MabarColors.fill, borderRadius: BorderRadius.circular(MabarRadius.chip)),
      child: SizedBox(width: 22, height: 22, child: Image.asset(sport.assetPath, fit: BoxFit.contain)),
    );
  }
}
