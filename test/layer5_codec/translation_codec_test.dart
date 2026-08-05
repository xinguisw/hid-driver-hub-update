import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer5_codec/codecs/keyvalue_table.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const t = TranslationCodec();
  const keys = KeyvalueTable();

  group('TranslationCodec.reportRateWireToHz', () {
    test('maps polling intervals to Hz', () {
      expect(t.reportRateWireToHz(1), 1000);
      expect(t.reportRateWireToHz(2), 500);
      expect(t.reportRateWireToHz(4), 250);
      expect(t.reportRateWireToHz(8), 125);
    });

    test('unknown wire returns null', () {
      expect(t.reportRateWireToHz(0), isNull);
      expect(t.reportRateWireToHz(3), isNull);
      expect(t.reportRateWireToHz(500), isNull);
    });
  });

  group('TranslationCodec.reportRateWireToLabel', () {
    test('complete labels with unit', () {
      expect(t.reportRateWireToLabel(1), '1000 Hz');
      expect(t.reportRateWireToLabel(2), '500 Hz');
      expect(t.reportRateWireToLabel(4), '250 Hz');
      expect(t.reportRateWireToLabel(8), '125 Hz');
      expect(t.reportRateWireToLabel(0), isNull);
    });
  });

  group('TranslationCodec.dpiActiveMaskToCount', () {
    test('0x1F is five active stages', () {
      expect(t.dpiActiveMaskToCount(0x1F), 5);
      expect(t.dpiActiveMaskToCount(31), 5);
    });

    test('other masks', () {
      expect(t.dpiActiveMaskToCount(0x00), 0);
      expect(t.dpiActiveMaskToCount(0x0F), 4);
      expect(t.dpiActiveMaskToCount(0x15), 3);
      expect(t.dpiActiveMaskToCount(0x01), 1);
    });

    test('dpiStageIndexActive for 0x1F is indices 0..4', () {
      for (var i = 0; i < 5; i++) {
        expect(t.dpiStageIndexActive(0x1F, i), isTrue);
      }
      expect(t.dpiStageIndexActive(0x1F, 5), isFalse);
      expect(t.dpiStageIndexActive(0x1F, 7), isFalse);
    });
  });

  group('TranslationCodec.dpiCurrentLevelWireToDisplay', () {
    test('0-based wire to 1-based display', () {
      expect(t.dpiCurrentLevelWireToDisplay(0), 1);
      expect(t.dpiCurrentLevelWireToDisplay(1), 2);
      expect(t.dpiCurrentLevelWireToDisplay(4), 5);
    });
  });

  group('TranslationCodec DPI table wire', () {
    test('hex 0x0320 → decimal 800 (identity big-endian)', () {
      expect(t.dpiAxisBytesToWire([0x03, 0x20], endian: 'big'), 0x0320);
      expect(
        t.dpiWireUnitToDisplay(0x0320, transform: 'identity', factor: 1),
        800,
      );
      final stage = t.decodeDpiStageWire(
        b0: 0x03,
        b1: 0x20,
        bytesPerAxis: 2,
        endian: 'big',
        independentXY: false,
        transform: 'identity',
        factor: 1,
      );
      expect(stage.value, 800);
      expect(stage.y, isNull);
    });

    test('interleaved stages 03 20 06 40 → UI 800, 1600', () {
      // Protocol stores C4 as sequential pairs; each pair is one stage.
      final stages = <(int, int)>[
        (0x03, 0x20),
        (0x06, 0x40),
        (0x09, 0x60),
        (0x0c, 0x80),
        (0x13, 0x88),
      ];
      final values = [
        for (final s in stages)
          t
              .decodeDpiStageWire(
                b0: s.$1,
                b1: s.$2,
                bytesPerAxis: 2,
                endian: 'big',
                independentXY: false,
                transform: 'identity',
                factor: 1,
              )
              .value,
      ];
      expect(values[0], 800);
      expect(values[1], 1600);
      expect(values[2], 2400);
      expect(values[3], 3200);
      expect(values[4], 5000);
    });

    test('unknown transform throws', () {
      expect(
        () => t.dpiWireUnitToDisplay(1, transform: 'mystery', factor: 1),
        throwsArgumentError,
      );
    });

    test('PAW3311 SDK cpiMap 0x13→840; Y ignored', () {
      const map = {
        0x13: 840,
        0x26: 1200,
        0x39: 1620,
        0x55: 3180,
      };
      expect(
        t.dpiWireUnitToDisplay(0x13, transform: 'paw3311', factor: 50, cpiMap: map),
        840,
      );
      final stage = t.decodeDpiStageWire(
        b0: 0x13,
        b1: 0x00,
        bytesPerAxis: 1,
        endian: 'big',
        independentXY: false,
        transform: 'paw3311',
        factor: 50,
        cpiMap: map,
      );
      expect(stage.value, 840);
      expect(stage.y, isNull);
      // Unmapped code uses (wire+1)*factor
      expect(
        t.dpiWireUnitToDisplay(0x0F, transform: 'paw3311', factor: 50, cpiMap: map),
        800,
      );
    });

    test('PAW-style divide wire*factor', () {
      expect(
        t.dpiWireUnitToDisplay(16, transform: 'divide', factor: 50),
        800,
      );
      final stage = t.decodeDpiStageWire(
        b0: 16,
        b1: 32,
        bytesPerAxis: 1,
        endian: 'big',
        independentXY: true,
        transform: 'divide',
        factor: 50,
      );
      expect(stage.value, 800);
      expect(stage.y, 1600);
    });
  });

  group('TranslationCodec.buttonIdToLabel', () {
    test('slot names for ids 1–6', () {
      expect(t.buttonIdToLabel(1), 'Left');
      expect(t.buttonIdToLabel(2), 'Right');
      expect(t.buttonIdToLabel(3), 'Middle');
      expect(t.buttonIdToLabel(4), 'Forward');
      expect(t.buttonIdToLabel(5), 'Backward');
      expect(t.buttonIdToLabel(6), 'DPI cycle');
    });
  });

  group('TranslationCodec.buttonActionToLabel', () {
    test('standard mouse actions', () {
      expect(t.buttonActionToLabel(action: 0x00), 'Disable / No action');
      expect(t.buttonActionToLabel(action: 0x02), 'Left click');
      expect(t.buttonActionToLabel(action: 0x03), 'Right click');
      expect(t.buttonActionToLabel(action: 0x04), 'Middle click');
      expect(t.buttonActionToLabel(action: 0x05), 'Forward');
      expect(t.buttonActionToLabel(action: 0x06), 'Backward');
      expect(t.buttonActionToLabel(action: 0x09), 'Swing left');
      expect(t.buttonActionToLabel(action: 0x0A), 'Swing right');
      expect(t.buttonActionToLabel(action: 0x0B), 'DPI increase');
      expect(t.buttonActionToLabel(action: 0x0D), 'DPI decrease');
      expect(t.buttonActionToLabel(action: 0x0E), 'DPI cycle');
    });

    test('shortcut names the key, never raw bytes', () {
      expect(
        t.buttonActionToLabel(action: 0x12, param1: 0xB3, param2: 0x00),
        'Volume up',
      );
      expect(
        t.buttonActionToLabel(action: 0x12, param1: 0x01, param2: 0x06),
        'Win lock + C',
      );
    });

    test('modifiers prefix the key whatever slot they occupy', () {
      expect(
        t.buttonActionToLabel(action: 0x12, param1: 0xE0, param2: 0x06),
        'Ctrl + C',
      );
      expect(
        t.buttonActionToLabel(
          action: 0x12,
          param1: 0xE0,
          param2: 0xE2,
          param3: 0x06,
        ),
        'Ctrl + Alt + C',
      );
      expect(
        t.buttonActionToLabel(action: 0x12, param1: 0x00, param3: 0x06),
        'C',
      );
    });

    test('consumer action shares the same key table', () {
      expect(
        t.buttonActionToLabel(action: 0x13, param1: 0xB1),
        'Play / pause',
      );
      expect(
        t.buttonActionToLabel(action: 0x13, param1: 0xAC),
        'Calculator',
      );
    });

    test('empty slots and unmapped bytes', () {
      expect(t.buttonActionToLabel(action: 0x12), 'Not assigned');
      expect(t.buttonActionToLabel(action: 0x12, param1: 0x02), 'Key 0x02');
    });
    test('macro and unknown', () {
      expect(
        t.buttonActionToLabel(action: 0x14, param1: 3),
        'Macro play (#3)',
      );
      expect(
        t.buttonActionToLabel(action: 0x99, param1: 1, param2: 2, param3: 3),
        'Unknown action 0x99 (p=1,2,3)',
      );
    });
  });

  group('TranslationCodec.keyValueToLabel', () {
    test('covers every keyvalue group', () {
      expect(t.keyValueToLabel(0x04), 'A');
      expect(t.keyValueToLabel(0x1E), '1');
      expect(t.keyValueToLabel(0x28), 'Enter');
      expect(t.keyValueToLabel(0x31), r'\');
      expect(t.keyValueToLabel(0x45), 'F12');
      expect(t.keyValueToLabel(0x73), 'F24');
      expect(t.keyValueToLabel(0x52), 'Up');
      expect(t.keyValueToLabel(0x62), 'Numpad 0');
      expect(t.keyValueToLabel(0xA1), 'System power');
      expect(t.keyValueToLabel(0xBE), 'Terminal lock');
      expect(t.keyValueToLabel(0xC6), 'Wheel up');
      expect(t.keyValueToLabel(0xCF), 'Copy');
      expect(t.keyValueToLabel(0xE7), 'Right Win');
      expect(t.keyValueToLabel(0xF0), 'Gamepad A');
      expect(t.keyValueToLabel(0xFF), 'Fn');
    });
  });

  group('KeyvalueTable', () {
    test('is the source of labels TranslationCodec consumes', () {
      expect(keys.keyValueToLabel(0xB3), 'Volume up');
      expect(keys.keyComboToLabel(0xE0, 0x06, 0), 'Ctrl + C');
      expect(KeyvalueTable.labels[0xB3], 'Volume up');
    });
  });

  group('TranslationCodec.triStateWireToLabel', () {
    test('FF On, 0F Off, 00 ignore', () {
      expect(t.triStateWireToLabel(0xFF), 'On');
      expect(t.triStateWireToLabel(0x0F), 'Off');
      expect(t.triStateWireToLabel(0x00), isNull);
      expect(t.triStateWireToLabel(0x01), isNull);
    });
  });

  group('TranslationCodec.triStateWireToBool', () {
    test('FF on, 0F off, 00 ignore', () {
      expect(t.triStateWireToBool(0xFF), isTrue);
      expect(t.triStateWireToBool(0x0F), isFalse);
      expect(t.triStateWireToBool(0x00), isNull);
      expect(t.triStateWireToBool(0x01), isNull);
    });
  });

  group('TranslationCodec.triStateBoolToWire', () {
    test('true FF, false 0F, and round-trips through triStateWireToBool', () {
      expect(t.triStateBoolToWire(true), 0xFF);
      expect(t.triStateBoolToWire(false), 0x0F);
      // why: a raw 1/0 write would decode to null, not on/off.
      expect(t.triStateWireToBool(t.triStateBoolToWire(true)), isTrue);
      expect(t.triStateWireToBool(t.triStateBoolToWire(false)), isFalse);
    });
  });

  group('TranslationCodec.debounceIndexToLabel', () {
    test('maps debounce table with unit', () {
      expect(t.debounceIndexToLabel(0x00), '2ms');
      expect(t.debounceIndexToLabel(0x01), '2ms');
      expect(t.debounceIndexToLabel(0x02), '4ms');
      expect(t.debounceIndexToLabel(0x06), '12ms');
      expect(t.debounceIndexToLabel(0x07), isNull);
    });
  });

  group('TranslationCodec.sleepIndexToLabel', () {
    test('maps sleep and RGB sleep table', () {
      expect(t.sleepIndexToLabel(0x00), '30 sec');
      expect(t.sleepIndexToLabel(0x01), '1 min');
      expect(t.sleepIndexToLabel(0x03), '5 min');
      expect(t.sleepIndexToLabel(0x06), '30 min');
      expect(t.sleepIndexToLabel(0x10), isNull);
    });
  });

  group('TranslationCodec.angleTuneWireToLabel', () {
    test('PAW3395 angle tune labels from catalog options', () {
      const options = [
        AngleTuneOption(wire: 0, label: '-30°'),
        AngleTuneOption(wire: 1, label: '-10°'),
        AngleTuneOption(wire: 2, label: '0°'),
        AngleTuneOption(wire: 3, label: '10°'),
        AngleTuneOption(wire: 4, label: '30°'),
      ];
      expect(t.angleTuneWireToLabel(0x00, options), '-30°');
      expect(t.angleTuneWireToLabel(0x02, options), '0°');
      expect(t.angleTuneWireToLabel(0x04, options), '30°');
      expect(t.angleTuneWireToLabel(0x05, options), isNull);
    });
  });

  group('TranslationCodec.lodWireToLabel', () {
    test('catalog-driven lift-off distance labels', () {
      const options = [
        LodOption(wire: 0, mm: 0.7),
        LodOption(wire: 1, mm: 1.0),
        LodOption(wire: 2, mm: 2.0),
      ];
      expect(t.lodWireToLabel(0, options), '0.7mm');
      expect(t.lodWireToLabel(1, options), '1mm');
      expect(t.lodWireToLabel(2, options), '2mm');
      expect(t.lodWireToLabel(3, options), isNull);
    });
  });

  group('TranslationCodec.rgbModeToLabel', () {
    test('named modes and unknown', () {
      expect(t.rgbModeToLabel(0x00), 'Close');
      expect(t.rgbModeToLabel(0x01), 'Constant');
      expect(t.rgbModeToLabel(0x02), 'Single breathing');
      expect(t.rgbModeToLabel(0x03), 'Sunning color');
      expect(t.rgbModeToLabel(0x04), '7 Cycle color');
      expect(t.rgbModeToLabel(0x09), 'Unknown RGB mode 0x9');
    });
  });

  group('TranslationCodec brightness and speed levels', () {
    test('five-step percent labels', () {
      expect(t.brightnessLevelToLabel(0), '0%');
      expect(t.brightnessLevelToLabel(2), '50%');
      expect(t.brightnessLevelToLabel(4), '100%');
      expect(t.brightnessLevelToLabel(5), isNull);
      expect(t.speedLevelToLabel(0), '10%');
      expect(t.speedLevelToLabel(4), '100%');
      expect(t.speedLevelToLabel(9), isNull);
    });
  });

  group('TranslationCodec.nakReasonToLabel', () {
    test('sheet reasons and fallback', () {
      expect(t.nakReasonToLabel(0x01), 'Handshake required before GET/SET');
      expect(t.nakReasonToLabel(0x02), 'Unknown config address');
      expect(t.nakReasonToLabel(0x03), 'Opcode is not GET or SET');
      expect(t.nakReasonToLabel(0x04), 'Payload length mismatch');
      expect(t.nakReasonToLabel(0x05), 'Array index out of bounds');
      expect(t.nakReasonToLabel(0x06), 'CRC16 mismatch on SET');
      expect(
        t.nakReasonToLabel(0xFF),
        'Config address not implemented on device',
      );
      expect(t.nakReasonToLabel(0xAB), 'NAK reason 0xab');
    });
  });
}
