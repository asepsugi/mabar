import 'package:flutter/material.dart';

/// Design tokens converted from design-tokens.json
class MabarColors {
  // Brand
  static const brand = Color(0xFF16A34A);
  static const brandDark = Color(0xFF14532D);
  static const brandTint = Color(0xFFF0FDF4);
  static const brandBorder = Color(0xFFBBF7D0);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const successTint = Color(0xFFF0FDF4);
  static const warning = Color(0xFFF59E0B);
  static const warningTint = Color(0xFFFEF3C7);
  static const warningBorder = Color(0xFFFDE68A);
  static const danger = Color(0xFFEF4444);
  static const dangerTint = Color(0xFFFEF2F2);
  static const dangerBorder = Color(0xFFFECACA);

  // Court palette (10 preset colors, cycled by index)
  static const List<Color> courtPalette = [
    Color(0xFF16A34A), // green
    Color(0xFFDC2626), // red
    Color(0xFF2563EB), // blue
    Color(0xFFEA580C), // orange
    Color(0xFF9333EA), // purple
    Color(0xFF0891B2), // cyan
    Color(0xFFDB2777), // pink
    Color(0xFF65A30D), // lime
    Color(0xFF7C3AED), // violet
    Color(0xFF0D9488), // teal
  ];

  // Surface
  static const background = Color(0xFFFAFAFA);
  static const card = Color(0xFFFFFFFF);
  static const raised = Color(0xFFF9FAFB);
  static const muted = Color(0xFFF3F4F6);

  // Border
  static const border = Color(0xFFE5E7EB);
  static const borderSubtle = Color(0xFFF3F4F6);
  static const borderStrong = Color(0xFFD1D5DB);

  // Text
  static const text1 = Color(0xFF111827);
  static const text2 = Color(0xFF374151);
  static const text3 = Color(0xFF6B7280);
  static const text4 = Color(0xFF9CA3AF);
  static const text5 = Color(0xFFD1D5DB);
  static const textInverse = Color(0xFFFFFFFF);
}

class MabarSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
}

class MabarRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double xxxl = 20;
  static const double full = 9999;
}

class MabarShadows {
  static const sm = [BoxShadow(color: Color(0x0A111827), offset: Offset(0, 1), blurRadius: 2)];
  static const md = [
    BoxShadow(color: Color(0x0F111827), offset: Offset(0, 2), blurRadius: 8),
    BoxShadow(color: Color(0x0A111827), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const lg = [BoxShadow(color: Color(0x14111827), offset: Offset(0, 8), blurRadius: 24)];
  static const brand = [BoxShadow(color: Color(0x4016A34A), offset: Offset(0, 4), blurRadius: 14)];
}

class MabarTheme {
  static ThemeData light() {
    const fontFamily = 'Inter';

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: MabarColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MabarColors.brand,
        primary: MabarColors.brand,
        onPrimary: MabarColors.textInverse,
        surface: MabarColors.card,
        onSurface: MabarColors.text1,
        error: MabarColors.danger,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: MabarColors.text1, letterSpacing: -1),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: MabarColors.text1,
          letterSpacing: -0.8,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: MabarColors.text1,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: MabarColors.text1,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: MabarColors.text1,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MabarColors.text1),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MabarColors.text1),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MabarColors.text2),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: MabarColors.text2, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: MabarColors.text2, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MabarColors.text3),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MabarColors.text3),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MabarColors.text3, letterSpacing: 0.2),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MabarColors.text4, letterSpacing: 0.3),
      ),
      cardTheme: CardThemeData(
        color: MabarColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MabarRadius.xxl)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MabarColors.brand,
          foregroundColor: MabarColors.textInverse,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MabarRadius.xxl + 2)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: fontFamily),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MabarColors.text1,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MabarRadius.xxl + 2)),
          side: const BorderSide(color: MabarColors.border, width: 1.5),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MabarColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: MabarSpacing.x4, vertical: MabarSpacing.x3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MabarRadius.xl),
          borderSide: const BorderSide(color: MabarColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MabarRadius.xl),
          borderSide: const BorderSide(color: MabarColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MabarRadius.xl),
          borderSide: const BorderSide(color: MabarColors.brand, width: 1.5),
        ),
        hintStyle: const TextStyle(color: MabarColors.text4, fontWeight: FontWeight.w400),
      ),
      dividerColor: MabarColors.borderSubtle,
      appBarTheme: const AppBarTheme(
        backgroundColor: MabarColors.card,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: MabarColors.text3),
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: MabarColors.text1,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}
