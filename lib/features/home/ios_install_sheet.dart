import 'package:flutter/material.dart';

import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';

/// Panduan pasang di iPhone/iPad. Safari tidak punya API pasang yang bisa dipicu dari
/// halaman, jadi tombol "Pasang" di sana hanya bisa menunjukkan jalannya.
Future<void> showIosInstallSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MabarColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MabarRadius.xxxl + 4)),
    ),
    builder: (_) => const _IosInstallSheet(),
  );
}

class _IosInstallSheet extends StatelessWidget {
  const _IosInstallSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x5, MabarSpacing.x5, MabarSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: MabarSpacing.x4),
                decoration: BoxDecoration(color: MabarColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MabarColors.brandTint,
                    borderRadius: BorderRadius.circular(MabarRadius.md),
                  ),
                  child: const Icon(Icons.install_mobile, size: 18, color: MabarColors.brand),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasang di iPhone',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: MabarColors.text1,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text('Lewat menu Bagikan di Safari', style: TextStyle(fontSize: 11, color: MabarColors.text4)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MabarSpacing.x4),
            // Safari iOS 26 (tata letak tab ringkas) menyembunyikan Bagikan di menu titik tiga.
            // "···" (bukan "⋯"): glyph itu tidak ada di Inter.
            const _Step(
              number: 1,
              icon: Icons.ios_share,
              text: [
                TextSpan(text: 'Ketuk '),
                TextSpan(text: 'Bagikan', style: _bold),
              ],
              caption: 'Kalau tidak kelihatan, ada di dalam menu ···',
            ),
            // Label menunya ikut bahasa iPhone, jadi versi Inggrisnya ikut ditulis.
            const _Step(
              number: 2,
              icon: Icons.add_box_outlined,
              text: [
                TextSpan(text: 'Pilih '),
                TextSpan(text: 'Tambah ke Layar Utama', style: _bold),
              ],
              caption: 'Add to Home Screen · geser ke bawah kalau belum kelihatan',
            ),
            const _Step(
              number: 3,
              icon: Icons.check_circle_outline,
              text: [
                TextSpan(text: 'Ketuk '),
                TextSpan(text: 'Tambah', style: _bold),
                TextSpan(text: ' di kanan atas'),
              ],
              caption: 'Mabar muncul di layar utama seperti app biasa',
              last: true,
            ),
            const SizedBox(height: MabarSpacing.x4),
            // Browser bawaan Instagram/Facebook dkk. tidak punya menu ini sama sekali.
            const MabarInfoBox(
              variant: MabarInfoVariant.neutral,
              icon: Icons.info_outline,
              title: 'Buka di Safari dulu',
              caption: 'Kalau link ini dibuka dari dalam app lain, menu Tambah ke Layar Utama tidak ada.',
            ),
            const SizedBox(height: MabarSpacing.x4),
            MabarPrimaryButton(label: 'Mengerti', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

const _bold = TextStyle(fontWeight: FontWeight.w700);

class _Step extends StatelessWidget {
  final int number;
  final IconData icon;
  final List<TextSpan> text;
  final String caption;
  final bool last;

  const _Step({required this.number, required this.icon, required this.text, required this.caption, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: MabarColors.borderSubtle)),
            ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: MabarColors.brandTint, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MabarColors.brand),
            ),
          ),
          const SizedBox(width: MabarSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: text),
                  style: const TextStyle(fontSize: 14, color: MabarColors.text1, height: 1.4),
                ),
                Text(caption, style: const TextStyle(fontSize: 11, color: MabarColors.text4, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: MabarSpacing.x3),
          Icon(icon, size: 22, color: MabarColors.text3),
        ],
      ),
    );
  }
}
