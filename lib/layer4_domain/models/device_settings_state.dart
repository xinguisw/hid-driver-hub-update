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

  /// Live D4 angle tune wire value; null = unknown.
  final int? angleTune;

  /// L5 [angleTuneWireToLabel]; null if unknown / unmapped.
  final String? angleTuneLabel;

  final bool hasLod;

  /// LOD options in mm; null/empty = no LOD.
  final List<int>? lodOptionsMm;

  /// Live LOD wire level (for later SET); prefer [lodLabel] for display.
  final int? lodMm;

  /// L5 [lodWireToLabel] e.g. `1mm`; null if unknown / unmapped.
  final String? lodLabel;

  /// D4 performance wire value; null = unknown.
  final bool hasPerformance;
  final int? performance;

  // --- Other ---

  final bool hasSleepTime;
  final List<int>? sleepOptionsSeconds;

  /// Live sleep wire index (for later SET); prefer [sleepLabel] for display.
  final int? sleepSeconds;

  /// L5 [sleepIndexToLabel]; null if unknown / unmapped.
  final String? sleepLabel;

  final bool hasButtonDebounce;
  final List<int>? debounceOptionsMs;

  /// Live debounce wire index (for later SET); prefer [debounceLabel] for display.
  final int? debounceMs;

  /// L5 [debounceIndexToLabel]; null if unknown / unmapped.
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
    this.reportRateOptions,
    this.reportRateHz,
    this.reportRateLabel,
    this.dpiMax,
    this.dpiMin,
    this.dpiStep,
    this.dpiMaxLevels,
    this.dpiActiveLevelCount,
    this.dpiDefaultLevel,
    this.dpiLevels,
    this.dpiActiveIndex,
    this.dpiRgbPerStage = false,
    this.buttonCount,
    this.buttons,
    this.mouseActionCatalog,
    this.sensorChip,
    this.hasSensorTuning = false,
    this.hasAngleTune = false,
    this.angleTune,
    this.angleTuneLabel,
    this.hasLod = false,
    this.lodOptionsMm,
    this.lodMm,
    this.lodLabel,
    this.hasPerformance = false,
    this.performance,
    this.rippleOn,
    this.angleSnapOn,
    this.hasSleepTime = false,
    this.sleepOptionsSeconds,
    this.sleepSeconds,
    this.sleepLabel,
    this.hasButtonDebounce = false,
    this.debounceOptionsMs,
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
    int? dpiMaxLevels,
    int? dpiActiveLevelCount,
    int? dpiDefaultLevel,
    List<DpiStageData>? dpiLevels,
    int? dpiActiveIndex,
    bool? dpiRgbPerStage,
    int? buttonCount,
    List<ButtonData>? buttons,
    List<ActionCatalogSectionData>? mouseActionCatalog,
    String? sensorChip,
    bool? hasSensorTuning,
    bool? hasAngleTune,
    int? angleTune,
    String? angleTuneLabel,
    bool? hasLod,
    List<int>? lodOptionsMm,
    int? lodMm,
    String? lodLabel,
    bool? hasPerformance,
    int? performance,
    bool? rippleOn,
    bool? angleSnapOn,
    bool? hasSleepTime,
    List<int>? sleepOptionsSeconds,
    int? sleepSeconds,
    String? sleepLabel,
    bool? hasButtonDebounce,
    List<int>? debounceOptionsMs,
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
    bool clearError = false,
  }) {
    return DeviceSettingsState(
      devId: devId ?? this.devId,
      displayName: displayName ?? this.displayName,
      connectionMode: connectionMode ?? this.connectionMode,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      reportRateOptions: reportRateOptions ?? this.reportRateOptions,
      reportRateHz: reportRateHz ?? this.reportRateHz,
      reportRateLabel: reportRateLabel ?? this.reportRateLabel,
      dpiMax: dpiMax ?? this.dpiMax,
      dpiMin: dpiMin ?? this.dpiMin,
      dpiStep: dpiStep ?? this.dpiStep,
      dpiMaxLevels: dpiMaxLevels ?? this.dpiMaxLevels,
      dpiActiveLevelCount: dpiActiveLevelCount ?? this.dpiActiveLevelCount,
      dpiDefaultLevel: dpiDefaultLevel ?? this.dpiDefaultLevel,
      dpiLevels: dpiLevels ?? this.dpiLevels,
      dpiActiveIndex: dpiActiveIndex ?? this.dpiActiveIndex,
      dpiRgbPerStage: dpiRgbPerStage ?? this.dpiRgbPerStage,
      buttonCount: buttonCount ?? this.buttonCount,
      buttons: buttons ?? this.buttons,
      mouseActionCatalog: mouseActionCatalog ?? this.mouseActionCatalog,
      sensorChip: sensorChip ?? this.sensorChip,
      hasSensorTuning: hasSensorTuning ?? this.hasSensorTuning,
      hasAngleTune: hasAngleTune ?? this.hasAngleTune,
      angleTune: angleTune ?? this.angleTune,
      angleTuneLabel: angleTuneLabel ?? this.angleTuneLabel,
      hasLod: hasLod ?? this.hasLod,
      lodOptionsMm: lodOptionsMm ?? this.lodOptionsMm,
      lodMm: lodMm ?? this.lodMm,
      lodLabel: lodLabel ?? this.lodLabel,
      hasPerformance: hasPerformance ?? this.hasPerformance,
      performance: performance ?? this.performance,
      rippleOn: rippleOn ?? this.rippleOn,
      angleSnapOn: angleSnapOn ?? this.angleSnapOn,
      hasSleepTime: hasSleepTime ?? this.hasSleepTime,
      sleepOptionsSeconds: sleepOptionsSeconds ?? this.sleepOptionsSeconds,
      sleepSeconds: sleepSeconds ?? this.sleepSeconds,
      sleepLabel: sleepLabel ?? this.sleepLabel,
      hasButtonDebounce: hasButtonDebounce ?? this.hasButtonDebounce,
      debounceOptionsMs: debounceOptionsMs ?? this.debounceOptionsMs,
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
          dpiMaxLevels == other.dpiMaxLevels &&
          dpiActiveLevelCount == other.dpiActiveLevelCount &&
          dpiDefaultLevel == other.dpiDefaultLevel &&
          _listEq(dpiLevels, other.dpiLevels) &&
          dpiActiveIndex == other.dpiActiveIndex &&
          dpiRgbPerStage == other.dpiRgbPerStage &&
          buttonCount == other.buttonCount &&
          _listEq(buttons, other.buttons) &&
          _listEq(mouseActionCatalog, other.mouseActionCatalog) &&
          sensorChip == other.sensorChip &&
          hasSensorTuning == other.hasSensorTuning &&
          hasAngleTune == other.hasAngleTune &&
          angleTune == other.angleTune &&
          angleTuneLabel == other.angleTuneLabel &&
          hasLod == other.hasLod &&
          _listEq(lodOptionsMm, other.lodOptionsMm) &&
          lodMm == other.lodMm &&
          lodLabel == other.lodLabel &&
          hasPerformance == other.hasPerformance &&
          performance == other.performance &&
          rippleOn == other.rippleOn &&
          angleSnapOn == other.angleSnapOn &&
          hasSleepTime == other.hasSleepTime &&
          _listEq(sleepOptionsSeconds, other.sleepOptionsSeconds) &&
          sleepSeconds == other.sleepSeconds &&
          sleepLabel == other.sleepLabel &&
          hasButtonDebounce == other.hasButtonDebounce &&
          _listEq(debounceOptionsMs, other.debounceOptionsMs) &&
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
        dpiMaxLevels,
        dpiActiveLevelCount,
        dpiDefaultLevel,
        Object.hashAll(dpiLevels ?? const []),
        dpiActiveIndex,
        dpiRgbPerStage,
        buttonCount,
        Object.hashAll(buttons ?? const []),
        Object.hashAll(mouseActionCatalog ?? const []),
        sensorChip,
        hasSensorTuning,
        hasAngleTune,
        angleTune,
        angleTuneLabel,
        hasLod,
        Object.hashAll(lodOptionsMm ?? const []),
        lodMm,
        lodLabel,
        hasPerformance,
        performance,
        rippleOn,
        angleSnapOn,
        hasSleepTime,
        Object.hashAll(sleepOptionsSeconds ?? const []),
        sleepSeconds,
        sleepLabel,
        hasButtonDebounce,
        Object.hashAll(debounceOptionsMs ?? const []),
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

  const ActionCatalogItemData({required this.id, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionCatalogItemData && id == other.id && label == other.label;

  @override
  int get hashCode => Object.hash(id, label);
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

  const RgbModeData({
    required this.id,
    required this.nameKey,
    required this.supportsColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RgbModeData &&
          id == other.id &&
          nameKey == other.nameKey &&
          supportsColor == other.supportsColor;

  @override
  int get hashCode => Object.hash(id, nameKey, supportsColor);
}

bool _listEq<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
