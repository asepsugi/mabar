import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import '../../services/share/result_text_builder.dart';
import '../schedule/tournament_controller.dart';
import 'share_card.dart';
import 'share_theme.dart';

/// Screen 10 · Bagikan Hasil — preview kartu hasil lalu share sebagai gambar.
class ShareResultScreen extends ConsumerStatefulWidget {
  const ShareResultScreen({super.key});

  @override
  ConsumerState<ShareResultScreen> createState() => _ShareResultScreenState();
}

class _ShareResultScreenState extends ConsumerState<ShareResultScreen> {
  ShareFormat _format = ShareFormat.ringkas;
  ShareTheme _theme = ShareTheme.biru;
  bool _sharing = false;

  /// Render poster di luar layar. Ukuran logisnya kecil supaya proporsi teks
  /// sama dengan preview; pixelRatio 3 yang membawanya ke 1080px.
  Future<XFile> _renderPoster(ActiveTournament active, ShareSelection selection, SharePosterSize size) async {
    final bytes = await ScreenshotController().captureFromWidget(
      ShareResultPoster(
        active: active,
        standings: selection.visible,
        hiddenCount: selection.hiddenCount,
        method: selection.method,
        theme: _theme,
        size: size,
      ),
      context: context,
      targetSize: size.logicalSize,
      pixelRatio: SharePosterSize.pixelRatio,
      delay: const Duration(milliseconds: 60),
    );
    return XFile.fromData(bytes, name: size.fileName, mimeType: 'image/png');
  }

  Future<void> _share(ActiveTournament active, ShareSelection selection) async {
    if (_sharing) return;
    setState(() => _sharing = true);

    final text = ResultTextBuilder.build(active: active, standings: selection.all, format: _format);

    try {
      // Watermark raket harus sudah ter-decode sebelum render off-screen,
      // kalau tidak posternya keluar tanpa gambar.
      await precacheImage(AssetImage(active.config.sport.assetPath), context);
      if (!mounted) return;

      final posters = [for (final size in SharePosterSize.values) await _renderPoster(active, selection, size)];
      await Share.shareXFiles(posters, text: text);
    } catch (_) {
      // Share sheet tidak tersedia (mis. desktop/web tanpa izin) — salin saja.
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hasil disalin')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _finish() {
    ref.read(tournamentProvider.notifier).close();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(tournamentProvider);
    if (active == null) {
      return const Scaffold(body: Center(child: Text('Belum ada turnamen berjalan')));
    }

    final selection = ShareSelection(
      all: ref.watch(standingEntriesProvider),
      method: ref.watch(rankingMethodProvider),
      format: _format,
    );

    return Scaffold(
      backgroundColor: MabarColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x2, MabarSpacing.x5, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MabarScreenHeader(
                leading: MabarBackButton(label: 'Peringkat', onTap: () => context.pop()),
                trailing: MabarStatusBadge(
                  label: active.isFinal ? 'FINAL' : 'SEMENTARA',
                  variant: active.isFinal ? MabarStatusVariant.finalized : MabarStatusVariant.live,
                ),
              ),
              const MabarPageTitle(title: 'Bagikan Hasil'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: MabarSpacing.x3),
                  children: [
                    ShareResultCard(
                      active: active,
                      standings: selection.visible,
                      hiddenCount: selection.hiddenCount,
                      method: selection.method,
                      theme: _theme,
                    ),
                    const SizedBox(height: 10),
                    _ThemePicker(selected: _theme, onSelected: (t) => setState(() => _theme = t)),
                    const SizedBox(height: 14),
                    const MabarFieldLabel('Format'),
                    Row(
                      children: [
                        for (final f in ShareFormat.values) ...[
                          Expanded(
                            child: MabarOptionButton(
                              label: f.label,
                              selected: _format == f,
                              onTap: () => setState(() => _format = f),
                            ),
                          ),
                          if (f != ShareFormat.values.last) const SizedBox(width: MabarSpacing.x2),
                        ],
                      ],
                    ),
                    const SizedBox(height: MabarSpacing.x2),
                    Text(
                      '${_format == ShareFormat.ringkas ? '${ShareSelection.previewCount} pemain teratas' : 'Semua ${selection.all.length} pemain'}'
                      ' · gambar untuk IG Feed & Story',
                      style: TextStyle(fontSize: 11, color: MabarColors.faint, height: 1.5),
                    ),
                  ],
                ),
              ),
              _ShareButton(busy: _sharing, onPressed: () => _share(active, selection)),
              const SizedBox(height: MabarSpacing.x2),
              OutlinedButton.icon(
                onPressed: _finish,
                icon: const Icon(MabarIcons.house, size: 16),
                label: const Text('Selesai'),
                style: OutlinedButton.styleFrom(foregroundColor: MabarColors.ink2),
              ),
              const SizedBox(height: MabarSpacing.x2),
              const Text(
                'Hasil turnamen tersimpan otomatis',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: MabarColors.faint, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pemilih warna latar kartu hasil, tepat di bawah banner preview.
class _ThemePicker extends StatelessWidget {
  final ShareTheme selected;
  final ValueChanged<ShareTheme> onSelected;

  const _ThemePicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // Wrap, bukan Row: pilihan warnanya lebih banyak dari satu baris layar.
    return Wrap(
      spacing: MabarSpacing.x2,
      runSpacing: MabarSpacing.x2,
      children: [
        for (final theme in ShareTheme.values)
          _Swatch(theme: theme, selected: theme == selected, onTap: () => onSelected(theme)),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final ShareTheme theme;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({required this.theme, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Warna ${theme.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          // Cincin putih memisahkan warna terpilih dari border brand-nya.
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MabarColors.card,
            border: Border.all(color: selected ? MabarColors.ink : MabarColors.line, width: selected ? 2 : 1),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: theme.gradient),
            child: selected ? Icon(MabarIcons.check, size: 14, color: theme.ink) : null,
          ),
        ),
      ),
    );
  }
}

/// Tombol kirim — memakai share sheet sistem, jadi tujuannya tidak lagi
/// khusus WhatsApp; ikonnya disamakan dengan tombol Share di layar Peringkat.
class _ShareButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool busy;

  const _ShareButton({required this.onPressed, required this.busy});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: MabarColors.ink3),
            )
          : const Icon(MabarIcons.shareNetwork, size: 18),
      label: Text(busy ? 'Menyiapkan gambar…' : 'Bagikan Hasil'),
    );
  }
}
