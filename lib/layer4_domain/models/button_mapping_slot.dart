/// L4 domain staging slot for one button map entry (not a wire frame).
///
/// L5 [ButtonMappingEntry] is built only at commit boundary in [DeviceScope].
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
