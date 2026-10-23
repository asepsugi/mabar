import '../../models/models.dart';
import '../../services/ranking/ranking_calculator.dart';
import '../../services/share/result_text_builder.dart';
import 'widgets/share_poster.dart';

/// Jumlah baris poster Ringkas.
const shareSummaryCount = 5;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// Isi poster Bagikan dari turnamen + baris Peringkat ([entries] = `standingEntriesProvider`, jadi nomornya
/// sama dengan Peringkat). Ringkas = 5 teratas + "+n lainnya"; Lengkap = semua yang bernomor. Fixed
/// menghitung "pasangan" dan menulis nilai + satuan saja (nama dua anggota sudah panjang); Mixed menambah
/// metode lain ("42 poin · 100%", "100% · +12"). Turnamen bernama: nama menggantikan baris kecil
/// "olahraga · mode · tanggal" dan tanggalnya pindah ke ringkasan, sama dengan baris akhir caption.
SharePosterData sharePosterData({
  required ActiveTournament active,
  required List<StandingEntry> entries,
  required RankingMethod method,
  required ShareFormat format,
  required bool isFinal,
}) {
  final config = active.config;
  final fixed = config.mode == PartnerMode.fixed;
  final unit = config.format.unit;
  final ranked = [for (final e in entries) if (e.position != null) e];
  final rows = format == ShareFormat.ringkas ? ranked.take(shareSummaryCount).toList() : ranked;
  final hidden = entries.length - rows.length;
  final created = active.tournament.createdAt;
  final date = '${created.day} ${_months[created.month - 1]} ${created.year}';
  final wo = active.matches.where((m) => m.status == MatchStatus.wo).length;

  SharePosterRow row(StandingEntry e) {
    final s = e.standing;
    final win = '${s.winPercent.round()}%';
    final diff = s.gameDiff > 0 ? '+${s.gameDiff}' : (s.gameDiff < 0 ? '−${-s.gameDiff}' : '0');
    final names = [for (final p in e.players) p.name];
    return method == RankingMethod.totalGames
        ? SharePosterRow(position: e.position!, names: names, value: '${s.totalPoint}', detail: fixed ? unit : '$unit · $win')
        : SharePosterRow(position: e.position!, names: names, value: win, detail: fixed ? null : '· $diff');
  }

  return SharePosterData(
    sport: config.sport,
    eyebrow: config.name ?? '${config.sport.label} · ${config.mode.label} · $date',
    isFinal: isFinal,
    rows: [for (final e in rows) row(e)],
    summary: [
      '${active.playedRoundCount} round',
      '${active.playedMatchCount} match',
      if (wo > 0) '$wo WO',
      if (config.name != null) date,
    ].join(' · '),
    more: format == ShareFormat.ringkas && hidden > 0 ? '+$hidden ${fixed ? 'pasangan' : 'pemain'} lainnya' : null,
    complete: format == ShareFormat.lengkap,
  );
}
