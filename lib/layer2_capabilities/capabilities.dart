import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:driver_hub/layer2_capabilities/dpi_wire_profile.dart';

/// Protocol conversion parameters consumed by Layer 5 macro encoding.
///
/// These values are capability data, not presentation constants. Layer 3 and
/// Layer 4 use the semantic wheel actions exposed by [MacroAction].
class MacroWireActions {
  const MacroWireActions._();

  static const wheelUp = 0xC6;
  static const wheelDown = 0xC7;
  static const tiltLeft = 0xB9;
  static const tiltRight = 0xB8;
}

/// Capabilities of a supported device.
///
/// Product data lives per mouse: [assets/catalog/mouse/{modelSlug}.json]
/// (e.g. m7x_se.json). This file holds the typed model and loader only.
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
              json['buttons'] as Map<String, dynamic>,
            ),
      reportRate: json['reportRate'] == null
          ? null
          : ReportRateCapabilities.fromJson(
              json['reportRate'] as Map<String, dynamic>,
            ),
      dpi: json['dpi'] == null
          ? null
          : DpiCapabilities.fromJson(json['dpi'] as Map<String, dynamic>),
      sensor: json['sensor'] == null
          ? null
          : SensorCapabilities.fromJson(json['sensor'] as Map<String, dynamic>),
      otherFeatures: json['otherFeatures'] == null
          ? null
          : OtherFeaturesCapabilities.fromJson(
              json['otherFeatures'] as Map<String, dynamic>,
            ),
      rgbBacklight: json['rgbBacklight'] == null
          ? null
          : RgbBacklightCapabilities.fromJson(
              json['rgbBacklight'] as Map<String, dynamic>,
            ),
      macro: json['macro'] == null
          ? null
          : MacroCapabilities.fromJson(json['macro'] as Map<String, dynamic>),
      osd: json['osd'] == null
          ? null
          : OsdCapabilities.fromJson(json['osd'] as Map<String, dynamic>),
    );
  }
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

  /// Number of DPI stages enabled by the product's default configuration.
  final int activeLevelCount;
  final int defaultLevel;
  final String wireProfileKey;
  final DpiRange range;
  final bool independentXY;
  final bool rgbPerStage;
  final List<DpiLevel> levels;
  const DpiCapabilities({
    required this.maxLevels,
    required this.activeLevelCount,
    required this.defaultLevel,
    required this.wireProfileKey,
    required this.range,
    required this.independentXY,
    required this.rgbPerStage,
    required this.levels,
  });

  factory DpiCapabilities.fromJson(Map<String, dynamic> json) {
    return DpiCapabilities(
      maxLevels: json['maxLevels'] as int,
      activeLevelCount: json['activeLevelCount'] as int,
      defaultLevel: json['defaultLevel'] as int,
      wireProfileKey: (json['wireProfile'] as String?) ?? 'telink_b80_dpi16',
      range: DpiRange.fromJson(json['range'] as Map<String, dynamic>),
      independentXY: json['independentXY'] as bool,
      rgbPerStage: json['rgbPerStage'] as bool,
      levels: (json['levels'] as List)
          .map((e) => DpiLevel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Shared L2 wire parameters for this product's USB DPI path.
  DpiWireProfile? get wireProfile => DpiWireProfiles.forKey(wireProfileKey);
}

/// DPI value bounds + step model for one product.
///
/// Single source of truth for the slider / validation. Per the mock
/// description, different sensors encode DPI differently:
/// - `fixed`: one step (e.g. step 50 → 800, 850, 900...)
/// - `tiered`: variable step by value range (e.g. M7X: step 50 below 10000,
///   step 100 above)
/// - `any`: any value in [minDpi, maxDpi] (no step constraint)
class DpiRange {
  final int minDpi;
  final int maxDpi;
  final String stepMode; // 'fixed' | 'tiered' | 'any'
  final int? step; // fixed mode
  final List<DpiStepTier>? tiers; // tiered mode
  const DpiRange({
    required this.minDpi,
    required this.maxDpi,
    required this.stepMode,
    this.step,
    this.tiers,
  });

  factory DpiRange.fromJson(Map<String, dynamic> json) {
    return DpiRange(
      minDpi: json['minDpi'] as int,
      maxDpi: json['maxDpi'] as int,
      stepMode: json['stepMode'] as String,
      step: json['step'] as int?,
      tiers: json['tiers'] == null
          ? null
          : (json['tiers'] as List)
                .map((e) => DpiStepTier.fromJson(e as Map<String, dynamic>))
                .toList(growable: false),
    );
  }

  /// Validates that [value] is within range and on-step for this model.
  ///
  /// Returns the snapped value, or null if out of range. `fixed` snaps down to
  /// the nearest step; `tiered` snaps down within the matching tier's own grid;
  /// `any` clamps only.
  int? snap(int value) {
    if (value < minDpi || value > maxDpi) return null;
    switch (stepMode) {
      case 'fixed':
        final s = step ?? 1;
        return minDpi + ((value - minDpi) ~/ s) * s;
      case 'tiered':
        return _snapTiered(value);
      case 'any':
      default:
        return value;
    }
  }

  /// Tiered snap: each tier's valid values are anchored at that tier's lower
  /// bound, not at [minDpi]. Per FR-DPI-004 + the sensor datasheet, M7X valid
  /// values are 50-step from 50..10000 then 100-step from 10000..12000 — so the
  /// max (12000) is reachable and mid values never land on a non-existent step
  /// (e.g. 11950). Snaps down to the nearest valid step; a value below the
  /// first tier's grid falls back to [minDpi].
  int? _snapTiered(int value) {
    final ts = tiers;
    if (ts == null || ts.isEmpty) return value;
    var lower = minDpi;
    for (final tier in ts) {
      if (value <= tier.max) {
        // Max of the tier must stay reachable even if it is off-grid.
        if (value == tier.max && tier.max == maxDpi) return maxDpi;
        return lower + ((value - lower) ~/ tier.step) * tier.step;
      }
      lower = tier.max;
    }
    return maxDpi;
  }

  /// Step that applies to [value] under a tiered model; null if no tier.
  int? stepFor(int value) {
    for (final tier in tiers ?? const <DpiStepTier>[]) {
      if (value <= tier.max) return tier.step;
    }
    return tiers?.isNotEmpty == true ? tiers!.last.step : null;
  }
}

/// One step tier: values up to [max] use [step].
class DpiStepTier {
  final int max;
  final int step;
  const DpiStepTier({required this.max, required this.step});

  factory DpiStepTier.fromJson(Map<String, dynamic> json) {
    return DpiStepTier(max: json['max'] as int, step: json['step'] as int);
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
  final String? model;
  final bool present;
  final SensorPerformance? performance;

  /// Grouped: ripple control + angle snap (both or neither).
  final bool sensorTuning;

  /// Separate feature from [sensorTuning].
  final bool angleTune;
  final AngleTuneCapabilities? angleTuneDetails;
  final LiftOffDistance? liftOffDistance;
  const SensorCapabilities({
    this.model,
    required this.present,
    this.performance,
    required this.sensorTuning,
    required this.angleTune,
    this.angleTuneDetails,
    this.liftOffDistance,
  });

  factory SensorCapabilities.fromJson(Map<String, dynamic> json) {
    return SensorCapabilities(
      model: json['model'] as String?,
      present: json['present'] as bool,
      performance: json['performance'] == null
          ? null
          : SensorPerformance.fromJson(
              json['performance'] as Map<String, dynamic>,
            ),
      sensorTuning: json['sensorTuning'] as bool,
      angleTune: json['angleTune'] as bool,
      angleTuneDetails: json['angleTuneDetails'] == null
          ? null
          : AngleTuneCapabilities.fromJson(
              json['angleTuneDetails'] as Map<String, dynamic>,
            ),
      liftOffDistance: json['liftOffDistance'] == null
          ? null
          : LiftOffDistance.fromJson(
              json['liftOffDistance'] as Map<String, dynamic>,
            ),
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
    final opts = json['options'] as List?;
    return AngleTuneCapabilities(
      present: json['present'] as bool,
      defaultWire: (json['defaultWire'] as int?) ?? (json['default'] as int?),
      options: opts
          ?.asMap()
          .entries
          .map((e) => AngleTuneOption.fromJson(e.value, e.key))
          .toList(),
    );
  }
}

/// One wire→label mapping for discrete angle tune.
class AngleTuneOption {
  final int wire;
  final String label;
  const AngleTuneOption({required this.wire, required this.label});

  factory AngleTuneOption.fromJson(dynamic json, [int defaultWire = 0]) {
    if (json is Map<String, dynamic>) {
      return AngleTuneOption(
        wire: (json['wire'] as int?) ?? defaultWire,
        label: json['label'] as String,
      );
    }
    if (json is num) {
      return AngleTuneOption(wire: defaultWire, label: '$json°');
    }
    return AngleTuneOption(wire: defaultWire, label: json.toString());
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

  factory LodOption.fromJson(dynamic json, [int defaultWire = 0]) {
    if (json is Map<String, dynamic>) {
      return LodOption(
        wire: (json['wire'] as int?) ?? defaultWire,
        mm: (json['mm'] as num).toDouble(),
      );
    }
    if (json is num) {
      return LodOption(wire: defaultWire, mm: json.toDouble());
    }
    return LodOption(wire: defaultWire, mm: 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LodOption && wire == other.wire && mm == other.mm;

  @override
  int get hashCode => Object.hash(wire, mm);
}

/// One wire→label mapping for a fixed-index option list (debounce, sleep).
class OptionPair {
  final int wire;
  final String label;
  const OptionPair({required this.wire, required this.label});

  factory OptionPair.fromJson(dynamic json, [int defaultWire = 0]) {
    if (json is Map<String, dynamic>) {
      return OptionPair(
        wire: (json['wire'] as int?) ?? defaultWire,
        label: json['label'] as String,
      );
    }
    return OptionPair(wire: defaultWire, label: json.toString());
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
    final opts = json['options'] as List;
    return LiftOffDistance(
      present: json['present'] as bool,
      options: opts
          .asMap()
          .entries
          .map((e) => LodOption.fromJson(e.value, e.key))
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
              json['buttonDebounce'] as Map<String, dynamic>,
            ),
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
    final opts = json['options'] as List;
    return ButtonDebounce(
      present: json['present'] as bool,
      options: opts
          .asMap()
          .entries
          .map((e) => OptionPair.fromJson(e.value, e.key))
          .toList(),
    );
  }
}

class SleepTime {
  final bool present;

  /// Default option wire index from the product capability description.
  final int defaultWire;
  final List<OptionPair> options;
  const SleepTime({
    required this.present,
    required this.defaultWire,
    required this.options,
  });

  factory SleepTime.fromJson(Map<String, dynamic> json) {
    final opts = json['options'] as List;
    return SleepTime(
      present: json['present'] as bool,
      defaultWire: (json['defaultWire'] as int?) ?? (json['default'] as int?) ?? 4,
      options: opts
          .asMap()
          .entries
          .map((e) => OptionPair.fromJson(e.value, e.key))
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
      sleepTimeOptions: (json['sleepTimeOptions'] as List)
          .map((e) => e as int)
          .toList(),
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

  static String assetPathForSlug(String slug) => '$_dir/$slug.json';

  /// Asset path for a catalog model name (e.g. `M7X SE` → `.../m7x_se.json`,
  /// `M7X PRO` → `.../m7x_pro.json`). Lowercased; spaces become underscores
  /// so a space in a display name maps to the snake_case asset file.
  static String assetPathForModel(String model) {
    var slug = model.toLowerCase().replaceAll(' ', '_');
    if (slug.startsWith('mouse_')) {
      slug = slug.substring(6);
    }
    return assetPathForSlug(slug);
  }

  /// Loads one mouse capabilities file. Cached per model slug.
  /// Call when entering mouse settings, not at app start.
  static Future<void> load(String modelOrSlug) async {
    var slug = modelOrSlug.toLowerCase().replaceAll(' ', '_');
    if (slug.startsWith('mouse_')) {
      slug = slug.substring(6);
    }
    if (_loadedSlugs.contains(slug)) {
      return;
    }
    final raw = await rootBundle.loadString(assetPathForSlug(slug));
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final caps = DeviceCapabilities.fromJson(json);
    _byDevId[caps.devId] = caps;
    _loadedSlugs.add(slug);
  }

  /// Returns the device capabilities for [devId], or null if unsupported / not loaded.
  static DeviceCapabilities? forDevice(String devId) => _byDevId[devId];
}
