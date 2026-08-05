import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:driver_hub/layer2_capabilities/sensor_profiles.dart';

/// Capabilities of a supported device.
///
/// Product data lives per mouse: [assets/catalog/mouse/{modelSlug}.json]
/// (e.g. m7xse.json). This file holds the typed model and loader only.
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

  factory DeviceCapabilities.fromJson(Map<String, dynamic> json) {
    return DeviceCapabilities(
      devId: json['devId'] as String,
      displayNameKey: json['displayNameKey'] as String,
      buttons: json['buttons'] == null
          ? null
          : ButtonCapabilities.fromJson(
              json['buttons'] as Map<String, dynamic>),
      reportRate: json['reportRate'] == null
          ? null
          : ReportRateCapabilities.fromJson(
              json['reportRate'] as Map<String, dynamic>),
      dpi: json['dpi'] == null
          ? null
          : DpiCapabilities.fromJson(json['dpi'] as Map<String, dynamic>),
      sensor: json['sensor'] == null
          ? null
          : SensorCapabilities.fromJson(
              json['sensor'] as Map<String, dynamic>),
      otherFeatures: json['otherFeatures'] == null
          ? null
          : OtherFeaturesCapabilities.fromJson(
              json['otherFeatures'] as Map<String, dynamic>),
      rgbBacklight: json['rgbBacklight'] == null
          ? null
          : RgbBacklightCapabilities.fromJson(
              json['rgbBacklight'] as Map<String, dynamic>),
      macro: json['macro'] == null
          ? null
          : MacroCapabilities.fromJson(json['macro'] as Map<String, dynamic>),
      osd: json['osd'] == null
          ? null
          : OsdCapabilities.fromJson(json['osd'] as Map<String, dynamic>),
    );
  }

  /// Sensor profile for this product [devId], or null if none.
  /// USB and 2.4G use the same profile (one sensor per device id).
  SensorProfile? sensorProfileFor() => SensorProfiles.forDevice(devId);
}

class ButtonCapabilities {
  final int count;
  final List<ButtonDef> list;
  const ButtonCapabilities({required this.count, required this.list});

  factory ButtonCapabilities.fromJson(Map<String, dynamic> json) {
    return ButtonCapabilities(
      count: json['count'] as int,
      list: (json['list'] as List)
          .map((e) => ButtonDef.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
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

  factory ButtonDef.fromJson(Map<String, dynamic> json) {
    return ButtonDef(
      id: json['id'] as int,
      labelKey: json['labelKey'] as String,
      remappable: json['remappable'] as bool,
      hotspot: Hotspot.fromJson(json['hotspot'] as Map<String, dynamic>),
    );
  }
}

class Hotspot {
  final double x, y, r;
  const Hotspot({required this.x, required this.y, required this.r});

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      r: (json['r'] as num).toDouble(),
    );
  }
}

class ReportRateCapabilities {
  final List<int> options;
  final int defaultValue;
  const ReportRateCapabilities({
    required this.options,
    required this.defaultValue,
  });

  factory ReportRateCapabilities.fromJson(Map<String, dynamic> json) {
    return ReportRateCapabilities(
      options: (json['options'] as List).map((e) => e as int).toList(),
      defaultValue: json['defaultValue'] as int,
    );
  }
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

