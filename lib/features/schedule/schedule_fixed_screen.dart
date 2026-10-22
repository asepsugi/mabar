import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_controls.dart';
import '../../core/widgets/mabar_layers.dart';
import '../../models/models.dart';
import 'schedule_widgets.dart';
import 'tournament_controller.dart';
import 'widgets/resting_list.dart';
import 'widgets/round_tabs.dart';
import 'widgets/schedule_match_row.dart';

/// Screen 05 · Jadwal Fixed — round-robin penuh sudah dibuat. Semua round bisa dibuka lewat tab, tapi
/// round di depan round berjalan terkunci sampai semua skor round itu terisi.
class ScheduleFixedScreen extends ConsumerStatefulWidget {
  final TournamentConfig config;
  const ScheduleFixedScreen({super.key, required this.config});

  @override
  ConsumerState<ScheduleFixedScreen> createState() => _ScheduleFixedScreenState();
}

class _ScheduleFixedScreenState extends ConsumerState<ScheduleFixedScreen> {
  /// Pilihan tab bertahan; tidak pindah otomatis saat round selesai.
  int? _selectedRound;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // Provider tidak boleh diubah selama widget sedang dibangun, jadi turnamen dimulai sesudah frame ini.
    Future.microtask(() {
      if (mounted) ref.read(tournamentProvider.notifier).startIfNeeded(widget.config);
    });
    // Waktu berjalan di subjudul — cukup ditik tiap menit.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _openMenu(BuildContext anchor) async {
    final picked = await showMabarMenu<bool>(
      anchor,
      items: const [MabarMenuItem(icon: MabarIcons.flag, label: 'Akhiri turnamen', value: true, danger: true)],
    );
    if (picked != true || !mounted || !await confirmFinishTournament(context)) return;
    ref.read(tournamentProvider.notifier).finishNow();
    if (mounted) context.push('/leaderboard');
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(tournamentProvider);
    if (active == null) return const Scaffold(backgroundColor: MabarColors.paper);

    final finished = active.tournament.isFinished;
    final current = active.currentRound;
    final live = !finished && !active.isRoundComplete(current);
    final selected = (_selectedRound ?? current).clamp(1, active.roundCount);
    final locked = !finished && selected > current;
    final matches = active.matchesOfRound(selected);
    final played = matches.where((m) => m.status == MatchStatus.done || m.status == MatchStatus.wo).length;
    final byePairId = active.byePairIdByRound[selected];
    final byePair = byePairId == null ? null : active.pairById(byePairId);

    void openScore(MatchGame m) => context.push('/score-input', extra: m.id);

    Widget faded(double opacity, Widget child) => locked ? Opacity(opacity: opacity, child: child) : child;

    return Scaffold(
      backgroundColor: MabarColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MabarAppBar(
            title: 'Round $selected',
            subtitle: scheduleSubtitle(active, ref.read(clockProvider)()),
            onBack: () => context.pop(),
            actions: [
              Builder(
                builder: (anchor) => MabarIconButton(
                  icon: MabarIcons.dotsThree,
                  semanticLabel: 'Menu',
                  // Satu-satunya item Fixed ("Akhiri turnamen") hilang setelah diakhiri.
                  onPressed: finished ? null : () => _openMenu(anchor),
                ),
              ),
            ],
          ),
          RoundTabs(
            count: active.roundCount,
            selected: selected,
            onSelect: (r) => setState(() => _selectedRound = r),
            liveRound: live ? current : null,
            isFuture: finished ? null : (r) => r > current,
            meta: '$played/${matches.length} match',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                if (locked) ...[
                  Row(
                    children: [
                      const Icon(MabarIcons.lockSimple, size: MabarSize.iconInButton, color: MabarColors.ink3),
                      const SizedBox(width: 8),
                      Text(
                        'Terbuka setelah semua skor R${selected - 1} terisi',
                        style: MabarType.body.copyWith(fontSize: 14, color: MabarColors.ink3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                faded(
                  0.5,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, m) in matches.indexed) ...[
                        if (i > 0) const SizedBox(height: 8),
                        ScheduleMatchRow(
                          active: active,
                          match: m,
                          onTap: locked ? null : () => openScore(m),
                          onFill: locked || m.status != MatchStatus.pending ? null : () => openScore(m),
                        ),
                      ],
                    ],
                  ),
                ),
                if (byePair != null) ...[
                  const SizedBox(height: 16),
                  faded(0.6, RestingList(names: [pairNames(active, byePair)])),
                ],
              ],
            ),
          ),
          MabarActionBar(
            children: [
              Expanded(
                child: active.isFinal
                    ? MabarButton(
                        label: 'Lihat peringkat',
                        icon: MabarIcons.ranking,
                        onPressed: () => context.push('/leaderboard'),
                      )
                    : MabarButton(
                        label: 'Peringkat',
                        icon: MabarIcons.ranking,
                        variant: MabarButtonVariant.secondary,
                        onPressed: () => context.push('/leaderboard'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
