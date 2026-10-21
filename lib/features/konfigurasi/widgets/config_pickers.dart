import 'package:flutter/material.dart';

import '../../../core/theme/mabar_icons.dart';
import '../../../core/theme/mabar_theme.dart';
import '../../../models/models.dart';

/// `.modes` — dua kartu Fixed / Mixed, isi rata tengah. Ilustrasi dari ikon: orang 40 pt + penghubung
/// 20 pt (`equals` = pasangan tetap, `shuffle` = berganti), warnanya ikut status terpilih.
class ModePicker extends StatelessWidget {
  final PartnerMode selected;
  final ValueChanged<PartnerMode> onChanged;

  const ModePicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _card(PartnerMode.fixed, MabarIcons.equals, 'Pasangan tetap')),
          const SizedBox(width: 10),
          Expanded(child: _card(PartnerMode.mixed, MabarIcons.shuffle, 'Pasangan berganti')),
        ],
      ),
    );
  }

  Widget _card(PartnerMode mode, IconData link, String description) {
    final on = mode == selected;
    final art = on ? MabarColors.ink : MabarColors.ink3;
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: MabarColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: on ? MabarColors.ink : MabarColors.line, width: on ? 2 : 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(mode),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(MabarIcons.user, size: 40, color: art),
                      const SizedBox(width: 2),
                      Icon(link, size: 20, color: art),
                      const SizedBox(width: 2),
                      Icon(MabarIcons.user, size: 40, color: art),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(mode.label, style: MabarType.body.copyWith(fontSize: 17, fontWeight: FontWeight.w700, color: MabarColors.ink)),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: MabarType.caption.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.swatch` — lingkaran warna court. Dengan [number]: penanda court di baris Konfigurasi (30 pt, nomor
/// putih 15). [selected] = cincin tinta di luar dengan celah putih, plus centang (sheet warna).
class CourtSwatch extends StatelessWidget {
  final Color color;
  final double size;
  final int? number;
  final bool selected;
  final VoidCallback? onTap;

  const CourtSwatch({super.key, required this.color, this.size = 30, this.number, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // `0 0 0 3px card, 0 0 0 5px ink`: celah putih 3 lalu cincin tinta 2, di luar lingkaran.
        boxShadow: selected
            ? const [BoxShadow(color: MabarColors.ink, spreadRadius: 5), BoxShadow(color: MabarColors.card, spreadRadius: 3)]
            : null,
      ),
      child: number != null
          ? Text('$number', style: MabarType.numM.copyWith(fontSize: 15, color: Colors.white))
          : selected
          ? const Icon(MabarIcons.check, size: MabarSize.icon, color: Colors.white)
          : null,
    );
    return onTap == null
        ? circle
        : Semantics(
            button: true,
            selected: selected,
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: circle),
          );
  }
}

/// `.swatches` — 10 warna court dalam 5 kolom (sheet pilih warna, 03e). Ketuk = pilih dan tutup.
class CourtColorGrid extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const CourtColorGrid({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const palette = MabarColors.courtPalette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth - 4 * 12) / 5;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < palette.length; i++)
              CourtSwatch(color: palette[i], size: size, selected: i == selected, onTap: () => onSelect(i)),
          ],
        );
      },
    );
  }
}
