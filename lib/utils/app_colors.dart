import 'package:flutter/material.dart';
import '../main.dart';

/// Returns theme-aware colors based on the global darkModeNotifier.
/// Use in build() methods — no need for BuildContext.
class AppColors {
  static bool get isDark => darkModeNotifier.value;

  // Backgrounds
  static Color get scaffold =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FC);
  static Color get card => isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get surface =>
      isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFF);

  // Text
  static Color get primaryText =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0A0A2E);
  static Color get secondaryText =>
      isDark ? const Color(0xFF94A3B8) : Colors.black54;
  static Color get labelText =>
      isDark ? const Color(0xFFE2E8F0) : Colors.black87;

  // Borders / dividers
  static Color get divider => isDark ? const Color(0xFF334155) : Colors.black12;
  static Color get border =>
      isDark ? const Color(0xFF334155) : const Color(0xFFEEEEEE);

  // Nav bar
  static Color get navBar => isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get navSelected => const Color(0xFF09AEF5);
  static Color get navUnselected =>
      isDark ? const Color(0xFF94A3B8) : Colors.grey;

  // App bar
  static Color get appBar =>
      isDark ? const Color(0xFF1E293B) : Colors.transparent;
  static Color get appBarForeground =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF05398F);

  // Shadows
  static Color get shadow => isDark ? Colors.black54 : Colors.black12;

  // Brand colours — never change
  static const Color primary = Color(0xFF09AEF5);
  static const Color primaryDark = Color(0xFF05398F);
}
