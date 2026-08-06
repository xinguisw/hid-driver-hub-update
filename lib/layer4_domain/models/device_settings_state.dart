import 'package:driver_hub/layer2_capabilities/capabilities.dart';

/// View model for one device's settings (same role as [DiscoveredCardState]).
///
/// Pure data — no HID, no DeviceCapabilityStore, no widgets. Owner packs this from
/// catalog + DeviceCapabilityStore + live GETs. UI maps fields to controls later
/// (null list / null value = hide section or show "—", like soft battery).
///
/// Presence of a feature: non-null option list or explicit has* where needed.
/// Live values: nullable until query succeeds.
class DeviceSettingsState {
  final String devId;
  final String displayName;
  final int connectionMode; // 0=USB, 1=2.4G

  /// True while owner is still loading device GETs.
  final bool loading;

  /// Soft error; settings can still show known fields.
  final String? error;

  /// Config block labels whose L5 decode was rejected (e.g. `dpiTable`).
  ///
  /// why: a block that never decoded has no trustworthy baseline, so L4 must
  /// not stage or dirty its controls (flow.drawio "Layer 5", decode-error box).
  final Set<String> decodeErrors;

  // --- Report rate (matrix: options differ per product) ---

  /// Allowed Hz; null = product has no report-rate feature.
  final List<int>? reportRateOptions;

  /// Live Hz from device; null = unknown.
  final int? reportRateHz;

  /// L5 [reportRateWireToLabel]; null until live GET.
  final String? reportRateLabel;

  // --- DPI (matrix: max, stages, rgb per stage) ---

  /// null = no DPI feature.
  final int? dpiMax;
  final int? dpiMin;
  final int? dpiStep;

  /// DPI step model: 'fixed' | 'tiered' | 'any' (from mouse catalog range).
  final String? dpiStepMode;

  /// Hardware max stages (e.g. 8).
  final int? dpiMaxLevels;

  /// How many stages product uses by default (e.g. 5 or 6).
  final int? dpiActiveLevelCount;

  /// 1-based default stage from product matrix.
  final int? dpiDefaultLevel;

  /// Default or live stage table; null = no DPI table yet.
  final List<DpiStageData>? dpiLevels;

  /// 1-based active stage for display (wire is 0-based); null = unknown.
  final int? dpiActiveIndex;

  /// Matrix "DPI RGB Customize".
  final bool dpiRgbPerStage;

  // --- Buttons ---

  /// null = no button mapping feature.
  final int? buttonCount;

  /// Button defs for remap UI; null if not present.
  final List<ButtonData>? buttons;

  /// Mouse tab action catalog (from L2 asset); null until packed.
  final List<ActionCatalogSectionData>? mouseActionCatalog;

  /// Keyboard tab action catalog (from L2 asset); null until packed.
  final List<ActionCatalogSectionData>? keyboardActionCatalog;

  /// Special tab action catalog (from L2 asset); null until packed.
  final List<ActionCatalogSectionData>? specialActionCatalog;

  // --- Sensor ---

  final String? sensorChip; // SG8925 / PAW3311 / PAW3395

  /// Product matrix "Sensor Feature". Grouped: false → hide both Ripple Control
  /// and Angle Snap; true → show both. Not the same as [hasAngleTune].
  final bool hasSensorTuning;

  /// Live values only meaningful when [hasSensorTuning] is true.
  final bool? rippleOn;
  final bool? angleSnapOn;

  /// Separate matrix row "Angle Tune Feature" (e.g. PRO only).
  final bool hasAngleTune;

  /// Per-mouse angle tune options (wire + label); null = no catalog.
  ///
  /// Discrete form only. TODO(range): the newer firmware / range sensors
  /// (e.g. 3950) use a continuous -30°..+30° instead of a lookup table;
  /// when the wire formula is confirmed this becomes the options list and
  /// the range is carried separately.
  final List<AngleTuneOption>? angleTuneOptions;

  /// Live angle tune enable flag (tri-state [6]); null = unknown.
  final bool? angleTuneOn;

  /// Live D4 angle tune wire value; null = unknown.
  final int? angleTune;

