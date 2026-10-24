import 'package:flutter/material.dart';

import '../theme/mabar_icons.dart';
import '../theme/mabar_theme.dart';

/// `.group` — kartu daftar bergaya pengaturan. Antar-anak diberi garis 1 pt; seperti `border-top` CSS
/// (border-box) garisnya memakan tempat, dan [MabarRow] di bawah garis mengurangi tinggi minimalnya
/// supaya total tetap 52. Latar [color] = paper di dalam sheet dan panel Beranda.
class MabarGroup extends StatelessWidget {
  final List<Widget> children;
  final Color color;

  const MabarGroup({super.key, required this.children, this.color = MabarColors.card});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(MabarRadius.group),
      child: ColoredBox(
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++)
              if (i == 0)
                children[i]
              else
                DecoratedBox(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: MabarColors.line))),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: _BelowDivider(child: children[i]),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Penanda bahwa baris ini ada di bawah garis grup (lihat [MabarGroup]).
class _BelowDivider extends InheritedWidget {
  const _BelowDivider({required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_BelowDivider>() != null;

  @override
  bool updateShouldNotify(_BelowDivider oldWidget) => false;
}

enum MabarRowTone {
  normal,

  /// `.row.link` — baris yang berupa aksi, biru court tebal.
  link,

  /// `.row.danger` — aksi berbahaya, clay.
  danger,
}

/// `.row` — satu baris grup, tinggi minimal 52. Isi: [leading] · judul (+ [subtitle]) · [value] ·
/// [trailing] · chevron, berjarak 12. [padded] = `.row.pad` (padding vertikal 12, untuk baris dua
/// tingkat). Untuk isi bebas yang ditumpuk (mis. segmented di grup Skor) pakai [MabarRow.stack].
class MabarRow extends StatelessWidget {
  final Widget? leading;
  final String? title;

  /// Isi judul selain teks biasa, mis. kotak isian sebaris; menggantikan [title].
  final Widget? titleWidget;
  final String? subtitle;

  /// Judul satu baris berelipsis (isi bebas dari host, mis. nama turnamen); default boleh turun baris.
  final bool titleOneLine;
  final String? value;
  final Widget? trailing;
  final bool chevron;
  final bool padded;
  final MabarRowTone tone;
  final VoidCallback? onTap;
  final List<Widget>? _stacked;

  const MabarRow({
    super.key,
    this.leading,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.titleOneLine = false,
    this.value,
    this.trailing,
    this.chevron = false,
    this.padded = false,
    this.tone = MabarRowTone.normal,
    this.onTap,
  }) : _stacked = null;

  /// `.row.stack` — anak ditumpuk selebar baris, jarak 8, padding vertikal 12.
  const MabarRow.stack({super.key, required List<Widget> children})
    : _stacked = children,
      leading = null,
      title = null,
      titleWidget = null,
      subtitle = null,
      titleOneLine = false,
      value = null,
      trailing = null,
      chevron = false,
      padded = true,
      tone = MabarRowTone.normal,
      onTap = null;

  @override
  Widget build(BuildContext context) {
    final minHeight = MabarSize.row - (_BelowDivider.of(context) ? 1 : 0);
    final stacked = _stacked;
    final Widget content;
    if (stacked != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < stacked.length; i++) ...[if (i > 0) const SizedBox(height: 8), stacked[i]],
        ],
      );
    } else {
      final titleStyle = switch (tone) {
        MabarRowTone.normal => MabarType.body.copyWith(color: MabarColors.ink),
        MabarRowTone.link => MabarType.body.copyWith(color: MabarColors.court, fontWeight: FontWeight.w700),
        MabarRowTone.danger => MabarType.body.copyWith(color: MabarColors.clay, fontWeight: FontWeight.w600),
      };
      final items = <Widget>[
        ?leading,
        Expanded(
          child:
              titleWidget ??
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    titleOneLine
                        ? Text(title!, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : Text(title!, style: titleStyle),
                  if (subtitle != null) Text(subtitle!, style: MabarType.caption),
                ],
              ),
        ),
        if (value != null) Text(value!, style: MabarType.body.copyWith(color: MabarColors.ink3)),
        ?trailing,
        if (chevron) const Icon(MabarIcons.caretRight, size: MabarSize.iconInButton, color: MabarColors.faint),
      ];
      content = Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: 12), items[i]],
        ],
      );
    }

    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: padded ? 12 : 0),
        child: Align(alignment: Alignment.centerLeft, widthFactor: 1, child: content),
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

/// `.rowic` — ikon 24 biru court di kotak kartu 38 pt, pembuka baris (panel Beranda, link di sheet Live score).
class MabarRowIcon extends StatelessWidget {
  final IconData icon;

  const MabarRowIcon(this.icon, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(color: MabarColors.card, borderRadius: BorderRadius.circular(MabarRadius.smallButton)),
    child: Icon(icon, size: MabarSize.icon, color: MabarColors.court),
  );
}

/// `.glabel` — label di atas grup (13/700 ink-3). Jaraknya ke grup 8; lihat [MabarSection].
class MabarGroupLabel extends StatelessWidget {
  final String text;

  const MabarGroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(text, style: MabarType.label));
}

/// `.gnote` — catatan di bawah grup; [error] = `.gnote.err` (clay).
class MabarGroupNote extends StatelessWidget {
  final String text;
  final bool error;

  const MabarGroupNote(this.text, {super.key, this.error = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(text, style: MabarType.caption.copyWith(color: error ? MabarColors.clay : MabarColors.ink3)),
  );
}

/// `.ghead` — label grup setinggi 18 dengan satu aksi teks atau tag di ujung kanannya. Aksi 44 pt
/// dibiarkan meluber ke atas-bawah dan menjorok 6 pt ke kanan (`margin-right: -6px`), seperti di CSS.
class MabarGroupHeader extends StatelessWidget {
  /// Label kiri; berupa widget supaya bisa memuat bagian berwarna ("Istirahat · Prioritas main di R4").
  final Widget label;
  final Widget? trailing;

  const MabarGroupHeader({super.key, required this.label, this.trailing});

  MabarGroupHeader.text(String label, {Key? key, Widget? trailing})
    : this(key: key, label: Text(label, style: MabarType.label), trailing: trailing);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: 4,
            child: Align(alignment: Alignment.centerLeft, child: label),
          ),
          if (trailing != null)
            Positioned(
              right: -6,
              top: (18 - MabarSize.iconButton) / 2,
              height: MabarSize.iconButton,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// Label/kepala + isi + catatan. Padanan `margin-bottom: -8px` pada `.glabel`/`.ghead` dan
/// `margin-top: -8px` pada `.gnote`: jaraknya = [bodyGap] − 8, dengan [bodyGap] jarak antar-bagian badan
/// layar (16, atau 12 di Konfigurasi).
class MabarSection extends StatelessWidget {
  /// [MabarGroupLabel] atau [MabarGroupHeader].
  final Widget? header;
  final Widget child;
  final Widget? note;
  final double bodyGap;

  const MabarSection({super.key, this.header, required this.child, this.note, this.bodyGap = 16});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: bodyGap - 8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[header!, gap],
        child,
        if (note != null) ...[gap, note!],
      ],
    );
  }
}
