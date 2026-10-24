import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/widgets/mabar_controls.dart';
import '../../core/widgets/mabar_layers.dart';

/// Dialog 06e "Akhiri turnamen?" — dipakai Jadwal Fixed dan Mixed.
Future<bool> confirmFinishTournament(BuildContext context) => showMabarConfirm(
  context,
  title: 'Akhiri turnamen?',
  message: 'Match yang belum main tidak dihitung.',
  confirmLabel: 'Akhiri',
  destructive: true,
);

/// Tombol Klasemen di action bar Jadwal: tombol utama "Lihat klasemen" setelah Final (06c, 12l), sekunder selama
/// turnamen berjalan (06a, 12h). Dipakai Jadwal Fixed dan Jadwal penonton.
class LeaderboardButton extends StatelessWidget {
  final bool isFinal;
  const LeaderboardButton({super.key, required this.isFinal});

  @override
  Widget build(BuildContext context) => MabarButton(
    label: isFinal ? 'Lihat klasemen' : 'Klasemen',
    icon: MabarIcons.ranking,
    variant: isFinal ? MabarButtonVariant.primary : MabarButtonVariant.secondary,
    onPressed: () => context.push('/leaderboard'),
  );
}
