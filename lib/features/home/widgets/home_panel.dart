import 'package:flutter/material.dart';

import '../../../core/theme/mabar_theme.dart';
import '../../../core/widgets/mabar_controls.dart';
import '../../../core/widgets/mabar_group.dart';
import '../../../models/models.dart';

/// `.homepanel` — panel bawah Beranda yang menimpa lapangan (satu-satunya kartu berbayangan selain menu
/// ⋯): "Turnamen baru", pilihan olahraga, tombol mulai, lalu baris tambahan ([rows]: turnamen terakhir,
/// pasang di HP) dalam grup berlatar paper. Jarak bawah mengikuti safe area (34 di frame).
class HomePanel extends StatelessWidget {
  final SportType sport;
  final ValueChanged<SportType> onSport;
  final VoidCallback onStart;
  final List<Widget> rows;

  const HomePanel({super.key, required this.sport, required this.onSport, required this.onStart, this.rows = const []});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom.clamp(16.0, double.infinity);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottom),
      decoration: const BoxDecoration(
        color: MabarColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(MabarRadius.homePanel)),
        boxShadow: MabarShadows.panel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Turnamen baru',
            style: MabarType.title.copyWith(fontSize: 18, height: 1.4, color: MabarColors.ink),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SportTile(sport: SportType.tennis, selected: sport == SportType.tennis, onTap: onSport)),
              const SizedBox(width: 10),
              Expanded(child: _SportTile(sport: SportType.padel, selected: sport == SportType.padel, onTap: onSport)),
            ],
          ),
          const SizedBox(height: 12),
          MabarButton(label: 'Mulai turnamen ${sport.label}', onPressed: onStart),
          if (rows.isNotEmpty) ...[const SizedBox(height: 12), MabarGroup(color: MabarColors.paper, children: rows)],
        ],
      ),
    );
  }
}

/// `.pickt` — ubin olahraga 76 pt: raket (aset PNG abu) + nama. Terpilih: latar kartu, cincin tinta 2,
/// raket digelapkan (`filter: brightness(.35)`).
class _SportTile extends StatelessWidget {
  final SportType sport;
  final bool selected;
  final ValueChanged<SportType> onTap;

  const _SportTile({required this.sport, required this.selected, required this.onTap});

  static const _darken = ColorFilter.matrix([0.35, 0, 0, 0, 0, 0, 0.35, 0, 0, 0, 0, 0, 0.35, 0, 0, 0, 0, 0, 1, 0]);

  @override
  Widget build(BuildContext context) {
    final racket = Image.asset(sport.assetPath, height: 50);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? MabarColors.card : MabarColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: selected ? const BorderSide(color: MabarColors.ink, width: 2) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(sport),
          child: SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  selected ? ColorFiltered(colorFilter: _darken, child: racket) : racket,
                  const SizedBox(width: 10),
                  Text(
                    sport.label,
                    style: MabarType.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? MabarColors.ink : MabarColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.install-step` — satu langkah pasang di iPhone (01i): nomor di kotak 36 pt, kalimat ([text], bagian
/// tebal dan ikon menu Safari sebaris lewat [icon]), keterangan kecil di bawah.
class InstallStep extends StatelessWidget {
  final int number;
  final List<InlineSpan> text;
  final String? sub;

  const InstallStep({super.key, required this.number, required this.text, this.sub});

  /// Bagian kalimat yang ditebalkan ("Bagikan").
  static TextSpan bold(String text) => TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.w700));

  /// `.chipi` — ikon menu Safari yang dimaksud, sebaris dengan kalimat.
  static WidgetSpan icon(IconData icon) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: MabarColors.paper, borderRadius: BorderRadius.circular(7)),
      child: Icon(icon, size: MabarSize.iconInButton, color: MabarColors.court),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: MabarColors.paper, borderRadius: BorderRadius.circular(MabarRadius.smallButton)),
          child: Text('$number', style: MabarType.numM.copyWith(fontSize: 18, color: MabarColors.ink2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(TextSpan(children: text), style: MabarType.body.copyWith(color: MabarColors.ink)),
              if (sub != null) Text(sub!, style: MabarType.caption),
            ],
          ),
        ),
      ],
    );
  }
}
