import 'package:flutter/material.dart';

import '../../core/theme/mabar_icons.dart';
import '../../core/theme/mabar_theme.dart';
import '../../models/models.dart';
import '../../services/ranking/ranking_calculator.dart';
import '../../services/share/result_text_builder.dart';

/// Ukuran gambar hasil yang dibagikan, mengikuti spesifikasi Instagram.
enum SharePosterSize {
  /// IG Feed — 1080x1080 (1:1). Kanvasnya pendek, jadi hurufnya lebih kecil
  /// supaya 5-8 baris tidak berdempetan.
  feed(1080, 1080, typeScale: 1.15, verticalPadding: 38),

  /// IG Story/Reels — 1080x1920 (9:16).
  story(1080, 1920, typeScale: 1.5, verticalPadding: 48);

  final double pixelWidth;
  final double pixelHeight;

  /// Skala huruf poster terhadap kartu preview di layar.
  final double typeScale;

  final double verticalPadding;

  const SharePosterSize(this.pixelWidth, this.pixelHeight, {required this.typeScale, required this.verticalPadding});

  /// Margin tepi poster (ukuran logis; dikali 3 saat di-render).
  EdgeInsets get padding => EdgeInsets.symmetric(horizontal: 38, vertical: verticalPadding);

  /// Poster digambar pada ukuran logis kecil lalu di-render 3x supaya teksnya
  /// tetap proporsional dengan preview di layar.
  static const pixelRatio = 3.0;

  Size get logicalSize => Size(pixelWidth / pixelRatio, pixelHeight / pixelRatio);

  String get fileName => 'mabar-$name-${pixelWidth.toInt()}x${pixelHeight.toInt()}.png';
}

/// Pilihan warna latar kartu/poster hasil. Semua pasangan dipilih yang cukup
/// gelap supaya teks putih tetap terbaca.
enum ShareTheme {
  // Gelap — tinta putih.
  hijau(Color(0xFF14532D), Color(0xFF16A34A)),
  biru(Color(0xFF172554), Color(0xFF2563EB)),
  ungu(Color(0xFF3B0764), Color(0xFF9333EA)),
  jingga(Color(0xFF7C2D12), Color(0xFFEA580C)),
  teal(Color(0xFF042F2E), Color(0xFF0D9488)),
  malam(Color(0xFF0B1220), Color(0xFF334155)),

  // Lembut — tintanya gelap supaya tetap terbaca.
  peach(Color(0xFFF6BE9C), Color(0xFFFDE3D0), ink: Color(0xFF6B3A22)),
  nude(Color(0xFFE2CDB6), Color(0xFFF8EFE5), ink: Color(0xFF4F3D2C)),
  sage(Color(0xFFBFD4C1), Color(0xFFEDF4EA), ink: Color(0xFF2C4133)),
  lilac(Color(0xFFD3C7EA), Color(0xFFF3EEFA), ink: Color(0xFF3E3457));

  /// Warna kiri-atas dan kanan-bawah gradien.
  final Color start;
  final Color end;

  /// Warna teks/garis di atas gradien ini.
  final Color ink;

  const ShareTheme(this.start, this.end, {this.ink = Colors.white});

  LinearGradient get gradient =>
      LinearGradient(colors: [start, end], begin: Alignment.topLeft, end: Alignment.bottomRight);

  Color inkAlpha(double alpha) => ink.withValues(alpha: alpha);

  /// Garis pemisah & watermark: tipis di tema gelap, sedikit lebih tegas di
  /// tema lembut supaya tidak hilang di latar terang.
  bool get isLight => ink != Colors.white;

  Color get divider => inkAlpha(isLight ? 0.22 : 0.15);

  /// Piala: bola di tema gelap, tinta tema di tema lembut (bola hilang di latar terang).
  Color get trophy => isLight ? ink : MabarColors.ball;
  Color get watermark => inkAlpha(isLight ? 0.22 : 0.18);
}

/// Baris mana yang tampil di kartu preview dan di gambar share: format
/// Ringkas hanya menampilkan [previewCount] teratas, Lengkap semua pemain.
class ShareSelection {
  static const previewCount = 5;

  final List<StandingEntry> all;
  final RankingMethod method;
  final ShareFormat format;

  const ShareSelection({required this.all, required this.method, required this.format});

  List<StandingEntry> get visible => format == ShareFormat.ringkas ? all.take(previewCount).toList() : all;

  int get hiddenCount => all.length - visible.length;
}

