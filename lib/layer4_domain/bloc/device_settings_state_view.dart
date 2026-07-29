import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';

/// L4 BLoC state: last synchronized profile + sandbox staging buffer.
///
/// Chart: staging holds dirty edits with **no** L5/L6 packets until Save.
class DeviceSettingsViewState {
  const DeviceSettingsViewState({
    this.synced,
    this.buttonMappingStaging,
    this.isDirty = false,
    this.committing = false,
    this.consecutiveFailures = 0,
    this.lastError,
  });

  /// Last device-synchronized settings (GET or successful Save).
  final DeviceSettingsState? synced;

  /// Sandbox buffer for button map (6 slots). Null when clean for that block.
  final List<ButtonMappingEntry>? buttonMappingStaging;

  /// Chart: sandbox dirty → Cancel/Save / nav-guard path.
  final bool isDirty;

  /// True while Save is talking to L5 (UI can disable controls).
  final bool committing;

  /// Chart error-tracking consecutive failure counter.
  final int consecutiveFailures;

  /// Soft error for L3; null if clean.
  final String? lastError;

  /// What L3 paints: staged button labels when dirty, else synced.
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
    List<ButtonMappingEntry>? buttonMappingStaging,
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

/// Overlay staged wire map onto [base] caps/hotspots + action labels.
DeviceSettingsState packButtonsOntoSettings(
  DeviceSettingsState base,
  List<ButtonMappingEntry> staging, {
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
