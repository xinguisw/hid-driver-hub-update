import 'package:auto_updater_platform_interface/auto_updater_platform_interface.dart';
import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:driver_hub/app_updater/services/auto_updater_io.dart';
import 'package:driver_hub/app_updater/services/auto_updater_service.dart';
import 'package:driver_hub/app_updater/services/auto_updater_stub.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test double simulating the native AutoUpdaterPlatform channel (WinSparkle/Sparkle).
///
/// This avoids invoking native C++ WinSparkle.dll or Cocoa Sparkle methods
/// during unit/widget test runs, capturing calls and parameters for assertion.
class FakeAutoUpdaterPlatform extends AutoUpdaterPlatform {
  String? feedUrl;
  int? checkInterval;
  int checkCount = 0;
  bool? lastInBackground;
  bool shouldThrow = false;

  @override
  Stream<Map<Object?, Object?>> get sparkleEvents => const Stream.empty();

  @override
  Future<void> setFeedURL(String feedURL) async {
    if (shouldThrow) throw Exception('Failed to set feed URL');
    feedUrl = feedURL;
  }

  @override
  Future<void> checkForUpdates({bool? inBackground}) async {
    if (shouldThrow) throw Exception('Check for updates failed');
    checkCount++;
    lastInBackground = inBackground;
  }

  @override
  Future<void> setScheduledCheckInterval(int interval) async {
    if (shouldThrow) throw Exception('Failed to set interval');
    checkInterval = interval;
  }
}

void main() {
  group('AutoUpdaterIoService', () {
    late FakeAutoUpdaterPlatform fakePlatform;
    late AutoUpdaterIoService service;

    setUp(() {
      fakePlatform = FakeAutoUpdaterPlatform();
      // Inject the fake platform double into the auto_updater plugin platform interface
      AutoUpdaterPlatform.instance = fakePlatform;
      service = AutoUpdaterIoService();
    });

    test('initializes and passes effectiveFeedUrl to platform interface', () async {
      // 1. Verify initial uninitialized state
      expect(service.isInitialized, isFalse);
      expect(service.config, isNull);

      // 2. Initialize with configuration
      const config = UpdaterConfig(owner: 'sumanram23', repo: 'hid-driver-hub');
      await service.initialize(config);

      // 3. Verify state and that the effective AppCast feed URL was forwarded to native layer
      expect(service.isInitialized, isTrue);
      expect(service.config, equals(config));
      expect(
        fakePlatform.feedUrl,
        equals('https://raw.githubusercontent.com/sumanram23/hid-driver-hub/main/dist/appcast.xml'),
      );
    });

    test('calls checkForUpdates on platform interface with correct background flag', () async {
      const config = UpdaterConfig();
      await service.initialize(config);

      // Manual check (e.g. user clicked "Check for Updates" in Settings) -> inBackground: false
      await service.checkForUpdates(isManual: true);
      expect(fakePlatform.checkCount, equals(1));
      expect(fakePlatform.lastInBackground, isFalse);

      // Automatic check (e.g. background startup check) -> inBackground: true
      await service.checkForUpdates(isManual: false);
      expect(fakePlatform.checkCount, equals(2));
      expect(fakePlatform.lastInBackground, isTrue);
    });

    test('auto-initializes if checkForUpdates called before initialize', () async {
      expect(service.isInitialized, isFalse);

      // Triggering check without prior initialization should automatically initialize with default config
      await service.checkForUpdates();

      expect(service.isInitialized, isTrue);
      expect(fakePlatform.checkCount, equals(1));
      expect(fakePlatform.feedUrl, isNotNull);
    });

    test('sets scheduled check interval', () async {
      // Configures periodic background check interval (in seconds)
      await service.setScheduledCheckInterval(3600);
      expect(fakePlatform.checkInterval, equals(3600));
    });

    test('rethrows exceptions when platform interface fails', () async {
      fakePlatform.shouldThrow = true;
      const config = UpdaterConfig();

      // Ensure platform errors propagate properly to caller/BLoC
      expect(() => service.initialize(config), throwsException);
      expect(service.isInitialized, isFalse);
    });
  });

  group('AutoUpdaterStubService', () {
    test('safely no-ops on Web / stub environments without throwing errors', () async {
      final stubService = AutoUpdaterStubService();
      expect(stubService.isInitialized, isFalse);

      const config = UpdaterConfig(owner: 'test_org', repo: 'test_repo');
      await stubService.initialize(config);

      expect(stubService.isInitialized, isTrue);
      expect(stubService.config, equals(config));

      // Verifies that web builds do not throw MissingPluginException or unsupported platform errors
      await expectLater(stubService.checkForUpdates(), completes);
      await expectLater(stubService.setScheduledCheckInterval(7200), completes);
    });
  });

  group('AutoUpdaterService factory', () {
    test('creates a non-null instance via default factory', () {
      // Verifies conditional import factory returns a valid concrete service instance
      final service = AutoUpdaterService();
      expect(service, isNotNull);
    });
  });
}
