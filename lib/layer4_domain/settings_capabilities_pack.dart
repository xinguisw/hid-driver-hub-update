import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer2_capabilities/sensor_profiles.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';

/// Pure pack: product matrix → presence + option lists on [DeviceSettingsState].
///
/// Does not touch live GET values. Caller overlays wire/translate after GETs.
/// Sensor chip comes from [SensorProfiles] when already loaded.
DeviceSettingsState applyCapabilitiesToSettings(
  DeviceSettingsState state,
  DeviceCapabilities caps,
) {
  var next = state;

  final report = caps.reportRate;
  if (report != null) {
    next = next.copyWith(reportRateOptions: report.options);
  }

  final dpi = caps.dpi;
  if (dpi != null) {
    next = next.copyWith(
      dpiMax: dpi.range.maxDpi,
      dpiMin: dpi.range.minDpi,
      dpiStep: dpi.range.step,
      dpiStepMode: dpi.range.stepMode,
      dpiMaxLevels: dpi.maxLevels,
      dpiDefaultLevel: dpi.defaultLevel,
      dpiRgbPerStage: dpi.rgbPerStage,
      dpiLevels: [
        for (final level in dpi.levels)
          DpiStageData(
            level: level.level,
            value: level.value,
            color: level.color.isEmpty ? null : level.color,
          ),
      ],
    );
  }

  final buttons = caps.buttons;
  if (buttons != null) {
    const translate = TranslationCodec();
    next = next.copyWith(
      buttonCount: buttons.count,
      buttons: [
        for (final b in buttons.list)
          ButtonData(
            id: b.id,
            labelKey: b.labelKey,
            remappable: b.remappable,
            hotspotX: b.hotspot.x,
            hotspotY: b.hotspot.y,
            hotspotR: b.hotspot.r,
            buttonLabel: translate.buttonIdToLabel(b.id),
          ),
      ],
    );
  }

  final sensor = caps.sensor;
  if (sensor != null) {
    final lod = sensor.liftOffDistance;
    final perf = sensor.performance;
    final angleTune = sensor.angleTuneDetails;
    next = next.copyWith(
      hasSensorTuning: sensor.sensorTuning,
      hasAngleTune: sensor.angleTune,
      angleTuneOptions:
          (angleTune != null && angleTune.present) ? angleTune.options : null,
      hasLod: lod?.present ?? false,
      lodOptions: (lod != null && lod.present) ? lod.options : null,
      hasPerformance: perf?.present ?? false,
      performanceOptions:
          (perf != null && perf.present) ? perf.options : null,
    );
    final profile = SensorProfiles.forDevice(caps.devId);
    if (profile != null) {
      next = next.copyWith(sensorChip: profile.chip);
    }
  }

  final other = caps.otherFeatures;
  if (other != null) {
    final debounce = other.buttonDebounce;
    final sleep = other.sleepTime;
    next = next.copyWith(
      hasButtonDebounce:
          other.present && (debounce?.present ?? false),
      debounceOptions:
          (other.present && debounce != null && debounce.present)
              ? debounce.options
              : null,
      hasSleepTime: other.present && (sleep?.present ?? false),
      sleepOptions:
          (other.present && sleep != null && sleep.present)
              ? sleep.options
              : null,
      hasWheelInvert: other.present && other.wheelDirectionInvert,
    );
  }

  final rgb = caps.rgbBacklight;
  if (rgb != null) {
    next = next.copyWith(
      hasRgbBacklight: rgb.present,
      rgbModes: rgb.present
          ? [
              for (final m in rgb.modes)
                RgbModeData(
                  id: m.id,
                  nameKey: m.nameKey,
                  supportsColor: m.supportsColor,
                  // why: dropdown renders a human label, not the raw key;
                  // L5 owns the mode naming table.
                  label: const TranslationCodec().rgbModeToLabel(m.id),
                ),
            ]
          : null,
      rgbBrightnessLevels: rgb.present ? rgb.brightnessLevels : null,
      rgbSpeedLevels: rgb.present ? rgb.speedLevels : null,
    );
  }

  return next;
}
