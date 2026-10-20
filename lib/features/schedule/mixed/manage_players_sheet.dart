import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mabar_theme.dart';
import '../../../core/widgets/mabar_widgets.dart';
import '../tournament_controller.dart';

/// Bottom sheet "Kelola Peserta" mode Mixed — tambah, keluarkan, atau
/// kembalikan pemain tanpa mengulang turnamen. Tidak ada di mockup; gayanya
/// mengikuti sheet WO (screen 7b).
Future<void> showManagePlayersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MabarColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MabarRadius.xxxl + 4)),
    ),
    builder: (_) => const _ManagePlayersSheet(),
  );
}

class _ManagePlayersSheet extends ConsumerStatefulWidget {
  const _ManagePlayersSheet();

  @override
  ConsumerState<_ManagePlayersSheet> createState() => _ManagePlayersSheetState();
}

class _ManagePlayersSheetState extends ConsumerState<_ManagePlayersSheet> {
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
    final canWithdraw = activeCount > 4;

    return Padding(
      // Sheet ikut naik saat keyboard muncul.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x5, MabarSpacing.x5, MabarSpacing.x6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: MabarSpacing.x4),
                    decoration: BoxDecoration(color: MabarColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: MabarColors.brandTint,
                        borderRadius: BorderRadius.circular(MabarRadius.md),
                      ),
                      child: const Icon(Icons.group_outlined, size: 18, color: MabarColors.brand),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kelola Peserta',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: MabarColors.text1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$activeCount pemain aktif · berlaku mulai R${active.roundCount + 1}',
                          style: const TextStyle(fontSize: 11, color: MabarColors.text4),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: MabarSpacing.x4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                        decoration: InputDecoration(hintText: 'Nama pemain baru', errorText: _error),
                      ),
                    ),
                    const SizedBox(width: MabarSpacing.x2),
                    ElevatedButton(
                      onPressed: _add,
                      // Tema memberi lebar minimum tak hingga (tombol full-width); di dalam Row harus dibatasi.
                      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
                const SizedBox(height: MabarSpacing.x3),
                const MabarInfoBox(
                  variant: MabarInfoVariant.neutral,
                  icon: Icons.info_outline,
                  title: 'Pemain baru langsung ikut main',
                  caption:
                      'Jumlah match mengikuti pemain yang paling jarang main. '
                      'Total Point tertinggal; Win % lebih adil untuk pemain baru.',
                ),
                const SizedBox(height: MabarSpacing.x4),
                MabarFieldLabel('Peserta (${active.config.players.length})'),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in active.config.players)
                        _PlayerRow(
                          name: p.name,
                          withdrawn: active.withdrawnPlayerIds.contains(p.id),
                          canWithdraw: canWithdraw,
                          onWithdraw: () => _controller.withdrawPlayer(p.id),
                          onReinstate: () => setState(() => _error = _controller.reinstatePlayer(p.id)),
                        ),
                    ],
                  ),
                ),
                if (!canWithdraw)
                  const Padding(
                    padding: EdgeInsets.only(top: MabarSpacing.x2),
                    child: Text('Butuh minimal 4 pemain', style: TextStyle(fontSize: 11, color: MabarColors.text4)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String name;
  final bool withdrawn;
  final bool canWithdraw;
  final VoidCallback onWithdraw;
  final VoidCallback onReinstate;

  const _PlayerRow({
    required this.name,
    required this.withdrawn,
    required this.canWithdraw,
    required this.onWithdraw,
    required this.onReinstate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MabarColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: withdrawn ? MabarColors.text4 : MabarColors.text1,
                    decoration: withdrawn ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (withdrawn)
                  const Text(
                    'Keluar · skornya tetap dihitung',
                    style: TextStyle(fontSize: 11, color: MabarColors.text4),
                  ),
              ],
            ),
          ),
          if (withdrawn)
            TextButton(onPressed: onReinstate, child: const Text('Kembalikan'))
          else
            TextButton(
              onPressed: canWithdraw ? onWithdraw : null,
              style: TextButton.styleFrom(foregroundColor: MabarColors.danger),
              child: const Text('Keluarkan'),
            ),
        ],
      ),
    );
  }
}
