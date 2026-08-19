import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String mouseButtonCalloutLabel(ButtonData button) {
    return button.actionLabel ?? button.buttonLabel ?? '';
  }

  group('mouseButtonCalloutLabel', () {
    test('shows the live assigned action when remapped', () {
      const button = ButtonData(
        id: 3,
        labelKey: 'button.middle',
        remappable: true,
        buttonLabel: 'Middle',
        actionLabel: 'DPI cycle',
      );

      expect(mouseButtonCalloutLabel(button), 'DPI cycle');
    });

    test('falls back to the physical label when no action label exists', () {
      const button = ButtonData(
        id: 4,
        labelKey: 'button.forward',
        remappable: true,
        buttonLabel: 'Forward',
      );

      expect(mouseButtonCalloutLabel(button), 'Forward');
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

  String mouseButtonCalloutText(ButtonData button) {
    return button.actionLabel ?? button.buttonLabel ?? '';
  }

  group('mouseButtonCalloutText', () {
    test('shows only the current assignment', () {
      const button = ButtonData(
        id: 4,
        labelKey: 'button.forward',
        remappable: true,
        buttonLabel: 'Forward',
        actionLabel: 'DPI cycle',
      );

      expect(mouseButtonCalloutText(button), 'DPI cycle');
    });

    test('shows a same-name assignment only once', () {
      const button = ButtonData(
        id: 3,
        labelKey: 'button.middle_click',
        remappable: true,
        buttonLabel: 'Middle Button',
        actionLabel: 'Middle Button',
      );

      expect(mouseButtonCalloutText(button), 'Middle Button');
    });

    test('falls back to the physical label when no action exists', () {
      const button = ButtonData(
        id: 6,
        labelKey: 'button.dpi_cycle',
        remappable: true,
        buttonLabel: 'DPI cycle',
      );

      expect(mouseButtonCalloutText(button), 'DPI cycle');
    });
  });
}
