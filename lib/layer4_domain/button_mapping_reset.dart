import 'package:driver_hub/layer4_domain/button_mapping_validate.dart';
import 'package:driver_hub/layer5_codec/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';

/// Identity defaults for button-map reset (sandbox; no HID).
List<ButtonMappingSlot> stageButtonMappingDefaults(
  List<ButtonData>? buttons, {
  int slotCount = kButtonMappingSlotCount,
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

/// Build staging from live device values (not factory defaults).
///
/// Used when user first selects an action — preserves current device state.
List<ButtonMappingSlot> stageButtonMappingFromLive(
  List<ButtonData>? buttons, {
  int slotCount = kButtonMappingSlotCount,
}) {
  return [
    for (var i = 0; i < slotCount; i++)
      _liveSlotEntry(id: i + 1, buttons: buttons),
  ];
}

ButtonMappingSlot _liveSlotEntry({
  required int id,
  required List<ButtonData>? buttons,
}) {
  final live = buttons?.firstWhere(
    (b) => b.id == id,
    orElse: () => ButtonData(id: id, labelKey: 'button.$id', remappable: true),
  );
  if (live == null) return const ButtonMappingSlot(action: 0);
  return ButtonMappingSlot(
    action: live.action ?? 0,
    param1: live.param1 ?? 0,
    param2: live.param2 ?? 0,
    param3: live.param3 ?? 0,
  );
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

/// 1→0x02, 2→0x03, 3→0x04, 4→0x05 (ACT_MOUSE_FORWARD), 5→0x06 (ACT_MOUSE_BACKWARD), 6→0x0E (factory identity; params 0).
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
