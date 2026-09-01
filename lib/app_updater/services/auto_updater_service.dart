import 'package:driver_hub/app_updater/models/updater_config.dart';

import 'auto_updater_stub.dart'
    if (dart.library.io) 'auto_updater_io.dart' as platform_impl;

/// Abstract adapter interface for application auto-updating across platforms.
abstract class AutoUpdaterService {
  /// Creates the platform-appropriate [AutoUpdaterService] instance.
  factory AutoUpdaterService() => platform_impl.createAutoUpdaterService();

  /// Whether the updater is currently initialized.
  bool get isInitialized;

  /// The active configuration, or null if not yet initialized.
  UpdaterConfig? get config;

  /// Initializes the updater with the provided [config] (setting the AppCast feed URL).
  Future<void> initialize(UpdaterConfig config);

  /// Triggers a version check against the remote AppCast feed.
  ///
  /// If [isManual] is true, the native WinSparkle/Sparkle modal is brought to foreground.
  Future<void> checkForUpdates({bool isManual = true});

  /// Sets the background scheduled update check interval in seconds (default is 86400 / 24h, 0 to disable).
  Future<void> setScheduledCheckInterval(int seconds);
}
