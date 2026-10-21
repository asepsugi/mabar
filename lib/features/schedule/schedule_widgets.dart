import 'package:flutter/material.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';

/// Potongan UI yang dipakai bareng oleh jadwal Fixed (6a) dan Mixed (6b).

class ScheduleHeaderIcon extends StatelessWidget {
  const ScheduleHeaderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: MabarColors.fill, borderRadius: BorderRadius.circular(MabarRadius.chip)),
      child: const Icon(MabarIcons.dotsThree, size: 16, color: MabarColors.ink3),
    );
  }
}

/// Judul tengah: nama layar + "R 2/7 · ⏱ 45m / 2j" (Fixed) atau "R 2 · ⏱ …" (Mixed).
class ScheduleHeaderTitle extends StatelessWidget {
  final ActiveTournament active;
  final int selectedRound;

  /// Mode endless tidak punya total round, jadi bagian "/n" disembunyikan.
  final bool showTotalRounds;

  const ScheduleHeaderTitle({
    super.key,
    required this.active,
    required this.selectedRound,
    this.showTotalRounds = true,
  });

  String get _title => active.config.mode == PartnerMode.fixed ? 'Jadwal Fixed' : 'Jadwal Mixed';

  String get _elapsed {
    final d = DateTime.now().difference(active.tournament.createdAt);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}j ${m}m' : '${m}m';
  }

  /// Sesi baru selesai saat court terakhir habis — booking bisa beda per
  /// court, apalagi setelah sebagian court diperpanjang (Lanjutkan Turnamen).
  String get _booking {
    final minutes = active.config.courts.map((c) => c.bookingDurationMinutes).reduce((a, b) => a > b ? a : b);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}j' : '${h}j ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final round = showTotalRounds ? 'R $selectedRound/${active.roundCount}' : 'R $selectedRound';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MabarColors.ink),
        ),
        const SizedBox(height: 2),
        Text('$round · ⏱ $_elapsed / $_booking', style: const TextStyle(fontSize: 11, color: MabarColors.faint)),
      ],
    );
  }
}

/// `.tabs-scroll` — tab round horizontal.
class ScheduleRoundTabs extends StatelessWidget {
  final int roundCount;
  final int selected;

  /// Round terakhir yang boleh dibuka. Mode Fixed memakainya untuk mengunci
  /// round di depan; mode Mixed selalu sama dengan [roundCount].
  final int currentRound;
  final bool Function(int) isRoundComplete;
  final ValueChanged<int> onSelect;

  /// Tab "R? " di ujung untuk round yang belum digenerate (mode Mixed).
  final bool showPlaceholderTab;

  const ScheduleRoundTabs({
    super.key,
    required this.roundCount,
    required this.selected,
    required this.currentRound,
    required this.isRoundComplete,
    required this.onSelect,
    this.showPlaceholderTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = roundCount + (showPlaceholderTab ? 1 : 0);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, 4, MabarSpacing.x5, 4),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final round = i + 1;
          if (showPlaceholderTab && round > roundCount) {
            return _Tab(label: 'R$round ?', background: MabarColors.card, foreground: MabarColors.line, dashed: true);
          }

          final done = isRoundComplete(round);
          final isActive = round == selected;
          final upcoming = round > currentRound;

          return GestureDetector(
            onTap: () => onSelect(round),
            child: _Tab(
              label:
                  'R$round${done
                      ? ' ✓'
                      : round == currentRound
                      ? ' ●'
                      : ''}',
              background: isActive
                  ? MabarColors.ink
                  : done
                  ? MabarColors.fill
                  : MabarColors.card,
              foreground: isActive
                  ? Colors.white
                  : done
                  ? MabarColors.faint
                  : upcoming
                  ? MabarColors.line
                  : MabarColors.ink3,
              bordered: !isActive && !done,
              highlighted: isActive,
              dashed: upcoming && !isActive,
            ),
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final bool bordered;
  final bool highlighted;
  final bool dashed;

  const _Tab({
    required this.label,
    required this.background,
    required this.foreground,
    this.bordered = false,
    this.highlighted = false,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MabarRadius.group),
        border: bordered && !dashed
            ? Border.all(color: MabarColors.line, width: 1.5)
            : highlighted
            ? Border.all(color: MabarColors.ink, width: 1.5)
            : null,
      ),
      foregroundDecoration: dashed
          ? const MabarDashedBorder(color: MabarColors.line, radius: MabarRadius.group, width: 1.5)
          : null,
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}

class ScheduleProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const ScheduleProgressBar({super.key, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MabarSpacing.x4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MabarRadius.chip),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : done / total,
          minHeight: 4,
          backgroundColor: MabarColors.fill,
          valueColor: const AlwaysStoppedAnimation(MabarColors.ink),
        ),
      ),
    );
  }
}