/// Latar `.share-card`: gradien + kilau + watermark raket.
///
/// Watermark diwarnai ulang memakai tinta tema (bukan warna asli PNG) supaya
/// tetap terbaca baik di gradien gelap maupun di tema lembut.
class _ShareCardBackground extends StatelessWidget {
  final SportType sport;
  final ShareTheme theme;
  final double racketWidth;
  final Widget child;

  const _ShareCardBackground({
    required this.sport,
    required this.theme,
    required this.racketWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: theme.gradient),
      child: Stack(
        children: [
          // Kilau lembut di pojok kanan atas.
          Positioned(
            top: -racketWidth * 0.23,
            right: -racketWidth * 0.23,
            child: Container(
              width: racketWidth * 0.92,
              height: racketWidth * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [theme.inkAlpha(theme.isLight ? 0.14 : 0.10), theme.inkAlpha(0)],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -racketWidth * 0.15,
            right: -racketWidth * 0.12,
            // Ilustrasi raket tennis sudah miring dari sananya; hanya padel
            // yang perlu dimiringkan.
            child: Transform.rotate(
              angle: sport == SportType.padel ? 20 * 3.1415926535 / 180 : 0,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(theme.watermark, BlendMode.srcIn),
                child: Image.asset(sport.assetPath, width: racketWidth),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// `.share-card` — preview hasil di layar 10.
class ShareResultCard extends StatelessWidget {
  final ActiveTournament active;
  final List<StandingEntry> standings;
  final int hiddenCount;
  final RankingMethod method;
  final ShareTheme theme;

  const ShareResultCard({
    super.key,
    required this.active,
    required this.standings,
    required this.hiddenCount,
    required this.method,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(MabarRadius.poster),
      child: _ShareCardBackground(
        sport: active.config.sport,
        theme: theme,
        racketWidth: 130,
        child: Padding(
          padding: const EdgeInsets.all(MabarSpacing.x5),
          child: ShareCardContent(
            active: active,
            standings: standings,
            hiddenCount: hiddenCount,
            method: method,
            theme: theme,
          ),
        ),
      ),
    );
  }
}

/// Versi gambar dari kartu hasil, berukuran pas untuk IG Feed/Story.
class ShareResultPoster extends StatelessWidget {
  final ActiveTournament active;
  final List<StandingEntry> standings;
  final int hiddenCount;
  final RankingMethod method;
  final ShareTheme theme;
  final SharePosterSize size;

  const ShareResultPoster({
    super.key,
    required this.active,
    required this.standings,
    required this.hiddenCount,
    required this.method,
    required this.theme,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final logical = size.logicalSize;
    final scale = size.typeScale;
    final contentWidth = logical.width - size.padding.horizontal;

    return SizedBox(
      width: logical.width,
      height: logical.height,
      child: _ShareCardBackground(
        sport: active.config.sport,
        theme: theme,
        racketWidth: logical.width * 0.62,
        child: Padding(
          padding: size.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'MABAR TURNAMEN · ${active.config.sport.label.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  color: theme.inkAlpha(0.8),
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: MabarSpacing.x1 * scale),
              Align(
                alignment: Alignment.centerLeft,
                child: _ShareTitle(theme: theme, scale: scale),
              ),
              SizedBox(height: MabarSpacing.x3 * scale),
              // Baris berbagi sisa tinggi sama rata, jadi isi poster selalu
              // penuh — 5 pemain di kanvas 1:1 tidak menyisakan ruang kosong.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < standings.length; i++)
                      Expanded(
                        child: _PosterRow(
                          entry: standings[i],
                          showDivider: i != standings.length - 1,
                          method: method,
                          theme: theme,
                          width: contentWidth,
                          scale: scale,
                        ),
                      ),
                  ],
                ),
              ),
              if (hiddenCount > 0)
                Padding(
                  padding: EdgeInsets.only(top: MabarSpacing.x2 * scale),
                  child: Text(
                    '+$hiddenCount pemain lainnya',
                    style: TextStyle(fontSize: 11 * scale, color: theme.inkAlpha(0.7)),
                  ),
                ),
              Container(
                margin: EdgeInsets.only(top: MabarSpacing.x3 * scale),
                padding: EdgeInsets.only(top: 10 * scale),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.divider)),
                ),
                child: Text(
                  ResultTextBuilder.summaryLine(active),
                  style: TextStyle(fontSize: 11 * scale, color: theme.inkAlpha(0.7), letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris peringkat di poster: tingginya dibagi rata oleh [Expanded] induknya,
/// teksnya mengecil sendiri kalau pemainnya banyak.
class _PosterRow extends StatelessWidget {
  final StandingEntry entry;
  final bool showDivider;
  final RankingMethod method;
  final ShareTheme theme;
  final double width;
  final double scale;

  const _PosterRow({
    required this.entry,
    required this.showDivider,
    required this.method,
    required this.theme,
    required this.width,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: theme.divider)) : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        // centerLeft supaya baris tetap sejajar judul kalau sempat mengecil.
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: width,
          child: _ShareRowContent(entry: entry, method: method, theme: theme, scale: scale),
        ),
      ),
    );
  }
}

/// Isi kartu: judul, daftar peringkat, ringkasan turnamen.
class ShareCardContent extends StatelessWidget {
  final ActiveTournament active;
  final List<StandingEntry> standings;
  final int hiddenCount;
  final RankingMethod method;
  final ShareTheme theme;
  final double scale;

  const ShareCardContent({
    super.key,
    required this.active,
    required this.standings,
    required this.hiddenCount,
    required this.method,
    required this.theme,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MABAR TURNAMEN · ${active.config.sport.label.toUpperCase()}',
          style: TextStyle(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w600,
            color: theme.inkAlpha(0.8),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: MabarSpacing.x1 * scale),
        _ShareTitle(theme: theme, scale: scale),
        SizedBox(height: MabarSpacing.x4 * scale),
        for (var i = 0; i < standings.length; i++)
          _ShareRow(
            entry: standings[i],
            showDivider: i != standings.length - 1,
            method: method,
            theme: theme,
            scale: scale,
          ),
        if (hiddenCount > 0)
          Padding(
            padding: EdgeInsets.only(top: MabarSpacing.x2 * scale),
            child: Text(
              '+$hiddenCount pemain lainnya',
              style: TextStyle(fontSize: 11 * scale, color: theme.inkAlpha(0.7)),
            ),
          ),
        Container(
          margin: EdgeInsets.only(top: MabarSpacing.x3 * scale),
          padding: EdgeInsets.only(top: 10 * scale),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.divider)),
          ),
          child: Text(
            ResultTextBuilder.summaryLine(active),
            style: TextStyle(fontSize: 11 * scale, color: theme.inkAlpha(0.7), letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }
}

/// Judul kartu: ikon piala yang sama dengan header layar Peringkat, bukan emoji
/// (emoji ikut selera font tiap device dan hilang saat poster di-render).
class _ShareTitle extends StatelessWidget {
  final ShareTheme theme;
  final double scale;
  const _ShareTitle({required this.theme, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(MabarIcons.trophy, size: 22 * scale, color: theme.trophy),
        SizedBox(width: MabarSpacing.x2 * scale),
        // Flexible supaya judul tidak pernah meluber di kanvas sempit.
        Flexible(
          child: Text(
            'Peringkat Akhir',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20 * scale,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: theme.ink,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  final StandingEntry entry;
  final bool showDivider;
  final RankingMethod method;
  final ShareTheme theme;
  final double scale;

  const _ShareRow({
    required this.entry,
    required this.showDivider,
    required this.method,
    required this.theme,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: MabarSpacing.x2 * scale),
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: theme.divider)) : null,
      ),
      child: _ShareRowContent(entry: entry, method: method, theme: theme, scale: scale),
    );
  }
}

/// Isi satu baris: nomor, nama, dan angka sesuai metode peringkat.
class _ShareRowContent extends StatelessWidget {
  final StandingEntry entry;
  final RankingMethod method;
  final ShareTheme theme;
  final double scale;

  const _ShareRowContent({
    required this.entry,
    required this.method,
    required this.theme,
    required this.scale,
  });

  /// Angka di kanan mengikuti chip metode yang dipilih di layar Peringkat.
  String get _value {
    final diff = entry.standing.gameDiff;
    return switch (method) {
      RankingMethod.totalGames =>
        '${entry.standing.totalPoint} poin · ${entry.standing.winPercent.toStringAsFixed(1)}%',
      RankingMethod.winPercent => '${entry.standing.winPercent.toStringAsFixed(1)}% · ${diff >= 0 ? '+' : ''}$diff',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24 * scale,
          child: Text(
            // Nomor bersama dengan Peringkat: statistik identik → nomor sama, belum main → "–".
            '${entry.position ?? '–'}.',
            style: TextStyle(
              fontSize: 13 * scale,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: theme.inkAlpha(0.8),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13 * scale, height: 1.1, fontWeight: FontWeight.w700, color: theme.ink),
          ),
        ),
        // Kolom angka lebih lebar dari nama supaya "6 poin · 100.0%" tidak
        // terpotong, dan Expanded membuatnya rata kanan di semua baris.
        Expanded(
          flex: 3,
          child: Text(
            _value,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12 * scale,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: theme.inkAlpha(0.9),
            ),
          ),
        ),
      ],
    );
  }
}
