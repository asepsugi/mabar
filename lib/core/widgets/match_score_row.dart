import 'package:flutter/material.dart';

import '../theme/mabar_theme.dart';

enum MatchScoreTone {
  /// Skor biasa (pemenang, seri).
  normal,

  /// `.s.l` — skor tim yang kalah.
  lost,

  /// Tambahan nilai WO di riwayat Detail ("+6"), tinta ketiga.
  credit,
}

/// Satu tim di [MatchScoreRow]: nama ("Andi · Budi"), skor per kolom (satu angka; format lama per
/// set), penanda menang, dan tag clay ("WO · Absen").
class MatchScoreSide {
  final String name;
  final List<String> scores;
  final MatchScoreTone tone;
  final bool win;
  final String? tag;

  const MatchScoreSide({required this.name, this.scores = const [], this.tone = MatchScoreTone.normal, this.win = false, this.tag});
}

/// `.bug` — satu match gaya scorebug: strip court berwarna (atau label round di riwayat Detail), dua
/// tim, dan ujung kanan ([trailing]: tombol "Isi skor", atau catatan lewat [note]). Pemenang tebal
/// dengan titik bola; [cancelled] = tidak dimainkan (dicoret, strip abu). [compact] membuang tinggi
/// minimal 84 (riwayat Detail).
class MatchScoreRow extends StatelessWidget {
  final String badge;
  final Color badgeColor;

  /// 19 untuk nomor court, 14 untuk label round ("R5") di riwayat.
  final double badgeFontSize;

  /// 42 di Jadwal (muat kotak jam), 34 di riwayat Detail.
  final double badgeWidth;

  /// `.court.timed` — hitung mundur sisa booking court ("01:15") di kotak jam tinta 22% di dasar strip; hanya di
  /// round yang sedang berjalan.
  final String? countdown;
  final MatchScoreSide top;
  final MatchScoreSide bottom;
  final Widget? trailing;

  /// `.note-r` di kanan: "Seri", "Tidak dimainkan".
  final String? note;
  final bool cancelled;
  final bool compact;
  final VoidCallback? onTap;

  const MatchScoreRow({
    super.key,
    required this.badge,
    required this.badgeColor,
    this.badgeFontSize = 19,
    this.badgeWidth = 34,
    this.countdown,
    required this.top,
    required this.bottom,
    this.trailing,
    this.note,
    this.cancelled = false,
    this.compact = false,
    this.onTap,
  });

  /// Tinta 22% di atas warna court: teks putih 13 pt ≥ 5:1 di kesepuluh warna (langsung di warna court, 4 warna
  /// gagal 4,5:1).
  static const _clockFill = Color(0x380F1E2C);

  Widget _clock(String text) => Container(
    height: 26,
    color: _clockFill,
    alignment: Alignment.center,
    child: Text(
      text,
      style: MabarType.numM.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, height: 1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final number = Text(
      badge,
      style: MabarType.numM.copyWith(fontSize: badgeFontSize, color: Colors.white, height: 1.4),
    );
    final end = trailing != null
        ? Padding(padding: const EdgeInsets.only(right: 12), child: trailing)
        : note != null
        ? Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(note!, style: MabarType.caption),
          )
        : null;
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 0 : 84),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: badgeWidth,
              color: cancelled ? MabarColors.off : badgeColor,
              alignment: Alignment.center,
              child: countdown == null
                  ? number
                  : Column(children: [Expanded(child: Center(child: number)), _clock(countdown!)]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_line(top), const SizedBox(height: 8), _line(bottom)],
                ),
              ),
            ),
            if (end != null) Center(child: end),
          ],
        ),
      ),
    );
    return Material(
      color: MabarColors.card,
      borderRadius: BorderRadius.circular(MabarRadius.group),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: row),
    );
  }

  /// Satu baris tim setinggi baris CSS (16 × 1,4 = 22,4). Mesin teks membulatkan tinggi baris ke 22, dan di
  /// riwayat Detail (tanpa tinggi minimal) selisihnya menumpuk 0,8 pt per baris.
  Widget _line(MatchScoreSide side) => SizedBox(height: 16 * 1.4, child: _team(side));

  /// `#A3AEB8` — skor yang kalah.
  static const _lostScore = Color(0xFFA3AEB8);

  Widget _team(MatchScoreSide side) {
    final name = MabarType.body.copyWith(
      color: cancelled ? MabarColors.faint : (side.win ? MabarColors.ink : MabarColors.ink2),
      fontWeight: side.win && !cancelled ? FontWeight.w700 : FontWeight.w400,
      decoration: cancelled ? TextDecoration.lineThrough : null,
      decorationColor: MabarColors.faint,
    );
    final items = <Widget>[
      Container(
        width: 7,
        height: 7,
        decoration: side.win && !cancelled
            ? BoxDecoration(
                color: MabarColors.ball,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x660F1E2C), strokeAlign: BorderSide.strokeAlignOutside),
              )
            : null,
      ),
      Expanded(child: Text(side.name, style: name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      if (side.scores.isNotEmpty)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < side.scores.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              SizedBox(
                width: 20,
                child: Text(
                  side.scores[i],
                  textAlign: TextAlign.right,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: MabarType.numM.copyWith(
                    height: 1,
                    color: switch (side.tone) {
                      MatchScoreTone.normal => MabarColors.ink,
                      MatchScoreTone.lost => _lostScore,
                      MatchScoreTone.credit => MabarColors.ink3,
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      if (side.tag != null)
        Text(
          side.tag!,
          style: MabarType.label.copyWith(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 12 * 0.02, color: MabarColors.clay),
        ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: 8), items[i]],
      ],
    );
  }
}
