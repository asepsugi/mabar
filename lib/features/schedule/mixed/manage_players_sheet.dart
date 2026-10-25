import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mabar_theme.dart';
import '../../../core/widgets/mabar_controls.dart';
import '../../../core/widgets/mabar_group.dart';
import '../../../core/widgets/mabar_inputs.dart';
import '../../../core/widgets/mabar_layers.dart';
import '../tournament_controller.dart';

/// Sheet 08a "Kelola pemain" (Mixed) — tambah, keluarkan, atau kembalikan pemain tanpa mengulang
/// turnamen; berlaku mulai round berikutnya. Keluarkan langsung tanpa konfirmasi: bisa dibatalkan lewat
/// Kembalikan, dan skornya tetap dihitung.
Future<void> showManagePlayersSheet(BuildContext context) {
  final next = (ProviderScope.containerOf(context).read(tournamentProvider)?.roundCount ?? 0) + 1;
  return showMabarSheet<void>(
    context,
    title: 'Kelola pemain',
    subtitle: 'Berlaku mulai R$next',
    builder: (_) => const _ManagePlayers(),
  );
}

class _ManagePlayers extends ConsumerStatefulWidget {
  const _ManagePlayers();

  @override
  ConsumerState<_ManagePlayers> createState() => _ManagePlayersState();
}

class _ManagePlayersState extends ConsumerState<_ManagePlayers> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  TournamentController get _controller => ref.read(tournamentProvider.notifier);

  void _add() {
    final error = _controller.addPlayer(_name.text);
    setState(() => _error = error);
    if (error == null) _name.clear();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(tournamentProvider);
    if (active == null) return const SizedBox.shrink();

    final activeCount = active.activePlayers.length;
    final withdrawn = active.withdrawnPlayerIds;
    final canWithdraw = activeCount > 4;
    final small = MabarType.caption.copyWith(color: MabarColors.ink3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MabarField(
                controller: _name,
                error: _error != null,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                // Enter = Tambah; isian tetap fokus untuk nama berikutnya.
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            // Sama tinggi dengan kolom nama di sebelahnya.
            MabarButton(label: 'Tambah', expand: false, height: 48, onPressed: _add),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(_error!, style: small.copyWith(color: MabarColors.clay, fontWeight: FontWeight.w600)),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Pemain baru langsung ikut main dan diprioritaskan sampai jumlah match-nya menyusul, dengan jeda '
              'istirahat 1 round. Total Point tertinggal; Win % lebih adil untuk pemain baru.',
              style: small,
            ),
          ),
        ],
        const SizedBox(height: 16),
        MabarSection(
          header: MabarGroupLabel(
            withdrawn.isEmpty ? '$activeCount pemain aktif' : '$activeCount pemain aktif · ${withdrawn.length} keluar',
          ),
          child: MabarGroup(
            color: MabarColors.paper,
            children: [
              for (final p in active.config.players)
                if (withdrawn.contains(p.id))
                  MabarRow(
                    padded: true,
                    titleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: MabarType.body.copyWith(color: MabarColors.faint, decoration: TextDecoration.lineThrough),
                        ),
                        const Text('Keluar · skornya tetap dihitung', style: MabarType.caption),
                      ],
                    ),
                    trailing: MabarRowAction(
                      label: 'Kembalikan',
                      restore: true,
                      onPressed: () => setState(() => _error = _controller.reinstatePlayer(p.id)),
                    ),
                  )
                else
                  MabarRow(
                    title: p.name,
                    trailing: MabarRowAction(
                      label: 'Keluarkan',
                      onPressed: canWithdraw ? () => _controller.withdrawPlayer(p.id) : null,
                    ),
                  ),
            ],
          ),
        ),
        if (!canWithdraw) ...[
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('Butuh minimal 4 pemain', style: small)),
        ],
      ],
    );
  }
}
