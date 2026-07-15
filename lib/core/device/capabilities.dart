import 'sensor_profiles.dart';

/// Capabilities of a supported device.
///
/// Capabilities are defined in Dart, not in a JSON data file. The registry
/// (supported_model.json) is the only catalog data; capabilities are code.
/// Adding a device's capabilities means adding a Dart definition, not editing
/// a data file.
///
/// Every capability block carries a [present] flag, mirroring the catalog
/// convention. A card renders a row only when its capability is present.
class DeviceCapabilities {
  final String devId;
  final String displayNameKey;
  final ButtonCapabilities? buttons;
  final ReportRateCapabilities? reportRate;
  final DpiCapabilities? dpi;
  final SensorCapabilities? sensor;
  final OtherFeaturesCapabilities? otherFeatures;
  final RgbBacklightCapabilities? rgbBacklight;
  final MacroCapabilities? macro;
  final OsdCapabilities? osd;

  const DeviceCapabilities({
    required this.devId,
    required this.displayNameKey,
    this.buttons,
    this.reportRate,
    this.dpi,
    this.sensor,
    this.otherFeatures,
    this.rgbBacklight,
    this.macro,
    this.osd,
  });

  /// Sensor profile for this device and mode, or null if none.
  SensorProfile? sensorProfileFor(int mode) =>
      SensorProfiles.forDevice(devId, mode);
}

class ButtonCapabilities {
  final int count;
  final List<ButtonDef> list;
  const ButtonCapabilities({required this.count, required this.list});
}

class ButtonDef {
  final int id;
  final String labelKey;
  final bool remappable;
  final Hotspot hotspot;
  const ButtonDef({
    required this.id,
    required this.labelKey,
    required this.remappable,
    required this.hotspot,
  });
}

class Hotspot {
  final double x, y, r;
  const Hotspot({required this.x, required this.y, required this.r});
}

class ReportRateCapabilities {
  final List<int> options;
  final int defaultValue;
  const ReportRateCapabilities({required this.options, required this.defaultValue});
}

class DpiCapabilities {
  final int maxLevels;
  final int defaultLevel;
  final int maxDpi;
  final bool independentXY;
  final bool rgbPerStage;
  final List<DpiLevel> levels;
  const DpiCapabilities({
    required this.maxLevels,
    required this.defaultLevel,
    required this.maxDpi,
    required this.independentXY,
    required this.rgbPerStage,
    required this.levels,
  });
}

class DpiLevel {
  final int level;
  final int value;
  final String color; // "#RRGGBB"
  const DpiLevel({required this.level, required this.value, required this.color});
}

/// Ripple control and angle snap are a coupled group: a device has both or
/// neither. They are not independent flags.
///
/// When [sensorTuning] is true, the device supports ripple control and angle
/// snap. Display labels: "Ripple Control" and "Angle Snap".
///
/// [angleTune] is a separate, independent capability. A device may have
/// sensor tuning without angle tune.
class SensorCapabilities {
  final bool present;
  final SensorPerformance? performance;
  final bool sensorTuning; // ripple control + angle snap, as one group
  final bool angleTune; // separate capability
  final LiftOffDistance? liftOffDistance;
  const SensorCapabilities({
    required this.present,
    this.performance,
    required this.sensorTuning,
    required this.angleTune,
    this.liftOffDistance,
  });
}

class SensorPerformance {
  final bool present;
  final List<int> options;
  const SensorPerformance({required this.present, required this.options});
}

class LiftOffDistance {
  final bool present;
  final List<int> options;
  const LiftOffDistance({required this.present, required this.options});
}

class OtherFeaturesCapabilities {
  final bool present;
  final ButtonDebounce? buttonDebounce;
  final SleepTime? sleepTime;
  final bool wheelDirectionInvert;
  const OtherFeaturesCapabilities({
    required this.present,
    this.buttonDebounce,
    this.sleepTime,
    required this.wheelDirectionInvert,
  });
}

class ButtonDebounce {
  final bool present;
  final List<int> options;
  const ButtonDebounce({required this.present, required this.options});
}

class SleepTime {
  final bool present;
  final List<int> options;
  const SleepTime({required this.present, required this.options});
}

class RgbBacklightCapabilities {
  final bool present;
  final List<RgbMode> modes;
  final int brightnessLevels;
  final int speedLevels;
  final List<int> sleepTimeOptions;
  const RgbBacklightCapabilities({
    required this.present,
    required this.modes,
    required this.brightnessLevels,
    required this.speedLevels,
    required this.sleepTimeOptions,
  });
}

class RgbMode {
  final int id;
  final String nameKey;
  final bool supportsColor;
  const RgbMode({required this.id, required this.nameKey, required this.supportsColor});
}

class MacroCapabilities {
  final int slots;
  final int maxLength;
  const MacroCapabilities({required this.slots, required this.maxLength});
}

class OsdCapabilities {
  final bool enabled;
  const OsdCapabilities({required this.enabled});
}

/// Returns the hardcoded capability definition for a device.
///
/// Capabilities are Dart code, not a data file. Adding a device's capabilities
/// means adding an entry to [_byDevId]. There is no JSON read.
class CapabilityStore {
  const CapabilityStore._();

