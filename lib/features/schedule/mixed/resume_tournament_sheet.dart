import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mabar_icons.dart';
import '../../../core/theme/mabar_theme.dart';
import '../../../core/widgets/mabar_controls.dart';
import '../../../core/widgets/mabar_group.dart';
import '../../../core/widgets/mabar_inputs.dart';
import '../../../core/widgets/mabar_layers.dart';
import '../../../models/models.dart';
import '../../konfigurasi/widgets/config_pickers.dart';
import '../tournament_controller.dart';

/// Sheet 08c "Lanjutkan turnamen" (Mixed) — tambah jam booking per court (sering cuma sebagian court
/// yang bisa diperpanjang), lalu turnamen aktif lagi tanpa mengulang. [archived] = dari Beranda, turnamen
/// sudah ditutup. Mengembalikan true kalau turnamen jadi dilanjutkan.
Future<bool> showResumeTournamentSheet(BuildContext context, ActiveTournament source, {bool archived = false}) async {
  final n = source.roundCount;
  final resumed = await showMabarSheet<bool>(
    context,
    title: 'Lanjutkan turnamen',
    subtitle: 'Skor & klasemen ${n == 1 ? 'R1' : 'R1–R$n'} tetap',
    builder: (_) => _ResumeTournament(source: source, archived: archived),
  );
  return resumed ?? false;
}

/// 200 → "3j 20m", 60 → "1j", 45 → "45m".
String _duration(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}j' : '${h}j ${m}m';
}

class _ResumeTournament extends ConsumerStatefulWidget {
  final ActiveTournament source;
  final bool archived;

  const _ResumeTournament({required this.source, required this.archived});

  @override
  ConsumerState<_ResumeTournament> createState() => _ResumeTournamentState();
}

class _ResumeTournamentState extends ConsumerState<_ResumeTournament> {
  static const _maxExtraHours = 6;
  static const _parentLine = StrutStyle(fontFamily: MabarType.family, fontSize: 16, height: 1.4, forceStrutHeight: true);

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
    final now = ref.read(clockProvider)();
    final ahead = _source.capacityAhead(now, _extraMinutes);
    final n = _source.roundCount;
    final unplayed = _source.matches.where((m) => m.status == MatchStatus.cancelled).length;
    final courts = _source.config.courts;
    final caption = MabarType.caption.copyWith(color: MabarColors.ink3);

    final facts = [
      if (ahead.rounds == 1) '1 round (R${n + 1})' else '${ahead.rounds} round (R${n + 1}–R${n + ahead.rounds})',
      if (ahead.matchesPerRound < ahead.courts)
        'maks ${ahead.matchesPerRound} match per round (${_source.activePlayers.length} pemain)'
      else if (ahead.fewerCourtsFrom != null)
        '${ahead.courts} court, berkurang mulai R${n + ahead.fewerCourtsFrom!}'
      else
        '${ahead.courts} court',
    ].join(' · ');
    final unplayedNote = unplayed > 0 ? '$unplayed match yang belum dimainkan bisa diisi lagi' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MabarSection(
          header: const MabarGroupLabel('Tambah jam booking'),
          child: MabarGroup(
            color: MabarColors.paper,
            children: [
              for (final (i, c) in courts.indexed)
                () {
                  final remaining = _source.remainingBookingMinutes(c, now);
                  final extra = _extraHours[c.id] ?? 0;
                  final left = remaining > 0 ? 'Sisa ${_duration(remaining)}' : 'Waktu habis';
                  return MabarRow(
                    padded: true,
                    leading: CourtSwatch(color: MabarColors.courtPalette[c.colorIndex], number: i + 1),
                    titleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: MabarType.body.copyWith(fontWeight: FontWeight.w600, color: MabarColors.ink)),
                        Text(extra == 0 ? left : '$left → ${_duration(remaining + extra * 60)}', style: MabarType.caption),
                      ],
                    ),
                    trailing: MabarStepper(
                      value: extra,
                      min: 0,
                      max: _maxExtraHours,
                      unit: 'jam',
                      onChanged: (h) => setState(() => _extraHours[c.id] = h),
                    ),
                  );
                }(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
          child: ahead.matches > 0
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${ahead.matches}', style: MabarType.numM.copyWith(fontSize: 40, height: 1, color: MabarColors.ink)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('match lagi', style: MabarType.body.copyWith(fontWeight: FontWeight.w700, color: MabarColors.ink)),
                          // Teks kecil di dalam blok 16/1,4: tinggi barisnya ikut induk (22,4), seperti CSS.
                          Text(facts, style: caption, strutStyle: _parentLine),
                          if (unplayedNote != null) Text(unplayedNote, style: caption, strutStyle: _parentLine),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(
                  unplayedNote ?? 'Tambah jam minimal satu court',
                  style: MabarType.body.copyWith(fontSize: 15, color: MabarColors.ink3),
                ),
        ),
        const SizedBox(height: 16),
        MabarButton(
          label: 'Lanjutkan',
          icon: MabarIcons.play,
          onPressed: ahead.matches > 0 || unplayed > 0 ? _resume : null,
        ),
      ],
    );
  }
}
