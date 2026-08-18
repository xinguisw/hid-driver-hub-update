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

  test('deleting a macro updates persistence and frees the slot', () async {
    final repo = InMemoryMacroRepository();
    final m1 = macro.copyWith(slot: 1, name: 'M1');
    final m2 = macro.copyWith(slot: 2, name: 'M2');
    final m3 = macro.copyWith(slot: 3, name: 'M3');

    await repo.save('01aa', [m1, m2, m3]);
    var stored = await repo.load('01aa');
    expect(stored.map((m) => m.slot), [1, 2, 3]);

    // Delete slot 2
    final updated = stored.where((m) => m.slot != 2).toList();
    await repo.save('01aa', updated);

    stored = await repo.load('01aa');
    expect(stored.map((m) => m.slot), [1, 3]);

    // Verify first unused slot is now slot 2
    final usedSlots = stored.map((m) => m.slot).toSet();
    int? nextSlot;
    for (var slot = 1; slot <= 16; slot++) {
      if (!usedSlots.contains(slot)) {
        nextSlot = slot;
        break;
      }
    }
    expect(nextSlot, 2);
  });

  test(
    'custom macro name is preserved in JSON serialization and storage',
    () async {
      final custom = macro.copyWith(slot: 1, name: 'Sniper Combo');
      final json = custom.toJson();
      expect(json['name'], 'Sniper Combo');

      final restored = MacroDefinition.fromJson(json);
      expect(restored.name, 'Sniper Combo');

      final repo = InMemoryMacroRepository();
      await repo.save('01aa', [custom]);
      final loaded = await repo.load('01aa');
      expect(loaded.single.name, 'Sniper Combo');
    },
  );
}