/// `.match` — kartu satu pertandingan.
class ScheduleMatchCard extends StatelessWidget {
  final ActiveTournament active;
  final MatchGame match;
  final bool locked;
  final VoidCallback onTap;

  const ScheduleMatchCard({
    super.key,
    required this.active,
    required this.match,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final court = active.courtById(match.courtId);
    final winnerId = match.winnerPairId;
    final isWo = match.status == MatchStatus.wo;
    final isDone = match.status == MatchStatus.done;
    final isCancelled = match.status == MatchStatus.cancelled;

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWo
            ? MabarColors.paper
            : isDone
            ? MabarColors.paper
            : MabarColors.card,
        border: Border.all(
          color: isWo
              ? MabarColors.line
              : isDone
              ? MabarColors.line
              : MabarColors.line,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MATCH ${match.matchNumberInRound}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MabarColors.faint,
                  letterSpacing: 0.3,
                ),
              ),
              Row(
                children: [
                  SportBadge(sport: active.config.sport),
                  const SizedBox(width: 4),
                  CourtBadge(court: court),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TeamColumn(
                  active: active,
                  pair: match.pair1,
                  result: _resultLabel(match, match.pair1.id, winnerId),
                  isWinner: winnerId == match.pair1.id,
                ),
              ),
              const Text(
                'VS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: MabarColors.line, letterSpacing: 1),
              ),
              Expanded(
                child: _TeamColumn(
                  active: active,
                  pair: match.pair2,
                  result: _resultLabel(match, match.pair2.id, winnerId),
                  isWinner: winnerId == match.pair2.id,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: MabarColors.line),
          const SizedBox(height: 10),
          _ScoreLine(match: match, locked: locked),
        ],
      ),
    );

    if (locked || isCancelled) return Opacity(opacity: 0.6, child: card);
    return GestureDetector(onTap: onTap, child: card);
  }

  static String? _resultLabel(MatchGame match, String pairId, String? winnerId) {
    if (winnerId == null) return null;
    if (match.status == MatchStatus.wo) {
      return winnerId == pairId ? 'Menang WO' : 'WO';
    }
    return winnerId == pairId ? 'Menang' : 'Kalah';
  }
}

class _TeamColumn extends StatelessWidget {
  final ActiveTournament active;
  final Pair pair;
  final String? result;
  final bool isWinner;

  const _TeamColumn({required this.active, required this.pair, required this.result, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          pair.playerIds.map((id) => active.playerName(id).split(' ').first).join('\n'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: -0.2,
            color: isWinner ? MabarColors.ink : MabarColors.ink,
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 2),
          Text(
            result!.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: MabarColors.faint,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final MatchGame match;
  final bool locked;

  const _ScoreLine({required this.match, required this.locked});

  @override
  Widget build(BuildContext context) {
    switch (match.status) {
      case MatchStatus.done:
        return Text(
          match.sets.map((s) => '${s.side1}-${s.side2}').join(' · '),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MabarColors.ink,
            letterSpacing: 0.5,
          ),
        );
      case MatchStatus.wo:
        return const Text(
          'Walkover',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MabarColors.clay),
        );
      case MatchStatus.cancelled:
        return const Text(
          'Tidak dimainkan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: MabarColors.line),
        );
      case MatchStatus.pending:
        return Text(
          locked ? 'Menunggu round sebelumnya' : 'Isi skor →',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MabarColors.line),
        );
    }
  }
}

