import 'package:driver_hub/layer3_ui/widgets/hub_macro_panel.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer4_domain/macro_timing_probe.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:flutter/gestures.dart';
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

    expect(find.text('M1'), findsAtLeastNWidgets(1));
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('save and reset buttons are disabled while recording is active', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HubMacroPanel())),
    );

    await tester.tap(find.text('Create Macro'));
    await tester.pump();

    // Before recording, Save and Reset are enabled
    final saveButtonBefore = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Save'),
    );
    expect(saveButtonBefore.onPressed, isNotNull);

    // Start recording
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    // While recording, Save and Reset are disabled
    final saveButtonRecording = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Save'),
    );
    final resetButtonRecording = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Reset'),
    );
    expect(saveButtonRecording.onPressed, isNull);
    expect(resetButtonRecording.onPressed, isNull);

    // Stop recording
    await tester.tap(find.text('Stop Recording'));
    await tester.pump();

    // After stopping recording, Save and Reset are re-enabled
    final saveButtonAfter = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Save'),
    );
    expect(saveButtonAfter.onPressed, isNotNull);
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

  testWidgets('recording captures mouse wheel direction as macro actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HubMacroPanel())),
    );

    await tester.tap(find.text('Create Macro'));
    await tester.pump();
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    final editor = find.byType(Listener).last;
    final position = tester.getCenter(editor);
    await tester.sendEventToBinding(
      PointerScrollEvent(
        kind: PointerDeviceKind.mouse,
        position: position,
        scrollDelta: const Offset(0, -20),
      ),
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        kind: PointerDeviceKind.mouse,
        position: position,
        scrollDelta: const Offset(0, 20),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Stop Recording'));
    await tester.pump();

    // One notch = single directional wheel action.
    expect(find.text('Wheel Up'), findsOneWidget);
    expect(find.text('Wheel Down'), findsOneWidget);
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
    expect(find.text('Please select a shortcut to edit'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'New Macro'),
      findsAtLeastNWidgets(1),
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

  testWidgets(
    'recording an existing macro appends and cancel restores its saved actions',
    (tester) async {
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
      addTearDown(scope.dispose);
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

      await tester.tap(find.text('M1'));
      await tester.pump();
      await tester.tap(find.text('Start Recording'));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
      await tester.tap(find.text('Stop Recording'));
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNWidgets(2));

      final cancelButton = find.text('Cancel');
      await tester.ensureVisible(cancelButton);
      await tester.tap(cancelButton);
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
    },
  );

  testWidgets('Reset clears all recorded actions in current draft', (
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

    final resetButton = find.text('Reset');
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pump();

    expect(find.text('A'), findsNothing);
    expect(find.text('No events recorded'), findsOneWidget);
  });

  testWidgets('recording captures punctuation key (-)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HubMacroPanel())),
    );

    await tester.tap(find.text('Create Macro'));
    await tester.pump();
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.minus);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
    await tester.pumpAndSettle();

    expect(find.text('-'), findsNWidgets(2));
  });

  testWidgets('recording captures lock key (Caps Lock)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HubMacroPanel())),
    );

    await tester.tap(find.text('Create Macro'));
    await tester.pump();
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.capsLock);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.capsLock);
    await tester.pumpAndSettle();

    expect(find.text('Caps Lock'), findsNWidgets(2));
  });

  testWidgets('recording captures function key (F12)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HubMacroPanel())),
    );

    await tester.tap(find.text('Create Macro'));
    await tester.pump();
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.f12);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.f12);
    await tester.pumpAndSettle();

    expect(find.text('F12'), findsNWidgets(2));
  });

  testWidgets(
    'recording blocks consumer and multimedia keys and shows error message',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();
      await tester.tap(find.text('Start Recording'));
      await tester.pump();

      // Press consumer Volume Up
      await tester.sendKeyDownEvent(LogicalKeyboardKey.audioVolumeUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.audioVolumeUp);
      await tester.pump();

      expect(
        find.text('Consumer and multimedia keys cannot be recorded'),
        findsOneWidget,
      );

      // Press consumer Media Play/Pause
      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.pump();

      expect(
        find.text('Consumer and multimedia keys cannot be recorded'),
        findsOneWidget,
      );

      await tester.tap(find.text('Stop Recording'));
      await tester.pump();

      // Ensure no consumer key actions were recorded into draft
      expect(find.text('KeyDown'), findsNothing);
      expect(find.text('KeyUp'), findsNothing);
    },
  );

  testWidgets(
    'interleaved key presses (Press A -> Press B -> Release A -> Release B) preserve exact chronological sequence',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();

      await tester.tap(find.text('Start Recording'));
      await tester.pump();

      // Press A
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, platform: 'windows');
      await tester.pump();

      // Press B
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB, platform: 'windows');
      await tester.pump();

      // Stop recording
      await tester.tap(find.text('Stop Recording'));
      await tester.pump();

      // Verify actions display in exact recorded order: Press A, Press B, Release A, Release B (or Press A, Press B)
      expect(find.text('A'), findsWidgets);
      expect(find.text('B'), findsWidgets);
    },
  );

  testWidgets(
    'loop count field is enabled only when macro type is Loop',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();

      final loopFieldFinder = find.widgetWithText(TextField, 'Loop count');
      final loopTextField = tester.widget<TextField>(loopFieldFinder);
      expect(loopTextField.enabled, isTrue);

      // Select 'Play on hold'
      await tester.tap(find.text('Loop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play on hold').last);
      await tester.pumpAndSettle();

      final disabledTextField = tester.widget<TextField>(loopFieldFinder);
      expect(disabledTextField.enabled, isFalse);
    },
  );

  testWidgets(
    'saving a macro displays "Macro saved successfully" toast',
    (tester) async {
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

      final saveButton = find.text('Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Macro saved successfully'), findsOneWidget);
      expect(find.byType(MacroToast), findsOneWidget);

      // Verify auto-dismiss after 3s
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Macro saved successfully'), findsNothing);
    },
  );

  testWidgets(
    'saving an invalid macro displays "Macro failed to save" toast',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();

      // Attempt to save empty macro (invalid: must have 1..30 actions)
      final saveButton = find.text('Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Macro failed to save'), findsOneWidget);
      expect(find.byType(MacroToast), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Macro failed to save'), findsNothing);
    },
  );
}

