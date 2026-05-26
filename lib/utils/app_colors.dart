import 'package:flutter/material.dart';
import '../main.dart';

/// Returns theme-aware colors based on the global darkModeNotifier.
/// Use in build() methods — no need for BuildContext.
class AppColors {
  static bool get isDark => darkModeNotifier.value;

  // Backgrounds
  static Color get scaffold => isDark ? const Color(0xFF0D0D14) : const Color(0xFFF4F7FC);
  static Color get card    => isDark ? const Color(0xFF1C1C2E) : Colors.white;
  static Color get surface => isDark ? const Color(0xFF252538) : const Color(0xFFF8FAFF);

  // Text
  static Color get primaryText   => isDark ? Colors.white       : const Color(0xFF0A0A2E);
  static Color get secondaryText => isDark ? Colors.white60     : Colors.black54;
  static Color get labelText     => isDark ? Colors.white70     : Colors.black87;

  // Borders / dividers
  static Color get divider => isDark ? Colors.white12 : Colors.black12;
  static Color get border  => isDark ? Colors.white10 : const Color(0xFFEEEEEE);

  // Nav bar
  static Color get navBar          => isDark ? const Color(0xFF1C1C2E) : Colors.white;
  static Color get navSelected     => const Color(0xFF09AEF5);
  static Color get navUnselected   => isDark ? Colors.white38 : Colors.grey;

  // App bar
  static Color get appBar          => isDark ? const Color(0xFF1C1C2E) : Colors.transparent;
  static Color get appBarForeground => isDark ? Colors.white : const Color(0xFF05398F);

  // Shadows
  static Color get shadow => isDark ? Colors.black54 : Colors.black12;

  // Brand colours — never change
  static const Color primary     = Color(0xFF09AEF5);
  static const Color primaryDark = Color(0xFF05398F);
}
