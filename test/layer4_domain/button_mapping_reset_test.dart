import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stageButtonMappingDefaults', () {
    test('empty live → six identity slots', () {
      final staged = stageButtonMappingDefaults(null);
      expect(staged.length, 6);
      expect(staged.map((e) => e.action).toList(),
          [0x02, 0x03, 0x04, 0x05, 0x06, 0x0E]);
      for (final e in staged) {
        expect(e.param1, 0);
        expect(e.param2, 0);
        expect(e.param3, 0);
      }
    });

    test('remappable true → identity even if live remapped', () {
      final live = [
        const ButtonData(
          id: 1,
          labelKey: 'button.left_click',
          remappable: true,
          action: 0x14,
          param1: 1,
          param2: 0,
          param3: 0,
        ),
      ];
      final staged = stageButtonMappingDefaults(live);
      expect(staged[0].action, 0x02);
      expect(staged[0].param1, 0);
    });

    test('remappable false → echo live wire', () {
      final live = [
        const ButtonData(
          id: 6,
          labelKey: 'button.dpi_cycle',
          remappable: false,
          action: 0x0E,
          param1: 0,
          param2: 0,
          param3: 0,
        ),
        const ButtonData(
          id: 1,
          labelKey: 'button.left_click',
          remappable: true,
          action: 0x03,
          param1: 0,
          param2: 0,
          param3: 0,
        ),
      ];
      final staged = stageButtonMappingDefaults(live);
      expect(staged[0].action, 0x02);
      expect(staged[5].action, 0x0E);
    });

    test('non-remappable without wire → disable slot', () {
      final live = [
        const ButtonData(
          id: 2,
          labelKey: 'button.right_click',
          remappable: false,
        ),
      ];
      final staged = stageButtonMappingDefaults(live);
      expect(staged[1].action, 0x00);
    });
  });
}
