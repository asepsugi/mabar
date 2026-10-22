import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/minute_ticker.dart';
import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/time_text.dart';
import '../../core/widgets/mabar_controls.dart';
import '../../models/models.dart';
import '../../services/scoring/score_entry.dart';
import '../schedule/tournament_controller.dart';
import 'walkover_sheet.dart';
import 'widgets/score_board.dart';

/// Screen 08 · Input Skor — papan skor gelap dengan satu angka per tim dan keypad sendiri, untuk ketiga
/// format. Aturan keypad dan sah/tidaknya skor di [ScoreEntry] / [ScoreRules]. Simpan → kembali ke Jadwal.
class ScoreInputScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ScoreInputScreen({super.key, required this.matchId});

  @override
  ConsumerState<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends ConsumerState<ScoreInputScreen> {
  ScoreEntry? _entry;
  MinuteTicker? _clock;

  @override
  void initState() {
    super.initState();
    // Sisa booking court di subjudul mengikuti jam sungguhan, sama dengan kotak jam di Jadwal.
    _clock = MinuteTicker(
      clock: ref.read(clockProvider),
      origin: () => ref.read(tournamentProvider)?.tournament.createdAt,
      onTick: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /// Skor tersimpan (juga skor lama match WO) dibuka terisi, belum ada kotak aktif sampai diketuk.
  ScoreEntry _initial(ActiveTournament active, MatchGame match) => match.sets.isEmpty
      ? ScoreEntry.start(active.config.format)
      : ScoreEntry.edit(active.config.format, match.sets.first);

  void _save(MatchGame match, SetScore score) {
    ref.read(tournamentProvider.notifier).submitScore(match.id, [score]);
    context.pop();
  }

  Future<void> _walkover(ActiveTournament active, MatchGame match) async {
    final result = await showWalkoverSheet(context, active: active, match: match);
    if (result == null || !mounted) return;
    ref.read(tournamentProvider.notifier).markWalkover(match.id, loserPairId: result.loserPairId, reason: result.reason);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(tournamentProvider);
    final match = active?.matchById(widget.matchId);
    if (active == null || match == null) return const Scaffold(backgroundColor: MabarColors.paper);

    final entry = _entry ??= _initial(active, match);
    String names(Pair pair) => pair.playerIds.map((id) => active.playerName(id).split(' ').first).join('\n');
    String team(Pair pair) => names(pair).replaceAll('\n', ' & ');
    final score = entry.score;
    final verdict = entry.verdict;
    final feedback = switch (verdict) {
      ScoreWin(:final winnerSide, :final winnerScore, :final loserScore) =>
        '${team(winnerSide == 1 ? match.pair1 : match.pair2)} menang '
            // Americano: total tetap, jadi yang berarti selisihnya.
            '${active.config.format.method == ScoringMethod.americano ? '+${winnerScore - loserScore}' : '$winnerScore–$loserScore'}',
      ScoreDraw() => 'Seri',
      ScoreInvalid(:final message) => message,
      null => null,
    };

    // Sisa booking court ini, hanya untuk match di round yang sedang berjalan; kurang dari satu match → clay.
    final court = active.courtById(match.courtId);
    String? left;
    var short = false;
    if (match.roundNumber == active.runningRound) {
      final minutes = active.remainingBookingMinutes(court, ref.read(clockProvider)());
      left = minutes > 0 ? 'sisa ${countdownText(minutes)}' : 'waktu habis';
      short = minutes < active.config.matchDurationMinutes;
    }

    return Scaffold(
      backgroundColor: MabarColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MabarAppBar(
            title: court.name,
            subtitle: 'Round ${match.roundNumber} · ${active.config.format.label}${left != null && !short ? ' · $left' : ''}',
            subtitleAlert: short ? left : null,
            onBack: () => context.pop(),
            actions: [
              MabarTextButton(label: 'WO', tone: MabarTextTone.danger, onPressed: () => _walkover(active, match)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: ScoreBoard(
              entry: entry,
              names: (names(match.pair1), names(match.pair2)),
              onSelect: (side) => setState(() => _entry = entry.select(side)),
            ),
          ),
          if (feedback != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                feedback,
                style: verdict is ScoreInvalid
                    ? MabarType.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: MabarColors.clay)
                    : MabarType.body.copyWith(fontSize: 15, color: MabarColors.ink2),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MabarButton(
              label: match.status == MatchStatus.pending ? 'Simpan skor' : 'Perbarui skor',
              icon: score == null ? null : MabarIcons.check,
              onPressed: score == null ? null : () => _save(match, score),
            ),
          ),
          ScoreKeypad(entry: entry, onChanged: (next) => setState(() => _entry = next)),
        ],
      ),
    );
  }
}
