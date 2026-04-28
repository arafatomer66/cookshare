import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Refined warm palette — espresso/cream with amber accent.
  static const Color seed = Color(0xFFE85D24); // warm amber, more saturated than orange
  static const Color background = Color(0xFFFBF6EF); // soft cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFDF8F1);
  static const Color ink = Color(0xFF1B1410); // deep espresso text
  static const Color inkSoft = Color(0xFF6B5A4F); // muted secondary
  static const Color hairline = Color(0xFFEDE2D2); // subtle dividers

  // Use system font (San Francisco on iOS, Roboto on Android) — both ship with the OS
  // so no network fetch is needed and they render crisp at small sizes.
  static const String _ui = '.SF Pro Text';

  static TextTheme _textTheme(Color body, Color soft) {
    TextStyle base(double size, FontWeight w, {Color? color, double? height, double letter = 0}) =>
        TextStyle(fontSize: size, fontWeight: w, color: color ?? body, height: height, letterSpacing: letter, fontFamilyFallback: const ['Roboto', _ui]);

    return TextTheme(
      displayLarge: base(40, FontWeight.w700, height: 1.05, letter: -1.2),
      displayMedium: base(32, FontWeight.w700, height: 1.1, letter: -0.8),
      headlineLarge: base(28, FontWeight.w700, height: 1.15, letter: -0.6),
      headlineMedium: base(22, FontWeight.w700, letter: -0.4),
      headlineSmall: base(18, FontWeight.w600, letter: -0.2),
      titleLarge: base(18, FontWeight.w600, letter: -0.2),
      titleMedium: base(15, FontWeight.w600),
      titleSmall: base(13, FontWeight.w500, color: soft, letter: 0.4),
      bodyLarge: base(15, FontWeight.w400, height: 1.45),
      bodyMedium: base(14, FontWeight.w400, height: 1.4),
      bodySmall: base(12, FontWeight.w400, color: soft, height: 1.4),
      labelLarge: base(14, FontWeight.w600, letter: 0.2),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: surfaceElevated,
      outline: hairline,
      outlineVariant: hairline,
    );

    const titleStyle = TextStyle(
      color: ink,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFamilyFallback: ['Roboto', _ui],
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      textTheme: _textTheme(ink, inkSoft),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: titleStyle,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        indicatorColor: seed.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? seed : inkSoft,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? seed : inkSoft, size: 24);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: surface,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(color: inkSoft, fontSize: 14),
        hintStyle: TextStyle(color: inkSoft.withValues(alpha: 0.7), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ink, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        side: const BorderSide(color: hairline),
        labelStyle: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      dividerTheme: const DividerThemeData(color: hairline, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: surface, fontSize: 14, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
