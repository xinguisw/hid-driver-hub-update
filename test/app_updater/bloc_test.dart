import 'dart:async';

import 'package:driver_hub/app_updater/bloc/app_update_bloc.dart';
import 'package:driver_hub/app_updater/bloc/app_update_event.dart';
import 'package:driver_hub/app_updater/bloc/app_update_state.dart';
import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:driver_hub/app_updater/services/auto_updater_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake test double implementing [AutoUpdaterService] to simulate responses in unit tests.
class FakeAutoUpdaterService implements AutoUpdaterService {
  bool _initialized = false;
  UpdaterConfig? _activeConfig;
  int checkCount = 0;
  bool? lastCheckIsManual;
  int? lastScheduledInterval;
  bool shouldThrowOnInitialize = false;
  bool shouldThrowOnCheck = false;
  Completer<void>? pendingCheckCompleter;

  @override
  bool get isInitialized => _initialized;

  @override
  UpdaterConfig? get config => _activeConfig;

  @override
  Future<void> initialize(UpdaterConfig config) async {
    if (shouldThrowOnInitialize) {
      throw Exception('Service initialization failed');
    }
    _activeConfig = config;
    _initialized = true;
  }

  @override
  Future<void> checkForUpdates({bool isManual = true}) async {
    if (pendingCheckCompleter != null) {
      await pendingCheckCompleter!.future;
    }
    if (shouldThrowOnCheck) {
      throw Exception('Network unreachable or feed 404');
    }
    checkCount++;
    lastCheckIsManual = isManual;
  }

  @override
  Future<void> setScheduledCheckInterval(int seconds) async {
    lastScheduledInterval = seconds;
  }
}

void main() {
  group('AppUpdateBloc', () {
    late FakeAutoUpdaterService fakeService;
    late AppUpdateBloc bloc;

    setUp(() {
      fakeService = FakeAutoUpdaterService();
      bloc = AppUpdateBloc(autoUpdaterService: fakeService);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('initial state is AppUpdateInitial', () {
      expect(bloc.state, equals(const AppUpdateInitial()));
    });

    test('InitializeUpdaterRequested initializes service successfully', () async {
      const customConfig = UpdaterConfig(owner: 'test_user', repo: 'test_repo');
      bloc.add(const InitializeUpdaterRequested(config: customConfig));

      await expectLater(
        bloc.stream,
        emitsInOrder([]), // Initialize does not change state on success
      );

      expect(fakeService.isInitialized, isTrue);
      expect(fakeService.config, equals(customConfig));
    });

    test('InitializeUpdaterRequested emits AppUpdateCheckFailure on error', () async {
      fakeService.shouldThrowOnInitialize = true;
      bloc.add(const InitializeUpdaterRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AppUpdateCheckFailure>().having(
            (s) => s.message,
            'message',
            contains('Service initialization failed'),
          ),
        ]),
      );
    });

    test('CheckForUpdatesRequested (manual) emits Checking then CheckSuccess', () async {
      bloc.add(const CheckForUpdatesRequested(isManual: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AppUpdateChecking(isManual: true),
          isA<AppUpdateCheckSuccess>().having(
            (s) => s.isManual,
            'isManual',
            isTrue,
          ),
        ]),
      );

      expect(fakeService.checkCount, equals(1));
      expect(fakeService.lastCheckIsManual, isTrue);
    });

    test('CheckForUpdatesRequested (background) emits Checking then CheckSuccess with isManual=false', () async {
      bloc.add(const CheckForUpdatesRequested(isManual: false));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AppUpdateChecking(isManual: false),
          isA<AppUpdateCheckSuccess>().having(
            (s) => s.isManual,
            'isManual',
            isFalse,
          ),
        ]),
      );

      expect(fakeService.checkCount, equals(1));
      expect(fakeService.lastCheckIsManual, isFalse);
    });

    test('CheckForUpdatesRequested emits Failure when service throws exception', () async {
      fakeService.shouldThrowOnCheck = true;
      bloc.add(const CheckForUpdatesRequested(isManual: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AppUpdateChecking(isManual: true),
          isA<AppUpdateCheckFailure>()
              .having((s) => s.message, 'message', contains('Network unreachable'))
              .having((s) => s.isManual, 'isManual', isTrue),
        ]),
      );
    });

    test('concurrency: droppable drops concurrent CheckForUpdatesRequested while check is active', () async {
      final completer = Completer<void>();
      fakeService.pendingCheckCompleter = completer;

      // Dispatch multiple events simultaneously
      bloc.add(const CheckForUpdatesRequested(isManual: true));
      bloc.add(const CheckForUpdatesRequested(isManual: true));
      bloc.add(const CheckForUpdatesRequested(isManual: true));

      // Wait a tick for the first event to be received and start checking
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(bloc.state, equals(const AppUpdateChecking(isManual: true)));

      // Complete the pending check
      completer.complete();

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AppUpdateCheckSuccess>(),
        ]),
      );

      // Only 1 call was processed, others were dropped by droppable()
      expect(fakeService.checkCount, equals(1));
    });

    test('SetUpdateIntervalRequested configures interval on service', () async {
      bloc.add(const SetUpdateIntervalRequested(intervalSeconds: 7200));

      // Give event loop time to process
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeService.lastScheduledInterval, equals(7200));
    });

    test('ResetUpdateStateRequested resets state back to AppUpdateInitial', () async {
      bloc.add(const CheckForUpdatesRequested(isManual: true));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<AppUpdateCheckSuccess>()),
      );

      bloc.add(const ResetUpdateStateRequested());
      await expectLater(
        bloc.stream,
        emits(const AppUpdateInitial()),
      );
    });
  });
}
