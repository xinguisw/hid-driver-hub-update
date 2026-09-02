import 'package:auto_updater_platform_interface/auto_updater_platform_interface.dart';
import 'package:driver_hub/app_updater/bloc/app_update_bloc.dart';
import 'package:driver_hub/app_updater/bloc/app_update_event.dart';
import 'package:driver_hub/app_updater/bloc/app_update_state.dart';
import 'package:driver_hub/app_updater/models/app_release.dart';
import 'package:driver_hub/app_updater/models/update_progress.dart';
import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:driver_hub/app_updater/services/auto_updater_io.dart';
import 'package:driver_hub/app_updater/services/auto_updater_stub.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock platform channel capturing calls made across the native boundary.
class MockAutoUpdaterPlatform extends AutoUpdaterPlatform {
  String? setFeedUrlCalledWith;
  int? checkIntervalConfigured;
  int checkForUpdatesCallCount = 0;
  bool? lastCheckWasInBackground;
  bool shouldFailOnSetFeed = false;
  bool shouldFailOnCheck = false;

  @override
  Stream<Map<Object?, Object?>> get sparkleEvents => const Stream.empty();

  @override
  Future<void> setFeedURL(String feedURL) async {
    if (shouldFailOnSetFeed) throw Exception('Simulated feed URL error');
    setFeedUrlCalledWith = feedURL;
  }

  @override
  Future<void> checkForUpdates({bool? inBackground}) async {
    if (shouldFailOnCheck) throw Exception('Simulated network failure on update check');
    checkForUpdatesCallCount++;
    lastCheckWasInBackground = inBackground;
  }

  @override
  Future<void> setScheduledCheckInterval(int interval) async {
    checkIntervalConfigured = interval;
  }
}

void main() {
  group('Integration: Subtasks 1 -> 2 -> 3 End-to-End Pipeline', () {
    late MockAutoUpdaterPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockAutoUpdaterPlatform();
      AutoUpdaterPlatform.instance = mockPlatform;
    });

    test('Flow 1: Custom UpdaterConfig (Subtask 1) flows through AutoUpdaterIoService (Subtask 2) via AppUpdateBloc (Subtask 3)', () async {
      // 1. Create a custom configuration from Subtask 1
      const customConfig = UpdaterConfig(
        owner: 'newmen-corp',
        repo: 'custom-driver-hub',
        feedUrl: 'https://updates.newmen.com/custom_feed.xml',
      );

      // 2. Initialize Real AutoUpdaterIoService from Subtask 2
      final ioService = AutoUpdaterIoService();

      // 3. Instantiate AppUpdateBloc from Subtask 3
      final bloc = AppUpdateBloc(
        autoUpdaterService: ioService,
        defaultConfig: customConfig,
      );

      // 4. Dispatch Initialize event
      bloc.add(const InitializeUpdaterRequested());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verify Subtask 1 -> Subtask 2 -> Subtask 3 connection
      expect(ioService.isInitialized, isTrue);
      expect(ioService.config, equals(customConfig));
      expect(mockPlatform.setFeedUrlCalledWith, equals('https://updates.newmen.com/custom_feed.xml'));

      // 5. Trigger manual update check
      bloc.add(const CheckForUpdatesRequested(isManual: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AppUpdateChecking(isManual: true),
          isA<AppUpdateCheckSuccess>().having((s) => s.isManual, 'isManual', isTrue),
        ]),
      );

      expect(mockPlatform.checkForUpdatesCallCount, equals(1));
      expect(mockPlatform.lastCheckWasInBackground, isFalse);

      await bloc.close();
    });

    test('Flow 2: Background check workflow correctly signals background mode to native platform', () async {
      const config = UpdaterConfig();
      final ioService = AutoUpdaterIoService();
      final bloc = AppUpdateBloc(
        autoUpdaterService: ioService,
        defaultConfig: config,
      );

      bloc.add(const CheckForUpdatesRequested(isManual: false));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AppUpdateChecking(isManual: false),
          isA<AppUpdateCheckSuccess>().having((s) => s.isManual, 'isManual', isFalse),
        ]),
      );

      expect(mockPlatform.checkForUpdatesCallCount, equals(1));
      expect(mockPlatform.lastCheckWasInBackground, isTrue);

      await bloc.close();
    });

    test('Flow 3: Error in Subtask 2 platform layer correctly emits AppUpdateCheckFailure in Subtask 3 BLoC', () async {
      mockPlatform.shouldFailOnCheck = true;
      final ioService = AutoUpdaterIoService();
      final bloc = AppUpdateBloc(autoUpdaterService: ioService);

      bloc.add(const CheckForUpdatesRequested(isManual: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AppUpdateChecking(isManual: true),
          isA<AppUpdateCheckFailure>()
              .having((s) => s.isManual, 'isManual', isTrue)
              .having((s) => s.message, 'message', contains('Simulated network failure')),
        ]),
      );

      await bloc.close();
    });

    test('Flow 4: Subtask 1 SemVer & Progress models remain interoperable with Web Stub Service (Subtask 2) and BLoC (Subtask 3)', () async {
      // Validate Subtask 1 models
      final release = AppRelease(
        tagName: 'v2.0.0',
        version: '2.0.0',
        releaseNotes: 'Brand new major version',
        assetDownloadUrl: 'https://github.com/.../installer.exe',
        assetName: 'installer.exe',
        assetSizeBytes: 50000000,
        publishedAt: DateTime.now(),
        htmlUrl: 'https://github.com/sumanram23/hid-driver-hub/releases/tag/v2.0.0',
      );
      expect(release.isNewerThan('1.0.0'), isTrue);

      const progress = UpdateProgress(
        receivedBytes: 50000000,
        totalBytes: 50000000,
      );
      expect(progress.isCompleted, isTrue);

      // Validate Web Stub Service interoperability with BLoC
      final stubService = AutoUpdaterStubService();
      final bloc = AppUpdateBloc(autoUpdaterService: stubService);

      bloc.add(const CheckForUpdatesRequested(isManual: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AppUpdateChecking(isManual: true),
          isA<AppUpdateCheckSuccess>().having((s) => s.isManual, 'isManual', isTrue),
        ]),
      );

      await bloc.close();
    });
  });
}