  /// Returns the capabilities for [devId], or null if unsupported.
  static DeviceCapabilities? forDevice(String devId) => _byDevId[devId];

  static const _byDevId = <String, DeviceCapabilities>{
    'aa4ecd01': _m7xse,
  };

  static const _m7xse = DeviceCapabilities(
    devId: 'aa4ecd01',
    displayNameKey: 'device.m7xse.name',
    buttons: ButtonCapabilities(
      count: 6,
      list: [
        ButtonDef(id: 1, labelKey: 'button.left_click', remappable: false,
            hotspot: Hotspot(x: 0.22, y: 0.12, r: 0.06)),
        ButtonDef(id: 2, labelKey: 'button.right_click', remappable: true,
            hotspot: Hotspot(x: 0.78, y: 0.12, r: 0.06)),
        ButtonDef(id: 3, labelKey: 'button.middle_click', remappable: true,
            hotspot: Hotspot(x: 0.50, y: 0.14, r: 0.05)),
        ButtonDef(id: 4, labelKey: 'button.forward', remappable: true,
            hotspot: Hotspot(x: 0.10, y: 0.55, r: 0.05)),
        ButtonDef(id: 5, labelKey: 'button.back', remappable: true,
            hotspot: Hotspot(x: 0.10, y: 0.65, r: 0.05)),
        ButtonDef(id: 6, labelKey: 'button.dpi_cycle', remappable: true,
            hotspot: Hotspot(x: 0.50, y: 0.30, r: 0.04)),
      ],
    ),
    reportRate: ReportRateCapabilities(options: [125, 500, 1000, 4000], defaultValue: 1000),
    dpi: DpiCapabilities(
      maxLevels: 8,
      defaultLevel: 1,
      maxDpi: 3200,
      independentXY: false,
      rgbPerStage: true,
      levels: [
        DpiLevel(level: 1, value: 400, color: '#FF0000'),
        DpiLevel(level: 2, value: 800, color: '#00FF00'),
        DpiLevel(level: 3, value: 1600, color: '#0000FF'),
      ],
    ),
    sensor: SensorCapabilities(
      present: true,
      performance: SensorPerformance(present: true, options: [0, 1, 2]),
      sensorTuning: true, // ripple control + angle snap (grouped)
      angleTune: false, // separate capability; M7XSE lacks it
      liftOffDistance: LiftOffDistance(present: true, options: [1, 2, 3]),
    ),
    otherFeatures: OtherFeaturesCapabilities(
      present: true,
      buttonDebounce: ButtonDebounce(present: true, options: [4, 8, 16, 24]),
      sleepTime: SleepTime(present: true, options: [30, 60, 300, 600]),
      wheelDirectionInvert: true,
    ),
    rgbBacklight: RgbBacklightCapabilities(
      present: true,
      modes: [
        RgbMode(id: 1, nameKey: 'light.wave', supportsColor: true),
        RgbMode(id: 2, nameKey: 'light.breathing', supportsColor: true),
        RgbMode(id: 3, nameKey: 'light.solid', supportsColor: true),
        RgbMode(id: 6, nameKey: 'light.off', supportsColor: false),
      ],
      brightnessLevels: 5,
      speedLevels: 5,
      sleepTimeOptions: [30, 60, 300],
    ),
    macro: MacroCapabilities(slots: 16, maxLength: 127),
    osd: OsdCapabilities(enabled: true),
  );

  // -------------------------------------------------------------------------
  // TEMPLATE — copy this block to add a new mouse.
  //
  // 1. Add a registry entry to assets/catalog/supported_model.json (devId,
  //    vid/pid/modes, usagePage). See docs/ADDING_A_DEVICE.md.
  // 2. Copy this block, rename _template to _<devId>, and fill every value.
  // 3. Add the entry to _byDevId above.
  // 4. Run `flutter analyze`.
  //
  // Every field is shown. Use null/false/empty for capabilities the device
  // does not have. The compiler checks the types; it cannot check correctness
  // of the values against the hardware.
  // -------------------------------------------------------------------------
  static const _template = DeviceCapabilities( // ignore: unused_field
    devId: '<devId>', // TODO: must match supported_model.json devId
    displayNameKey: 'device.<devId>.name', // TODO: i18n key
    buttons: null, // TODO: ButtonCapabilities(count: N, list: [...])
    reportRate: null, // TODO: ReportRateCapabilities(options: [...], defaultValue: N)
    dpi: null, // TODO: DpiCapabilities(maxLevels: N, ...)
    sensor: null, // TODO: SensorCapabilities(...)
    //  sensorTuning groups ripple control + angle snap. angleTune is separate.
    otherFeatures: null, // TODO: OtherFeaturesCapabilities(...)
    rgbBacklight: null, // TODO: RgbBacklightCapabilities(...) if device has RGB
    macro: null, // TODO: MacroCapabilities(slots: N, maxLength: N) if supported
    osd: OsdCapabilities(enabled: false), // TODO: true if device pushes OSD reports
  );
}
