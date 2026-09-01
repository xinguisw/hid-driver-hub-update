import 'dart:io';

import 'package:auto_updater/auto_updater.dart' as win_sparkle;
import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:driver_hub/app_updater/services/auto_updater_service.dart';
import 'package:flutter/foundation.dart';

AutoUpdaterService createAutoUpdaterService() => AutoUpdaterIoService();

/// Desktop (Windows/macOS) implementation using the native [auto_updater] plugin.
///
/// On Windows, this delegates to WinSparkle (C++ DLL) which manages the native update
/// lifecycle, AppCast RSS parsing, and Inno Setup installer execution.
/// On macOS, this delegates to the Sparkle Cocoa framework.
class AutoUpdaterIoService implements AutoUpdaterService {
  AutoUpdaterIoService({win_sparkle.AutoUpdater? nativeUpdater})
      : _nativeUpdater = nativeUpdater ?? win_sparkle.autoUpdater;

  final win_sparkle.AutoUpdater _nativeUpdater;

  bool _isInitialized = false;
  UpdaterConfig? _config;

  @override
  bool get isInitialized => _isInitialized;

  @override
  UpdaterConfig? get config => _config;

  /// Guard to check if current execution runtime is a supported desktop OS.
  bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS);

  /// Initializes the native Sparkle/WinSparkle engine by configuring the AppCast feed URL.
  ///
  /// [config.effectiveFeedUrl] points to the XML feed (e.g. GitHub raw `dist/appcast.xml`).
  @override
  Future<void> initialize(UpdaterConfig config) async {
    _config = config;

    if (!_isSupportedPlatform) {
      _isInitialized = true;
      return;
    }

    try {
      await _nativeUpdater.setFeedURL(config.effectiveFeedUrl);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[AutoUpdater] Failed to set feed URL: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Triggers a version check against the remote AppCast feed URL.
  ///
  /// - When [isManual] is true (e.g. user clicked "Check for Updates" in Settings),
  ///   `inBackground: false` is passed so WinSparkle shows its UI modal immediately
  ///   (notifying the user even if the app is already up to date).
  /// - When [isManual] is false (e.g. periodic or startup background check),
  ///   `inBackground: true` is passed so WinSparkle remains silent if no update exists.
  @override
  Future<void> checkForUpdates({bool isManual = true}) async {
    if (!_isSupportedPlatform) {
      debugPrint('[AutoUpdater] checkForUpdates skipped on unsupported platform');
      return;
    }

    if (!_isInitialized) {
      await initialize(_config ?? const UpdaterConfig());
    }

    try {
      await _nativeUpdater.checkForUpdates(inBackground: !isManual);
    } catch (e) {
      debugPrint('[AutoUpdater] checkForUpdates error: $e');
      rethrow;
    }
  }

  /// Configures the background periodic check interval in seconds.
  /// Default: 86400 (24 hours). Set to 0 to disable periodic checks.
  @override
  Future<void> setScheduledCheckInterval(int seconds) async {
    if (!_isSupportedPlatform) return;

    try {
      await _nativeUpdater.setScheduledCheckInterval(seconds);
    } catch (e) {
      debugPrint('[AutoUpdater] setScheduledCheckInterval error: $e');
      rethrow;
    }
  }
}
