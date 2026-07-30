import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';

/// B2 protocol slot count (6 × 4 data bytes).
const int kButtonMappingSlotCount = 6;

/// Wire field range for action/param bytes.
bool isButtonMappingByte(int v) => v >= 0 && v <= 0xFF;

/// Validates button-map staging before Save (reset path).
///
/// @returns null if OK; otherwise a short error for [DeviceSettingsViewState.lastError].
String? validateButtonMappingStaging({
  required List<ButtonMappingSlot> staging,
  required DeviceSettingsState synced,
}) {
  if (staging.length != kButtonMappingSlotCount) {
    return 'button mapping: expected $kButtonMappingSlotCount slots, '
        'got ${staging.length}';
  }

  final byId = <int, ButtonData>{
    if (synced.buttons != null)
      for (final b in synced.buttons!) b.id: b,
  };

  for (var i = 0; i < staging.length; i++) {
    final slot = staging[i];
    final id = i + 1;
    final err = _validateSlot(
      id: id,
      slot: slot,
      live: byId[id],
    );
    if (err != null) return err;
  }
  return null;
}

/// Validates button-map staging against L2 device capabilities.
///
/// Checks:
/// - All staged button IDs exist in capabilities
/// - Non-remappable buttons are not being changed from their default/live values
///
/// @returns null if OK; otherwise a short error message.
String? validateButtonMappingAgainstCapabilities({
  required List<ButtonMappingSlot> staging,
  required DeviceSettingsState synced,
  DeviceCapabilities? capabilities,
}) {
  if (capabilities == null) {
    return null; // No capabilities loaded, skip L2 validation
  }

  final capButtons = capabilities.buttons;
  if (capButtons == null) {
    return null; // No button capabilities, skip validation
  }

  final capById = <int, ButtonDef>{
    for (final b in capButtons.list) b.id: b,
  };

  for (var i = 0; i < staging.length; i++) {
    final slot = staging[i];
    final id = i + 1;
    final cap = capById[id];

    if (cap == null) {
      return 'button mapping B$id: not in device capabilities';
    }

    // Check if trying to change a non-remappable button
    if (!cap.remappable) {
      final live = synced.buttons?.firstWhere(
        (b) => b.id == id,
        orElse: () => ButtonData(id: id, labelKey: 'button.$id', remappable: false),
      );
      final expectedAction = live?.action ?? 0;
      if (slot.action != expectedAction) {
        return 'button mapping B$id: cannot change non-remappable button '
            '(got 0x${slot.action.toRadixString(16)}, '
            'expected 0x${expectedAction.toRadixString(16)})';
      }
    }
  }

  return null;
}

String? _validateSlot({
  required int id,
  required ButtonMappingSlot slot,
  required ButtonData? live,
}) {
  if (!isButtonMappingByte(slot.action) ||
      !isButtonMappingByte(slot.param1) ||
      !isButtonMappingByte(slot.param2) ||
      !isButtonMappingByte(slot.param3)) {
    return 'button mapping B$id: value out of 0..255';
  }

  final expected = _expectedResetSlot(id: id, live: live);
  if (slot != expected) {
    return 'button mapping B$id: staging does not match reset policy '
        '(got 0x${slot.action.toRadixString(16)}, '
        'expected 0x${expected.action.toRadixString(16)})';
  }
  return null;
}

/// Same rules as [stageButtonMappingDefaults] for one physical id.
ButtonMappingSlot _expectedResetSlot({
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
