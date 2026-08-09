import 'package:driver_hub/layer4_domain/models/macro.dart';

/// Builds the temporary M5 probe used to identify macro timing semantics.
///
/// The raw timing-special codes are intentionally represented as domain
/// actions here. L5 remains responsible for packing them into the wire bytes.
MacroDefinition buildMacroTimingProbe({int slot = 5}) {
  final actions = <MacroAction>[
    ..._tap(0x04, 'A', breakDelay: 1),
    ..._tap(0x05, 'B'),
    ..._tap(0x06, 'C', breakDelay: 10),
    ..._tap(0x07, 'D'),
    ..._tap(0x08, 'E', breakDelay: 127),
    ..._tap(0x09, 'F'),
    ..._tap(0x0A, 'G'),
    _timing(0x01, 1),
    ..._tap(0x0B, 'H'),
    ..._tap(0x0C, 'I'),
    _timing(0x02, 1),
    ..._tap(0x0D, 'J'),
    ..._tap(0x0E, 'K'),
    _timing(0x03, 1),
    ..._tap(0x0F, 'L'),
  ];

  return MacroDefinition(
    slot: slot,
    name: 'M$slot',
    mode: MacroMode.loop,
    loopTimes: 1,
    actions: List.unmodifiable(actions),
  );
}

/// Builds one isolated probe for a single timing-special key code.
///
/// The surrounding key pairs make the measured gap observable while keeping
/// all three candidates out of the same macro execution.
MacroDefinition buildIsolatedMacroTimingProbe({
  required int slot,
  required int timingCode,
}) {
  final pair = switch (timingCode) {
    0x01 => (0x04, 'A', 0x05, 'B'),
    0x02 => (0x06, 'C', 0x07, 'D'),
    0x03 => (0x08, 'E', 0x09, 'F'),
    _ => throw ArgumentError.value(timingCode, 'timingCode'),
  };
  return MacroDefinition(
    slot: slot,
    name: 'M$slot',
    mode: MacroMode.loop,
    loopTimes: 1,
    actions: List.unmodifiable([
      ..._tap(pair.$1, pair.$2),
      _timing(timingCode, 1),
      ..._tap(pair.$3, pair.$4),
    ]),
  );
}

List<MacroAction> _tap(int keyCode, String label, {int breakDelay = 0}) => [
  MacroAction(keyCode: keyCode, isBreak: false, delay: 0, label: label),
  MacroAction(keyCode: keyCode, isBreak: true, delay: breakDelay, label: label),
];

MacroAction _timing(int keyCode, int multiplier) => MacroAction(
  keyCode: keyCode,
  isBreak: false,
  delay: multiplier,
  label: 'Timing 0x${keyCode.toRadixString(16).padLeft(2, '0')} x $multiplier',
);
