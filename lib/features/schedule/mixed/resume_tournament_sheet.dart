import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mabar_theme.dart';
import '../../../core/widgets/mabar_widgets.dart';
import '../../../models/models.dart';
import '../schedule_widgets.dart';
import '../tournament_controller.dart';

/// Bottom sheet "Lanjutkan Turnamen" mode Mixed — tambah jam booking per court
/// (sering cuma sebagian court yang masih bisa diperpanjang), lalu turnamen
/// kembali LIVE tanpa mengulang. [archived] true kalau turnamennya sudah ditutup.
/// Mengembalikan true kalau turnamen jadi dilanjutkan.
Future<bool> showResumeTournamentSheet(BuildContext context, ActiveTournament source, {bool archived = false}) async {
  final resumed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MabarColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MabarRadius.xxxl + 4)),
    ),
    builder: (_) => _ResumeTournamentSheet(source: source, archived: archived),
  );
  return resumed ?? false;
}

class _ResumeTournamentSheet extends ConsumerStatefulWidget {
  final ActiveTournament source;
  final bool archived;
  const _ResumeTournamentSheet({required this.source, required this.archived});

  @override
  ConsumerState<_ResumeTournamentSheet> createState() => _ResumeTournamentSheetState();
}

class _ResumeTournamentSheetState extends ConsumerState<_ResumeTournamentSheet> {
  static const _hourOptions = [0, 1, 2, 3];

  /// Tambahan jam per court id.
  final Map<String, int> _extraHours = {};

  ActiveTournament get _source => widget.source;

  /// Round yang masih muat setelah ditambah — dihitung dari court yang paling
  /// lama tersedia, karena round tetap jalan selama masih ada satu court.
  int get _roundsAhead {
    final duration = _source.config.matchDurationMinutes;
    var best = 0;
    for (final c in _source.config.courts) {
      final minutes = _source.remainingBookingMinutes(c) + (_extraHours[c.id] ?? 0) * 60;
      best = max(best, minutes ~/ duration);
    }
    return best;
  }

  void _resume() {
    ref
        .read(tournamentProvider.notifier)
        .resume({
          for (final e in _extraHours.entries) e.key: e.value * 60,
        }, from: widget.archived ? _source : null);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final rounds = _roundsAhead;
    final unplayed = _source.matches.where((m) => m.status == MatchStatus.cancelled).length;

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
                  child: const Icon(Icons.more_time, size: 18, color: MabarColors.brand),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lanjutkan Turnamen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: MabarColors.text1,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Skor & peringkat R1–R${_source.roundCount} tetap',
                      style: const TextStyle(fontSize: 11, color: MabarColors.text4),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MabarSpacing.x4),
            const MabarFieldLabel('Tambah Jam Booking'),
            for (final c in _source.config.courts)
              _CourtExtensionRow(
                court: c,
                remainingMinutes: _source.remainingBookingMinutes(c),
                options: _hourOptions,
                selected: _extraHours[c.id] ?? 0,
                onSelect: (h) => setState(() => _extraHours[c.id] = h),
              ),
            const SizedBox(height: MabarSpacing.x4),
            MabarInfoBox(
              variant: rounds > 0 ? MabarInfoVariant.success : MabarInfoVariant.warning,
              icon: rounds > 0 ? Icons.all_inclusive : Icons.timer_off_outlined,
              title: rounds > 0 ? 'Cukup untuk $rounds round lagi' : 'Tambah jam minimal satu court',
              caption: unplayed > 0 ? '$unplayed match yang belum dimainkan bisa diisi skornya lagi' : null,
            ),
            const SizedBox(height: MabarSpacing.x4),
            MabarPrimaryButton(
              label: 'Lanjutkan',
              icon: Icons.play_arrow_rounded,
              onPressed: rounds > 0 || unplayed > 0 ? _resume : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// 200 → "3j 20m", 60 → "1j", 45 → "45m".
String _duration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}j' : '${h}j ${m}m';
}

class _CourtExtensionRow extends StatelessWidget {
  final Court court;
  final int remainingMinutes;
  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;

  const _CourtExtensionRow({
    required this.court,
    required this.remainingMinutes,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MabarColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Di dalam Row supaya badge selebar isinya; `alignment` di
                // CourtBadge membuatnya melebar penuh kalau lebarnya dibatasi.
                Row(children: [CourtBadge(court: court)]),
                const SizedBox(height: 4),
                Text(
                  remainingMinutes > 0 ? 'Sisa ${_duration(remainingMinutes)}' : 'Waktu habis',
                  style: const TextStyle(fontSize: 11, color: MabarColors.text4),
                ),
              ],
            ),
          ),
          for (final h in options) ...[
            const SizedBox(width: 5),
            MabarChip(
              label: h == 0 ? '0' : '+${h}j',
              variant: selected == h ? MabarChipVariant.active : MabarChipVariant.filled,
              onTap: () => onSelect(h),
            ),
          ],
        ],
      ),
    );
  }
}
