import 'package:flutter/material.dart';

abstract class AppTheme {
  // Brand accent colors
  static const Color brandPrimary = Color(0xFFC85628);
  static const Color brandAccent = Color(0xFFFF6D00);

  // Light Theme Colors
  static const Color _lightScaffoldBg = Color(0xFFF8F9FA);
  static const Color _lightSurfaceBg = Colors.white;
  static const Color _lightCardBorder = Color(0xFFE5E7EB);
  static const Color _lightTextPrimary = Color(0xFF111827);
  static const Color _lightTextSecondary = Color(0xFF6B7280);

  // Dark Theme Colors
  static const Color _darkScaffoldBg = Color(0xFF121214);
  static const Color _darkSurfaceBg = Color(0xFF1E1E22);
  static const Color _darkCardBorder = Color(0xFF2E2E34);
  static const Color _darkTextPrimary = Color(0xFFF3F4F6);
  static const Color _darkTextSecondary = Color(0xFF9CA3AF);

  // Font Fallbacks for CJK / Multi-language support
  static const List<String> fontFallbacks = [
    'Noto Sans SC',
    'Noto Sans CJK SC',
    'PingFang SC',
    'Microsoft YaHei',
    'SimHei',
    'Source Han Sans SC',
    'sans-serif',
  ];

  /// Light Theme (cached to prevent runtime rebuild allocations)
  static final ThemeData lightTheme = _buildLightTheme();

  /// Dark Theme (cached to prevent runtime rebuild allocations)
  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      fontFamilyFallback: fontFallbacks,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: brandPrimary,
        secondary: brandAccent,
        surface: _lightSurfaceBg,
        onSurface: _lightTextPrimary,
        onSurfaceVariant: _lightTextSecondary,
        outline: _lightCardBorder,
        outlineVariant: Color(0xFFD1D5DB),
        surfaceContainerHighest: Color(0xFFF3F4F6),
      ),
      scaffoldBackgroundColor: _lightScaffoldBg,
      cardColor: _lightSurfaceBg,
      cardTheme: CardThemeData(
        color: _lightSurfaceBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightCardBorder),
        ),
      ),
      dividerColor: _lightCardBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightScaffoldBg,
        foregroundColor: _lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );

    return baseTheme.copyWith(
      textTheme: _applyPoppinsHierarchy(baseTheme.textTheme),
    );
  }

  static ThemeData _buildDarkTheme() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      fontFamilyFallback: fontFallbacks,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandAccent,
        surface: _darkSurfaceBg,
        onSurface: _darkTextPrimary,
        onSurfaceVariant: _darkTextSecondary,
        outline: _darkCardBorder,
        outlineVariant: Color(0xFF3F3F46),
        surfaceContainerHighest: Color(0xFF27272A),
      ),
      scaffoldBackgroundColor: _darkScaffoldBg,
      cardColor: _darkSurfaceBg,
      cardTheme: CardThemeData(
        color: _darkSurfaceBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkCardBorder),
        ),
      ),
      dividerColor: _darkCardBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkScaffoldBg,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );

    return baseTheme.copyWith(
      textTheme: _applyPoppinsHierarchy(baseTheme.textTheme),
    );
  }

  /// Applies Poppins font with proper typographic hierarchy weights and CJK fallbacks
  static TextTheme _applyPoppinsHierarchy(TextTheme baseTheme) {
    final poppinsTheme = baseTheme.apply(
      fontFamily: 'Poppins',
      fontFamilyFallback: fontFallbacks,
    );
    return poppinsTheme.copyWith(
      // Headers get bold weights for strong contrast
      headlineLarge: poppinsTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: poppinsTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: poppinsTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),

      // Titles get medium/semibold weights
      titleLarge: poppinsTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: poppinsTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      titleSmall: poppinsTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      ),

      // Body text stays regular (w400) for maximum readability and default size of 14.0
      bodyLarge: poppinsTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
      ),
      bodyMedium: poppinsTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
      ),
      bodySmall: poppinsTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
      ),

      // UI Labels & Buttons use medium and default size of 14.0
      labelLarge: poppinsTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      ),
      labelMedium: poppinsTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      ),
      labelSmall: poppinsTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      ),
    );
  }
}
