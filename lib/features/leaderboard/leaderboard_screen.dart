import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import '../../services/ranking/ranking_calculator.dart';
import '../schedule/tournament_controller.dart';

/// Screen 8 · Peringkat — bisa dibuka kapan saja, metode ranking bisa
/// diganti langsung di halaman ini.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(tournamentProvider);
    if (active == null) {
      return const Scaffold(body: Center(child: Text('Belum ada turnamen berjalan')));
    }

    final method = ref.watch(rankingMethodProvider);
    final entries = ref.watch(standingEntriesProvider);

    final total = active.matches.length;
    final played = active.playedMatchCount;
    final isFinal = active.isFinal;
    final woCount = active.matches.where((m) => m.status == MatchStatus.wo).length;

    return Scaffold(
      backgroundColor: MabarColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x2, MabarSpacing.x5, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MabarScreenHeader(
                leading: MabarBackButton(label: 'Jadwal', onTap: () => context.pop()),
                trailing: MabarStatusBadge(
                  label: isFinal ? 'FINAL' : 'SEMENTARA',
                  variant: isFinal ? MabarStatusVariant.finalized : MabarStatusVariant.live,
                ),
              ),
              const Row(
                children: [
                  Icon(MabarIcons.trophy, size: 24, color: MabarColors.ink2),
                  SizedBox(width: MabarSpacing.x2),
                  Text(
                    'Peringkat',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: MabarColors.ink,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_roundLabel(active)} · $played/$total match selesai',
                style: const TextStyle(fontSize: 11, color: MabarColors.faint),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(MabarRadius.chip),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : played / total,
                  minHeight: 4,
                  backgroundColor: MabarColors.fill,
                  valueColor: AlwaysStoppedAnimation(isFinal ? MabarColors.ink : MabarColors.ball),
                ),
              ),
              const SizedBox(height: MabarSpacing.x4),
              const MabarFieldLabel('Urutkan Berdasarkan'),
              Row(
                children: [
                  for (final m in RankingMethod.values) ...[
                    MabarChip(
                      label: m.label,
                      variant: method == m ? MabarChipVariant.active : MabarChipVariant.filled,
                      onTap: () => ref.read(rankingMethodProvider.notifier).state = m,
                    ),
                    const SizedBox(width: 5),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: MabarSpacing.x3),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) => _StandingRow(
                    entry: entries[i],
                    method: method,
                    format: active.config.format,
                    // Di mode Fixed statistik kedua anggota pasangan identik,
                    // jadi detail anggota pertama mewakili barisnya.
                    onTap: () => context.push('/detail-player', extra: entries[i].players.first.id),
                  ),
                ),
              ),
              if (woCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: MabarSpacing.x3),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      '⚠ $woCount match WO',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MabarColors.clay),
                    ),
                  ),
                ),
              MabarPrimaryButton(label: 'Bagikan', icon: MabarIcons.shareNetwork, onPressed: () => context.push('/share')),
            ],
          ),
        ),
      ),
    );
  }

  String _roundLabel(ActiveTournament active) => active.config.mode == PartnerMode.fixed
      ? 'R ${active.currentRound}/${active.roundCount}'
      : 'R ${active.roundCount}';
}

/// `.lb-row` — satu baris peringkat.
class _StandingRow extends StatelessWidget {
  final StandingEntry entry;
  final RankingMethod method;
  final ScoreFormat format;
  final VoidCallback onTap;

  const _StandingRow({required this.entry, required this.method, required this.format, required this.onTap});

  /// Belum main = tanpa nomor, diurutkan di belakang.
  int? get position => entry.position;

  PlayerStanding get standing => entry.standing;

  /// Angka besar di kanan mengikuti metode yang sedang dipilih.
  String get _primary =>
      method == RankingMethod.totalGames ? '${standing.totalPoint} poin' : '${standing.winPercent.toStringAsFixed(1)}%';

  String get _secondary {
    if (method == RankingMethod.totalGames) {
      return '${standing.winPercent.toStringAsFixed(1)}% win';
    }
    final diff = standing.gameDiff;
    return '${diff >= 0 ? '+' : ''}$diff ${format.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final diffPositive = standing.gameDiff >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: MabarSpacing.x3),
        decoration: BoxDecoration(
          color: (position ?? 99) <= 3 ? MabarColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(MabarRadius.group),
        ),
        child: Row(
          children: [
            _PositionBadge(position: position),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    // Dua nama lengkap sering tidak muat satu baris di layar HP.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MabarColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Menang ${standing.wins} · Kalah ${standing.losses}'
                    '${standing.draws > 0 ? ' · Seri ${standing.draws}' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: MabarColors.faint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _primary,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: MabarColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _secondary,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: method == RankingMethod.totalGames
                        ? MabarColors.faint
                        : diffPositive
                        ? MabarColors.ink
                        : MabarColors.clay,
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

/// `.lb-pos` — lingkaran nomor; peringkat 1 diberi warna bola (token `ball`).
class _PositionBadge extends StatelessWidget {
  final int? position;
  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final first = position == 1;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: first ? MabarColors.ball : MabarColors.card),
      child: Text(
        position == null ? '–' : '$position',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: first ? MabarColors.ink : MabarColors.ink3),
      ),
    );
  }
}
