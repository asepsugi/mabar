import 'package:flutter/material.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';

class WalkoverResult {
  final String loserPairId;
  final WoReason? reason;

  const WalkoverResult({required this.loserPairId, this.reason});
}

/// Screen 7b · bottom sheet "Tandai Walkover".
Future<WalkoverResult?> showWalkoverSheet(
  BuildContext context, {
  required ActiveTournament active,
  required MatchGame match,
}) {
  return showModalBottomSheet<WalkoverResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MabarColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MabarRadius.sheet)),
    ),
    builder: (_) => _WalkoverSheet(active: active, match: match),
  );
}

class _WalkoverSheet extends StatefulWidget {
  final ActiveTournament active;
  final MatchGame match;

  const _WalkoverSheet({required this.active, required this.match});

  @override
  State<_WalkoverSheet> createState() => _WalkoverSheetState();
}

class _WalkoverSheetState extends State<_WalkoverSheet> {
  String? _loserPairId;
  WoReason? _reason;

  @override
  void initState() {
    super.initState();
    _loserPairId = widget.match.woLoserPairId;
    _reason = widget.match.woReason;
  }

  Pair get _pair1 => widget.match.pair1;
  Pair get _pair2 => widget.match.pair2;

  Pair? get _winner {
    if (_loserPairId == null) return null;
    return _loserPairId == _pair1.id ? _pair2 : _pair1;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final match = widget.match;

    return SafeArea(
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
                decoration: BoxDecoration(color: MabarColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MabarColors.paper,
                    borderRadius: BorderRadius.circular(MabarRadius.chip),
                  ),
                  child: const Icon(MabarIcons.user, size: 18, color: MabarColors.clay),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tandai Walkover',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: MabarColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Round ${match.roundNumber} · Match ${match.matchNumberInRound}',
                      style: const TextStyle(fontSize: 11, color: MabarColors.faint),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih pasangan yang tidak bisa main. Lawan otomatis menang.',
              style: TextStyle(fontSize: 13, color: MabarColors.ink3, height: 1.5),
            ),
            const SizedBox(height: MabarSpacing.x4),
            for (final pair in [_pair1, _pair2]) ...[
              _PairOption(
                label: active.pairLabel(pair),
                selected: _loserPairId == pair.id,
                onTap: () => setState(() => _loserPairId = pair.id),
              ),
              const SizedBox(height: MabarSpacing.x2),
            ],
            const SizedBox(height: 6),
            if (_winner != null) ...[
              MabarInfoBox(
                variant: MabarInfoVariant.success,
                icon: MabarIcons.trophy,
                title: '${active.pairLabel(_winner!)} menang WO',
              ),
              const SizedBox(height: MabarSpacing.x4),
            ],
            const MabarFieldLabel('Alasan (opsional)'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reason in WoReason.values)
                  MabarChip(
                    label: reason.label,
                    variant: _reason == reason ? MabarChipVariant.active : MabarChipVariant.filled,
                    onTap: () => setState(() => _reason = _reason == reason ? null : reason),
                  ),
              ],
            ),
            const SizedBox(height: MabarSpacing.x5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ),
                const SizedBox(width: MabarSpacing.x2),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _loserPairId == null
                        ? null
                        : () => Navigator.pop(context, WalkoverResult(loserPairId: _loserPairId!, reason: _reason)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MabarColors.clay,
                      disabledBackgroundColor: MabarColors.clay.withValues(alpha: 0.4),
                      disabledForegroundColor: Colors.white,
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PairOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PairOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? MabarColors.paper : MabarColors.card,
          border: Border.all(color: selected ? MabarColors.clay : MabarColors.line, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MabarColors.card,
                border: Border.all(color: selected ? MabarColors.clay : MabarColors.line, width: 2),
              ),
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: MabarColors.clay, shape: BoxShape.circle),
                    )
                  : null,
            ),
            const SizedBox(width: MabarSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MabarColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected ? 'Kalah WO' : 'Tetap main',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? MabarColors.clay : MabarColors.faint,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Text(
                'DIPILIH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: MabarColors.clay,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