/// Badge court — tingginya disamakan dengan badge sport (32px) supaya sejajar.
class CourtBadge extends StatelessWidget {
  final Court court;
  const CourtBadge({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x3),
      decoration: BoxDecoration(
        color: MabarColors.courtPalette[court.colorIndex],
        borderRadius: BorderRadius.circular(MabarRadius.chip),
      ),
      child: Text(
        court.name.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
      ),
    );
  }
}

class SportBadge extends StatelessWidget {
  final SportType sport;
  const SportBadge({super.key, required this.sport});

  @override
  Widget build(BuildContext context) {
    // `.sport-badge` 32×32 dengan ikon 22×22 di dalamnya.
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: MabarColors.fill, borderRadius: BorderRadius.circular(MabarRadius.chip)),
      child: SizedBox(width: 22, height: 22, child: Image.asset(sport.assetPath, fit: BoxFit.contain)),
    );
  }
}

/// `.resting` — pair yang bye (Fixed) atau pemain yang istirahat (Mixed).
class ScheduleRestingRow extends StatelessWidget {
  final String label;
  final String names;
  final String? hint;

  const ScheduleRestingRow({super.key, required this.label, required this.names, this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x3, vertical: 10),
      decoration: BoxDecoration(color: MabarColors.fill, borderRadius: BorderRadius.circular(MabarRadius.group)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: MabarColors.card, borderRadius: BorderRadius.circular(MabarRadius.chip)),
            child: const Icon(MabarIcons.clock, size: 16, color: MabarColors.ink3),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MabarColors.ink2,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(names, style: const TextStyle(fontSize: 12, color: MabarColors.ink3)),
                if (hint != null)
                  Text(
                    hint!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MabarColors.ink),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.footer-actions` — tombol Peringkat (+ aksi tambahan opsional) + tombol hentikan turnamen.
///
/// Tinggi baris dikunci, bukan diserahkan ke `minimumSize` tema: di web desktop
/// `VisualDensity` memendekkan tombol biasa tapi tidak tombol persegi, jadi
/// keduanya sempat tidak sejajar.
class ScheduleFooterActions extends StatelessWidget {
  static const height = 48.0;

  final VoidCallback onRanking;
  final VoidCallback onFinish;

  /// Tombol sekunder di antara Peringkat dan tombol hentikan (Mixed: Kelola Peserta).
  final Widget? extra;

  const ScheduleFooterActions({super.key, required this.onRanking, required this.onFinish, this.extra});

  @override
  Widget build(BuildContext context) {
    // Padding horizontal tema (20px) terlalu lebar untuk 2 tombol + tombol persegi di HP 375px.
    final style = OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x2));
    return OutlinedButtonTheme(
      data: OutlinedButtonThemeData(style: style.merge(Theme.of(context).outlinedButtonTheme.style)),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRanking,
                icon: const Icon(MabarIcons.ranking, size: 18),
                label: const Text('Peringkat'),
              ),
            ),
            if (extra != null) ...[const SizedBox(width: MabarSpacing.x2), Expanded(child: extra!)],
            const SizedBox(width: MabarSpacing.x2),
            SizedBox(
              width: height,
              child: OutlinedButton(
                onPressed: onFinish,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  foregroundColor: MabarColors.clay,
                  side: const BorderSide(color: MabarColors.clay, width: 1.5),
                ),
                child: const Icon(MabarIcons.flag, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog konfirmasi "Selesaikan Turnamen Sekarang".
Future<bool> confirmFinishTournament(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MabarColors.card,
      title: const Text('Akhiri turnamen?'),
      content: const Text(
        'Match yang belum main tidak dihitung.',
        style: TextStyle(fontSize: 14, color: MabarColors.ink3, height: 1.5),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Akhiri', style: TextStyle(color: MabarColors.clay)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
