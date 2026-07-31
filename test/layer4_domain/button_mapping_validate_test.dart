import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/button_mapping_validate.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeviceSettingsState synced({
    List<ButtonData>? buttons,
  }) =>
      DeviceSettingsState(
        devId: 'aa4ecd01',
        displayName: 'M7XSE',
        connectionMode: 0,
        buttonCount: 6,
        buttons: buttons ??
            [
              for (var id = 1; id <= 6; id++)
                ButtonData(
                  id: id,
                  labelKey: 'button.$id',
                  remappable: true,
                  action: 0x14,
                  param1: 1,
                ),
            ],
      );

  group('validateButtonMappingStaging', () {
    test('reset staging passes', () {
      final s = synced();
      final staging = stageButtonMappingDefaults(s.buttons);
      expect(
        validateButtonMappingStaging(staging: staging, synced: s),
        isNull,
      );
    });

    test('wrong length fails', () {
      final s = synced();
      expect(
        validateButtonMappingStaging(
          staging: const [ButtonMappingSlot(action: 0x02)],
          synced: s,
        ),
        contains('expected 6'),
      );
    });

    test('out of byte range fails', () {
      final s = synced();
      final staging = stageButtonMappingDefaults(s.buttons);
      final bad = [
        for (var i = 0; i < staging.length; i++)
          i == 0
              ? const ButtonMappingSlot(action: 0x100)
              : staging[i],
      ];
      expect(
        validateButtonMappingStaging(staging: bad, synced: s),
        contains('0..255'),
      );
    });

    test('tampered remappable slot fails policy', () {
      final s = synced();
      final staging = stageButtonMappingDefaults(s.buttons);
      final bad = [
        const ButtonMappingSlot(action: 0x14, param1: 1),
        ...staging.skip(1),
      ];
      expect(
        validateButtonMappingStaging(staging: bad, synced: s),
        contains('reset policy'),
      );
    });

    test('non-remappable must echo live wire', () {
      final s = synced(
        buttons: [
          const ButtonData(
            id: 1,
            labelKey: 'b1',
            remappable: true,
            action: 0x02,
          ),
          const ButtonData(
            id: 2,
            labelKey: 'b2',
            remappable: false,
            action: 0x03,
            param1: 0,
          ),
          for (var id = 3; id <= 6; id++)
            ButtonData(
              id: id,
              labelKey: 'b$id',
              remappable: true,
              action: 0x02,
            ),
        ],
      );
      final ok = stageButtonMappingDefaults(s.buttons);
      expect(validateButtonMappingStaging(staging: ok, synced: s), isNull);

      final tampered = [
        ok[0],
        const ButtonMappingSlot(action: 0x0E), // forced dpi on non-remappable
        ...ok.skip(2),
      ];
      expect(
        validateButtonMappingStaging(staging: tampered, synced: s),
        contains('B2'),
      );
    });
  });
}
