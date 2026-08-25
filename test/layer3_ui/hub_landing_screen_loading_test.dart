import 'dart:async';

import 'package:driver_hub/layer3_ui/screens/hub_landing_screen.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fake_device_runtime.dart';

void main() {
  testWidgets('displays themed loading indicator during onboard query', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('A RenderFlex overflowed')) {
        previousFlutterError?.call(details);
      }
    };
    addTearDown(() {
      FlutterError.onError = previousFlutterError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final completer = Completer<DeviceSettingsState>();
    final scope = _TestDeviceScope(onboardCompleter: completer);

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF121212)),
          home: HubLandingScreen(card: _card, scope: scope),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Loading device capabilities...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(
        const DeviceSettingsState(
          devId: '03AA',
          displayName: 'M7X PRO',
          connectionMode: 0,
          hasRgbBacklight: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Loading device capabilities...'), findsNothing);
      expect(find.text('Backlight Setting'), findsOneWidget);
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('failed onboard query pops back to dashboard', (tester) async {
    final scope = _TestDeviceScope(
      onboardError: const DeviceSettingsState(
        devId: '03AA',
        displayName: 'M7X PRO',
        connectionMode: 0,
        error: 'timeout',
      ),
    );

    bool popped = false;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onDidRemovePage: (page) {
              popped = true;
            },
            pages: [
              const MaterialPage(child: Text('Dashboard')),
              MaterialPage(
                child: HubLandingScreen(card: _card, scope: scope),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(popped, true);
      expect(find.text('Dashboard'), findsOneWidget);
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('timeout during save pops back to dashboard', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('A RenderFlex overflowed')) {
        previousFlutterError?.call(details);
      }
    };
    addTearDown(() {
      FlutterError.onError = previousFlutterError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final scope = _TestDeviceScope(onCommitTimeout: true);

    bool popped = false;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onDidRemovePage: (page) {
              popped = true;
            },
            pages: [
              const MaterialPage(child: Text('Dashboard')),
              MaterialPage(
                child: HubLandingScreen(card: _card, scope: scope),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bloc = scope.lastCreatedBloc;
      expect(bloc, isNotNull);
      bloc!.add(const DeviceSettingsReportRateRequested(hz: 500));
      await tester.pump();
      bloc.add(const DeviceSettingsSaveDpiConfigurationRequested());
      await tester.pumpAndSettle();

      expect(popped, true);
      expect(find.text('Dashboard'), findsOneWidget);
    } finally {
      await scope.dispose();
    }
  });
}

const _card = DiscoveredCardState(
  devId: '03AA',
  displayName: 'M7X PRO',
  connectionMode: 0,
  firmwareVersion: '',
  batteryPercentage: -1,
  isCharging: false,
  physicalHandle: null,
  imageSmall: '',
  imageLarge: '',
);

class _TestDeviceScope extends DeviceScope {
  _TestDeviceScope({
    this.onboardCompleter,
    this.onboardError,
    this.onCommitTimeout = false,
  }) : super.forTesting(
         runtime: const FakeDeviceRuntime(),
         macroRepository: InMemoryMacroRepository(),
         appSettingsRepository: MemoryAppSettingsRepository(),
       );

  final Completer<DeviceSettingsState>? onboardCompleter;
  final DeviceSettingsState? onboardError;
  final bool onCommitTimeout;
  DeviceSettingsBloc? lastCreatedBloc;

  @override
  bool isCardConnected(DiscoveredCardState card) => true;

  @override
  DeviceSettingsBloc createSettingsBloc(
    DiscoveredCardState card, {
    SaveCompletedCallback? onSaveCompleted,
    EscalationCallback? onEscalationRequested,
  }) {
    if (onCommitTimeout) {
      lastCreatedBloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {
          throw TimeoutException(
            'HidSession.sendAndWait timed out waiting for a matching report (attempt 3/3)',
          );
        },
        commitDpiLevel: (_) async {},
        commitDpiValues: (_) async {},
        commitDpiStages: (_, _) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
        commitRgbBacklight: (_) async {},
        onSaveCompleted: onSaveCompleted,
        onEscalationRequested: onEscalationRequested,
      );
      return lastCreatedBloc!;
    }
    lastCreatedBloc = super.createSettingsBloc(
      card,
      onSaveCompleted: onSaveCompleted,
      onEscalationRequested: onEscalationRequested,
    );
    return lastCreatedBloc!;
  }

  @override
  Future<DeviceSettingsState> loadOnboardSettings(
    DiscoveredCardState card,
  ) async {
    if (onboardCompleter != null) {
      return onboardCompleter!.future;
    }
    if (onboardError != null) {
      return onboardError!;
    }
    return DeviceSettingsState(
      devId: card.devId,
      displayName: card.displayName,
      connectionMode: card.connectionMode,
      reportRateHz: 1000,
    );
  }
}
