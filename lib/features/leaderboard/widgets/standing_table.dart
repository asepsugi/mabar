import 'package:flutter/material.dart';

import '../../../core/theme/mabar_theme.dart';

/// Satu baris [StandingTable]. [names] satu nama (Mixed) atau dua nama ditumpuk (pasangan Fixed).
class StandingTableRow {
  final int position;
  final List<String> names;

  /// Kolom Main: jumlah match yang sudah dimainkan (selesai + WO).
  final int played;

  /// Kolom W–L–D, "3–0–0" atau "4–0".
  final String record;

  /// Kolom terakhir: nilai metode ("42", "75").
  final String value;
  final VoidCallback? onTap;

  const StandingTableRow({required this.position, required this.names, required this.played, required this.record, required this.value, this.onTap});
}

/// `.rank` — tabel peringkat rapat dengan angka rata kanan: # · nama · Main · W–L–D (atau W–L kalau format
/// tidak bisa seri) · nilai metode. Peringkat 1 diberi bola (semua baris bernomor 1). Pemain yang belum
/// main dikelompokkan di bawah judul "Belum main" tanpa nomor ([idleNames]).
class StandingTable extends StatelessWidget {
  /// Judul kolom nama: "Pemain" atau "Pasangan".
  final String subjectLabel;

  /// "W–L–D" atau "W–L".
  final String recordLabel;

  /// "Poin", "Game", atau "Win %".
  final String valueLabel;
  final List<StandingTableRow> rows;
  final List<List<String>> idleNames;

  const StandingTable({
    super.key,
    required this.subjectLabel,
    required this.recordLabel,
    required this.valueLabel,
    required this.rows,
    this.idleNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _row(
        minHeight: 34,
        afterLine: false,
        cells: (
          Text('#', style: _head, textAlign: TextAlign.left),
          Text(subjectLabel, style: _head),
          Text('Main', style: _head, textAlign: TextAlign.right),
          Text(recordLabel, style: _head, textAlign: TextAlign.right),
          Text(valueLabel, style: _head, textAlign: TextAlign.right),
        ),
      ),
      for (final r in rows) _ranked(r),
      if (idleNames.isNotEmpty) ...[
        _row(minHeight: 32, color: _subBackground, cells: (const SizedBox(), Text('Belum main', style: _head), const SizedBox(), const SizedBox(), const SizedBox())),
        for (final names in idleNames) _idle(names),
      ],
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(MabarRadius.group),
      child: ColoredBox(
        color: MabarColors.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++)
              if (i == 0)
                children[i]
              else
                DecoratedBox(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: MabarColors.line))),
                  child: Padding(padding: const EdgeInsets.only(top: 1), child: children[i]),
                ),
          ],
        ),
      ),
    );
  }

  static final _head = MabarType.label.copyWith(fontSize: 12);
  static const _subBackground = Color(0xFFF5F7F9);
  static const _idleNumber = Color(0xFFA3AEB8);

  /// Kolom grid: 30 | sisa | 34 | 58 | 52, jarak 8, padding samping 14. Tinggi minimal termasuk garis atas
  /// 1 pt (border-box), jadi baris setelah garis dikurangi 1.
  Widget _row({
    required double minHeight,
    required (Widget, Widget, Widget, Widget, Widget) cells,
    Color? color,
    VoidCallback? onTap,
    bool afterLine = true,
  }) {
    final row = ColoredBox(
      color: color ?? Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight - (afterLine ? 1 : 0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              SizedBox(width: 30, child: cells.$1),
              const SizedBox(width: 8),
              Expanded(child: cells.$2),
              const SizedBox(width: 8),
              SizedBox(width: 34, child: cells.$3),
              const SizedBox(width: 8),
              SizedBox(width: 58, child: cells.$4),
              const SizedBox(width: 8),
              SizedBox(width: 52, child: cells.$5),
            ],
          ),
        ),
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }

  Widget _ranked(StandingTableRow r) {
    final lead = r.position == 1;
    final number = lead
        ? Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MabarColors.ball,
                shape: BoxShape.circle,
                border: Border.all(color: MabarColors.ballEdge),
              ),
              child: Text('1', style: MabarType.numM.copyWith(fontSize: 17, height: 1, color: MabarColors.ink)),
            ),
          )
        : Text('${r.position}', textAlign: TextAlign.center, style: MabarType.numM.copyWith(fontSize: 20, color: MabarColors.ink2));
    return _row(
      // Pasangan Fixed: dua nama ditumpuk, baris 62 (09c).
      minHeight: r.names.length > 1 ? 62 : MabarSize.rankRow,
      onTap: r.onTap,
      cells: (
        number,
        Text(
          r.names.join('\n'),
          maxLines: r.names.length,
          overflow: TextOverflow.ellipsis,
          style: MabarType.body.copyWith(fontWeight: FontWeight.w600, color: MabarColors.ink),
        ),
        Text('${r.played}', textAlign: TextAlign.right, style: MabarType.numM.copyWith(fontSize: 18, color: MabarColors.ink2)),
        Text(r.record, textAlign: TextAlign.right, style: MabarType.numM.copyWith(fontSize: 18, color: MabarColors.ink2)),
        Text(r.value, textAlign: TextAlign.right, style: MabarType.numM.copyWith(color: MabarColors.ink)),
      ),
    );
  }

  Widget _idle(List<String> names) {
    final dash = MabarType.body.copyWith(color: _idleNumber);
    return _row(
      minHeight: names.length > 1 ? 62 : MabarSize.rankRow,
      cells: (
        Text('–', textAlign: TextAlign.center, style: MabarType.numM.copyWith(fontSize: 20, color: _idleNumber)),
        Text(names.join('\n'), maxLines: names.length, overflow: TextOverflow.ellipsis, style: MabarType.body.copyWith(color: MabarColors.ink3)),
        Text('–', textAlign: TextAlign.right, style: dash),
        Text('–', textAlign: TextAlign.right, style: dash),
        Text('–', textAlign: TextAlign.right, style: dash),
      ),
    );
  }
}
