import 'package:driver_hub/layer3_ui/widgets/hub_button_mapping_panel.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:flutter/material.dart';
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
}
