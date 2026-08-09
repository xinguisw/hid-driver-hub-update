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
