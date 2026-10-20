import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import 'mixed/manage_players_sheet.dart';
import 'schedule_widgets.dart';
import 'tournament_controller.dart';

/// Screen 6b · Jadwal Mixed (Endless) — round dibuat satu per satu,
/// round lama tetap bisa dilihat dan skornya masih bisa diedit.
class ScheduleMixedScreen extends ConsumerStatefulWidget {
  final TournamentConfig config;
  const ScheduleMixedScreen({super.key, required this.config});

  @override
  ConsumerState<ScheduleMixedScreen> createState() => _ScheduleMixedScreenState();
}

class _ScheduleMixedScreenState extends ConsumerState<ScheduleMixedScreen> {
  int? _selectedRound;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    ref.read(tournamentProvider.notifier).startIfNeeded(widget.config);
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

  void _generateNext() {
    ref.read(tournamentProvider.notifier).generateNextRound();
    // Langsung pindah ke round yang baru dibuat.
    setState(() => _selectedRound = null);
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(tournamentProvider);
    if (active == null || active.roundCount == 0) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final lastRound = active.roundCount;
    final selected = (_selectedRound ?? lastRound).clamp(1, lastRound);
    final matches = active.matchesOfRound(selected);
    final resting = active.restingPlayerIdsByRound[selected] ?? const [];

    final nextRound = lastRound + 1;
    final courtsLeft = active.courtsAvailableForRound(nextRound);
    final canGenerate = active.canGenerateNextRound;

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
                  trailing: active.tournament.isFinished
                      ? const ScheduleHeaderIcon()
                      : const MabarStatusBadge(label: 'LIVE', variant: MabarStatusVariant.live),
                  center: ScheduleHeaderTitle(active: active, selectedRound: selected, showTotalRounds: false),
                ),
              ),
              ScheduleRoundTabs(
                roundCount: lastRound,
                selected: selected,
                currentRound: lastRound,
                isRoundComplete: active.isRoundComplete,
                onSelect: (r) => setState(() => _selectedRound = r),
                showPlaceholderTab: !active.tournament.isFinished,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScheduleProgressBar(done: active.playedMatchCount, total: active.matches.length),
                    if (!active.tournament.isFinished)
                      MabarInfoBox(
                        variant: MabarInfoVariant.warning,
                        icon: Icons.all_inclusive,
                        title: 'R$nextRound dibuat setelah skor R$lastRound lengkap',
                        caption: courtsLeft.length < active.config.courtCount
                            ? 'Sisa waktu booking: ${courtsLeft.length} dari ${active.config.courtCount} court'
                            : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: MabarSpacing.x3),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
                  children: [
                    for (final m in matches)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ScheduleMatchCard(
                          active: active,
                          match: m,
                          locked: false,
                          onTap: () => context.push('/score-input', extra: m.id),
                        ),
                      ),
                    if (resting.isNotEmpty)
                      ScheduleRestingRow(
                        label: 'Istirahat',
                        names: resting.map(active.playerName).join(', '),
                        hint: selected == lastRound ? '→ Prioritas main di R$nextRound' : null,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
                child: Column(
                  children: [
                    if (!active.tournament.isFinished) ...[
                      _GenerateButton(label: 'Buat R$nextRound', onPressed: canGenerate ? _generateNext : null),
                      const SizedBox(height: MabarSpacing.x2),
                      Text(
                        _generateHint(canGenerate: canGenerate, courtsLeft: courtsLeft.length, lastRound: lastRound),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: MabarColors.text4),
                      ),
                      const SizedBox(height: MabarSpacing.x3),
                    ],
                    ScheduleFooterActions(
                      onRanking: () => context.push('/leaderboard'),
                      onFinish: _finish,
                      extra: active.tournament.isFinished
                          ? null
                          : OutlinedButton.icon(
                              onPressed: () => showManagePlayersSheet(context),
                              icon: const Icon(Icons.group_outlined, size: 18),
                              label: Text('Peserta (${active.activePlayers.length})'),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _generateHint({required bool canGenerate, required int courtsLeft, required int lastRound}) {
    if (courtsLeft == 0) return 'Waktu booking semua court sudah habis';
    if (!canGenerate) return 'Isi semua skor R$lastRound dulu';
    return 'Pemain yang istirahat diprioritaskan di round berikutnya';
  }
}

/// `.btn.btn-outlined-brand` — tombol generate round berikutnya.
class _GenerateButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _GenerateButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        width: double.infinity,
        height: ScheduleFooterActions.height,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            backgroundColor: MabarColors.brandTint,
            foregroundColor: MabarColors.brand,
            disabledForegroundColor: MabarColors.brand,
            side: const BorderSide(color: MabarColors.brand, width: 1.5),
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