  /// L5 [angleTuneWireToLabel]; null if unknown / unmapped.
  final String? angleTuneLabel;

  final bool hasLod;

  /// LOD options (wire + mm); null/empty = no LOD.
  final List<LodOption>? lodOptions;

  /// Live LOD wire level (for later SET); prefer [lodLabel] for display.
  final int? lodMm;

  /// L5 [lodWireToLabel] e.g. `1mm`; null if unknown / unmapped.
  final String? lodLabel;

  /// D4 performance wire value; null = unknown.
  final bool hasPerformance;

  /// Performance options (wire ids); null/empty = no performance feature.
  ///
  /// TODO(mock): real values pending; catalog currently carries [0,1,2].
  final List<int>? performanceOptions;

  final int? performance;

  // --- Other ---

  final bool hasSleepTime;
  final List<OptionPair>? sleepOptions;

  /// Live sleep wire index (for later SET); prefer [sleepLabel] for display.
  final int? sleepSeconds;

  /// L5 [optionPairWireToLabel]; null if unknown / unmapped.
  final String? sleepLabel;

  final bool hasButtonDebounce;
  final List<OptionPair>? debounceOptions;

  /// Live debounce wire index (for later SET); prefer [debounceLabel] for display.
  final int? debounceMs;

  /// L5 [optionPairWireToLabel]; null if unknown / unmapped.
  final String? debounceLabel;

  final bool hasWheelInvert;
  final bool? wheelInvert;

  // --- RGB backlight (E2: enable, mode, bri, speed, R, G, B, sleep) ---

  final bool hasRgbBacklight;
  final List<RgbModeData>? rgbModes;
  final bool? rgbEnable;
  final int? rgbModeId;

  /// L5 [rgbModeToLabel]; null until live GET.
  final String? rgbModeLabel;

  final int? rgbBrightnessLevels;

  /// Live brightness level index (for later SET); prefer [rgbBrightnessLabel].
  final int? rgbBrightness;

  /// L5 [brightnessLevelToLabel]; null if unknown / unmapped.
  final String? rgbBrightnessLabel;

  final int? rgbSpeedLevels;

  /// Live speed level index (for later SET); prefer [rgbSpeedLabel].
  final int? rgbSpeed;

  /// L5 [speedLevelToLabel]; null if unknown / unmapped.
  final String? rgbSpeedLabel;

  final int? rgbR;
  final int? rgbG;
  final int? rgbB;

  /// Live RGB sleep wire index (for later SET); prefer [rgbSleepLabel].
  final int? rgbSleepTime;

  /// L5 [sleepIndexToLabel] for RGB sleep; null if unknown / unmapped.
  final String? rgbSleepLabel;

  const DeviceSettingsState({
    required this.devId,
    required this.displayName,
    required this.connectionMode,
    this.loading = false,
    this.error,
    this.decodeErrors = const <String>{},
    this.reportRateOptions,
    this.reportRateHz,
    this.reportRateLabel,
    this.dpiMax,
    this.dpiMin,
    this.dpiStep,
    this.dpiStepMode,
    this.dpiMaxLevels,
    this.dpiActiveLevelCount,
    this.dpiDefaultLevel,
    this.dpiLevels,
    this.dpiActiveIndex,
    this.dpiRgbPerStage = false,
    this.buttonCount,
    this.buttons,
    this.mouseActionCatalog,
    this.keyboardActionCatalog,
    this.specialActionCatalog,
    this.sensorChip,
    this.hasSensorTuning = false,
    this.hasAngleTune = false,
    this.angleTuneOptions,
    this.angleTuneOn,
    this.angleTune,
    this.angleTuneLabel,
    this.hasLod = false,
    this.lodOptions,
    this.lodMm,
    this.lodLabel,
    this.hasPerformance = false,
    this.performanceOptions,
    this.performance,
    this.rippleOn,
    this.angleSnapOn,
    this.hasSleepTime = false,
    this.sleepOptions,
    this.sleepSeconds,
    this.sleepLabel,
    this.hasButtonDebounce = false,
    this.debounceOptions,
    this.debounceMs,
    this.debounceLabel,
    this.hasWheelInvert = false,
    this.wheelInvert,
    this.hasRgbBacklight = false,
    this.rgbModes,
    this.rgbEnable,
    this.rgbModeId,
    this.rgbModeLabel,
    this.rgbBrightnessLevels,
    this.rgbBrightness,
    this.rgbBrightnessLabel,
    this.rgbSpeedLevels,
    this.rgbSpeed,
    this.rgbSpeedLabel,
    this.rgbR,
    this.rgbG,
    this.rgbB,
    this.rgbSleepTime,
    this.rgbSleepLabel,
  });

