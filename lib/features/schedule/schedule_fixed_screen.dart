import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import 'schedule_widgets.dart';
import 'tournament_controller.dart';

/// Screen 6a · Jadwal Fixed — semua round sudah ditentukan di awal,
/// navigasinya linier (round berikutnya terbuka setelah round ini beres).
class ScheduleFixedScreen extends ConsumerStatefulWidget {
  final TournamentConfig config;
  const ScheduleFixedScreen({super.key, required this.config});

  @override
  ConsumerState<ScheduleFixedScreen> createState() => _ScheduleFixedScreenState();
}

class _ScheduleFixedScreenState extends ConsumerState<ScheduleFixedScreen> {
  int? _selectedRound;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    ref.read(tournamentProvider.notifier).startIfNeeded(widget.config);
    // Jam berjalan di header — cukup ditik tiap menit.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!await confirmFinishTournament(context)) return;
    ref.read(tournamentProvider.notifier).finishNow();
    if (mounted) context.push('/leaderboard');
  }

  String _pairLabel(ActiveTournament active, String pairId) {
    final pair = active.pairById(pairId);
    if (pair == null) return '-';
    return pair.playerIds.map((id) => active.playerName(id).split(' ').first).join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(tournamentProvider);
    if (active == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentRound = active.currentRound;
    final selected = (_selectedRound ?? currentRound).clamp(1, active.roundCount);
    final matches = active.matchesOfRound(selected);
    final byePairId = active.byePairIdByRound[selected];
    final locked = selected > currentRound;

    return Scaffold(
      backgroundColor: MabarColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: MabarSpacing.x2, bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
                child: MabarScreenHeader(
                  leading: MabarBackButton(label: '', onTap: () => context.pop()),
                  trailing: const ScheduleHeaderIcon(),
                  center: ScheduleHeaderTitle(active: active, selectedRound: selected),
                ),
              ),
              ScheduleRoundTabs(
                roundCount: active.roundCount,
                selected: selected,
                currentRound: currentRound,
                isRoundComplete: active.isRoundComplete,
                onSelect: (r) => setState(() => _selectedRound = r),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
                child: ScheduleProgressBar(done: active.playedMatchCount, total: active.matches.length),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
                  children: [
                    if (locked) ...[
                      const MabarInfoBox(
                        variant: MabarInfoVariant.neutral,
                        icon: MabarIcons.lockSimple,
                        title: 'Round belum bisa dimulai',
                        caption: 'Selesaikan skor round sebelumnya',
                      ),
                      const SizedBox(height: 10),
                    ],
                    for (final m in matches)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ScheduleMatchCard(
                          active: active,
                          match: m,
                          locked: locked,
                          onTap: () => context.push('/score-input', extra: m.id),
                        ),
                      ),
                    if (byePairId != null) ScheduleRestingRow(label: 'Istirahat', names: _pairLabel(active, byePairId)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
                child: ScheduleFooterActions(onRanking: () => context.push('/leaderboard'), onFinish: _finish),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