  factory DpiCapabilities.fromJson(Map<String, dynamic> json) {
    return DpiCapabilities(
      maxLevels: json['maxLevels'] as int,
      defaultLevel: json['defaultLevel'] as int,
      maxDpi: json['maxDpi'] as int,
      independentXY: json['independentXY'] as bool,
      rgbPerStage: json['rgbPerStage'] as bool,
      levels: (json['levels'] as List)
          .map((e) => DpiLevel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class DpiLevel {
  final int level;
  final int value;
  final String color; // "#RRGGBB"
  const DpiLevel({
    required this.level,
    required this.value,
    required this.color,
  });

  factory DpiLevel.fromJson(Map<String, dynamic> json) {
    return DpiLevel(
      level: json['level'] as int,
      value: json['value'] as int,
      color: json['color'] as String,
    );
  }
}

/// Sensor-related product flags.
///
/// [sensorTuning] is grouped: ripple control + angle snap (both or neither).
/// [angleTune] is a separate capability.
class SensorCapabilities {
  final bool present;
  final SensorPerformance? performance;
  /// Grouped: ripple control + angle snap (both or neither).
  final bool sensorTuning;
  /// Separate feature from [sensorTuning].
  final bool angleTune;
  final AngleTuneCapabilities? angleTuneDetails;
  final LiftOffDistance? liftOffDistance;
  const SensorCapabilities({
    required this.present,
    this.performance,
    required this.sensorTuning,
    required this.angleTune,
    this.angleTuneDetails,
    this.liftOffDistance,
  });

  factory SensorCapabilities.fromJson(Map<String, dynamic> json) {
    return SensorCapabilities(
      present: json['present'] as bool,
      performance: json['performance'] == null
          ? null
          : SensorPerformance.fromJson(
              json['performance'] as Map<String, dynamic>),
      sensorTuning: json['sensorTuning'] as bool,
      angleTune: json['angleTune'] as bool,
      angleTuneDetails: json['angleTuneDetails'] == null
          ? null
          : AngleTuneCapabilities.fromJson(
              json['angleTuneDetails'] as Map<String, dynamic>),
      liftOffDistance: json['liftOffDistance'] == null
          ? null
          : LiftOffDistance.fromJson(
              json['liftOffDistance'] as Map<String, dynamic>),
    );
  }
}

/// Angle-tune value encoding, per mouse (not per sensor — two mice with the
/// same sensor may differ).
///
/// Discrete form ([options]): a fixed wire→label lookup table. This is the
/// current 14-byte firmware shape: `data[3]` of the 0xD4 block is the value
/// byte.
///
/// TODO(range encoding): the newer firmware / range-based sensors (e.g. 3950)
/// expose a continuous -30°..+30° range instead of a lookup table. When the
/// wire formula is confirmed, add a `range` form here (e.g. `min/max/step`)
/// alongside [options] — L5 decodes it by computation, L3 renders a counter
/// bounded by min/max. Do NOT hardcode the formula in L5.
class AngleTuneCapabilities {
  final bool present;
  final int? defaultWire;
  final List<AngleTuneOption>? options;
  const AngleTuneCapabilities({
    required this.present,
    this.defaultWire,
    this.options,
  });

  factory AngleTuneCapabilities.fromJson(Map<String, dynamic> json) {
    return AngleTuneCapabilities(
      present: json['present'] as bool,
      defaultWire: json['default'] as int?,
      options: json['options'] == null
          ? null
          : (json['options'] as List)
              .map((e) => AngleTuneOption.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

/// One wire→label mapping for discrete angle tune.
///
/// Mirrors [LodOption]: `wire` is the device byte, `label` is the display
/// string (e.g. `-30°`). L5 owns the lookup logic, L2 owns the per-mouse list.
class AngleTuneOption {
  final int wire;
  final String label;
  const AngleTuneOption({required this.wire, required this.label});

  factory AngleTuneOption.fromJson(Map<String, dynamic> json) {
    return AngleTuneOption(
      wire: json['wire'] as int,
      label: json['label'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AngleTuneOption && wire == other.wire && label == other.label;

  @override
  int get hashCode => Object.hash(wire, label);
}

class SensorPerformance {
  final bool present;
  final List<int> options;
  const SensorPerformance({required this.present, required this.options});

  factory SensorPerformance.fromJson(Map<String, dynamic> json) {
    return SensorPerformance(
      present: json['present'] as bool,
      options: (json['options'] as List).map((e) => e as int).toList(),
    );
  }
}

class LodOption {
  final int wire;
  final double mm;
  const LodOption({required this.wire, required this.mm});

  factory LodOption.fromJson(Map<String, dynamic> json) {
    return LodOption(
      wire: json['wire'] as int,
      mm: (json['mm'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LodOption && wire == other.wire && mm == other.mm;

  @override
  int get hashCode => Object.hash(wire, mm);
}

/// One wire→label mapping for a fixed-index option list (debounce, sleep).
///
/// Mirrors [LodOption] / [AngleTuneOption]: `wire` is the device byte, `label`
/// is the display string (e.g. `2ms`, `30 sec`). L2 owns the per-mouse list;
/// L5 owns the generic lookup.
class OptionPair {
  final int wire;
  final String label;
  const OptionPair({required this.wire, required this.label});

  factory OptionPair.fromJson(Map<String, dynamic> json) {
    return OptionPair(
      wire: json['wire'] as int,
      label: json['label'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptionPair && wire == other.wire && label == other.label;

  @override
  int get hashCode => Object.hash(wire, label);
}

class LiftOffDistance {
  final bool present;
  final List<LodOption> options;
  const LiftOffDistance({required this.present, required this.options});

  factory LiftOffDistance.fromJson(Map<String, dynamic> json) {
    return LiftOffDistance(
      present: json['present'] as bool,
      options: (json['options'] as List)
          .map((e) => LodOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
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

  factory OtherFeaturesCapabilities.fromJson(Map<String, dynamic> json) {
    return OtherFeaturesCapabilities(
      present: json['present'] as bool,
      buttonDebounce: json['buttonDebounce'] == null
          ? null
          : ButtonDebounce.fromJson(
              json['buttonDebounce'] as Map<String, dynamic>),
      sleepTime: json['sleepTime'] == null
          ? null
          : SleepTime.fromJson(json['sleepTime'] as Map<String, dynamic>),
      wheelDirectionInvert: json['wheelDirectionInvert'] as bool,
    );
  }
}

class ButtonDebounce {
  final bool present;
  final List<OptionPair> options;
  const ButtonDebounce({required this.present, required this.options});

  factory ButtonDebounce.fromJson(Map<String, dynamic> json) {
    return ButtonDebounce(
      present: json['present'] as bool,
      options: (json['options'] as List)
          .map((e) => OptionPair.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SleepTime {
  final bool present;
  final List<OptionPair> options;
  const SleepTime({required this.present, required this.options});

  factory SleepTime.fromJson(Map<String, dynamic> json) {
    return SleepTime(
      present: json['present'] as bool,
      options: (json['options'] as List)
          .map((e) => OptionPair.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
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

  factory RgbBacklightCapabilities.fromJson(Map<String, dynamic> json) {
    return RgbBacklightCapabilities(
      present: json['present'] as bool,
      modes: (json['modes'] as List)
          .map((e) => RgbMode.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      brightnessLevels: json['brightnessLevels'] as int,
      speedLevels: json['speedLevels'] as int,
      sleepTimeOptions:
          (json['sleepTimeOptions'] as List).map((e) => e as int).toList(),
    );
  }
}

class RgbMode {
  final int id;
  final String nameKey;
  final bool supportsColor;
  const RgbMode({
    required this.id,
    required this.nameKey,
    required this.supportsColor,
  });

  factory RgbMode.fromJson(Map<String, dynamic> json) {
    return RgbMode(
      id: json['id'] as int,
      nameKey: json['nameKey'] as String,
      supportsColor: json['supportsColor'] as bool,
    );
  }
}

class MacroCapabilities {
  final int slots;
  final int maxLength;
  const MacroCapabilities({required this.slots, required this.maxLength});

  factory MacroCapabilities.fromJson(Map<String, dynamic> json) {
    return MacroCapabilities(
      slots: json['slots'] as int,
      maxLength: json['maxLength'] as int,
    );
  }
}

class OsdCapabilities {
  final bool enabled;
  const OsdCapabilities({required this.enabled});

  factory OsdCapabilities.fromJson(Map<String, dynamic> json) {
    return OsdCapabilities(enabled: json['enabled'] as bool);
  }
}

/// Loads per-mouse capabilities from [assets/catalog/mouse/{modelSlug}.json].
///
/// Not loaded at app start. Load when the user opens settings for a mouse
/// (device card → settings). [forDevice] returns caps for a [devId], or null
/// if not loaded / unknown. Each model file is cached after first [load].
///
/// Add a mouse: new file e.g. `assets/catalog/mouse/m8xxx.json` (slug =
/// catalog model lowercased) with that product's capability object.
class DeviceCapabilityStore {
  DeviceCapabilityStore._();

  static const _dir = 'assets/catalog/mouse';

  static final Map<String, DeviceCapabilities> _byDevId = {};
  static final Set<String> _loadedSlugs = {};

  /// Asset path for a catalog model name (e.g. `M7XSE` → `.../m7xse.json`,
  /// `M7X PRO` → `.../m7x_pro.json`). Lowercased; spaces become underscores
  /// so a space in a display name maps to the snake_case asset file.
  static String assetPathForModel(String model) =>
      '$_dir/${model.toLowerCase().replaceAll(' ', '_')}.json';

  /// Loads one mouse capabilities file. Cached per model slug.
  /// Call when entering mouse settings, not at app start.
  static Future<void> load(String model) async {
    final slug = model.toLowerCase();
    if (_loadedSlugs.contains(slug)) return;
    final raw = await rootBundle.loadString(assetPathForModel(model));
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final caps = DeviceCapabilities.fromJson(json);
    _byDevId[caps.devId] = caps;
    _loadedSlugs.add(slug);
  }

  /// Returns the device capabilities for [devId], or null if unsupported / not loaded.
  static DeviceCapabilities? forDevice(String devId) => _byDevId[devId];
}
