import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import '../../services/pairing/pair_generator.dart';

enum _PairMode { acak, manual }

/// Screen 4 · Buat Pasangan (mode Fixed) — acak otomatis atau susun manual.
class PairSetupScreen extends StatefulWidget {
  final TournamentConfig config;
  const PairSetupScreen({super.key, required this.config});

  @override
  State<PairSetupScreen> createState() => _PairSetupScreenState();
}

class _PairSetupScreenState extends State<PairSetupScreen> {
  _PairMode _mode = _PairMode.acak;
  PairingDraft _draft = PairingDraft.empty;

  /// Pemain yang sudah diketuk tapi belum dapat pasangan (mode manual).
  final List<Player> _picked = [];

  List<Player> get _players => widget.config.players;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() => setState(() {
    _picked.clear();
    _draft = PairGenerator.random(_players);
  });

  void _switchMode(_PairMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _picked.clear();
      _draft = mode == _PairMode.acak ? PairGenerator.random(_players) : PairingDraft.empty;
    });
  }

  bool _isAssigned(Player p) => _draft.pairs.any((pair) => pair.contains(p.id)) || _picked.contains(p);

  void _tapPlayer(Player p) {
    if (_mode != _PairMode.manual || _isAssigned(p)) return;
    setState(() {
      _picked.add(p);
      if (_picked.length == 2) {
        final assigned = [for (final pair in _draft.pairs) ...pair.playerIds, ..._picked.map((e) => e.id)];
        _draft = PairingDraft(
          pairs: [
            ..._draft.pairs,
            Pair(id: 'pair-${_picked[0].id}-${_picked[1].id}', player1Id: _picked[0].id, player2Id: _picked[1].id),
          ],
          unpaired: _players.where((e) => !assigned.contains(e.id)).toList(),
        );
        _picked.clear();
      }
    });
  }

  /// Buang pasangan terakhir supaya host bisa mengulang tanpa reset semua.
  void _undoLastPair() {
    if (_draft.pairs.isEmpty) return;
    setState(() {
      final pairs = [..._draft.pairs]..removeLast();
      final assigned = [for (final pair in pairs) ...pair.playerIds];
      _draft = PairingDraft(pairs: pairs, unpaired: _players.where((e) => !assigned.contains(e.id)).toList());
      _picked.clear();
    });
  }

  String _pairLabel(Pair pair) {
    String firstName(String id) => _players.firstWhere((p) => p.id == id).name.split(' ').first;
    return '${firstName(pair.player1Id)} + ${firstName(pair.player2Id)}';
  }

  void _lock() {
    final config = widget.config.copyWith(fixedPairs: _draft.pairs);
    context.push('/schedule', extra: config);
  }

  @override
  Widget build(BuildContext context) {
    final slotCount = _players.length ~/ 2;

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
                      const MabarPageTitle(title: 'Buat Pasangan', subtitle: 'Acak atau atur sendiri.'),
                      _ModeButtons(mode: _mode, onSelect: _switchMode),
                      const SizedBox(height: MabarSpacing.x4),
                      const MabarFieldLabel('Pemain'),
                      _Pool(
                        players: _players,
                        isAssigned: _isAssigned,
                        isPicked: _picked.contains,
                        onTap: _mode == _PairMode.manual ? _tapPlayer : null,
                      ),
                      const SizedBox(height: 14),
                      MabarFieldLabel(
                        _mode == _PairMode.acak ? 'Pasangan' : 'Pasangan (${_draft.pairs.length}/$slotCount)',
                      ),
                      _PairGrid(slotCount: slotCount, pairs: _draft.pairs, label: _pairLabel),
                      const SizedBox(height: MabarSpacing.x3),
                      if (_mode == _PairMode.acak)
                        _GhostButton(icon: Icons.refresh, label: 'Acak Ulang', onTap: _shuffle)
                      else
                        _GhostButton(
                          icon: Icons.undo,
                          label: 'Urungkan',
                          onTap: _draft.pairs.isEmpty ? null : _undoLastPair,
                        ),
                      const SizedBox(height: MabarSpacing.x3),
                      if (_draft.unpaired.isNotEmpty)
                        MabarInfoBox(
                          variant: MabarInfoVariant.warning,
                          icon: Icons.error_outline,
                          title: '${_draft.unpaired.length} pemain belum punya pasangan',
                          caption: _draft.unpaired.map((e) => e.name).join(', '),
                        )
                      else
                        const MabarInfoBox(
                          variant: MabarInfoVariant.danger,
                          icon: Icons.lock_outline,
                          title: 'Pasangan tidak bisa diubah setelah jadwal dibuat',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              MabarPrimaryButton(
                label: 'Buat Jadwal',
                icon: Icons.lock_outline,
                onPressed: _draft.isComplete ? _lock : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButtons extends StatelessWidget {
  final _PairMode mode;
  final ValueChanged<_PairMode> onSelect;

  const _ModeButtons({required this.mode, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            icon: Icons.casino_outlined,
            label: 'Acak',
            active: mode == _PairMode.acak,
            onTap: () => onSelect(_PairMode.acak),
          ),
        ),
        const SizedBox(width: MabarSpacing.x2),
        Expanded(
          child: _ModeButton(
            icon: Icons.checklist,
            label: 'Manual',
            active: mode == _PairMode.manual,
            onTap: () => onSelect(_PairMode.manual),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? MabarColors.brandTint : MabarColors.card,
          border: Border.all(color: active ? MabarColors.brand : MabarColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? MabarColors.brand : MabarColors.text1),
            const SizedBox(width: MabarSpacing.x2),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? MabarColors.brand : MabarColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.pool` — daftar pemain; yang sudah dapat pasangan dicoret.
class _Pool extends StatelessWidget {
  final List<Player> players;
  final bool Function(Player) isAssigned;
  final bool Function(Player) isPicked;
  final ValueChanged<Player>? onTap;

  const _Pool({required this.players, required this.isAssigned, required this.isPicked, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: MabarColors.raised, borderRadius: BorderRadius.circular(14)),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final p in players)
            _PoolChip(
              name: p.name,
              picked: isPicked(p),
              done: isAssigned(p) && !isPicked(p),
              onTap: onTap == null ? null : () => onTap!(p),
            ),
        ],
      ),
    );
  }
}

class _PoolChip extends StatelessWidget {
  final String name;
  final bool picked;
  final bool done;
  final VoidCallback? onTap;

  const _PoolChip({required this.name, required this.picked, required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x3, vertical: 6),
      decoration: BoxDecoration(
        color: picked
            ? MabarColors.brand
            : done
            ? MabarColors.muted
            : MabarColors.card,
        border: Border.all(
          color: picked
              ? MabarColors.brand
              : done
              ? Colors.transparent
              : MabarColors.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(MabarRadius.lg),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: picked
              ? MabarColors.textInverse
              : done
              ? MabarColors.text5
              : MabarColors.text1,
          decoration: done ? TextDecoration.lineThrough : null,
          decorationColor: MabarColors.text5,
        ),
      ),
    );

    if (onTap == null || done) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}

/// `.pair-grid` — slot pasangan; kosong = border dashed.
class _PairGrid extends StatelessWidget {
  final int slotCount;
  final List<Pair> pairs;
  final String Function(Pair) label;

  const _PairGrid({required this.slotCount, required this.pairs, required this.label});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: MabarSpacing.x2,
      runSpacing: MabarSpacing.x2,
      children: [
        for (var i = 0; i < slotCount; i++)
          LayoutBuilder(
            builder: (context, _) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - MabarSpacing.x5 * 2 - MabarSpacing.x2) / 2,
              child: i < pairs.length
                  ? _PairSlot(text: label(pairs[i]), filled: true)
                  : _PairSlot(text: 'Slot ${i + 1}', filled: false),
            ),
          ),
      ],
    );
  }
}

class _PairSlot extends StatelessWidget {
  final String text;
  final bool filled;

  const _PairSlot({required this.text, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      alignment: Alignment.center,
      decoration: filled
          ? BoxDecoration(
              color: MabarColors.brandTint,
              border: Border.all(color: MabarColors.brand, width: 2),
              borderRadius: BorderRadius.circular(MabarRadius.xl),
            )
          : BoxDecoration(color: MabarColors.raised, borderRadius: BorderRadius.circular(MabarRadius.xl)),
      foregroundDecoration: filled ? null : MabarDashedBorder(color: MabarColors.border, radius: MabarRadius.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: filled ? 13 : 12,
          fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
          color: filled ? MabarColors.text1 : MabarColors.text4,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _GhostButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: enabled ? MabarColors.text2 : MabarColors.text5),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? MabarColors.text2 : MabarColors.text5,
          ),
        ),
      ),
    );
  }
}
