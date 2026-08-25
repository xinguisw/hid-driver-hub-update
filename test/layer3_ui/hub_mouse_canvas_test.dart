import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/i18n/catalog_localization.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String mouseButtonCalloutLabel(ButtonData button) {
    return button.actionLabel ?? button.buttonLabel ?? 'B${button.id}';
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

    test('CatalogLocalization translates combo key callouts', () async {
      const button = ButtonData(
        id: 2,
        labelKey: 'button.right',
        remappable: true,
        action: 0x12,
        param1: 0xE3, // Left Win
        param2: 0x19, // V
        actionLabel: 'Left Win + V',
      );

      final en = await AppLocale.en.build();
      final zh = await AppLocale.zh.build();
      expect(CatalogLocalization.localizeButtonCallout(button, en), 'Left Win + V');
      expect(CatalogLocalization.localizeButtonCallout(button, zh), '左 Win + V');
    });

    test('CatalogLocalization translates Consumer Web Home and Web Back callouts', () async {
      const buttonHome = ButtonData(
        id: 5,
        labelKey: 'button.5',
        remappable: true,
        action: 0x13,
        param1: 0xA4, // Web Home
      );

      const buttonBack = ButtonData(
        id: 5,
        labelKey: 'button.5',
        remappable: true,
        action: 0x13,
        param1: 0xA5, // Web Back
      );

      const buttonBackward = ButtonData(
        id: 5,
        labelKey: 'button.backward',
        remappable: true,
        action: 0x06, // Backward Button
      );

      final en = await AppLocale.en.build();
      final zh = await AppLocale.zh.build();

      expect(CatalogLocalization.localizeButtonCallout(buttonHome, en), 'Web Home');
      expect(CatalogLocalization.localizeButtonCallout(buttonHome, zh), '主页');

      expect(CatalogLocalization.localizeButtonCallout(buttonBack, en), 'Web Back');
      expect(CatalogLocalization.localizeButtonCallout(buttonBack, zh), '网页后退');

      expect(CatalogLocalization.localizeButtonCallout(buttonBackward, en), 'Backward Button');
      expect(CatalogLocalization.localizeButtonCallout(buttonBackward, zh), '后退');
    });
  });
}
