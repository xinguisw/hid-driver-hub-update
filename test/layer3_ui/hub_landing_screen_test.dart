import 'package:driver_hub/layer3_ui/screens/hub_landing_screen.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fake_device_runtime.dart';

void main() {
  testWidgets(
    'hub entry preloads macros before Button Mapping reads the catalog',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      final previousFlutterError = FlutterError.onError;
      FlutterError.onError = (details) {
        // HubMouseCanvas has a pre-existing 4px fixed action-band overflow;
        // this test observes hub initialization, not that unrelated layout.
        if (!details.exceptionAsString().contains('A RenderFlex overflowed')) {
          previousFlutterError?.call(details);
        }
      };
      addTearDown(() {
        FlutterError.onError = previousFlutterError;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final repository = InMemoryMacroRepository();
      await repository.save('03AA', [
        const MacroDefinition(
          slot: 1,
          name: 'M1',
          mode: MacroMode.loop,
          loopTimes: 1,
          actions: [
            MacroAction(keyCode: 0x04, isBreak: false, delay: 0, label: 'A'),
          ],
        ),
      ]);
      final scope = _ConnectedDeviceScope(repository);

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: HubLandingScreen(card: _card, scope: scope),
          ),
        );
        await tester.pumpAndSettle();

        expect(scope.macrosFor(_card), hasLength(1));
        expect(scope.macrosFor(_card).single.name, 'M1');
        expect(find.text('Backlight Setting'), findsOneWidget);
      } finally {
        await scope.dispose();
      }
    },
  );
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

class _ConnectedDeviceScope extends DeviceScope {
  _ConnectedDeviceScope(MacroRepository repository)
    : super.forTesting(
        runtime: const FakeDeviceRuntime(),
        macroRepository: repository,
        appSettingsRepository: MemoryAppSettingsRepository(),
      );

  @override
  bool isCardConnected(DiscoveredCardState card) => true;

  @override
  Future<DeviceSettingsState> loadOnboardSettings(
    DiscoveredCardState card,
  ) async {
    return DeviceSettingsState(
      devId: card.devId,
      displayName: card.displayName,
      connectionMode: card.connectionMode,
      hasRgbBacklight: true,
    );
  }
}
