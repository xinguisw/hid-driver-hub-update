import 'dart:async';

import 'package:driver_hub/layer2_capabilities/action_catalog.dart';
import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer2_capabilities/sensor_profiles.dart';
import 'package:driver_hub/layer4_domain/device_repository.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/settings_capabilities_pack.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:flutter/foundation.dart';

/// L4: hydrate [DeviceSettingsState] from L2 blueprints + live GETs via [DeviceRepository].
///
/// Not discovery lifecycle (L1). Not UI (L3). Caller supplies a live repository.

/// Onboard config for settings (not at card load).
///
/// 1) Load product caps (L2) → presence + options on state.
/// 2) GET **all** config blocks (L5); translate known live fields.
/// 3) Overlay live values without turning off-matrix features on.
///
/// [onPartial] receives the caps-seeded state (still `loading: true`) before
/// hardware GETs so the canvas can mount with the correct blocks.
///
/// Handshake failure or [TimeoutException] on any GET →
/// [DeviceSettingsState.error] (caller should pop home). Other errors soft-fail.
Future<DeviceSettingsState> queryOnboardConfig(
  DeviceRepository session,
  DiscoveredCardState card, {
  void Function(DeviceSettingsState partial)? onPartial,
}) async {
  final name = card.displayName;
  var state = DeviceSettingsState(
    devId: card.devId,
    displayName: card.displayName,
    connectionMode: card.connectionMode,
    loading: true,
  );
  if (!session.isAlive) {
    return state.copyWith(loading: false, error: 'no session');
  }

  // --- L2 product matrix (show/hide + options); soft-fail if missing ---
  final caps = await _loadCapabilitiesForSession(session, card);
  final hasCaps = caps != null;
  if (hasCaps) {
    state = applyCapabilitiesToSettings(state, caps);
    debugPrint(
      '[settings] caps $name: devId=${caps.devId} '
      'reportRate=${state.reportRateOptions} '
      'sensorTuning=${state.hasSensorTuning} sleep=${state.hasSleepTime}',
    );
  } else {
    debugPrint('[settings] caps $name: none — UI falls back to live GETs');
  }
  // L2 action catalogs (Mouse / Keyboard / Special) — soft-fail per tab.
  state = await _packActionCatalogTab(state, name, 'mouse', (s, sections) {
    return s.copyWith(mouseActionCatalog: sections);
  });
  state = await _packActionCatalogTab(state, name, 'keyboard', (s, sections) {
    return s.copyWith(keyboardActionCatalog: sections);
  });
  state = await _packActionCatalogTab(state, name, 'special', (s, sections) {
    return s.copyWith(specialActionCatalog: sections);
  });
  // why: block presence is known here; live values arrive after the GETs below.
  onPartial?.call(state);

  final ok = await session.rehandshake();
  if (!ok || !session.isAlive) {
    debugPrint('[settings] $name: rehandshake failed');
    return state.copyWith(loading: false, error: 'rehandshake failed');
  }

  try {
    final buttons = await session.queryButtonMapping();
    if (buttons != null) {
      // Slot order is 1-based: Left, Right, Middle, Forward, Backward, DPI.
      const translate = TranslationCodec();
      final live = [
        for (var i = 0; i < buttons.buttons.length; i++)
          ButtonData(
            id: i + 1,
            labelKey: state.buttons != null && i < state.buttons!.length
                ? state.buttons![i].labelKey
                : 'button.${i + 1}',
            remappable: state.buttons != null && i < state.buttons!.length
                ? state.buttons![i].remappable
                : true,
            hotspotX: state.buttons != null && i < state.buttons!.length
                ? state.buttons![i].hotspotX
                : null,
            hotspotY: state.buttons != null && i < state.buttons!.length
                ? state.buttons![i].hotspotY
                : null,
            hotspotR: state.buttons != null && i < state.buttons!.length
                ? state.buttons![i].hotspotR
                : null,
            buttonLabel: state.buttons != null && i < state.buttons!.length
                ? (state.buttons![i].buttonLabel ??
                    translate.buttonIdToLabel(i + 1))
                : translate.buttonIdToLabel(i + 1),
            actionLabel: translate.buttonActionToLabel(
              action: buttons.buttons[i].action,
              param1: buttons.buttons[i].param1,
              param2: buttons.buttons[i].param2,
              param3: buttons.buttons[i].param3,
            ),
            // why: L4 reset echoes non-remappable slots without re-GET invent
            action: buttons.buttons[i].action,
            param1: buttons.buttons[i].param1,
            param2: buttons.buttons[i].param2,
            param3: buttons.buttons[i].param3,
          ),
      ];
      state = state.copyWith(
        buttonCount: live.length,
        buttons: live,
      );
      debugPrint(
        '[settings] config buttonMapping $name: '
        '${[
          for (var i = 0; i < buttons.buttons.length; i++)
            'B${i + 1}=0x${buttons.buttons[i].action.toRadixString(16)}'
        ].join(' ')}',
      );
    }
  } catch (e) {
    final fatal = _settingsLoadFatal(e, name, 'buttonMapping');
    if (fatal != null) {
      return state.copyWith(loading: false, error: fatal);
    }
  }

  // C2 active-stage bitmask (e.g. 0x1F = stages 0..4). Used to filter C4 table.
  int? dpiActiveMask;
  try {
    final info = await session.queryReportRateDpiInfo();
    if (info != null) {
      // L5 keeps wire; L4 packs display values via TranslationCodec.
      const translate = TranslationCodec();
      dpiActiveMask = info.dpiActiveLevel;
      final activeCount =
          translate.dpiActiveMaskToCount(info.dpiActiveLevel);
      final currentLevel =
          translate.dpiCurrentLevelWireToDisplay(info.dpiCurrentLevel);
      final hz = translate.reportRateWireToHz(info.reportRate);
      // Caps may have seeded 8 catalog stages; keep only active slots.
      final seeded = state.dpiLevels;
      final activeMask = info.dpiActiveLevel;
      final filteredSeed = seeded == null
          ? null
          : [
              for (var i = 0; i < seeded.length; i++)
                if (translate.dpiStageIndexActive(activeMask, i)) seeded[i],
            ];
      state = state.copyWith(
        reportRateHz: hz,
        reportRateLabel: translate.reportRateWireToLabel(info.reportRate),
        dpiActiveIndex: currentLevel,
        dpiActiveLevelCount: activeCount,
        dpiLevels: filteredSeed ?? state.dpiLevels,
      );
      debugPrint(
        '[settings] config reportRateDpi $name: '
        'rate wire=${info.reportRate}→${hz ?? '—'}Hz '
        'activeMask=0x${info.dpiActiveLevel.toRadixString(16)}→$activeCount '
        'currentLv wire=${info.dpiCurrentLevel}→$currentLevel',
      );
    }
  } catch (e) {
    final fatal = _settingsLoadFatal(e, name, 'reportRateDpi');
    if (fatal != null) {
      return state.copyWith(loading: false, error: fatal);
    }
  }

  List<DpiStageData>? dpiLevels = state.dpiLevels;
  try {
    final table = await session.queryDpiTable();
    if (table != null) {
      // Decode C4 stages with this device's sensor encoding profile.
      // Active mask (C2) selects which of the eight slots are shown.
      final sensorTable = _sensorEncodingTableFor(card);
      if (sensorTable == null) {
        throw StateError(
          'dpiTable: no sensor profile for $name '
          '(devId=${card.devId} mode=${card.connectionMode})',
        );
      }
      final enc = sensorTable.dpiEncoding;
      const translate = TranslationCodec();
      final decodedLevels = <DpiStageData>[];
      for (var i = 0; i < table.stages.length; i++) {
        if (dpiActiveMask != null &&
            !translate.dpiStageIndexActive(dpiActiveMask, i)) {
          continue;
        }
        final stage = table.stages[i];
        final decoded = translate.decodeDpiStageWire(
          b0: stage.x,
          b1: stage.y,
          bytesPerAxis: enc.bytesPerAxis,
          endian: enc.endian,
          independentXY: enc.independentXY,
          transform: enc.transform,
          factor: enc.factor,
          cpiMap: enc.cpiMap,
        );
        final wireWord = enc.bytesPerAxis == 1
            ? (stage.x & 0xFF)
            : translate.dpiAxisBytesToWire(
                [stage.x, stage.y],
                endian: enc.endian,
              );
        debugPrint(
          '[settings] dpi L${i + 1} bytes='
          '${stage.x.toRadixString(16).padLeft(2, '0')}'
          '${stage.y.toRadixString(16).padLeft(2, '0')} '
          'wire=0x${wireWord.toRadixString(16)} → ${decoded.value}',
        );
        final hwLevel = i + 1;
        String? seedColor;
        final seededColors = state.dpiLevels;
        if (seededColors != null) {
          for (final d in seededColors) {
            if (d.level == hwLevel) {
              seedColor = d.color;
              break;
            }
          }
        }
        decodedLevels.add(
          DpiStageData(
            level: hwLevel,
            value: decoded.value,
            y: decoded.y,
            color: seedColor,
          ),
        );
      }
      dpiLevels = decodedLevels;
      state = state.copyWith(dpiLevels: dpiLevels);
      debugPrint(
        '[settings] config dpiTable $name: stages=${table.stages.length} '
        'active=${decodedLevels.length} '
        'sensor=${sensorTable.chip}/${sensorTable.mode} '
        'enc=${enc.transform}/${enc.bytesPerAxis}b',
      );
    }
  } catch (e) {
    final fatal = _settingsLoadFatal(e, name, 'dpiTable');
    if (fatal != null) {
      return state.copyWith(loading: false, error: fatal);
    }
  }

  try {
    final rgb = await session.queryDpiRgb();
    if (rgb != null && dpiLevels != null) {
      // Colors only matter when product matrix allows per-stage RGB.
      // Map by hardware stage index (level - 1), not filtered list index.
      final useColors = !hasCaps || state.dpiRgbPerStage;
      final merged = <DpiStageData>[
        for (final d in dpiLevels)
          DpiStageData(
            level: d.level,
            value: d.value,
            y: d.y,
            color: () {
              if (!useColors) return d.color;
              final hi = d.level - 1;
              if (hi < 0 || hi >= rgb.stages.length) return d.color;
              final c = rgb.stages[hi];
              return _rgbHex(c.r, c.g, c.b);
            }(),
          ),
      ];
      state = state.copyWith(dpiLevels: merged);
      debugPrint('[settings] config dpiRgb $name: ok useColors=$useColors');
    }
  } catch (e) {
    final fatal = _settingsLoadFatal(e, name, 'dpiRgb');
    if (fatal != null) {
      return state.copyWith(loading: false, error: fatal);
    }
  }

  try {
    final sensor = await session.querySensorOther();
    if (sensor != null) {
      // Always GET; only surface fields allowed by caps (or all if no caps).
      // why: L5 owns wire→meaning; L4 only packs (tri-state, labels, wire ids).
      const translate = TranslationCodec();
      final showAll = !hasCaps;
      state = state.copyWith(
        rippleOn: (showAll || state.hasSensorTuning)
            ? translate.triStateWireToBool(sensor.rippleControl)
            : state.rippleOn,
        angleSnapOn: (showAll || state.hasSensorTuning)
            ? translate.triStateWireToBool(sensor.angleSnap)
            : state.angleSnapOn,
        lodMm: (showAll || state.hasLod) ? sensor.lod : state.lodMm,
        lodLabel: (showAll || state.hasLod)
            ? translate.lodWireToLabel(sensor.lod)
            : state.lodLabel,
        angleTune:
            (showAll || state.hasAngleTune) ? sensor.angleTune : state.angleTune,
        angleTuneLabel: (showAll || state.hasAngleTune)
            ? translate.angleTuneWireToLabel(sensor.angleTune)
            : state.angleTuneLabel,
        performance: (showAll || state.hasPerformance)
            ? sensor.performance
            : state.performance,
        debounceMs: (showAll || state.hasButtonDebounce)
            ? sensor.debounceTime
            : state.debounceMs,
        debounceLabel: (showAll || state.hasButtonDebounce)
            ? translate.debounceIndexToLabel(sensor.debounceTime)
            : state.debounceLabel,
        sleepSeconds: (showAll || state.hasSleepTime)
            ? sensor.sleepTime
            : state.sleepSeconds,
        sleepLabel: (showAll || state.hasSleepTime)
            ? translate.sleepIndexToLabel(sensor.sleepTime)
            : state.sleepLabel,
        wheelInvert: (showAll || state.hasWheelInvert)
            ? translate.triStateWireToBool(sensor.wheelDirection)
            : state.wheelInvert,
      );
      if (showAll) {
        // No matrix: keep previous "show whatever GET returned" behavior.
        state = state.copyWith(
          hasSensorTuning: true,
          hasLod: true,
          hasAngleTune: true,
          hasPerformance: true,
          hasButtonDebounce: true,
          hasSleepTime: true,
          hasWheelInvert: true,
        );
      }
      debugPrint('[settings] config sensorOther $name: $sensor');
    }
  } catch (e) {
    final fatal = _settingsLoadFatal(e, name, 'sensorOther');
    if (fatal != null) {
      return state.copyWith(loading: false, error: fatal);
    }
  }

  try {
    final light = await session.queryRgbBacklight();
    if (light != null) {
      final showRgb = !hasCaps || state.hasRgbBacklight;
      if (showRgb) {
        // why: L5 labels + tri-state; wire ids kept for later SET.
        const translate = TranslationCodec();
        state = state.copyWith(
          hasRgbBacklight: hasCaps ? state.hasRgbBacklight : true,
          rgbEnable: translate.triStateWireToBool(light.enable),
          rgbModeId: light.mode,
          rgbModeLabel: translate.rgbModeToLabel(light.mode),
          rgbBrightness: light.brightness,
          rgbBrightnessLabel:
              translate.brightnessLevelToLabel(light.brightness),
          rgbSpeed: light.speed,
          rgbSpeedLabel: translate.speedLevelToLabel(light.speed),
          rgbR: light.r,
          rgbG: light.g,
          rgbB: light.b,
          rgbSleepTime: light.sleepTime,
          rgbSleepLabel: translate.sleepIndexToLabel(light.sleepTime),
        );
      }
      debugPrint(
        '[settings] config rgbBacklight $name: show=$showRgb $light',
      );
    }
  } catch (e) {
    final fatal = _settingsLoadFatal(e, name, 'rgbBacklight');
    if (fatal != null) {
      return state.copyWith(loading: false, error: fatal);
    }
  }

  return state.copyWith(loading: false);
}

