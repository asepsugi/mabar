import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mabar_icons.dart';
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(MabarRadius.sheet)),
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
  static const _maxExtraHours = 6;

  /// Tambahan jam per court id.
  final Map<String, int> _extraHours = {};

  ActiveTournament get _source => widget.source;

  Map<String, int> get _extraMinutes => {for (final e in _extraHours.entries) e.key: e.value * 60};

  void _resume() {
    ref.read(tournamentProvider.notifier).resume(_extraMinutes, from: widget.archived ? _source : null);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final ahead = _source.capacityAhead(_extraMinutes);
    final lastRound = _source.roundCount;
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
                  child: const Icon(MabarIcons.clock, size: 18, color: MabarColors.ink),
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
                        color: MabarColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Skor & peringkat ${lastRound == 1 ? 'R1' : 'R1–R$lastRound'} tetap',
                      style: const TextStyle(fontSize: 11, color: MabarColors.faint),
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
                extraHours: _extraHours[c.id] ?? 0,
                maxHours: _maxExtraHours,
                onChanged: (h) => setState(() => _extraHours[c.id] = h),
              ),
            const SizedBox(height: MabarSpacing.x4),
            MabarInfoBox(
              variant: ahead.matches > 0 ? MabarInfoVariant.success : MabarInfoVariant.warning,
              icon: ahead.matches > 0 ? MabarIcons.shuffle : MabarIcons.clock,
              title: ahead.matches > 0 ? 'Cukup untuk ${ahead.matches} match lagi' : 'Tambah jam minimal satu court',
              caption: [
                if (ahead.rounds > 0) '${ahead.rounds} round (R${lastRound + 1}–R${lastRound + ahead.rounds})',
                // Court yang lebih cepat habis — round sesudahnya main dengan court lebih sedikit.
                if (ahead.fullRounds < ahead.rounds)
                  'mulai R${lastRound + ahead.fullRounds + 1} court berkurang',
                if (unplayed > 0) '$unplayed match yang belum dimainkan bisa diisi skornya lagi',
              ].join(' · ').ifNotEmpty,
            ),
            const SizedBox(height: MabarSpacing.x4),
            MabarPrimaryButton(
              label: 'Lanjutkan',
              icon: MabarIcons.play,
              onPressed: ahead.matches > 0 || unplayed > 0 ? _resume : null,
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String? get ifNotEmpty => isEmpty ? null : this;
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
  final int extraHours;
  final int maxHours;
  final ValueChanged<int> onChanged;

  const _CourtExtensionRow({
    required this.court,
    required this.remainingMinutes,
    required this.extraHours,
    required this.maxHours,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = remainingMinutes > 0 ? 'Sisa ${_duration(remainingMinutes)}' : 'Waktu habis';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MabarColors.line)),
      ),
      // Badge di tengah tinggi blok kanan (stepper + keterangan sisa jam).
      child: Row(
        children: [
          // Di dalam Row supaya badge selebar isinya; `alignment` di CourtBadge
          // membuatnya melebar penuh kalau lebarnya dibatasi.
          CourtBadge(court: court),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MabarStepper(value: extraHours, min: 0, max: maxHours, unit: 'jam', onChanged: onChanged),
              const SizedBox(height: 4),
              Text(
                extraHours == 0 ? remaining : '$remaining → ${_duration(remainingMinutes + extraHours * 60)}',
                style: const TextStyle(fontSize: 11, color: MabarColors.faint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
