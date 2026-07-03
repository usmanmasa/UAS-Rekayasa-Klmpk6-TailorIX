import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tema global TailorLX — "Atelier Modern".
/// Dipasang sekali di `MaterialApp(theme: AppTheme.light)` (lihat main.dart),
/// lalu mengalir otomatis ke AppBar, tombol, input, kartu, dan navigasi
/// bawah di SEMUA layar tanpa perlu mengatur ulang per-screen.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    const colorScheme = ColorScheme.light(
      primary: AppColors.indigo,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.indigoLight,
      onPrimaryContainer: AppColors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.indigoDeep,
      secondaryContainer: AppColors.goldPale,
      onSecondaryContainer: Color(0xFF8A6314),
      tertiary: AppColors.sage,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.sagePale,
      onTertiaryContainer: AppColors.sage,
      error: AppColors.red,
      onError: AppColors.white,
      errorContainer: AppColors.redPale,
      onErrorContainer: AppColors.red,
      surface: AppColors.white,
      onSurface: AppColors.charcoal,
      surfaceContainerHighest: AppColors.linen,
      onSurfaceVariant: AppColors.charcoalSoft,
      outline: AppColors.linenDark,
      outlineVariant: AppColors.linenDark,
    );

    // Fraunces -> judul & angka besar (nuansa atelier/jahit).
    // Plus Jakarta Sans -> teks isi & label (mudah dibaca di layar kecil).
    final displayFont = GoogleFonts.frauncesTextTheme(base.textTheme);
    final bodyFont = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    final textTheme = bodyFont.copyWith(
      displayLarge: displayFont.displayLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.charcoal),
      displayMedium: displayFont.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.charcoal),
      displaySmall: displayFont.displaySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.charcoal),
      headlineLarge: displayFont.headlineLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.charcoal),
      headlineMedium: displayFont.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.charcoal),
      headlineSmall: displayFont.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.charcoal),
      titleLarge: displayFont.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.charcoal),
      titleMedium: bodyFont.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.charcoal),
      titleSmall: bodyFont.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.charcoal),
      bodyLarge: bodyFont.bodyLarge?.copyWith(color: AppColors.charcoal),
      bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.charcoal),
      bodySmall: bodyFont.bodySmall?.copyWith(color: AppColors.charcoalSoft),
      labelLarge: bodyFont.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.charcoal),
      labelMedium: bodyFont.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.charcoalSoft),
      labelSmall: bodyFont.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.charcoalSoft),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.chalk,
      textTheme: textTheme,
      primaryColor: AppColors.indigo,
      splashColor: AppColors.gold.withAlpha(31),
      highlightColor: AppColors.gold.withAlpha(20),
      dividerTheme: const DividerThemeData(color: AppColors.linenDark, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.chalk,
        foregroundColor: AppColors.charcoal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.charcoal,
        ),
        iconTheme: const IconThemeData(color: AppColors.charcoal),
      ),

      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.indigoDeep.withAlpha(13)),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.goldPale,
        labelStyle: const TextStyle(color: Color(0xFF8A6314), fontWeight: FontWeight.w700, fontSize: 11.5),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
      ),

      // NOTE: The global ElevatedButton minimumSize uses `Size.fromHeight(48)`
      // intentionally to make most buttons in the app full-width when placed
      // inside a vertical layout (e.g. Column). However, that makes the
      // button request an unbounded width when used inside a horizontal
      // parent like Row or Wrap (or next to a Spacer), which leads to the
      // runtime error "BoxConstraints forces an infinite width" on web
      // (and other platforms) if the button isn't constrained locally.
      //
      // Guidance: keep `minimumSize: Size.fromHeight(...)` here for the
      // common full-width pattern, but override the button's `minimumSize`
      // locally when placing an ElevatedButton inside a Row/Wrap so it can
      // receive a bounded width (see `lib/screens/onboarding/onboarding_screen.dart`)
      // where we set `minimumSize: Size(88, 44)` on the specific button.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.indigoDeep,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.indigo,
          side: const BorderSide(color: AppColors.indigo, width: 1.4),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.indigo,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: const TextStyle(color: AppColors.charcoalSoft, fontSize: 13, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: AppColors.charcoalSoft, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.linenDark, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.linenDark, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.4),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.goldPale,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.indigo : AppColors.charcoalSoft,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.indigo : AppColors.charcoalSoft);
        }),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.indigo,
        unselectedItemColor: AppColors.charcoalSoft,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.indigoDeep,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.indigoDeep,
        contentTextStyle: const TextStyle(color: AppColors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.indigo,
        unselectedLabelColor: AppColors.charcoalSoft,
        indicatorColor: AppColors.gold,
      ),

      iconTheme: const IconThemeData(color: AppColors.charcoal),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: GoogleFonts.fraunces(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.charcoal),
        contentTextStyle: const TextStyle(fontSize: 13, color: AppColors.charcoalSoft),
      ),
    );
  }
}
