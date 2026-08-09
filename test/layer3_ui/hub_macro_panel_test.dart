import 'package:driver_hub/layer3_ui/widgets/hub_macro_panel.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer4_domain/macro_timing_probe.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fake_device_runtime.dart';

void main() {
  test('M5 timing probe stays within the documented macro limits', () {
    final probe = buildMacroTimingProbe();

    expect(probe.slot, 5);
    expect(probe.actions, hasLength(27));
    expect(validateMacro(probe), isEmpty);
    expect(
      probe.actions.where(
        (action) => action.keyCode >= 0x01 && action.keyCode <= 0x03,
      ),
      hasLength(3),
    );
  });

  test('isolated probes contain one timing-special action each', () {
    for (final entry in const [(6, 0x01), (7, 0x02), (8, 0x03)]) {
      final probe = buildIsolatedMacroTimingProbe(
        slot: entry.$1,
        timingCode: entry.$2,
      );

      expect(probe.actions, hasLength(5));
      expect(validateMacro(probe), isEmpty);
      expect(probe.actions[2].keyCode, entry.$2);
    }
  });

  testWidgets('creating a macro opens a draft without adding a sidebar entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HubMacroPanel())),
    );

    expect(find.byType(ListTile), findsNothing);
    expect(find.text('No macros configured'), findsOneWidget);
    expect(find.text('Create M5 Timing Probe'), findsNothing);
    expect(find.text('Create M6 Probe (0x01)'), findsNothing);
    expect(find.text('Create M7 Probe (0x02)'), findsNothing);
    expect(find.text('Create M8 Probe (0x03)'), findsNothing);

    await tester.tap(find.text('Create Macro'));
    await tester.pump();

    expect(find.text('M1'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('recorded taps retain inline delays on the preceding actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HubMacroPanel())),
    );

    await tester.tap(find.text('Create Macro'));
    await tester.pump();
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.tap(find.text('Stop Recording'));
    await tester.pump();

    expect(find.text('A'), findsNWidgets(2));
    expect(find.text('KeyDown'), findsOneWidget);
    expect(find.text('KeyUp'), findsOneWidget);
    final keyDownRow = find
        .ancestor(of: find.text('KeyDown'), matching: find.byType(Row))
        .first;
    final keyUpRow = find
        .ancestor(of: find.text('KeyUp'), matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: keyDownRow, matching: find.text('10 ms')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: keyUpRow, matching: find.text('0 ms')),
      findsOneWidget,
    );
  });

  testWidgets('saving recorded actions validates the captured action list', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HubMacroPanel())),
    );

    await tester.tap(find.text('Create Macro'));
    await tester.pump();
    await tester.tap(find.text('Start Recording'));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
    await tester.tap(find.text('Stop Recording'));
    await tester.pump();

    final saveButton = find.text('Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(
      find.text('Macro must contain between 1 and 30 actions'),
      findsNothing,
    );
  });

  testWidgets('loaded macros wait for an explicit selection', (tester) async {
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
    final scope = DeviceScope(
      runtime: const FakeDeviceRuntime(),
      macroRepository: repository,
      appSettingsRepository: MemoryAppSettingsRepository(),
    );
    const card = DiscoveredCardState(
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HubMacroPanel(scope: scope, card: card),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('M1'), findsOneWidget);
    expect(find.text('Please select a shortcut to edit'), findsOneWidget);
    expect(find.text('Macro type'), findsNothing);

    await tester.tap(find.text('M1'));
    await tester.pump();

    expect(find.text('Please select a shortcut to edit'), findsNothing);
    expect(find.text('Macro type'), findsOneWidget);
  });
}
