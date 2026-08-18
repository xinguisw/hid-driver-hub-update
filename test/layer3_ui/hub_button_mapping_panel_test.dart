import 'package:driver_hub/layer3_ui/widgets/hub_button_mapping_panel.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Macro tab displays saved macro slots immediately', (
    tester,
  ) async {
    const savedMacro = MacroDefinition(
      slot: 3,
      name: 'Burst fire',
      mode: MacroMode.loop,
      loopTimes: 1,
      actions: [
        MacroAction(keyCode: 0x04, isBreak: false, delay: 0, label: 'A'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HubButtonMappingPanel(macroSlots: const [savedMacro]),
        ),
      ),
    );

    await tester.tap(find.text('Macro'));
    await tester.pump();

    expect(find.text('Burst fire'), findsOneWidget);
  });

  testWidgets('Special tab allows entering Any Key without modifier keys', (
    tester,
  ) async {
    List<String>? receivedMods;
    String? receivedKey;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HubButtonMappingPanel(
            selectedButtonId: 1,
            specialActionCatalog: const [
              ActionCatalogSectionData(
                title: 'Combination Keys',
                items: [
                  ActionCatalogItemData(
                    id: 'special.mod.ctrl',
                    label: 'Ctrl',
                    role: 'modifier',
                  ),
                  ActionCatalogItemData(
                    id: 'special.any_key',
                    label: 'Any key',
                    role: 'any_key',
                  ),
                ],
              ),
            ],
            onComboSelected: (mods, key) {
              receivedMods = mods;
              receivedKey = key;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Special'));
    await tester.pumpAndSettle();

    // Tap Any key input box (last InkWell in _SpecialCombinationBody)
    await tester.tap(
      find.byType(InkWell).last,
    );
    await tester.pumpAndSettle();

    // Simulate key press 'A'
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pumpAndSettle();

    expect(receivedMods, isEmpty);
    expect(receivedKey, equals('a'));
  });

  testWidgets(
    'Special tab updates combo when toggling modifier after Any Key captured',
    (tester) async {
      List<String>? receivedMods;
      String? receivedKey;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HubButtonMappingPanel(
              selectedButtonId: 1,
              specialActionCatalog: const [
                ActionCatalogSectionData(
                  title: 'Combination Keys',
                  items: [
                    ActionCatalogItemData(
                      id: 'special.mod.ctrl',
                      label: 'Ctrl',
                      role: 'modifier',
                    ),
                    ActionCatalogItemData(
                      id: 'special.any_key',
                      label: 'Any key',
                      role: 'any_key',
                    ),
                  ],
                ),
              ],
              onComboSelected: (mods, key) {
                receivedMods = mods;
                receivedKey = key;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Special'));
      await tester.pumpAndSettle();

      // Tap Any key input box and press 'b'
      await tester.tap(
        find.byType(InkWell).last,
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB, character: 'b');
      await tester.pumpAndSettle();

      expect(receivedMods, isEmpty);
      expect(receivedKey, equals('b'));

      // Toggle 'Ctrl' modifier on
      await tester.tap(find.text('Ctrl'));
      await tester.pumpAndSettle();

      expect(receivedMods, equals(['special.mod.ctrl']));
      expect(receivedKey, equals('b'));
    },
  );
}

