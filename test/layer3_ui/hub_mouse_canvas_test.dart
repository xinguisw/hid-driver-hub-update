import 'package:driver_hub/layer3_ui/widgets/hub_mouse_canvas.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mouseButtonCalloutLabel', () {
    test('keeps the physical label when the live action differs', () {
      const button = ButtonData(
        id: 4,
        labelKey: 'button.forward',
        remappable: true,
        buttonLabel: 'Forward',
        actionLabel: 'Backward',
      );

      expect(mouseButtonCalloutLabel(button), 'Forward');
    });

    test('falls back to the live action when no physical label exists', () {
      const button = ButtonData(
        id: 5,
        labelKey: 'button.back',
        remappable: true,
        actionLabel: 'Backward',
      );

      expect(mouseButtonCalloutLabel(button), 'Backward');
    });

    test('falls back to the button id when no labels exist', () {
      const button = ButtonData(
        id: 6,
        labelKey: 'button.dpi_cycle',
        remappable: true,
      );

      expect(mouseButtonCalloutLabel(button), 'B6');
    });
  });
}
