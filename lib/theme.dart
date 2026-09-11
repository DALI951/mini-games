import 'package:flutter/material.dart';

/// MiniGames design system — Dali's dark cinema look:
/// near-black backgrounds, ONE red accent, gray text hierarchy, rounded cards.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF14161D);
  static const Color card = Color(0xFF1A1D26);
  static const Color cardBorder = Color(0x14FFFFFF); // white @ 8%
  static const Color accent = Color(0xFFDC2626);
  static const Color accentDark = Color(0xFF991B1B);
  static const Color text = Color(0xFFF3F4F6);
  static const Color subtext = Color(0xFF9CA3AF);

  /// Per-game identity colors (used only as small glyph chips in the hub).
  static const Color gameRed = Color(0xFFDC2626);
  static const Color gameAmber = Color(0xFFD97706);
  static const Color gameGreen = Color(0xFF059669);
  static const Color gameBlue = Color(0xFF0284C7);
  static const Color gameViolet = Color(0xFF7C3AED);
}

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: Color(0xFFFFFFFF),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      secondary: AppColors.accentDark,
      onSecondary: Color(0xFFFFFFFF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppColors.text),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.card,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Simple filled button in the house style.
ElevatedButton accentButton(String label, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.accentDark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    child: Text(label),
  );
}

/// Secondary pill button in the house style.
OutlinedButton ghostButton(String label, VoidCallback onPressed) {
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.text,
      side: const BorderSide(color: AppColors.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    child: Text(label),
  );
}
