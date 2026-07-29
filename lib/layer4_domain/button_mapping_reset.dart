import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';

/// L4: stage caps-aware identity defaults for button-map reset (no HID).
///
/// SDRD FR-OPS-001: sandbox only. Commit is [DeviceSettingsSaveRequested].
/// Action codes match factory identity / L5 label enum (not catalog invent).
List<ButtonMappingSlot> stageButtonMappingDefaults(
  List<ButtonData>? buttons, {
  int slotCount = 6,
}) {
  final byId = <int, ButtonData>{
    if (buttons != null)
      for (final b in buttons) b.id: b,
  };
  return [
    for (var i = 0; i < slotCount; i++)
      _slotEntry(id: i + 1, live: byId[i + 1]),
  ];
}

ButtonMappingSlot _slotEntry({
  required int id,
  required ButtonData? live,
}) {
  if (live == null || live.remappable) {
    return identityButtonMappingDefault(id);
  }
  if (live.action != null) {
    return ButtonMappingSlot(
      action: live.action!,
      param1: live.param1 ?? 0,
      param2: live.param2 ?? 0,
      param3: live.param3 ?? 0,
    );
  }
  return const ButtonMappingSlot(action: 0);
}

/// Physical button id (1..6) → factory identity action (params 0).
///
/// 1 Left 0x02 … 6 DPI cycle 0x0E — same enum as L5 display maps.
ButtonMappingSlot identityButtonMappingDefault(int buttonId) {
  final action = switch (buttonId) {
    1 => 0x02,
    2 => 0x03,
    3 => 0x04,
    4 => 0x05,
    5 => 0x06,
    6 => 0x0E,
    _ => 0x00,
  };
  return ButtonMappingSlot(action: action);
}