  DeviceSettingsState copyWith({
    String? devId,
    String? displayName,
    int? connectionMode,
    bool? loading,
    String? error,
    List<int>? reportRateOptions,
    int? reportRateHz,
    String? reportRateLabel,
    int? dpiMax,
    int? dpiMin,
    int? dpiStep,
    String? dpiStepMode,
    int? dpiMaxLevels,
    int? dpiActiveLevelCount,
    int? dpiDefaultLevel,
    List<DpiStageData>? dpiLevels,
    int? dpiActiveIndex,
    bool? dpiRgbPerStage,
    int? buttonCount,
    List<ButtonData>? buttons,
    List<ActionCatalogSectionData>? mouseActionCatalog,
    List<ActionCatalogSectionData>? keyboardActionCatalog,
    List<ActionCatalogSectionData>? specialActionCatalog,
    String? sensorChip,
    bool? hasSensorTuning,
    bool? hasAngleTune,
    List<AngleTuneOption>? angleTuneOptions,
    bool? angleTuneOn,
    int? angleTune,
    String? angleTuneLabel,
    bool? hasLod,
    List<LodOption>? lodOptions,
    int? lodMm,
    String? lodLabel,
    bool? hasPerformance,
    List<int>? performanceOptions,
    int? performance,
    bool? rippleOn,
    bool? angleSnapOn,
    bool? hasSleepTime,
    List<OptionPair>? sleepOptions,
    int? sleepSeconds,
    String? sleepLabel,
    bool? hasButtonDebounce,
    List<OptionPair>? debounceOptions,
    int? debounceMs,
    String? debounceLabel,
    bool? hasWheelInvert,
    bool? wheelInvert,
    bool? hasRgbBacklight,
    List<RgbModeData>? rgbModes,
    bool? rgbEnable,
    int? rgbModeId,
    String? rgbModeLabel,
    int? rgbBrightnessLevels,
    int? rgbBrightness,
    String? rgbBrightnessLabel,
    int? rgbSpeedLevels,
    int? rgbSpeed,
    String? rgbSpeedLabel,
    int? rgbR,
    int? rgbG,
    int? rgbB,
    int? rgbSleepTime,
    String? rgbSleepLabel,
    Set<String>? decodeErrors,
    bool clearError = false,
  }) {
    return DeviceSettingsState(
      devId: devId ?? this.devId,
      displayName: displayName ?? this.displayName,
      connectionMode: connectionMode ?? this.connectionMode,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      // why: clearError is the caller's "retry succeeded" signal; a stale
      // decode error must not outlive it and keep a good block locked.
      decodeErrors: clearError
          ? const <String>{}
          : (decodeErrors ?? this.decodeErrors),
      reportRateOptions: reportRateOptions ?? this.reportRateOptions,
      reportRateHz: reportRateHz ?? this.reportRateHz,
      reportRateLabel: reportRateLabel ?? this.reportRateLabel,
      dpiMax: dpiMax ?? this.dpiMax,
      dpiMin: dpiMin ?? this.dpiMin,
      dpiStep: dpiStep ?? this.dpiStep,
      dpiStepMode: dpiStepMode ?? this.dpiStepMode,
      dpiMaxLevels: dpiMaxLevels ?? this.dpiMaxLevels,
      dpiActiveLevelCount: dpiActiveLevelCount ?? this.dpiActiveLevelCount,
      dpiDefaultLevel: dpiDefaultLevel ?? this.dpiDefaultLevel,
      dpiLevels: dpiLevels ?? this.dpiLevels,
      dpiActiveIndex: dpiActiveIndex ?? this.dpiActiveIndex,
      dpiRgbPerStage: dpiRgbPerStage ?? this.dpiRgbPerStage,
      buttonCount: buttonCount ?? this.buttonCount,
      buttons: buttons ?? this.buttons,
      mouseActionCatalog: mouseActionCatalog ?? this.mouseActionCatalog,
      keyboardActionCatalog:
          keyboardActionCatalog ?? this.keyboardActionCatalog,
      specialActionCatalog: specialActionCatalog ?? this.specialActionCatalog,
      sensorChip: sensorChip ?? this.sensorChip,
      hasSensorTuning: hasSensorTuning ?? this.hasSensorTuning,
      hasAngleTune: hasAngleTune ?? this.hasAngleTune,
      angleTuneOptions: angleTuneOptions ?? this.angleTuneOptions,
      angleTuneOn: angleTuneOn ?? this.angleTuneOn,
      angleTune: angleTune ?? this.angleTune,
      angleTuneLabel: angleTuneLabel ?? this.angleTuneLabel,
      hasLod: hasLod ?? this.hasLod,
      lodOptions: lodOptions ?? this.lodOptions,
      lodMm: lodMm ?? this.lodMm,
      lodLabel: lodLabel ?? this.lodLabel,
      hasPerformance: hasPerformance ?? this.hasPerformance,
      performanceOptions: performanceOptions ?? this.performanceOptions,
      performance: performance ?? this.performance,
      rippleOn: rippleOn ?? this.rippleOn,
      angleSnapOn: angleSnapOn ?? this.angleSnapOn,
      hasSleepTime: hasSleepTime ?? this.hasSleepTime,
      sleepOptions: sleepOptions ?? this.sleepOptions,
      sleepSeconds: sleepSeconds ?? this.sleepSeconds,
      sleepLabel: sleepLabel ?? this.sleepLabel,
      hasButtonDebounce: hasButtonDebounce ?? this.hasButtonDebounce,
      debounceOptions: debounceOptions ?? this.debounceOptions,
      debounceMs: debounceMs ?? this.debounceMs,
      debounceLabel: debounceLabel ?? this.debounceLabel,
      hasWheelInvert: hasWheelInvert ?? this.hasWheelInvert,
      wheelInvert: wheelInvert ?? this.wheelInvert,
      hasRgbBacklight: hasRgbBacklight ?? this.hasRgbBacklight,
      rgbModes: rgbModes ?? this.rgbModes,
      rgbEnable: rgbEnable ?? this.rgbEnable,
      rgbModeId: rgbModeId ?? this.rgbModeId,
      rgbModeLabel: rgbModeLabel ?? this.rgbModeLabel,
      rgbBrightnessLevels: rgbBrightnessLevels ?? this.rgbBrightnessLevels,
      rgbBrightness: rgbBrightness ?? this.rgbBrightness,
      rgbBrightnessLabel: rgbBrightnessLabel ?? this.rgbBrightnessLabel,
      rgbSpeedLevels: rgbSpeedLevels ?? this.rgbSpeedLevels,
      rgbSpeed: rgbSpeed ?? this.rgbSpeed,
      rgbSpeedLabel: rgbSpeedLabel ?? this.rgbSpeedLabel,
      rgbR: rgbR ?? this.rgbR,
      rgbG: rgbG ?? this.rgbG,
      rgbB: rgbB ?? this.rgbB,
      rgbSleepTime: rgbSleepTime ?? this.rgbSleepTime,
      rgbSleepLabel: rgbSleepLabel ?? this.rgbSleepLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSettingsState &&
          runtimeType == other.runtimeType &&
          devId == other.devId &&
          displayName == other.displayName &&
          connectionMode == other.connectionMode &&
          loading == other.loading &&
          error == other.error &&
          _listEq(reportRateOptions, other.reportRateOptions) &&
          reportRateHz == other.reportRateHz &&
          reportRateLabel == other.reportRateLabel &&
          dpiMax == other.dpiMax &&
          dpiMin == other.dpiMin &&
          dpiStep == other.dpiStep &&
          dpiStepMode == other.dpiStepMode &&
          dpiMaxLevels == other.dpiMaxLevels &&
          dpiActiveLevelCount == other.dpiActiveLevelCount &&
          dpiDefaultLevel == other.dpiDefaultLevel &&
          _listEq(dpiLevels, other.dpiLevels) &&
          dpiActiveIndex == other.dpiActiveIndex &&
          dpiRgbPerStage == other.dpiRgbPerStage &&
          buttonCount == other.buttonCount &&
          _listEq(buttons, other.buttons) &&
          _listEq(mouseActionCatalog, other.mouseActionCatalog) &&
          _listEq(keyboardActionCatalog, other.keyboardActionCatalog) &&
          _listEq(specialActionCatalog, other.specialActionCatalog) &&
          sensorChip == other.sensorChip &&
          hasSensorTuning == other.hasSensorTuning &&
          hasAngleTune == other.hasAngleTune &&
          _listEq(angleTuneOptions, other.angleTuneOptions) &&
          angleTuneOn == other.angleTuneOn &&
          angleTune == other.angleTune &&
          angleTuneLabel == other.angleTuneLabel &&
          hasLod == other.hasLod &&
          _listEq(lodOptions, other.lodOptions) &&
          lodMm == other.lodMm &&
          lodLabel == other.lodLabel &&
          hasPerformance == other.hasPerformance &&
          _listEq(performanceOptions, other.performanceOptions) &&
          performance == other.performance &&
          rippleOn == other.rippleOn &&
          angleSnapOn == other.angleSnapOn &&
          hasSleepTime == other.hasSleepTime &&
          _listEq(sleepOptions, other.sleepOptions) &&
          sleepSeconds == other.sleepSeconds &&
          sleepLabel == other.sleepLabel &&
          hasButtonDebounce == other.hasButtonDebounce &&
          _listEq(debounceOptions, other.debounceOptions) &&
          debounceMs == other.debounceMs &&
          debounceLabel == other.debounceLabel &&
          hasWheelInvert == other.hasWheelInvert &&
          wheelInvert == other.wheelInvert &&
          hasRgbBacklight == other.hasRgbBacklight &&
          _listEq(rgbModes, other.rgbModes) &&
          rgbEnable == other.rgbEnable &&
          rgbModeId == other.rgbModeId &&
          rgbModeLabel == other.rgbModeLabel &&
          rgbBrightnessLevels == other.rgbBrightnessLevels &&
          rgbBrightness == other.rgbBrightness &&
          rgbBrightnessLabel == other.rgbBrightnessLabel &&
          rgbSpeedLevels == other.rgbSpeedLevels &&
          rgbSpeed == other.rgbSpeed &&
          rgbSpeedLabel == other.rgbSpeedLabel &&
          rgbR == other.rgbR &&
          rgbG == other.rgbG &&
          rgbB == other.rgbB &&
          rgbSleepTime == other.rgbSleepTime &&
          rgbSleepLabel == other.rgbSleepLabel;

  @override
  int get hashCode => Object.hashAll([
        devId,
        displayName,
        connectionMode,
        loading,
        error,
        Object.hashAll(reportRateOptions ?? const []),
        reportRateHz,
        reportRateLabel,
        dpiMax,
        dpiMin,
        dpiStep,
        dpiStepMode,
        dpiMaxLevels,
        dpiActiveLevelCount,
        dpiDefaultLevel,
        Object.hashAll(dpiLevels ?? const []),
        dpiActiveIndex,
        dpiRgbPerStage,
        buttonCount,
        Object.hashAll(buttons ?? const []),
        Object.hashAll(mouseActionCatalog ?? const []),
        Object.hashAll(keyboardActionCatalog ?? const []),
        Object.hashAll(specialActionCatalog ?? const []),
        sensorChip,
        hasSensorTuning,
        hasAngleTune,
        Object.hashAll(angleTuneOptions ?? const []),
        angleTuneOn,
        angleTune,
        angleTuneLabel,
        hasLod,
        Object.hashAll(lodOptions ?? const []),
        lodMm,
        lodLabel,
        hasPerformance,
        Object.hashAll(performanceOptions ?? const []),
        performance,
        rippleOn,
        angleSnapOn,
        hasSleepTime,
        Object.hashAll(sleepOptions ?? const []),
        sleepSeconds,
        sleepLabel,
        hasButtonDebounce,
        Object.hashAll(debounceOptions ?? const []),
        debounceMs,
        debounceLabel,
        hasWheelInvert,
        wheelInvert,
        hasRgbBacklight,
        Object.hashAll(rgbModes ?? const []),
        rgbEnable,
        rgbModeId,
        rgbModeLabel,
        rgbBrightnessLevels,
        rgbBrightness,
        rgbBrightnessLabel,
        rgbSpeedLevels,
        rgbSpeed,
        rgbSpeedLabel,
        rgbR,
        rgbG,
        rgbB,
        rgbSleepTime,
        rgbSleepLabel,
      ]);
}

/// One DPI stage row (data only). [value] = wire X; [y] = wire Y when known.
class DpiStageData {
  final int level; // 1-based
  final int value;
  final int? y;
  final String? color; // "#RRGGBB" when known

  const DpiStageData({
    required this.level,
    required this.value,
    this.y,
    this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DpiStageData &&
          level == other.level &&
          value == other.value &&
          y == other.y &&
          color == other.color;

  @override
  int get hashCode => Object.hash(level, value, y, color);
}

/// One action-catalog row for remap panel (domain paint data).
class ActionCatalogItemData {
  final String id;
  final String label;

  /// Optional UI role from L2 (e.g. `modifier`, `any_key`).
  final String? role;

  const ActionCatalogItemData({
    required this.id,
    required this.label,
    this.role,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionCatalogItemData &&
          id == other.id &&
          label == other.label &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, label, role);
}

/// One action-catalog section for remap panel.
class ActionCatalogSectionData {
  final String title;
  final List<ActionCatalogItemData> items;

  const ActionCatalogSectionData({required this.title, required this.items});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionCatalogSectionData &&
          title == other.title &&
          _listEq(items, other.items);

  @override
  int get hashCode => Object.hash(title, Object.hashAll(items));
}

/// One button def / live action (data only).
class ButtonData {
  final int id;
  final String labelKey;
  final bool remappable;
  final double? hotspotX;
  final double? hotspotY;
  final double? hotspotR;

  /// Display name for the physical button (set in L4; L3 must not use L5).
  final String? buttonLabel;

  /// Live mapping label from GET; null = unknown.
  final String? actionLabel;

  /// Live wire action + params (for echo on non-remappable reset slots).
  final int? action;
  final int? param1;
  final int? param2;
  final int? param3;

  const ButtonData({
    required this.id,
    required this.labelKey,
    required this.remappable,
    this.hotspotX,
    this.hotspotY,
    this.hotspotR,
    this.buttonLabel,
    this.actionLabel,
    this.action,
    this.param1,
    this.param2,
    this.param3,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ButtonData &&
          id == other.id &&
          labelKey == other.labelKey &&
          remappable == other.remappable &&
          hotspotX == other.hotspotX &&
          hotspotY == other.hotspotY &&
          hotspotR == other.hotspotR &&
          buttonLabel == other.buttonLabel &&
          actionLabel == other.actionLabel &&
          action == other.action &&
          param1 == other.param1 &&
          param2 == other.param2 &&
          param3 == other.param3;

  @override
  int get hashCode => Object.hash(
        id,
        labelKey,
        remappable,
        hotspotX,
        hotspotY,
        hotspotR,
        buttonLabel,
        actionLabel,
        action,
        param1,
        param2,
        param3,
      );
}

/// One RGB mode option (data only).
class RgbModeData {
  final int id;
  final String nameKey;
  final bool supportsColor;

  /// Human-readable label (L5 [rgbModeToLabel]); falls back to [nameKey] when
  /// null (e.g. hydrated from cache before capabilities pack ran).
  final String? label;

  const RgbModeData({
    required this.id,
    required this.nameKey,
    required this.supportsColor,
    this.label,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RgbModeData &&
          id == other.id &&
          nameKey == other.nameKey &&
          supportsColor == other.supportsColor &&
          label == other.label;

  @override
  int get hashCode => Object.hash(id, nameKey, supportsColor, label);
}

bool _listEq<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
