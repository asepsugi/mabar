import 'package:flutter/material.dart';

import '../../core/widgets/mabar_layers.dart';

/// Dialog 06e "Akhiri turnamen?" — dipakai Jadwal Fixed dan Mixed.
Future<bool> confirmFinishTournament(BuildContext context) => showMabarConfirm(
  context,
  title: 'Akhiri turnamen?',
  message: 'Match yang belum main tidak dihitung.',
  confirmLabel: 'Akhiri',
  destructive: true,
);

