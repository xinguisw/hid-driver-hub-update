/// Wire-shaped value for one button map entry: action + three keyvalue params.
///
/// Lives in L5 (Codec) — these four fields are the protocol frame's button
/// mapping payload. Upper layers (L4 staging, L2 wire-map) import it downward;
/// L4 keeps no separate staging copy, so staging and wire stay one type.
class ButtonMappingSlot {
  final int action;
  final int param1;
  final int param2;
  final int param3;

  const ButtonMappingSlot({
    required this.action,
    this.param1 = 0,
    this.param2 = 0,
    this.param3 = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ButtonMappingSlot &&
          action == other.action &&
          param1 == other.param1 &&
          param2 == other.param2 &&
          param3 == other.param3;

  @override
  int get hashCode => Object.hash(action, param1, param2, param3);
}
