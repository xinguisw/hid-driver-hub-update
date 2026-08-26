import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Controller for application theme state management (Layer 3 UI).
///
/// why: Manages active [ThemeMode] (light vs dark) across the application,
/// notifying listeners when the theme changes and persisting user preference via Hive.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.light);

  /// Global singleton instance for access across the app.
  static final ThemeController instance = ThemeController._();

  static const String _boxName = 'theme_settings';
  static const String _keyThemeMode = 'theme_mode';
  Box<int>? _box;

  /// Initializes persistence box and loads saved theme selection.
  /// why: Ensures user's dark/light mode preference is restored on app startup.
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<int>(_boxName);
      final savedIndex = _box?.get(_keyThemeMode);
      if (savedIndex != null &&
          savedIndex >= 0 &&
          savedIndex < ThemeMode.values.length) {
        value = ThemeMode.values[savedIndex];
      }
    } catch (e) {
      debugPrint('[ThemeController] Hive storage initialization error: $e');
    }
  }

  /// Toggles between Light and Dark mode.
  /// why: Provides a one-tap action for users to switch themes from UI header icons.
  void toggleTheme() {
    if (value == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  /// Sets specific ThemeMode and persists choice to storage.
  /// why: Updates runtime theme state immediately and syncs to Hive asynchronously.
  void setThemeMode(ThemeMode mode) {
    if (value == mode) return;
    value = mode;
    // Decouple disk I/O from UI frame dispatch to guarantee zero frame lag
    scheduleMicrotask(() {
      _box?.put(_keyThemeMode, mode.index).catchError((e) {
        debugPrint('[ThemeController] Failed to persist theme: $e');
      });
    });
  }

  /// Helper to check if dark mode is currently active given context brightness or state.
  /// why: Enables custom painter or icon rendering code to check active theme state easily.
  bool isDarkMode(BuildContext context) {
    if (value == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return value == ThemeMode.dark;
  }
}
