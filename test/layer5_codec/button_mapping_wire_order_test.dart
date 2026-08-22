import 'package:driver_hub/layer5_codec/button_mapping_wire_order.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ui = [
    for (var i = 0; i < 6; i++)
      ButtonMappingEntry(
        action: i + 1,
        param1: 0x10 + i,
        param2: 0x20 + i,
        param3: 0x30 + i,
      ),
  ];

  test('maps the shared direct button wire order', () {
    final wire = buttonMappingUiToWire(ui);

    expect(wire[0], same(ui[0]));
    expect(wire[1], same(ui[1]));
    expect(wire[2], same(ui[2]));
    expect(wire[3], same(ui[3]));
    expect(wire[4], same(ui[4]));
    expect(wire[5], same(ui[5]));
  });

  test('wire-to-UI translation round-trips every action parameter', () {
    final wire = buttonMappingUiToWire(ui);
    final restored = buttonMappingWireToUi(wire);

    expect(restored, hasLength(ui.length));
    for (var i = 0; i < ui.length; i++) {
      expect(restored[i].action, ui[i].action);
      expect(restored[i].param1, ui[i].param1);
      expect(restored[i].param2, ui[i].param2);
      expect(restored[i].param3, ui[i].param3);
    }
  });

  test('factory UI identity builds the observed device payload', () {
    final frame = MouseProtocol.buildButtonMappingSetFrame([
      const ButtonMappingEntry(action: 0x02, param1: 0, param2: 0, param3: 0),
      const ButtonMappingEntry(action: 0x03, param1: 0, param2: 0, param3: 0),
      const ButtonMappingEntry(action: 0x04, param1: 0, param2: 0, param3: 0),
      const ButtonMappingEntry(action: 0x05, param1: 0, param2: 0, param3: 0),
      const ButtonMappingEntry(action: 0x06, param1: 0, param2: 0, param3: 0),
      const ButtonMappingEntry(action: 0x0E, param1: 0, param2: 0, param3: 0),
    ]);

    expect(frame.sublist(5, 29), [
      0x02,
      0x00,
      0x00,
      0x00,
      0x03,
      0x00,
      0x00,
      0x00,
      0x04,
      0x00,
      0x00,
      0x00,
      0x05,
      0x00,
      0x00,
      0x00,
      0x06,
      0x00,
      0x00,
      0x00,
      0x0E,
      0x00,
      0x00,
      0x00,
    ]);
  });
}
