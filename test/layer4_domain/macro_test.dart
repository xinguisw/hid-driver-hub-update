import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const macro = MacroDefinition(
    slot: 1,
    name: 'M1',
    mode: MacroMode.loop,
    loopTimes: 3,
    actions: [
      MacroAction(keyCode: 0x04, isBreak: false, delay: 0, label: 'A'),
      MacroAction(keyCode: 0x04, isBreak: true, delay: 12, label: 'A'),
    ],
  );

  test('validates protocol limits and preserves semantic JSON', () {
    expect(validateMacro(macro), isEmpty);
    expect(MacroDefinition.fromJson(macro.toJson()).toJson(), macro.toJson());
  });

  test('stop-on-any-key mode matches protocol 0x01 and SDRD label', () {
    expect(MacroMode.stopOnAnyKey.wireValue, 0x01);
    expect(MacroMode.stopOnAnyKey.label, 'Stop on any key or mouse click');
    expect(MacroMode.fromWire(0x01), MacroMode.stopOnAnyKey);
  });

  test('accepts semantic protocol mouse wheel actions', () {
    final wheelMacro = macro.copyWith(
      actions: const [
        MacroAction.wheelUp(isBreak: false, delay: 1, label: 'Wheel up'),
        MacroAction.wheelUp(isBreak: true, delay: 0, label: 'Wheel up'),
        MacroAction.wheelDown(isBreak: false, delay: 1, label: 'Wheel down'),
        MacroAction.wheelDown(isBreak: true, delay: 0, label: 'Wheel down'),
      ],
    );

    expect(validateMacro(wheelMacro), isEmpty);
  });

  test('rejects obsolete F6/F7 wheel codes', () {
    final legacyWheel = macro.copyWith(
      actions: const [
        MacroAction(keyCode: 0xF6, isBreak: false, delay: 0, label: 'Wheel up'),
      ],
    );

    expect(validateMacro(legacyWheel), isNotEmpty);
  });

  test('rejects more than 30 actions and invalid slots', () {
    final invalid = macro.copyWith(
      slot: 17,
      actions: [
        for (var i = 0; i < 31; i++)
          const MacroAction(keyCode: 0x04, isBreak: false, delay: 0),
      ],
    );
    expect(validateMacro(invalid), hasLength(2));
  });

  test(
    'in-memory repository replaces a slot without losing other records',
    () async {
      final repo = InMemoryMacroRepository();
      await repo.save('03aa', [macro]);
      expect((await repo.load('03aa')).single.slot, 1);
      await repo.save('03aa', [macro.copyWith(slot: 2)]);
      expect((await repo.load('03aa')).single.slot, 2);
    },
  );
}
