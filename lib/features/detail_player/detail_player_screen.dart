import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import '../../services/ranking/ranking_calculator.dart';
import '../schedule/tournament_controller.dart';

/// Screen 9 · Detail Pemain — statistik satu peserta + riwayat pertandingannya.
class DetailPlayerScreen extends ConsumerWidget {
  final String playerId;
  const DetailPlayerScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(tournamentProvider);
    if (active == null) {
      return const Scaffold(body: Center(child: Text('Belum ada turnamen berjalan')));
    }

    // Urutannya ikut chip yang dipilih di layar Peringkat — termasuk
    // penggabungan per pasangan di mode Fixed, supaya nomor peringkat di sini
    // sama dengan yang barusan dilihat host.
    final entries = ref.watch(standingEntriesProvider);
    final entry = entries.where((e) => e.hasPlayer(playerId)).firstOrNull;
    if (entry == null) {
      return const Scaffold(body: Center(child: Text('Pemain tidak ditemukan')));
    }

    final standing = entry.standing;
    final player = active.config.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => const Player(id: '', name: '?'),
    );
    final profile = PlayerProfile.of(playerId: playerId, matches: active.matches);
    final otherPlayers = active.config.players.length - 1;

    return Scaffold(
      backgroundColor: MabarColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x2, MabarSpacing.x5, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MabarScreenHeader(
                leading: MabarBackButton(label: 'Peringkat', onTap: () => context.pop()),
                trailing: const Text(
                  'Detail',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MabarColors.faint,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _PlayerHeader(player: player, standing: standing, position: entry.position, unit: active.config.format.unit),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: MabarSpacing.x3),
                  children: [
                    _StatGrid(standing: standing, format: active.config.format),
                    const SizedBox(height: MabarSpacing.x4),
                    _CoverageCard(
                      partners: profile.partnerIds.length,
                      opponents: profile.opponentIds.length,
                      total: otherPlayers,
                      woLosses: standing.woLosses,
                    ),
                    const SizedBox(height: MabarSpacing.x4),
                    const MabarFieldLabel('Riwayat Match'),
                    if (profile.playedMatches.isEmpty)
                      const MabarInfoBox(
                        variant: MabarInfoVariant.neutral,
                        icon: MabarIcons.clockCounterClockwise,
                        title: 'Belum ada match',
                        caption: 'Muncul setelah skor pertama diisi.',
                      )
                    else
                      for (final m in profile.playedMatches)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _HistoryRow(active: active, match: m, playerId: playerId),
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
}

class _PlayerHeader extends StatelessWidget {
  final Player player;
  final PlayerStanding standing;

  /// Null = belum main.
  final int? position;
  final String unit;

  const _PlayerHeader({required this.player, required this.standing, required this.position, required this.unit});

  @override
  Widget build(BuildContext context) {
    final initial = player.name.trim().isEmpty ? '?' : player.name.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: MabarSpacing.x5),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [MabarColors.ink, MabarColors.ink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(
              initial,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MabarColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${position == null ? 'Belum main' : 'Peringkat #$position'} · ${standing.totalPoint} $unit · '
                  '${standing.winPercent.toStringAsFixed(1)}% win',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MabarColors.faint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final PlayerStanding standing;
  final ScoreFormat format;
  const _StatGrid({required this.standing, required this.format});

  @override
  Widget build(BuildContext context) {
    final diff = standing.gameDiff;
    return Column(
      children: [
        // Total point jadi metrik utama peringkat, jadi ditaruh paling atas.
        SizedBox(
          width: double.infinity,
          child: MabarStatBox(value: '${standing.totalPoint}', label: 'Total Point', valueColor: MabarColors.ink),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MabarStatBox(
                value: '${standing.winPercent.toStringAsFixed(1)}%',
                label: 'Win %',
                valueColor: MabarColors.ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MabarStatBox(
                value: '${diff >= 0 ? '+' : ''}$diff',
                label: format.method == ScoringMethod.americano ? 'Selisih Poin' : 'Selisih Game',
                valueColor: diff >= 0 ? MabarColors.ink : MabarColors.clay,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MabarStatBox(value: '${standing.wins}–${standing.losses}', label: 'W – L'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MabarStatBox(value: '${standing.matchesPlayed}', label: 'Match'),
            ),
          ],
        ),
      ],
    );
  }
}

/// `.card-flat` — cakupan partner & lawan unik.
class _CoverageCard extends StatelessWidget {
  final int partners;
  final int opponents;
  final int total;
  final int woLosses;

  const _CoverageCard({required this.partners, required this.opponents, required this.total, required this.woLosses});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: MabarSpacing.x2),
      decoration: BoxDecoration(color: MabarColors.paper, borderRadius: BorderRadius.circular(MabarRadius.group)),
      child: Column(
        children: [
          _CoverageRow(label: 'Beda partner', value: '$partners / $total'),
          const Divider(height: 1, color: MabarColors.line),
          _CoverageRow(label: 'Beda lawan', value: '$opponents / $total'),
          const Divider(height: 1, color: MabarColors.line),
          _CoverageRow(label: 'Kalah WO', value: '$woLosses'),
        ],
      ),
    );
  }
}

class _CoverageRow extends StatelessWidget {
  final String label;
  final String value;

  const _CoverageRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: MabarColors.ink2)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MabarColors.ink),
          ),
        ],
      ),
    );
  }
}

/// Satu baris riwayat: hasil, lawan, dan skornya.
class _HistoryRow extends StatelessWidget {
  final ActiveTournament active;
  final MatchGame match;
  final String playerId;

  const _HistoryRow({required this.active, required this.match, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final ownPair = match.pair1.contains(playerId) ? match.pair1 : match.pair2;
    final opponent = ownPair.id == match.pair1.id ? match.pair2 : match.pair1;

    final winnerId = match.winnerPairId;
    final won = winnerId == ownPair.id;
    final drawn = winnerId == null;
    final isWo = match.status == MatchStatus.wo;

    final (badgeLabel, badgeColor, background) = switch ((isWo, won, drawn)) {
      (true, _, _) => ('WO', MabarColors.clay, MabarColors.paper),
      (_, _, true) => ('S', MabarColors.ink3, MabarColors.fill),
      (_, true, _) => ('W', MabarColors.ink, MabarColors.paper),
      _ => ('L', MabarColors.clay, MabarColors.paper),
    };

    final detail = isWo
        ? 'Walkover (${won ? 'menang' : 'kalah'})'
        : match.sets
              .map((s) {
                final own = ownPair.id == match.pair1.id;
                return '${own ? s.side1 : s.side2}-${own ? s.side2 : s.side1}';
              })
              .join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x3, vertical: MabarSpacing.x2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(MabarRadius.group)),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: badgeLabel.length > 1 ? 9 : 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'R${match.roundNumber} · vs ${active.pairLabel(opponent)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MabarColors.ink),
                ),
                Text(detail, style: const TextStyle(fontSize: 10, color: MabarColors.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
