import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../core/widgets/mabar_brand_mark.dart';
import '../../core/widgets/mabar_widgets.dart';
import '../../models/models.dart';
import '../schedule/mixed/resume_tournament_sheet.dart';
import '../schedule/tournament_controller.dart';
import 'app_install.dart';
import 'ios_install_sheet.dart';

/// Screen 1 · Home — pilih jenis permainan (tidak ada default, wajib pilih).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Turnamen yang belum ditutup, dibaca dari device saat app dibuka.
    final active = ref.watch(tournamentProvider);
    // Turnamen yang sudah ditutup; hanya Mixed yang bisa dilanjutkan.
    final last = ref.watch(lastFinishedProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: MabarTheme.statusBarLight,
      child: Scaffold(
        backgroundColor: MabarColors.card,
        // Tanpa SafeArea atas: hero biru naik sampai di bawah status bar, jarak
        // amannya diberikan di dalam hero.
        body: SafeArea(
          top: false,
          // Spacer mendorong pilihan permainan ke bawah selama muat; di layar pendek (browser HP
          // dengan bar alamat + kartu lanjutkan + kartu pasang) halamannya bisa digulir.
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  // Padding horizontal dipasang per-bagian, bukan di sini, supaya hero
                  // bisa full-bleed sampai tepi layar.
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    children: [
                      const _BrandHero(),
                      const SizedBox(height: MabarSpacing.x5),
                      const _Gutter(child: _QuickStats()),
                      if (active != null) ...[
                        const SizedBox(height: MabarSpacing.x4),
                        _Gutter(
                          child: _ResumeCard(
                            title: 'Lanjutkan turnamen',
                            active: active,
                            // Config-nya dioper apa adanya supaya `startIfNeeded` mengenalinya sebagai
                            // turnamen yang sama (perbandingannya `identical`) dan tidak menimpa state.
                            onTap: () => context.push('/schedule', extra: active.config),
                          ),
                        ),
                      ] else if (last != null && last.config.mode == PartnerMode.mixed) ...[
                        const SizedBox(height: MabarSpacing.x4),
                        _Gutter(
                          child: _ResumeCard(
                            title: 'Turnamen terakhir · tambah jam',
                            active: last,
                            onTap: () async {
                              if (!await showResumeTournamentSheet(context, last, archived: true)) return;
                              final resumed = ref.read(tournamentProvider);
                              if (resumed != null && context.mounted) context.push('/schedule', extra: resumed.config);
                            },
                          ),
                        ),
                      ],
                      const _InstallCard(),
                      const Spacer(),
                      const Text(
                        'PILIH JENIS PERMAINAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MabarColors.faint,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _Gutter(child: _SportSelector()),
                      const SizedBox(height: 14),
                      const Text(
                        'Skor tersimpan otomatis · v1.0',
                        style: TextStyle(fontSize: 11, color: MabarColors.faint, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Margin kiri-kanan standar screen (20px).
class _Gutter extends StatelessWidget {
  final Widget child;
  const _Gutter({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
      child: child,
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  /// Full-bleed sampai tepi layar, jadi hanya sudut bawah yang dibulatkan.
  static const _heroRadius = BorderRadius.vertical(bottom: Radius.circular(MabarRadius.homePanel));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: _heroRadius,
        child: MabarCourtBackground(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 32 + MediaQuery.paddingOf(context).top, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TennisBall(),
                const SizedBox(height: MabarSpacing.x4),
                Text(
                  'MABAR',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.15), offset: const Offset(0, 2), blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: MabarSpacing.x1),
                const Text(
                  'Turnamen Tennis & Padel',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TennisBall extends StatelessWidget {
  const _TennisBall();

  @override
  Widget build(BuildContext context) {
    // `.icon-badge` 76×76 sebagai kotak jarak, bolanya sendiri 48×48 di tengah.
    return const SizedBox(width: 76, height: 76, child: Center(child: MabarTennisBall(size: 48)));
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats();

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight: samakan tinggi ketiga box walau labelnya beda jumlah baris.
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MabarStatBox(value: '20', label: 'Max Pemain'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: MabarStatBox(value: '10', label: 'Max Court'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: MabarStatBox(value: '2', label: 'Mode'),
          ),
        ],
      ),
    );
  }
}

/// Jalan masuk kembali ke turnamen yang belum ditutup — tanpa kartu ini,
/// turnamen yang di-resume dari device tidak bisa dicapai lagi. Dipakai juga
/// untuk melanjutkan turnamen Mixed yang sudah ditutup.
class _ResumeCard extends StatelessWidget {
  final String title;
  final ActiveTournament active;
  final VoidCallback onTap;
  const _ResumeCard({required this.title, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final config = active.config;
    return _ActionCard(
      icon: MabarIcons.play,
      title: title,
      subtitle:
          '${config.sport.label} · ${config.mode.label} · ${config.players.length} pemain · '
          '${active.playedMatchCount}/${active.matches.length} match',
      onTap: onTap,
    );
  }
}

/// Ajakan memasang PWA ke layar utama, hanya di browser yang belum memasangnya. Di Chrome
/// dkk. langsung memunculkan dialog pasang bawaan; iPhone tidak punya API-nya, jadi
/// tombolnya membuka panduan menu Bagikan.
class _InstallCard extends StatelessWidget {
  const _InstallCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appInstallMode,
      builder: (context, mode, _) {
        if (mode == AppInstallMode.none) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(MabarSpacing.x5, MabarSpacing.x4, MabarSpacing.x5, 0),
          child: _ActionCard(
            icon: MabarIcons.deviceMobile,
            title: 'Pasang Mabar di HP',
            subtitle: 'Buka dari layar utama, tanpa browser',
            onTap: mode == AppInstallMode.prompt ? promptAppInstall : () => showIosInstallSheet(context),
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(MabarSpacing.x4),
        decoration: BoxDecoration(
          color: MabarColors.paper,
          border: Border.all(color: MabarColors.line),
          borderRadius: BorderRadius.circular(MabarRadius.group),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: MabarColors.ink),
            const SizedBox(width: MabarSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MabarColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: MabarColors.ink3)),
                ],
              ),
            ),
            const Icon(MabarIcons.caretRight, size: 20, color: MabarColors.ink),
          ],
        ),
      ),
    );
  }
}

class _SportSelector extends ConsumerWidget {
  const _SportSelector();

  /// Slot turnamen aktif cuma satu, jadi memulai turnamen baru membuang yang
  /// sedang berjalan. Host harus menyetujuinya dulu.
  Future<void> _start(BuildContext context, WidgetRef ref, SportType sport) async {
    if (ref.read(tournamentProvider) != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mulai turnamen baru?'),
          content: const Text('Turnamen yang sedang berlangsung akan dihapus.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: MabarColors.clay),
              child: const Text('Hapus & Mulai Baru'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    if (context.mounted) context.push('/setup-peserta', extra: sport);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        for (final sport in SportType.values) ...[
          if (sport != SportType.values.first) const SizedBox(width: 10),
          Expanded(
            child: _SportButton(sport: sport, onTap: () => _start(context, ref, sport)),
          ),
        ],
      ],
    );
  }
}

class _SportButton extends StatefulWidget {
  final SportType sport;
  final VoidCallback onTap;
  const _SportButton({required this.sport, required this.onTap});

  @override
  State<_SportButton> createState() => _SportButtonState();
}

class _SportButtonState extends State<_SportButton> {
  bool _hovering = false;
  bool _pressed = false;

  bool get _highlighted => _hovering || _pressed;

  @override
  Widget build(BuildContext context) {
    final accent = _highlighted ? MabarColors.ink : MabarColors.ink3;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
          transform: Matrix4.translationValues(0, _highlighted ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: MabarColors.card,
            border: Border.all(color: _highlighted ? MabarColors.ink : MabarColors.line, width: 2),
            borderRadius: BorderRadius.circular(MabarRadius.group),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 80,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                  child: Image.asset(widget.sport.assetPath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.sport.label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent, letterSpacing: -0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
