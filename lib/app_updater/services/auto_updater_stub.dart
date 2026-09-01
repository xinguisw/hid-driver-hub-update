import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:driver_hub/app_updater/services/auto_updater_service.dart';
import 'package:flutter/foundation.dart';

AutoUpdaterService createAutoUpdaterService() => AutoUpdaterStubService();

/// Web and non-desktop stub implementation of [AutoUpdaterService].
///
/// Because WinSparkle/Sparkle are native C++/Cocoa desktop binaries, they cannot run
/// in a browser. This stub ensures web builds compile and execute cleanly without
/// throwing [MissingPluginException] or `dart:io` runtime errors.
class AutoUpdaterStubService implements AutoUpdaterService {
  bool _isInitialized = false;
  UpdaterConfig? _config;

  @override
  bool get isInitialized => _isInitialized;

  @override
  UpdaterConfig? get config => _config;

  /// Simulates initialization in Web/stub environment.
  @override
  Future<void> initialize(UpdaterConfig config) async {
    _config = config;
    _isInitialized = true;
    debugPrint('[AutoUpdaterStub] Initialized in web/stub environment with feed: ${config.effectiveFeedUrl}');
  }

  /// No-ops gracefully on Web. In UI integration (Subtask 4), Web users are directed to the release website.
  @override
  Future<void> checkForUpdates({bool isManual = true}) async {
    debugPrint('[AutoUpdaterStub] checkForUpdates called in web/stub environment.');
  }

  /// No-ops scheduled checks on Web.
  @override
  Future<void> setScheduledCheckInterval(int seconds) async {
    debugPrint('[AutoUpdaterStub] setScheduledCheckInterval ($seconds s) ignored in web/stub environment.');
  }
}
