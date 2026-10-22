import 'package:flutter/material.dart';

import '../../../core/theme/mabar_theme.dart';
import '../../../core/widgets/mabar_controls.dart';
import '../../../core/widgets/match_score_row.dart';
import '../../../models/models.dart';

/// Subjudul app bar Jadwal: "Tennis · Race to 6 · 45m dari 2 jam" — waktu berjalan sejak mulai dibanding
/// booking court terpanjang (sesi baru selesai saat court terakhir habis), atau "diakhiri".
String scheduleSubtitle(ActiveTournament active, DateTime now) {
  final config = active.config;
  final String time;
  if (active.tournament.isFinished) {
    time = 'diakhiri';
  } else {
    String span(int minutes) {
      final h = minutes ~/ 60, m = minutes % 60;
      return h == 0 ? '${m}m' : (m == 0 ? '${h}j' : '${h}j ${m}m');
    }

    final elapsed = now.difference(active.tournament.createdAt).inMinutes;
    final booking = config.courts.map((c) => c.bookingDurationMinutes).reduce((a, b) => a > b ? a : b);
    time = '${span(elapsed)} dari ${booking % 60 == 0 ? '${booking ~/ 60} jam' : span(booking)}';
  }
  return '${config.sport.label} · ${config.format.label} · $time';
}

/// Nama depan pasangan dipisah titik tengah: "Andi · Budi" (baris match, Istirahat Fixed).
String pairNames(ActiveTournament active, Pair pair) =>
    pair.playerIds.map((id) => active.playerName(id).split(' ').first).join(' · ');

/// Satu match di Jadwal sebagai [MatchScoreRow]: strip court bernomor, nama depan pasangan "Andi · Budi",
/// skor / WO / Seri / "Tidak dimainkan". [onTap] null = tidak bisa diketuk (round terkunci, dibatalkan).
/// [onFill] = tombol "Isi skor" untuk match yang belum diisi.
class ScheduleMatchRow extends StatelessWidget {
  final ActiveTournament active;
  final MatchGame match;
  final VoidCallback? onTap;
  final VoidCallback? onFill;

  const ScheduleMatchRow({super.key, required this.active, required this.match, this.onTap, this.onFill});

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
      top: side(match.pair1, match.pair1TotalGames),
      bottom: side(match.pair2, match.pair2TotalGames),
      cancelled: cancelled,
      note: cancelled ? 'Tidak dimainkan' : (draw ? 'Seri' : null),
      trailing: onFill == null ? null : MabarButton(label: 'Isi skor', small: true, onPressed: onFill),
      onTap: cancelled ? null : onTap,
    );
  }
}
