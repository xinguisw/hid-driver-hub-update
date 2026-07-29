import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';

/// L4 BLoC state: last synchronized profile + sandbox staging buffer.
///
/// SDRD FR-OPS-001: staging holds dirty edits with **no** transport packets
/// until explicit Save (FR-OPS-003).
class DeviceSettingsViewState {
  const DeviceSettingsViewState({
    this.synced,
    this.buttonMappingStaging,
    this.isDirty = false,
    this.committing = false,
    this.consecutiveFailures = 0,
    this.lastError,
  });

  final DeviceSettingsState? synced;

  /// Sandbox buffer (domain slots). Null when clean for that block.
  final List<ButtonMappingSlot>? buttonMappingStaging;

  final bool isDirty;
  final bool committing;
  final int consecutiveFailures;
  final String? lastError;

  /// L3 paints staged button labels when dirty, else synced.
  DeviceSettingsState? get displaySettings {
    final base = synced;
    if (base == null) return null;
    final staging = buttonMappingStaging;
    if (!isDirty || staging == null) return base;
    return packButtonsOntoSettings(base, staging);
  }

  static const empty = DeviceSettingsViewState();

  DeviceSettingsViewState copyWith({
    DeviceSettingsState? synced,
    List<ButtonMappingSlot>? buttonMappingStaging,
    bool? isDirty,
    bool? committing,
    int? consecutiveFailures,
    String? lastError,
    bool clearStaging = false,
    bool clearError = false,
  }) {
    return DeviceSettingsViewState(
      synced: synced ?? this.synced,
      buttonMappingStaging: clearStaging
          ? null
          : (buttonMappingStaging ?? this.buttonMappingStaging),
      isDirty: clearStaging ? false : (isDirty ?? this.isDirty),
      committing: committing ?? this.committing,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Overlay staged domain slots onto [base] for L3 paint / post-Save synced.
DeviceSettingsState packButtonsOntoSettings(
  DeviceSettingsState base,
  List<ButtonMappingSlot> staging, {
  TranslationCodec translate = const TranslationCodec(),
}) {
  final baseButtons = base.buttons;
  final live = [
    for (var i = 0; i < staging.length; i++)
      ButtonData(
        id: i + 1,
        labelKey: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].labelKey
            : 'button.${i + 1}',
        remappable: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].remappable
            : true,
        hotspotX: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].hotspotX
            : null,
        hotspotY: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].hotspotY
            : null,
        hotspotR: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].hotspotR
            : null,
        buttonLabel: baseButtons != null && i < baseButtons.length
            ? (baseButtons[i].buttonLabel ?? translate.buttonIdToLabel(i + 1))
            : translate.buttonIdToLabel(i + 1),
        actionLabel: translate.buttonActionToLabel(
          action: staging[i].action,
          param1: staging[i].param1,
          param2: staging[i].param2,
          param3: staging[i].param3,
        ),
        action: staging[i].action,
        param1: staging[i].param1,
        param2: staging[i].param2,
        param3: staging[i].param3,
      ),
  ];
  return base.copyWith(
    buttonCount: live.length,
    buttons: live,
    clearError: true,
  );
}
