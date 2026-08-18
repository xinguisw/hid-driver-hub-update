import 'package:flutter/material.dart';

/// Simple controller for managing app theme (light/dark mode).
/// Exposes a [ValueNotifier<ThemeMode>] that can be listened to by the app's
/// MaterialApp to rebuild with the new theme.
class ThemeController {
  // Private constructor for singleton
  ThemeController._internal();

  static final ThemeController _instance = ThemeController._internal();

  /// Singleton instance
  static ThemeController get instance => _instance;

  /// Notifier that holds the current [ThemeMode].
  /// Listen to this to rebuild the app when theme changes.
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  /// Toggle between light and dark themes.
  /// If currently light, switches to dark; if dark, switches to light.
  /// If system, defaults to light on first toggle.
  void toggleTheme() {
    final current = themeModeNotifier.value;
    final newMode = switch (current) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light, // first toggle → light
    };
    themeModeNotifier.value = newMode;
  }

  /// Explicitly set a theme mode.
  void setTheme(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  /// Dispose resources when no longer needed.
  void dispose() {
    themeModeNotifier.dispose();
  }
}
