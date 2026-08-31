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

  testWidgets('macro draft is cleared when the panel becomes inactive', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HubMacroPanel(isActive: true)),
      ),
    );

    await tester.tap(find.text('Create Macro'));
    await tester.pump();

    expect(find.text('M1'), findsAtLeastNWidgets(1));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HubMacroPanel(isActive: false)),
      ),
    );
    await tester.pump();

    expect(find.text('Create Macro'), findsOneWidget);
    expect(find.text('M1'), findsNothing);
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
    final saveButtonBefore = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(saveButtonBefore.onPressed, isNotNull);

    // Start recording
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    // While recording, Save and Reset are disabled (Save becomes OutlinedButton with null onPressed)
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
    final saveButtonAfter = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
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
    expect(find.text('Macro saved successfully'), findsOneWidget);
    expect(
      find.byType(HubMacroPanel),
      findsOneWidget,
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

  testWidgets(
    'entering a macro name exceeding 30 characters displays error message',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();

      // Enter 31 characters in Macro Name field
      final nameField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Macro Name',
      );
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'A' * 31);
      await tester.pump();

      expect(
        find.text('Macro name must not exceed 30 characters'),
        findsOneWidget,
      );

      // Shorten name to 30 characters
      await tester.enterText(nameField, 'A' * 30);
      await tester.pump();

      expect(
        find.text('Macro name must not exceed 30 characters'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'delay mode defaults to Recorded Delay ChoiceChip',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();

      final recordedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Recorded Delay'),
      );
      final fixedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Fixed Delay'),
      );

      expect(recordedChip.selected, isTrue);
      expect(fixedChip.selected, isFalse);
    },
  );

  testWidgets(
    'selecting Fixed Delay ChoiceChip applies configured fixed delay to actions',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();

      // Select Fixed Delay
      await tester.tap(find.widgetWithText(ChoiceChip, 'Fixed Delay'));
      await tester.pump();

      // Enter 50 ms in Fixed Delay field
      final fixedDelayField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Fixed Delay (ms)',
      );
      expect(fixedDelayField, findsOneWidget);
      await tester.enterText(fixedDelayField, '50');
      await tester.pump();

      // Record key taps
      await tester.tap(find.text('Start Recording'));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.tap(find.text('Stop Recording'));
      await tester.pump();

      // First action delay should be fixed 50 ms
      expect(find.text('50 ms'), findsOneWidget);
    },
  );

  testWidgets(
    'entering a fixed delay > 100 ms displays error message',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();

      // Select Fixed Delay
      await tester.tap(find.widgetWithText(ChoiceChip, 'Fixed Delay'));
      await tester.pump();

      final fixedDelayField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Fixed Delay (ms)',
      );
      await tester.enterText(fixedDelayField, '150');
      await tester.pump();

      expect(
        find.text('Fixed delay must be between 1 and 100 ms'),
        findsOneWidget,
      );

      // Attempt save
      final saveButton = find.text('Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Macro failed to save'), findsOneWidget);
    },
  );

  testWidgets(
    'Reset preserves the chosen delay mode selection',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HubMacroPanel())),
      );

      await tester.tap(find.text('Create Macro'));
      await tester.pump();

      // Select Fixed Delay
      await tester.tap(find.widgetWithText(ChoiceChip, 'Fixed Delay'));
      await tester.pump();

      // Reset recording
      await tester.tap(find.text('Reset'));
      await tester.pump();

      // Fixed Delay should still be selected
      final fixedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Fixed Delay'),
      );
      expect(fixedChip.selected, isTrue);
    },
  );

  testWidgets(
    'creating a new macro resets delay mode to recorded and fixed delay to 10',
    (tester) async {
      final repository = InMemoryMacroRepository();
      await repository.save('03AA', [
        const MacroDefinition(
          slot: 1,
          name: 'M1',
          mode: MacroMode.loop,
          loopTimes: 1,
          actions: [
            MacroAction(keyCode: 0x04, isBreak: false, delay: 5, label: 'A'),
            MacroAction(keyCode: 0x04, isBreak: true, delay: 5, label: 'A'),
            MacroAction(keyCode: 0x05, isBreak: false, delay: 5, label: 'B'),
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

      // Open M1 which has fixed delay 50ms
      await tester.tap(find.text('M1'));
      await tester.pump();

      final fixedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Fixed Delay'),
      );
      expect(fixedChip.selected, isTrue);

      // Now click + to create new macro
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      // Should reset to Recorded Delay and 10ms
      final recordedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Recorded Delay'),
      );
      expect(recordedChip.selected, isTrue);

      final fixedDelayField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Fixed Delay (ms)',
        ),
      );
      expect(fixedDelayField.controller?.text, '10');
    },
  );

  testWidgets(
    'selecting a recorded macro with non-uniform delays defaults fixed field to 10 instead of first action delay',
    (tester) async {
      final repository = InMemoryMacroRepository();
      await repository.save('03AA', [
        const MacroDefinition(
          slot: 1,
          name: 'RecordedMacro',
          mode: MacroMode.loop,
          loopTimes: 1,
          actions: [
            MacroAction(keyCode: 0x04, isBreak: false, delay: 10, label: 'A'),
            MacroAction(keyCode: 0x04, isBreak: true, delay: 0, label: 'A'),
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

      await tester.tap(find.text('RecordedMacro'));
      await tester.pump();

      final recordedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Recorded Delay'),
      );
      expect(recordedChip.selected, isTrue);

      // Fixed delay field should be '10', NOT '100'
      final fixedDelayField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Fixed Delay (ms)',
        ),
      );
      expect(fixedDelayField.controller?.text, '10');
    },
  );

  testWidgets(
    'deleting a macro updates list optimistically without replacing UI with full-screen loading spinner',
    (tester) async {
      final repository = InMemoryMacroRepository();
      await repository.save('03AA', [
        const MacroDefinition(
          slot: 1,
          name: 'MacroOne',
          mode: MacroMode.loop,
          loopTimes: 1,
          actions: [
            MacroAction(keyCode: 0x04, isBreak: false, delay: 0, label: 'A'),
          ],
        ),
        const MacroDefinition(
          slot: 2,
          name: 'MacroTwo',
          mode: MacroMode.loop,
          loopTimes: 1,
          actions: [
            MacroAction(keyCode: 0x05, isBreak: false, delay: 0, label: 'B'),
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

      expect(find.text('MacroOne'), findsOneWidget);
      expect(find.text('MacroTwo'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap delete on MacroOne
      final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteButtons, findsNWidgets(2));
      await tester.tap(deleteButtons.first);
      await tester.pump();

      // MacroOne should immediately disappear without full-screen CircularProgressIndicator
      expect(find.text('MacroOne'), findsNothing);
      expect(find.text('MacroTwo'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}

