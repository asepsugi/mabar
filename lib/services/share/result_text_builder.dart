import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../ranking/ranking_calculator.dart';

enum ShareFormat { ringkas, lengkap }

extension ShareFormatX on ShareFormat {
  String get label => switch (this) {
    ShareFormat.ringkas => 'Ringkas',
    ShareFormat.lengkap => 'Lengkap',
  };
}

/// Menyusun teks hasil turnamen untuk dibagikan ke WhatsApp/Telegram/clipboard.
class ResultTextBuilder {
  static String build({
    required Tournament tournament,
    required List<StandingEntry> standings,
    required ShareFormat format,
  }) {
    final config = tournament.config;
    final buffer = StringBuffer()
      ..writeln('🏆 Mabar Turnamen · ${config.sport.label}')
      ..writeln(DateFormat('d MMMM yyyy', 'id').format(tournament.createdAt))
      ..writeln();

    buffer.writeln('Peringkat Akhir');
    for (var i = 0; i < standings.length; i++) {
      final entry = standings[i];
      final s = entry.standing;
      final diff = s.gameDiff;
      buffer.writeln(
        '${i + 1}. ${entry.label} — ${s.totalPoint} poin · '
        '${s.winPercent.toStringAsFixed(1)}% '
        '(${s.wins}-${s.losses}, ${diff >= 0 ? '+' : ''}$diff game)',
      );
    }

    if (format == ShareFormat.lengkap) {
      buffer.writeln();
      buffer.writeln('Hasil per Round');
      var round = 0;
      for (final m in tournament.matches) {
        if (m.status == MatchStatus.pending) continue;
        if (m.roundNumber != round) {
          round = m.roundNumber;
          buffer.writeln('· Round $round');
        }
        buffer.writeln('  ${_matchLine(config, m)}');
      }
    }

    buffer
      ..writeln()
      ..writeln(summaryLine(tournament));
    return buffer.toString().trimRight();
  }

  /// "7 round · 14 match · 1 WO · 14 September 2026"
  static String summaryLine(Tournament tournament) {
    final matches = tournament.matches;
    final rounds = matches.isEmpty ? 0 : matches.last.roundNumber;
    final played = matches.where((m) => m.status == MatchStatus.done || m.status == MatchStatus.wo).length;
    final wo = matches.where((m) => m.status == MatchStatus.wo).length;

    return [
      '$rounds round',
      '$played match',
      if (wo > 0) '$wo WO',
      DateFormat('d MMM yyyy', 'id').format(tournament.createdAt),
    ].join(' · ');
  }

  static String _matchLine(TournamentConfig config, MatchGame m) {
    String name(String id) => config.players
        .firstWhere(
          (p) => p.id == id,
          orElse: () => const Player(id: '', name: '?'),
        )
        .name;
    String pair(Pair p) => p.playerIds.map((id) => name(id).split(' ').first).join('+');

    final left = pair(m.pair1);
    final right = pair(m.pair2);

    switch (m.status) {
      case MatchStatus.done:
        final score = m.sets.map((s) => '${s.side1}-${s.side2}').join(' ');
        return '$left vs $right → $score';
      case MatchStatus.wo:
        final winner = m.winnerPairId == m.pair1.id ? left : right;
        return '$left vs $right → WO, $winner menang';
      case MatchStatus.cancelled:
        return '$left vs $right → tidak dimainkan';
      case MatchStatus.pending:
        return '$left vs $right';
    }
  }
}
