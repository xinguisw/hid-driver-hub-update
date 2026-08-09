import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_backlight_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_button_mapping_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_device_setting_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_left_sidebar.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_macro_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_mouse_canvas.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_parameter_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_performance_panel.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Per-device hub shell after card tap on home.
///
/// L3 only: dispatch BLoC events + paint [displaySettings]. No L1 session,
/// no SET, no codec (manager L3 + SDRD FR-OPS).
class HubLandingScreen extends StatefulWidget {
  const HubLandingScreen({super.key, required this.card, required this.scope});

  final DiscoveredCardState card;
  final DeviceScope scope;

  @override
  State<HubLandingScreen> createState() => _HubLandingScreenState();
}

class _HubLandingScreenState extends State<HubLandingScreen> {
  int _selectedIndex = 0;
  int? _selectedButtonId;
  int? _selectedDpiLevel;
  late final DeviceSettingsBloc _settingsBloc;

  static const int _buttonMappingIndex = 0;
  static const int _macroIndex = 1;
  static const int _performanceIndex = 2;
  static const int _parameterIndex = 3;
  static const int _backlightIndex = 4;
  static const int _deviceSettingIndex = 6;

  @override
  void initState() {
    super.initState();
    // why: Scope owns commit hook (L1->L5); L3 never sees sessions
    _settingsBloc = widget.scope.createSettingsBloc(
      widget.card,
      onSaveCompleted: () {
        // Dismiss sidebar after successful save
        if (mounted) {
          setState(() => _selectedButtonId = null);
        }
      },
    );
    final cached = widget.scope.settingsFor(widget.card);
    if (cached != null) {
      _settingsBloc.add(DeviceSettingsHydrated(cached));
    }
    widget.scope.cards.addListener(_onCardsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnboardConfig());
  }

  @override
  void dispose() {
    widget.scope.cards.removeListener(_onCardsChanged);
    _settingsBloc.close();
    super.dispose();
  }

