import 'package:flutter/material.dart';

import '../theme/mabar_theme.dart';

/// Header atas setiap screen (`.screen-header` di hifi.html):
/// tinggi konstan dengan padding 12px atas, 20px bawah.
class MabarScreenHeader extends StatelessWidget {
  final Widget? leading;
  final Widget? trailing;

  /// Judul di tengah (dipakai screen jadwal). Kalau null, leading & trailing
  /// menempel ke tepi kiri-kanan.
  final Widget? center;

  const MabarScreenHeader({super.key, this.leading, this.trailing, this.center});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: MabarSpacing.x3, bottom: MabarSpacing.x5),
      child: SizedBox(
        height: 32,
        child: center == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [leading ?? const SizedBox.shrink(), trailing ?? const SizedBox.shrink()],
              )
            // Stack, bukan Row: judul tetap presisi di tengah tanpa memaksa
            // lebar leading/trailing (yang bikin badge kepotong/melar).
            : Stack(
                alignment: Alignment.center,
                children: [
                  Center(child: center),
                  if (leading != null) Align(alignment: Alignment.centerLeft, child: leading),
                  if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing),
                ],
              ),
      ),
    );
  }
}

/// `.back-btn` — chevron + label tujuan (bukan judul screen sekarang).
class MabarBackButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const MabarBackButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MabarRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left, size: 18, color: MabarColors.text3),
            if (label.isNotEmpty) ...[
              const SizedBox(width: MabarSpacing.x1),
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MabarColors.text3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `.step-indicator` — "02 / 11".
class MabarStepIndicator extends StatelessWidget {
  final int step;
  final int total;

  const MabarStepIndicator({super.key, required this.step, this.total = 11});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${step.toString().padLeft(2, '0')} / $total',
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MabarColors.text4, letterSpacing: 0.5),
    );
  }
}

/// `h1.title` + `p.subtitle`.
class MabarPageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const MabarPageTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: MabarColors.text1,
            letterSpacing: -0.8,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 14, color: MabarColors.text3, height: 1.5)),
        ],
        const SizedBox(height: MabarSpacing.x6),
      ],
    );
  }
}

/// `.label` — label kecil di atas field.
class MabarFieldLabel extends StatelessWidget {
  final String text;
  const MabarFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MabarSpacing.x2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MabarColors.text3, letterSpacing: 0.2),
      ),
    );
  }
}

enum MabarChipVariant { filled, outlined, active, danger }

/// `.chip` beserta varian `.outlined` / `.active` / `.danger`.
class MabarChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final MabarChipVariant variant;

  const MabarChip({super.key, required this.label, this.icon, this.onTap, this.variant = MabarChipVariant.filled});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      MabarChipVariant.filled => (MabarColors.muted, MabarColors.text2, null),
      MabarChipVariant.outlined => (Colors.transparent, MabarColors.text2, MabarColors.border),
      MabarChipVariant.active => (MabarColors.brand, MabarColors.textInverse, null),
      MabarChipVariant.danger => (MabarColors.dangerTint, MabarColors.danger, null),
    };

    final content = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MabarRadius.full),
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 5)],
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(MabarRadius.full), child: content);
  }
}

/// `code` — potongan format inline.
class MabarCode extends StatelessWidget {
  final String text;
  const MabarCode(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: MabarColors.muted, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        // 'monospace' hanya dikenal Android; iOS butuh nama family sungguhan.
        style: const TextStyle(
          fontSize: 11,
          color: MabarColors.text2,
          fontFamily: 'monospace',
          fontFamilyFallback: ['Menlo', 'Courier'],
        ),
      ),
    );
  }
}

/// `.stat-box` — angka besar + label uppercase.
class MabarStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const MabarStatBox({super.key, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: MabarColors.raised, borderRadius: BorderRadius.circular(MabarRadius.xl)),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? MabarColors.text1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: MabarSpacing.x1),
          // Label selalu satu baris & di tengah: di grid 3 kolom label panjang sempat patah
          // ke baris kedua rata kiri sehingga tinggi & posisi tiap kotak tidak sejajar.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: MabarColors.text4,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.btn.btn-primary` — tombol aksi utama dengan glow hijau saat aktif.
class MabarPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const MabarPrimaryButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MabarRadius.xxl + 2),
        boxShadow: enabled ? MabarShadows.brand : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: MabarColors.brand.withValues(alpha: 0.4),
          disabledForegroundColor: MabarColors.textInverse,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: MabarSpacing.x2)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

enum MabarInfoVariant { success, warning, danger, neutral }

/// `.info` — kotak informasi kontekstual dengan ikon di kiri.
class MabarInfoBox extends StatelessWidget {
  final MabarInfoVariant variant;
  final IconData icon;
  final String title;
  final String? caption;

  const MabarInfoBox({super.key, required this.variant, required this.icon, required this.title, this.caption});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      MabarInfoVariant.success => (MabarColors.brandTint, MabarColors.brandDark, MabarColors.brandBorder),
      MabarInfoVariant.warning => (MabarColors.warningTint, const Color(0xFF92400E), MabarColors.warningBorder),
      MabarInfoVariant.danger => (MabarColors.dangerTint, const Color(0xFF991B1B), MabarColors.dangerBorder),
      MabarInfoVariant.neutral => (MabarColors.raised, MabarColors.text2, null),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: MabarSpacing.x3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MabarRadius.xl),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w700, color: fg),
                ),
                if (caption != null)
                  Text(caption!, style: TextStyle(fontSize: 11, height: 1.5, color: fg.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Border dashed untuk slot/kartu kosong (`.pair-slot`, match card status kosong).
/// Dipakai lewat `foregroundDecoration` supaya isi kotak tetap bebas.
class MabarDashedBorder extends Decoration {
  final Color color;
  final double radius;
  final double width;
  final double dash;
  final double gap;

  const MabarDashedBorder({required this.color, required this.radius, this.width = 2, this.dash = 6, this.gap = 4});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DashedBoxPainter(this);
}

class _DashedBoxPainter extends BoxPainter {
  final MabarDashedBorder spec;
  _DashedBoxPainter(this.spec);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;

    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(spec.width / 2), Radius.circular(spec.radius));
    final paint = Paint()
      ..color = spec.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = spec.width;

    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + spec.dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + spec.gap;
      }
    }
  }
}

enum MabarStatusVariant { live, finalized }

/// `.status-badge` — "LIVE" / "SEMENTARA" (kuning) dan "FINAL" (hijau).
class MabarStatusBadge extends StatelessWidget {
  final String label;
  final MabarStatusVariant variant;

  const MabarStatusBadge({super.key, required this.label, required this.variant});

  @override
  Widget build(BuildContext context) {
    final live = variant == MabarStatusVariant.live;
    final bg = live ? MabarColors.warningTint : MabarColors.brandTint;
    final fg = live ? const Color(0xFF92400E) : MabarColors.brandDark;
    final dot = live ? MabarColors.warning : MabarColors.brand;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(MabarRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

/// Stepper − n + (mis. "Jumlah court" di Konfigurasi, tambahan jam court).
/// [unit] ditulis kecil di sebelah angka, mis. "2 jam".
class MabarStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String? unit;
  final ValueChanged<int> onChanged;

  const MabarStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: MabarColors.raised, borderRadius: BorderRadius.circular(MabarRadius.xl)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(label: '−', enabled: value > min, onTap: () => onChanged(value - 1)),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text.rich(
                TextSpan(
                  text: '$value',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MabarColors.text1),
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: MabarColors.text3),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          _StepperButton(label: '+', enabled: value < max, onTap: () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MabarColors.card,
            borderRadius: BorderRadius.circular(MabarRadius.md),
            boxShadow: MabarShadows.sm,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MabarColors.text2),
          ),
        ),
      ),
    );
  }
}
