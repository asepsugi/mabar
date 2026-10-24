import 'package:flutter/material.dart';

import '../../../core/theme/mabar_theme.dart';
import '../../../core/time_text.dart';
import '../../../core/widgets/mabar_controls.dart';
import '../../../core/widgets/match_score_row.dart';
import '../../../models/models.dart';

/// Subjudul app bar Jadwal: "Tennis · Race to 6", atau "… · diakhiri". Waktu tidak di sini: court bisa mulai di
/// jam berbeda, jadi sisa booking ditulis di strip court masing-masing ([ScheduleMatchRow]). [named] = halaman
/// penonton: nama turnamen menggantikan olahraga kalau ada, seperti Beranda (12h).
String scheduleSubtitle(ActiveTournament active, {bool named = false}) {
  final config = active.config;
  final lead = named ? config.name ?? config.sport.label : config.sport.label;
  return '$lead · ${config.format.label}${active.tournament.isFinished ? ' · diakhiri' : ''}';
}

/// Nama depan pasangan dipisah titik tengah: "Andi · Budi" (baris match, Istirahat Fixed).
String pairNames(ActiveTournament active, Pair pair) =>
    pair.playerIds.map((id) => active.playerName(id).split(' ').first).join(' · ');

/// Satu match di Jadwal sebagai [MatchScoreRow]: strip court bernomor (42 pt), nama depan pasangan "Andi · Budi",
/// skor / WO / Seri / "Tidak dimainkan". [onTap] null = tidak bisa diketuk (round terkunci, dibatalkan).
/// [onFill] = tombol "Isi skor" untuk match yang belum diisi. Di round yang sedang berjalan strip-nya membawa sisa
/// booking court itu pada [now].
class ScheduleMatchRow extends StatelessWidget {
  final ActiveTournament active;
  final MatchGame match;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onFill;

  const ScheduleMatchRow({
    super.key,
    required this.active,
    required this.match,
    required this.now,
    this.onTap,
    this.onFill,
  });

  @override
  Widget build(BuildContext context) {
    final courts = active.config.courts;
    final court = active.courtById(match.courtId);

    final winner = match.winnerPairId;
    MatchScoreSide side(Pair pair, int score) {
      final name = pairNames(active, pair);
      return switch (match.status) {
        MatchStatus.done => MatchScoreSide(
          name: name,
          scores: ['$score'],
          win: winner == pair.id,
          tone: winner != null && winner != pair.id ? MatchScoreTone.lost : MatchScoreTone.normal,
        ),
        MatchStatus.wo when match.woLoserPairId == pair.id => MatchScoreSide(
          name: name,
          tag: match.woReason == null ? 'WO' : 'WO · ${match.woReason!.label}',
        ),
        MatchStatus.wo => MatchScoreSide(name: name, win: true),
        _ => MatchScoreSide(name: name),
      };
    }

    final cancelled = match.status == MatchStatus.cancelled;
    final draw = match.status == MatchStatus.done && winner == null;
    return MatchScoreRow(
      badge: '${courts.indexOf(court) + 1}',
      badgeColor: MabarColors.courtPalette[court.colorIndex],
      badgeWidth: 42,
      countdown: match.roundNumber == active.runningRound
          ? countdownText(active.remainingBookingMinutes(court, now))
          : null,
      top: side(match.pair1, match.pair1TotalGames),
      bottom: side(match.pair2, match.pair2TotalGames),
      cancelled: cancelled,
      note: cancelled ? 'Tidak dimainkan' : (draw ? 'Seri' : null),
      trailing: onFill == null ? null : MabarButton(label: 'Isi skor', small: true, onPressed: onFill),
      onTap: cancelled ? null : onTap,
    );
  }
}