  void _onCardsChanged() {
    if (!mounted) return;
    if (!widget.scope.isCardConnected(widget.card)) {
      debugPrint('[hub] ${widget.card.displayName}: disconnected - pop');
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  Future<void> _loadOnboardConfig() async {
    if (!widget.scope.isCardConnected(widget.card)) {
      debugPrint('[hub] ${widget.card.displayName}: no live session');
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    debugPrint('[hub] ${widget.card.displayName}: loading onboard config...');
    final packed = await widget.scope.loadOnboardSettings(widget.card);
    if (!mounted) return;
    if (!widget.scope.isCardConnected(widget.card) || packed.error != null) {
      debugPrint(
        '[hub] ${widget.card.displayName}: load failed '
        '(${packed.error ?? 'no session'}) - pop home',
      );
      Navigator.of(context).maybePop();
      return;
    }
    _settingsBloc.add(DeviceSettingsHydrated(packed));
    debugPrint('[hub] ${widget.card.displayName}: onboard config done');
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.scope.resolveCard(widget.card);
    return BlocProvider<DeviceSettingsBloc>.value(
      value: _settingsBloc,
      child: BlocListener<DeviceSettingsBloc, DeviceSettingsViewState>(
        listenWhen: (prev, next) =>
            prev.synced != next.synced &&
            next.synced != null &&
            !next.isDirty &&
            next.lastError == null,
        listener: (context, state) {
          final s = state.synced;
          if (s != null) widget.scope.putSettings(widget.card, s);
        },
        child: Scaffold(
          body: Row(
            children: [
              HubLeftSidebar(
                card: selected,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  // FR-OPS-005: dirty sweep when navigating away from button mapping
                  if (_selectedIndex == _buttonMappingIndex &&
                      index != _buttonMappingIndex) {
                    _settingsBloc.add(
                      const DeviceSettingsNavigationRequested(),
                    );
                  }
                  setState(() {
                    _selectedIndex = index;
                    if (index != _buttonMappingIndex) {
                      _selectedButtonId = null;
                    }
                  });
                },
                onDeviceTap: () => Navigator.of(context).maybePop(),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              if (_selectedIndex == _buttonMappingIndex)
                Expanded(
                  child: BlocBuilder<DeviceSettingsBloc, DeviceSettingsViewState>(
                    buildWhen: (p, n) =>
                        p.displaySettings != n.displaySettings ||
                        p.isDirty != n.isDirty ||
                        p.committing != n.committing ||
                        p.lastError != n.lastError,
                    builder: (context, view) {
                      final display = view.displaySettings;
                      final buttons = display?.buttons ?? const [];
                      final bloc = context.read<DeviceSettingsBloc>();
                      return Row(
                        children: [
                          Expanded(
                            child: HubMouseCanvas(
                              imageLarge: selected.imageLarge,
                              buttons: buttons,
                              selectedButtonId: _selectedButtonId,
                              isDirty: view.isDirty,
                              committing: view.committing,
                              onButtonSelected: (id) {
                                setState(() => _selectedButtonId = id);
                              },
                              onResetToDefault: () {
                                debugPrint(
                                  '[hub] ${widget.card.displayName}: '
                                  'dispatch reset',
                                );
                                bloc.add(
                                  const DeviceSettingsResetButtonMappingRequested(),
                                );
                              },
                              onSave: () {
                                debugPrint(
                                  '[hub] ${widget.card.displayName}: '
                                  'dispatch save',
                                );
                                bloc.add(const DeviceSettingsSaveRequested());
                              },
                              onCancel: () {
                                debugPrint(
                                  '[hub] ${widget.card.displayName}: '
                                  'dispatch cancel',
                                );
                                bloc.add(const DeviceSettingsCancelRequested());
                              },
                            ),
                          ),
                          if (_selectedButtonId != null) ...[
                            const VerticalDivider(thickness: 1, width: 1),
                            HubButtonMappingPanel(
                              selectedButtonId: _selectedButtonId,
                              mouseActionCatalog: display?.mouseActionCatalog,
                              keyboardActionCatalog:
                                  display?.keyboardActionCatalog,
                              specialActionCatalog:
                                  display?.specialActionCatalog,
                              onActionSelected: (catalogId) {
                                _settingsBloc.add(
                                  DeviceSettingsButtonMappingSlotRequested(
                                    buttonId: _selectedButtonId!,
                                    catalogId: catalogId,
                                  ),
                                );
                              },
                              onComboSelected: (modifierIds, keyChar) {
                                _settingsBloc.add(
                                  DeviceSettingsSpecialComboRequested(
                                    buttonId: _selectedButtonId!,
                                    modifierIds: modifierIds,
                                    keyChar: keyChar,
                                  ),
                                );
                              },
                              macroSlots: widget.scope.macrosFor(widget.card),
                              onMacroSelected: (macroSlot) {
                                _settingsBloc.add(
                                  DeviceSettingsMacroMappingRequested(
                                    buttonId: _selectedButtonId!,
                                    macroSlot: macroSlot,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                )
              else if (_selectedIndex == _macroIndex)
                Expanded(
                  child: HubMacroPanel(
                    scope: widget.scope,
                    card: widget.card,
                    onChanged: () => setState(() {}),
                  ),
                )
              else if (_selectedIndex == _performanceIndex)
                Expanded(
                  child: BlocBuilder<DeviceSettingsBloc, DeviceSettingsViewState>(
                    buildWhen: (p, n) =>
                        p.displaySettings != n.displaySettings ||
                        p.reportRateStaging != n.reportRateStaging ||
                        p.dpiCurrentLevelStaging != n.dpiCurrentLevelStaging ||
                        p.dpiValueStaging != n.dpiValueStaging ||
                        p.dpiStageAddStaging != n.dpiStageAddStaging ||
                        p.dpiStageRemoveLevelStaging !=
                            n.dpiStageRemoveLevelStaging ||
                        p.dpiStageLevelsStaging != n.dpiStageLevelsStaging ||
                        p.isDirty != n.isDirty ||
                        p.committing != n.committing ||
                        p.lastError != n.lastError,
                    builder: (context, view) {
                      final display = view.displaySettings;
                      final bloc = context.read<DeviceSettingsBloc>();
                      return Column(
                        children: [
                          Expanded(
                            child: HubPerformancePanel(
                              // why: staged add/remove level list paints the
                              // rearranged containers live before Save.
                              dpiStages:
                                  view.dpiStageLevelsStaging ??
                                  display?.dpiLevels,
                              // why: highlight the user's UI selection; fall
                              // back to the device's active level initially.
                              dpiCurrentLevel:
                                  _selectedDpiLevel ?? display?.dpiActiveIndex,
                              dpiCurrentLevelStaging:
                                  view.dpiCurrentLevelStaging,
                              onDpiLevelSelected: (level) {
                                setState(() => _selectedDpiLevel = level);
                                bloc.add(
                                  DeviceSettingsDpiLevelRequested(level: level),
                                );
                              },
                              dpiMin: display?.dpiMin,
                              dpiMax: display?.dpiMax,
                              dpiStep: display?.dpiStep,
                              dpiValueStaging: view.dpiValueStaging,
                              onDpiValueChanged: (pair) {
                                bloc.add(
                                  DeviceSettingsDpiValueRequested(
                                    level: pair.level,
                                    value: pair.value,
                                  ),
                                );
                              },
                              dpiActiveLevelCount: display?.dpiActiveLevelCount,
                              dpiMaxLevels: display?.dpiMaxLevels,
                              onDpiStageAdd: () {
                                bloc.add(
                                  const DeviceSettingsDpiStageAddRequested(),
                                );
                              },
                              // why: `x` only removes the user's clicked
                              // level; disabled until a level is selected.
                              dpiRemoveEnabled: _selectedDpiLevel != null,
                              onDpiStageRemove: () {
                                final level = _selectedDpiLevel;
                                if (level != null) {
                                  bloc.add(
                                    DeviceSettingsDpiStageRemoveRequested(
                                      level: level,
                                    ),
                                  );
                                }
                              },
                              reportRateOptions: display?.reportRateOptions,
                              reportRateHz: display?.reportRateHz,
                              reportRateStaging: view.reportRateStaging,
                              onReportRateChanged: (hz) {
                                bloc.add(
                                  DeviceSettingsReportRateRequested(hz: hz),
                                );
                              },
                            ),
                          ),
                          _PerformanceActionBar(
                            isDirty: view.isDirty,
                            committing: view.committing,
                            onReset: () {
                              debugPrint(
                                '[hub] ${widget.card.displayName}: '
                                'dispatch reset DPI configuration',
                              );
                              setState(() => _selectedDpiLevel = null);
                              bloc.add(
                                const DeviceSettingsResetDpiConfigurationRequested(),
                              );
                            },
                            onSave: () {
                              final hasDpiValueStaging =
                                  view.dpiValueStaging != null &&
                                  view.dpiValueStaging!.isNotEmpty;
                              final hasDpiStageStaging =
                                  view.dpiStageAddStaging ||
                                  view.dpiStageRemoveLevelStaging != null;
                              if (view.reportRateStaging != null ||
                                  view.dpiCurrentLevelStaging != null ||
                                  hasDpiValueStaging ||
                                  hasDpiStageStaging) {
                                bloc.add(
                                  const DeviceSettingsSaveDpiConfigurationRequested(),
                                );
                              }
                            },
                            onCancel: () {
                              bloc.add(const DeviceSettingsCancelRequested());
                            },
                          ),
                        ],
                      );
                    },
                  ),
                )
              else if (_selectedIndex == _parameterIndex)
                Expanded(
                  child: BlocBuilder<DeviceSettingsBloc, DeviceSettingsViewState>(
                    buildWhen: (p, n) =>
                        p.synced != n.synced ||
                        p.rippleControlStaging != n.rippleControlStaging ||
                        p.angleSnapStaging != n.angleSnapStaging ||
                        p.angleTuneStaging != n.angleTuneStaging ||
                        p.angleTuneLabelStaging != n.angleTuneLabelStaging ||
                        p.angleTuneEnabledStaging !=
                            n.angleTuneEnabledStaging ||
                        p.lodStaging != n.lodStaging ||
                        p.performanceStaging != n.performanceStaging ||
                        p.debounceStaging != n.debounceStaging ||
                        p.sleepStaging != n.sleepStaging ||
                        p.wheelInvertStaging != n.wheelInvertStaging ||
                        p.isDirty != n.isDirty ||
                        p.committing != n.committing ||
                        p.lastError != n.lastError,
                    builder: (context, view) {
                      final synced = view.synced;
                      final bloc = context.read<DeviceSettingsBloc>();
                      return Column(
                        children: [
                          Expanded(
                            child: HubParameterPanel(
                              hasSensorTuning: synced?.hasSensorTuning ?? false,
                              hasLod: synced?.hasLod ?? false,
                              hasAngleTune: synced?.hasAngleTune ?? false,
                              hasPerformance: synced?.hasPerformance ?? false,
                              hasButtonDebounce:
                                  synced?.hasButtonDebounce ?? false,
                              hasWheelInvert: synced?.hasWheelInvert ?? false,
                              hasSleepTime: synced?.hasSleepTime ?? false,
                              lodOptions: synced?.lodOptions,
                              buttonDebounceOptions: synced?.debounceOptions,
                              sleepTimeOptions: synced?.sleepOptions,
                              rippleOn: synced?.rippleOn,
                              rippleStaging: view.rippleControlStaging,
                              angleSnapOn: synced?.angleSnapOn,
                              angleSnapStaging: view.angleSnapStaging,
                              angleTuneOn:
                                  view.angleTuneEnabledStaging ??
                                  synced?.angleTuneOn ??
                                  false,
                              // why: staged label when dirty, else live
                              // synced label (value always visible even
                              // when toggled off).
                              angleTuneLabel:
                                  view.angleTuneLabelStaging ??
                                  synced?.angleTuneLabel ??
                                  '0°',
                              // why: staging paints ahead of synced so the
                              // radio follows the tap.
                              lodMm: view.lodStaging ?? synced?.lodMm,
                              performance:
                                  view.performanceStaging ??
                                  synced?.performance,
                              debounceMs:
                                  view.debounceStaging ?? synced?.debounceMs,
                              sleepSeconds:
                                  view.sleepStaging ?? synced?.sleepSeconds,
                              wheelInvert:
                                  view.wheelInvertStaging ??
                                  synced?.wheelInvert,
                              onDebounceChanged: (wire) {
                                bloc.add(
                                  DeviceSettingsButtonDebounceRequested(
                                    wire: wire,
                                  ),
                                );
                              },
                              onSleepChanged: (wire) {
                                bloc.add(
                                  DeviceSettingsSleepTimeRequested(wire: wire),
                                );
                              },
                              onWheelInvertChanged: (invert) {
                                bloc.add(
                                  DeviceSettingsWheelInvertRequested(
                                    invert: invert,
                                  ),
                                );
                              },
                              onLodChanged: (wire) {
                                bloc.add(
                                  DeviceSettingsLodRequested(wire: wire),
                                );
                              },
                              onPerformanceChanged: (wire) {
                                bloc.add(
                                  DeviceSettingsPerformanceRequested(
                                    wire: wire,
                                  ),
                                );
                              },
                              onRippleChanged: (on) {
                                bloc.add(
                                  DeviceSettingsRippleControlRequested(
                                    enabled: on,
                                  ),
                                );
                              },
                              onAngleSnapChanged: (on) {
                                bloc.add(
                                  DeviceSettingsAngleSnapRequested(enabled: on),
                                );
                              },
                              onAngleTuneToggled: (on) {
                                bloc.add(
                                  DeviceSettingsAngleTuneToggled(enabled: on),
                                );
                              },
                              onAngleTuneDecrement: () {
                                final current =
                                    view.angleTuneStaging ??
                                    (synced?.angleTune ?? 0);
                                final options =
                                    synced?.angleTuneOptions ??
                                    const <AngleTuneOption>[];
                                final idx = options.indexWhere(
                                  (o) => o.wire == current,
                                );
                                if (idx > 0) {
                                  bloc.add(
                                    DeviceSettingsAngleTuneValueChanged(
                                      wireValue: options[idx - 1].wire,
                                    ),
                                  );
                                }
                              },
                              onAngleTuneIncrement: () {
                                final current =
                                    view.angleTuneStaging ??
                                    (synced?.angleTune ?? 0);
                                final options =
                                    synced?.angleTuneOptions ??
                                    const <AngleTuneOption>[];
                                final idx = options.indexWhere(
                                  (o) => o.wire == current,
                                );
                                if (idx >= 0 && idx < options.length - 1) {
                                  bloc.add(
                                    DeviceSettingsAngleTuneValueChanged(
                                      wireValue: options[idx + 1].wire,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          _ParameterActionBar(
                            isDirty: view.isDirty,
                            committing: view.committing,
                            onSave: () {
                              if (view.rippleControlStaging != null ||
                                  view.angleSnapStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSaveSensorTuningRequested(),
                                );
                              } else if (view.angleTuneStaging != null ||
                                  view.angleTuneEnabledStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSaveAngleTuneRequested(),
                                );
                              } else if (view.lodStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSaveLodRequested(),
                                );
                              } else if (view.performanceStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSavePerformanceRequested(),
                                );
                              } else if (view.debounceStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSaveButtonDebounceRequested(),
                                );
                              } else if (view.sleepStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSaveSleepTimeRequested(),
                                );
                              } else if (view.wheelInvertStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSaveWheelInvertRequested(),
                                );
                              }
                            },
                            onCancel: () {
                              bloc.add(const DeviceSettingsCancelRequested());
                            },
                          ),
                        ],
                      );
                    },
                  ),
                )
              else if (_selectedIndex == _backlightIndex)
                Expanded(
                  child: BlocBuilder<DeviceSettingsBloc, DeviceSettingsViewState>(
                    buildWhen: (p, n) =>
                        p.synced != n.synced ||
                        p.isDirty != n.isDirty ||
                        p.committing != n.committing ||
                        p.rgbEnableStaging != n.rgbEnableStaging ||
                        p.rgbModeIdStaging != n.rgbModeIdStaging ||
                        p.rgbBrightnessStaging != n.rgbBrightnessStaging ||
                        p.rgbSpeedStaging != n.rgbSpeedStaging ||
                        p.rgbRStaging != n.rgbRStaging ||
                        p.rgbGStaging != n.rgbGStaging ||
                        p.rgbBStaging != n.rgbBStaging ||
                        p.rgbSleepTimeStaging != n.rgbSleepTimeStaging,
                    builder: (context, view) {
                      final synced = view.synced;
                      final bloc = context.read<DeviceSettingsBloc>();
                      // why: sleep options live in L2 capability schema, not in
                      // synced state — sourced from RgbBacklightCapabilities
                      // (never hardcoded) per FR-RGB-004 / FR-ARC-001.
                      final sleepOpts = DeviceCapabilityStore.forDevice(
                        widget.card.devId,
                      )?.rgbBacklight?.sleepTimeOptions;
                      return Column(
                        children: [
                          Expanded(
                            child: HubBacklightPanel(
                              rgbModes: [
                                for (final m
                                    in synced?.rgbModes ??
                                        const <RgbModeData>[])
                                  RgbMode(
                                    id: m.id,
                                    nameKey: m.nameKey,
                                    supportsColor: m.supportsColor,
                                  ),
                              ],
                              // why: dropdown shows the human label (L5-owned),
                              // not the raw localization key.
                              rgbModeLabels: [
                                for (final m
                                    in synced?.rgbModes ??
                                        const <RgbModeData>[])
                                  m.label ?? m.nameKey,
                              ],
                              rgbEnable: view.displayRgbEnable,
                              rgbModeId: view.displayRgbModeId,
                              rgbBrightnessLevels: synced?.rgbBrightnessLevels,
                              rgbBrightness: view.displayRgbBrightness,
                              rgbSpeedLevels: synced?.rgbSpeedLevels,
                              rgbSpeed: view.displayRgbSpeed,
                              rgbR: view.displayRgbR,
                              rgbG: view.displayRgbG,
                              rgbB: view.displayRgbB,
                              rgbSleepTime: view.displayRgbSleepTime,
                              rgbSleepOptions: sleepOpts,
                              onEnableChanged: (v) => bloc.add(
                                DeviceSettingsBacklightEnableRequested(
                                  enable: v,
                                ),
                              ),
                              onModeChanged: (id) => bloc.add(
                                DeviceSettingsBacklightModeRequested(
                                  modeId: id,
                                ),
                              ),
                              onColorChanged: (c) => bloc.add(
                                DeviceSettingsBacklightColorRequested(
                                  r: (c.r * 255.0).round().clamp(0, 255),
                                  g: (c.g * 255.0).round().clamp(0, 255),
                                  b: (c.b * 255.0).round().clamp(0, 255),
                                ),
                              ),
                              onBrightnessChanged: (lvl) => bloc.add(
                                DeviceSettingsBacklightBrightnessRequested(
                                  level: lvl,
                                ),
                              ),
                              onSpeedChanged: (lvl) => bloc.add(
                                DeviceSettingsBacklightSpeedRequested(
                                  level: lvl,
                                ),
                              ),
                              onSleepChanged: (idx) => bloc.add(
                                DeviceSettingsBacklightSleepRequested(
                                  wire: idx,
                                ),
                              ),
                            ),
                          ),
                          _BacklightActionBar(
                            isDirty: view.isDirty,
                            committing: view.committing,
                            onSave: () {
                              bloc.add(
                                const DeviceSettingsSaveBacklightRequested(),
                              );
                            },
                            onCancel: () {
                              bloc.add(const DeviceSettingsCancelRequested());
                            },
                          ),
                        ],
                      );
                    },
                  ),
                )
              else if (_selectedIndex == _deviceSettingIndex)
                Expanded(child: HubDeviceSettingPanel(card: selected))
              else
                const Expanded(child: Center(child: Text(''))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-right action bar for Parameter Setting.
///
/// Save/Cancel buttons docked right. No Reset — only Performance and Button
/// Mapping offer reset-to-default for now.
class _ParameterActionBar extends StatelessWidget {
  const _ParameterActionBar({
    this.isDirty = false,
    this.committing = false,
    this.onSave,
    this.onCancel,
  });

  final bool isDirty;
  final bool committing;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurface,
      side: BorderSide(color: theme.colorScheme.outline),
      shape: const StadiumBorder(),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: (!isDirty || committing) ? null : onSave,
            style: style,
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: committing ? null : onCancel,
            style: style,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Bottom-right action bar for Backlight Setting.
///
/// Save/Cancel buttons docked right. No Reset — only Performance and Button
/// Mapping offer reset-to-default for now.
class _BacklightActionBar extends StatelessWidget {
  const _BacklightActionBar({
    this.isDirty = false,
    this.committing = false,
    this.onSave,
    this.onCancel,
  });

  final bool isDirty;
  final bool committing;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurface,
      side: BorderSide(color: theme.colorScheme.outline),
      shape: const StadiumBorder(),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: (!isDirty || committing) ? null : onSave,
            style: style,
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: committing ? null : onCancel,
            style: style,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Bottom-right action bar for Performance Setting.
///
/// Reset/Save/Cancel buttons docked right.
class _PerformanceActionBar extends StatelessWidget {
  const _PerformanceActionBar({
    this.isDirty = false,
    this.committing = false,
    this.onReset,
    this.onSave,
    this.onCancel,
  });

  final bool isDirty;
  final bool committing;
  final VoidCallback? onReset;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: committing ? null : onReset,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.colorScheme.outline),
              shape: const StadiumBorder(),
            ),
            child: const Text('Reset to Default'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: (!isDirty || committing) ? null : onSave,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.colorScheme.outline),
              shape: const StadiumBorder(),
            ),
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: committing ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.colorScheme.outline),
              shape: const StadiumBorder(),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
