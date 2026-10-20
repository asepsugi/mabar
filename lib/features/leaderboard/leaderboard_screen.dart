import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final isFinal = active.tournament.isFinished || (total > 0 && played == total);
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
                  Icon(Icons.emoji_events_outlined, size: 24, color: MabarColors.warning),
                  SizedBox(width: MabarSpacing.x2),
                  Text(
                    'Peringkat',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: MabarColors.text1,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_roundLabel(active)} · $played/$total match selesai',
                style: const TextStyle(fontSize: 11, color: MabarColors.text4),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(MabarRadius.full),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : played / total,
                  minHeight: 4,
                  backgroundColor: MabarColors.muted,
                  valueColor: AlwaysStoppedAnimation(isFinal ? MabarColors.brand : MabarColors.warning),
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
                    position: i + 1,
                    entry: entries[i],
                    method: method,
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
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MabarColors.danger),
                    ),
                  ),
                ),
              MabarPrimaryButton(label: 'Bagikan', icon: Icons.share, onPressed: () => context.push('/share')),
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
  final int position;
  final StandingEntry entry;
  final RankingMethod method;
  final VoidCallback onTap;

  const _StandingRow({required this.position, required this.entry, required this.method, required this.onTap});

  PlayerStanding get standing => entry.standing;

  /// Angka besar di kanan mengikuti metode yang sedang dipilih.
  String get _primary =>
      method == RankingMethod.totalGames ? '${standing.totalPoint} poin' : '${standing.winPercent.toStringAsFixed(1)}%';

  String get _secondary {
    if (method == RankingMethod.totalGames) {
      return '${standing.winPercent.toStringAsFixed(1)}% win';
    }
    final diff = standing.gameDiff;
    return '${diff >= 0 ? '+' : ''}$diff game';
  }

  @override
  Widget build(BuildContext context) {
    final diffPositive = standing.gameDiff >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: MabarSpacing.x3),
        decoration: BoxDecoration(
          color: position == 1
              ? MabarColors.brandTint
              : position <= 3
              ? MabarColors.raised
              : Colors.transparent,
          borderRadius: BorderRadius.circular(MabarRadius.xl),
          boxShadow: position == 1 ? MabarShadows.sm : null,
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
                      color: MabarColors.text1,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Menang ${standing.wins} · Kalah ${standing.losses}'
                    '${standing.draws > 0 ? ' · Seri ${standing.draws}' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: MabarColors.text4),
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
                    color: MabarColors.text1,
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
                        ? MabarColors.text4
                        : diffPositive
                        ? MabarColors.brand
                        : MabarColors.danger,
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

/// `.lb-pos` — lingkaran nomor, emas/perak/perunggu untuk tiga besar.
class _PositionBadge extends StatelessWidget {
  final int position;
  const _PositionBadge({required this.position});

  static const _medals = {
    1: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
    2: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
    3: [Color(0xFFFDBA74), Color(0xFFEA580C)],
  };

  @override
  Widget build(BuildContext context) {
    final medal = _medals[position];
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medal == null ? MabarColors.card : null,
        gradient: medal == null
            ? null
            : LinearGradient(colors: medal, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: MabarShadows.sm,
      ),
      child: Text(
        '$position',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: medal == null ? MabarColors.text3 : Colors.white,
        ),
      ),
    );
  }
}
