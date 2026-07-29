import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';

/// L4: stage caps-aware identity defaults for button-map reset (no HID).
///
/// Chart sandbox step only. Commit is [DeviceScope.resetButtonMappingToDefault]
/// auto-Save → L1/L5. Codes match [TranslationCodec.buttonActionToLabel] /
/// factory identity (not catalog invent).
List<ButtonMappingEntry> stageButtonMappingDefaults(
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

ButtonMappingEntry _slotEntry({
  required int id,
  required ButtonData? live,
}) {
  // Remappable (or unknown present): identity default for that physical id.
  if (live == null || live.remappable) {
    return identityButtonMappingDefault(id);
  }
  // Non-remappable: echo last synced wire; never force identity (e.g. no DPI).
  if (live.action != null) {
    return ButtonMappingEntry(
      action: live.action!,
      param1: live.param1 ?? 0,
      param2: live.param2 ?? 0,
      param3: live.param3 ?? 0,
    );
  }
  // Caps row without live GET yet — leave disabled rather than invent.
  return const ButtonMappingEntry(
    action: 0,
    param1: 0,
    param2: 0,
    param3: 0,
  );
}

/// Physical button id (1..6) → factory identity action (params 0).
///
/// 1 Left 0x02, 2 Right 0x03, 3 Middle 0x04, 4 Forward 0x05,
/// 5 Backward 0x06, 6 DPI cycle 0x0E — same enum as L5 labels.
ButtonMappingEntry identityButtonMappingDefault(int buttonId) {
  final action = switch (buttonId) {
    1 => 0x02,
    2 => 0x03,
    3 => 0x04,
    4 => 0x05,
    5 => 0x06,
    6 => 0x0E,
    _ => 0x00,
  };
  return ButtonMappingEntry(
    action: action,
    param1: 0,
    param2: 0,
    param3: 0,
  );
}