/// Encoding table for this card’s sensor (after [SensorProfiles.load]).
EncodingTable? _sensorEncodingTableFor(DiscoveredCardState card) {
  final profile =
      SensorProfiles.forDevice(card.devId);
  if (profile == null) return null;
  return SensorProfiles.table(profile.table);
}

/// Load per-model caps + sensor tables. Null if asset missing / unknown devId.
Future<DeviceCapabilities?> _loadCapabilitiesForSession(
  DeviceRepository session,
  DiscoveredCardState card,
) async {
  final model = session.card.displayName;
  try {
    await DeviceCapabilityStore.load(model);
  } catch (e) {
    debugPrint(
      '[settings] caps load failed for model=$model: $e',
    );
  }
  try {
    await SensorProfiles.load();
  } catch (e) {
    debugPrint('[settings] sensor profiles load failed: $e');
  }
  return DeviceCapabilityStore.forDevice(card.devId);
}

/// Timeout → error string for [DeviceSettingsState.error]; other errors soft-fail (null).
String? _settingsLoadFatal(Object e, String name, String label) {
  debugPrint('[settings] config $label $name FAILED: $e');
  if (e is TimeoutException) {
    return 'timeout';
  }
  return null;
}

String _rgbHex(int r, int g, int b) {
  String h(int v) => v.clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${h(r)}${h(g)}${h(b)}'.toUpperCase();
}

Future<DeviceSettingsState> _packActionCatalogTab(
  DeviceSettingsState state,
  String name,
  String tab,
  DeviceSettingsState Function(
    DeviceSettingsState,
    List<ActionCatalogSectionData>,
  ) apply,
) async {
  try {
    final loaded = await ActionCatalogStore.load(tab);
    final sections = [
      for (final s in loaded.sections)
        ActionCatalogSectionData(
          title: s.title,
          items: [
            for (final i in s.items)
              ActionCatalogItemData(id: i.id, label: i.label, role: i.role),
          ],
        ),
    ];
    debugPrint(
      '[settings] actionCatalog $tab $name: ${sections.length} sections',
    );
    return apply(state, sections);
  } catch (e) {
    debugPrint('[settings] actionCatalog $tab $name: soft-fail $e');
    return state;
  }
}

