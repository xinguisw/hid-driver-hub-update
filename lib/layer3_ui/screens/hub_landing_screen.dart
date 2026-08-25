import 'dart:async';
import 'dart:math' as math;

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
import 'package:driver_hub/layer4_domain/models/osd_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_hub/i18n/strings.g.dart';

String _dpiColorHex(Color color) {
  int channel(double value) => (value * 255).round().clamp(0, 255);
  String part(int value) => value.toRadixString(16).padLeft(2, '0');
  return '#${part(channel(color.r))}${part(channel(color.g))}${part(channel(color.b))}'
      .toUpperCase();
}

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
  int? _lastSelectedButtonId;
  int? _selectedDpiLevel;
  bool _isLoadingOnboard = true;
  late final DeviceSettingsBloc _settingsBloc;
  StreamSubscription<OsdPerformanceEvent>? _performanceSubscription;

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
      onEscalationRequested: (reason) {
        debugPrint(
          '[hub] ${widget.card.displayName}: write failure escalation ($reason) - pop home',
        );
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      },
    );
    final cached = widget.scope.settingsFor(widget.card);
    if (cached != null) {
      _settingsBloc.add(DeviceSettingsHydrated(cached));
    }
    widget.scope.cards.addListener(_onCardsChanged);
    _performanceSubscription = widget.scope.osdEvents.listen(
      _onLivePerformance,
    );
    // why: one frame after mount — load onboard config and macro catalog
    // together so Button Mapping Macro tab has slots without visiting Macro first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOnboardConfig();
      _loadMacros();
    });
  }

  @override
  void didUpdateWidget(HubLandingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.devId != widget.card.devId) {
      _loadOnboardConfig();
      _loadMacros();
    }
  }

  @override
  void dispose() {
    widget.scope.cards.removeListener(_onCardsChanged);
    unawaited(_performanceSubscription?.cancel());
    _settingsBloc.close();
    super.dispose();
  }

  void _onLivePerformance(OsdPerformanceEvent event) {
    if (!mounted ||
        event.deviceId.toLowerCase() != widget.card.devId.toLowerCase()) {
      return;
    }

    _settingsBloc.add(
      DeviceSettingsLivePerformanceUpdated(
        dpiLevel: event.dpiLevel,
        reportRateHz: event.reportRateHz,
        reportRateLabel: event.reportRateLabel,
      ),
    );

    // The active hardware stage, rather than a stale UI selection, is what
    // the Performance page should highlight after a physical button change.
    setState(() => _selectedDpiLevel = event.dpiLevel);
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

  Future<void> _loadMacros() async {
    try {
      await widget.scope.loadMacros(widget.card);
      if (mounted) setState(() {});
      debugPrint('[hub] ${widget.card.displayName}: macros loaded');
    } catch (error) {
      // Macro storage is app-local and optional for the rest of hub startup;
      // keep Button Mapping available while retaining a diagnostic signal.
      debugPrint(
        '[hub] ${widget.card.displayName}: macro catalog load failed: $error',
      );
    }
  }

  Future<void> _loadOnboardConfig() async {
    if (!widget.scope.isCardConnected(widget.card)) {
      debugPrint('[hub] ${widget.card.displayName}: no live session');
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    Timer? loadingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isLoadingOnboard = true);
    });
    debugPrint('[hub] ${widget.card.displayName}: loading onboard config...');
    final packed = await widget.scope.loadOnboardSettings(widget.card);
    loadingTimer.cancel();
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
    if (mounted) setState(() => _isLoadingOnboard = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOnboard) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading device capabilities...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    final selected = widget.scope.resolveCard(widget.card);
    return BlocProvider<DeviceSettingsBloc>.value(
      value: _settingsBloc,
      child: BlocListener<DeviceSettingsBloc, DeviceSettingsViewState>(
        listenWhen: (prev, next) =>
            (prev.synced != next.synced &&
                next.synced != null &&
                !next.isDirty &&
                next.lastError == null) ||
            (prev.dpiCurrentLevelStaging != next.dpiCurrentLevelStaging) ||
            (prev.buttonMappingStaging != next.buttonMappingStaging) ||
            (prev.isDirty != next.isDirty) ||
            (prev.lastError != next.lastError),
        listener: (context, state) {
          final s = state.synced;
          if (s != null) widget.scope.putSettings(widget.card, s);
          if (state.lastError != null &&
              (state.lastError!.contains('TimeoutException') ||
                  state.lastError!.contains('timed out'))) {
            debugPrint(
              '[hub] ${widget.card.displayName}: timeout error (${state.lastError}) - pop home',
            );
            Navigator.of(context).maybePop();
            return;
          }
          if (state.dpiCurrentLevelStaging == null && !state.isDirty) {
            if (_selectedDpiLevel != null) {
              setState(() => _selectedDpiLevel = null);
            }
          }
          if (state.buttonMappingStaging == null && !state.isDirty) {
            if (_selectedButtonId != null) {
              setState(() => _selectedButtonId = null);
            }
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              Row(
                children: [
                  BlocBuilder<DeviceSettingsBloc, DeviceSettingsViewState>(
                    buildWhen: (previous, next) =>
                        previous.synced?.hasRgbBacklight !=
                        next.synced?.hasRgbBacklight,
                    builder: (context, view) => HubLeftSidebar(
                      card: selected,
                      selectedIndex: _selectedIndex,
                      hasRgbBacklight: view.synced?.hasRgbBacklight ?? false,
                      onDestinationSelected: (index) {
                        // FR-OPS-005: dirty sweep when navigating away from any configuration page
                        if (_selectedIndex != index) {
                          _settingsBloc.add(
                            const DeviceSettingsNavigationRequested(),
                          );
                        }
                        setState(() {
                          _selectedIndex = index;
                          _selectedButtonId = null;
                          _selectedDpiLevel = null;
                        });
                      },
                      onDeviceTap: () {
                        _settingsBloc.add(
                          const DeviceSettingsNavigationRequested(),
                        );
                        setState(() {
                          _selectedButtonId = null;
                          _selectedDpiLevel = null;
                        });
                        Navigator.of(context).maybePop();
                      },
                    ),
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
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final maxSidebarW = (constraints.maxWidth * 0.6)
                                  .clamp(160.0, HubButtonMappingPanel.width);
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
                                      onBackgroundTap: () {
                                        setState(() => _selectedButtonId = null);
                                      },
                                      onResetToDefault: () {
                                        final t = context.t;
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(t.common.tip),
                                            content: Text(
                                              t.mouseCanvas.restoreDefaultKeysTip,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(false),
                                                child: Text(t.common.cancel),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(ctx).pop(true);
                                                  debugPrint(
                                                    '[hub] ${widget.card.displayName}: dispatch reset',
                                                  );
                                                  bloc.add(
                                                    const DeviceSettingsResetButtonMappingRequested(),
                                                  );
                                                },
                                                child: Text(t.common.confirm),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onSave: () {
                                        debugPrint(
                                          '[hub] ${widget.card.displayName}: '
                                          'dispatch save',
                                        );
                                        bloc.add(
                                          const DeviceSettingsSaveRequested(),
                                        );
                                      },
                                      onCancel: () {
                                        debugPrint(
                                          '[hub] ${widget.card.displayName}: '
                                          'dispatch cancel',
                                        );
                                        setState(() => _selectedButtonId = null);
                                        bloc.add(
                                          const DeviceSettingsCancelRequested(),
                                        );
                                      },
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      if (_selectedButtonId != null) {
                                        _lastSelectedButtonId =
                                            _selectedButtonId;
                                      }
                                      final activeId =
                                          _selectedButtonId ??
                                          _lastSelectedButtonId;
                                      final isOpen = _selectedButtonId != null;

                                      return _AnimatedRightSidebar(
                                        isOpen: isOpen,
                                        targetWidth: maxSidebarW,
                                        child: activeId == null
                                            ? const SizedBox.shrink()
                                            : HubButtonMappingPanel(
                                                selectedButtonId:
                                                    _selectedButtonId,
                                                buttons: buttons,
                                                mouseActionCatalog:
                                                    display?.mouseActionCatalog,
                                                keyboardActionCatalog: display
                                                    ?.keyboardActionCatalog,
                                                specialActionCatalog: display
                                                    ?.specialActionCatalog,
                                                onActionSelected: (catalogId) {
                                                  _settingsBloc.add(
                                                    DeviceSettingsButtonMappingSlotRequested(
                                                      buttonId: activeId,
                                                      catalogId: catalogId,
                                                    ),
                                                  );
                                                },
                                                onComboSelected:
                                                    (modifierIds, keyChar) {
                                                      _settingsBloc.add(
                                                        DeviceSettingsSpecialComboRequested(
                                                          buttonId: activeId,
                                                          modifierIds:
                                                              modifierIds,
                                                          keyChar: keyChar,
                                                        ),
                                                      );
                                                    },
                                                macroSlots: widget.scope
                                                    .macrosFor(widget.card)
                                                    .indexed
                                                    .map(
                                                      (entry) => MacroSlot(
                                                        id: (entry.$1 + 1)
                                                            .toString(),
                                                        name: entry.$2.name,
                                                      ),
                                                    )
                                                    .toList(),
                                                onMacroSelected: (macroSlot) {
                                                  _settingsBloc.add(
                                                    DeviceSettingsMacroMappingRequested(
                                                      buttonId: activeId,
                                                      macroSlot:
                                                          int.tryParse(
                                                            macroSlot,
                                                          ) ??
                                                          0,
                                                    ),
                                                  );
                                                },
                                                onCollapse: () {
                                                  setState(() {
                                                    _selectedButtonId = null;
                                                  });
                                                },
                                              ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
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
                            p.dpiCurrentLevelStaging !=
                                n.dpiCurrentLevelStaging ||
                            p.dpiValueStaging != n.dpiValueStaging ||
                            p.dpiStageAddStaging != n.dpiStageAddStaging ||
                            p.dpiStageRemoveLevelStaging !=
                                n.dpiStageRemoveLevelStaging ||
                            p.dpiStageLevelsStaging !=
                                n.dpiStageLevelsStaging ||
                            p.dpiRgbStaging != n.dpiRgbStaging ||
                            p.isDirty != n.isDirty ||
                            p.committing != n.committing ||
                            p.lastError != n.lastError,
                        builder: (context, view) {
                          final display = view.displaySettings;
                          final bloc = context.read<DeviceSettingsBloc>();
                          final baseStages =
                              view.dpiStageLevelsStaging ?? display?.dpiLevels;
                          final rgbStaging = view.dpiRgbStaging;
                          final resolvedStages =
                              (baseStages != null &&
                                  rgbStaging != null &&
                                  rgbStaging.isNotEmpty)
                              ? baseStages.map((stage) {
                                  final stagedColor = rgbStaging[stage.level];
                                  if (stagedColor == null) return stage;
                                  return DpiStageData(
                                    level: stage.level,
                                    value: stage.value,
                                    y: stage.y,
                                    color: stagedColor,
                                  );
                                }).toList()
                              : baseStages;
                          return _buildScrollablePanel(
                            panel: HubPerformancePanel(
                              // why: staged add/remove level list paints the
                              // rearranged containers live before Save.
                              dpiStages: resolvedStages,
                              dpiRgbPerStage:
                                  display?.dpiRgbPerStage ?? false,
                              onDpiColorChanged: (change) {
                                bloc.add(
                                  DeviceSettingsDpiColorRequested(
                                    level: change.level,
                                    color: _dpiColorHex(change.color),
                                  ),
                                );
                              },
                              // why: highlight the user's UI selection; fall
                              // back to the device's active level initially.
                              dpiCurrentLevel:
                                  view.dpiCurrentLevelStaging ??
                                  _selectedDpiLevel ??
                                  display?.dpiActiveIndex,
                              dpiCurrentLevelStaging:
                                  view.dpiCurrentLevelStaging,
                              onDpiLevelSelected: (level) {
                                setState(() => _selectedDpiLevel = level);
                                bloc.add(
                                  DeviceSettingsDpiLevelRequested(
                                    level: level,
                                  ),
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
                              dpiActiveLevelCount:
                                  display?.dpiActiveLevelCount,
                              dpiMaxLevels: display?.dpiMaxLevels,
                              onDpiStageAdd: () {
                                bloc.add(
                                  const DeviceSettingsDpiStageAddRequested(),
                                );
                              },
                              // why: `x` only removes the user's clicked
                              // level; disabled until a level is selected.
                              dpiRemoveEnabled: _selectedDpiLevel != null,
                              onDpiStageRemove: (level) {
                                setState(() => _selectedDpiLevel = 1);
                                bloc.add(
                                  DeviceSettingsDpiStageRemoveRequested(
                                    level: level,
                                  ),
                                );
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
                            actionBar: _PerformanceActionBar(
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
                                final hasDpiRgbStaging =
                                    view.dpiRgbStaging != null &&
                                    view.dpiRgbStaging!.isNotEmpty;
                                final hasDpiStageStaging =
                                    view.dpiStageAddStaging ||
                                    view.dpiStageRemoveLevelStaging != null;
                                if (view.reportRateStaging != null ||
                                    view.dpiCurrentLevelStaging != null ||
                                    hasDpiValueStaging ||
                                    hasDpiRgbStaging ||
                                    hasDpiStageStaging ||
                                    view.dpiStageLevelsStaging != null) {
                                  bloc.add(
                                    const DeviceSettingsSaveDpiConfigurationRequested(),
                                  );
                                }
                              },
                              onCancel: () {
                                setState(() => _selectedDpiLevel = null);
                                bloc.add(
                                  const DeviceSettingsCancelRequested(),
                                );
                              },
                            ),
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
                            p.angleTuneLabelStaging !=
                                n.angleTuneLabelStaging ||
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
                          return _buildScrollablePanel(
                            panel: HubParameterPanel(
                                  hasSensorTuning:
                                      synced?.hasSensorTuning ?? false,
                                  hasLod: synced?.hasLod ?? false,
                                  hasAngleTune: synced?.hasAngleTune ?? false,
                                  hasPerformance:
                                      synced?.hasPerformance ?? false,
                                  hasButtonDebounce:
                                      synced?.hasButtonDebounce ?? false,
                                  hasWheelInvert:
                                      synced?.hasWheelInvert ?? false,
                                  hasSleepTime: synced?.hasSleepTime ?? false,
                                  lodOptions: synced?.lodOptions,
                                  buttonDebounceOptions:
                                      synced?.debounceOptions,
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
                                      view.debounceStaging ??
                                      synced?.debounceMs,
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
                                      DeviceSettingsSleepTimeRequested(
                                        wire: wire,
                                      ),
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
                                      DeviceSettingsAngleSnapRequested(
                                        enabled: on,
                                      ),
                                    );
                                  },
                                  onAngleTuneToggled: (on) {
                                    bloc.add(
                                      DeviceSettingsAngleTuneToggled(
                                        enabled: on,
                                      ),
                                    );
                                  },
                                  onAngleTuneDecrement: () {
                                    final currentWire =
                                        view.angleTuneStaging ??
                                        synced?.angleTune;
                                    final options =
                                        synced?.angleTuneOptions ??
                                        const <AngleTuneOptionData>[];
                                    var idx = options.indexWhere(
                                      (o) => o.wire == currentWire,
                                    );
                                    if (idx < 0 && options.isNotEmpty) {
                                      idx = options.indexWhere(
                                        (o) =>
                                            o.label == synced?.angleTuneLabel,
                                      );
                                      if (idx < 0) {
                                        idx = (options.length / 2).floor();
                                      }
                                    }
                                    if (idx > 0) {
                                      bloc.add(
                                        DeviceSettingsAngleTuneValueChanged(
                                          wireValue: options[idx - 1].wire,
                                        ),
                                      );
                                    }
                                  },
                                  onAngleTuneIncrement: () {
                                    final currentWire =
                                        view.angleTuneStaging ??
                                        synced?.angleTune;
                                    final options =
                                        synced?.angleTuneOptions ??
                                        const <AngleTuneOptionData>[];
                                    var idx = options.indexWhere(
                                      (o) => o.wire == currentWire,
                                    );
                                    if (idx < 0 && options.isNotEmpty) {
                                      idx = options.indexWhere(
                                        (o) =>
                                            o.label == synced?.angleTuneLabel,
                                      );
                                      if (idx < 0) {
                                        idx = (options.length / 2).floor();
                                      }
                                    }
                                    if (idx >= 0 && idx < options.length - 1) {
                                      bloc.add(
                                        DeviceSettingsAngleTuneValueChanged(
                                          wireValue: options[idx + 1].wire,
                                        ),
                                      );
                                    }
                                  },
                                ),
                            actionBar: _ParameterActionBar(
                                isDirty: view.isDirty,
                                committing: view.committing,
                                onSave: () {
                                  bloc.add(
                                    const DeviceSettingsSaveParameterSettingsRequested(),
                                  );
                                },
                                onCancel: () {
                                  bloc.add(
                                    const DeviceSettingsCancelRequested(),
                                  );
                                },
                              ),
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
                          return _buildScrollablePanel(
                            panel: HubBacklightPanel(
                                  rgbModes: synced?.rgbModes,
                                  // why: dropdown shows the human label (L5-owned),
                                  // not the raw localization key.
                                  rgbModeLabels: [
                                    for (final m
                                        in synced?.rgbModes ??
                                            const <RgbModeData>[])
                                      m.label ?? m.nameKey,
                                  ],
                                  rgbModeId: view.displayRgbModeId,
                                  rgbBrightnessLevels:
                                      synced?.rgbBrightnessLevels,
                                  rgbBrightness: view.displayRgbBrightness,
                                  rgbSpeedLevels: synced?.rgbSpeedLevels,
                                  rgbSpeed: view.displayRgbSpeed,
                                  rgbR: view.displayRgbR,
                                  rgbG: view.displayRgbG,
                                  rgbB: view.displayRgbB,
                                  rgbSleepTime: view.displayRgbSleepTime,
                                  rgbSleepOptions: sleepOpts,
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
                              actionBar: _BacklightActionBar(
                                isDirty: view.isDirty,
                                committing: view.committing,
                                onSave: () {
                                  bloc.add(
                                    const DeviceSettingsSaveBacklightRequested(),
                                  );
                                },
                                onCancel: () {
                                  bloc.add(
                                    const DeviceSettingsCancelRequested(),
                                  );
                                },
                              ),
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
              BlocBuilder<DeviceSettingsBloc, DeviceSettingsViewState>(
                buildWhen: (p, n) =>
                    p.committing != n.committing ||
                    p.consecutiveFailures != n.consecutiveFailures,
                builder: (context, view) {
                  return CommitOverlay(
                    committing: view.committing,
                    consecutiveFailures: view.consecutiveFailures,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay displaying save / retry status with threshold & minimum duration.
///
/// why: fast device writes (<200ms) finish before threshold timer fires,
/// preventing a 1-frame flash/jitter. Writes taking longer than 200ms (or retries)
/// fade in smoothly with [AnimatedOpacity] and hold for at least 350ms.
@visibleForTesting
class CommitOverlay extends StatefulWidget {
  const CommitOverlay({
    super.key,
    required this.committing,
    required this.consecutiveFailures,
    this.threshold = const Duration(milliseconds: 200),
    this.minDuration = const Duration(milliseconds: 350),
  });

  final bool committing;
  final int consecutiveFailures;
  final Duration threshold;
  final Duration minDuration;

  @override
  State<CommitOverlay> createState() => _CommitOverlayState();
}

class _CommitOverlayState extends State<CommitOverlay> {
  Timer? _thresholdTimer;
  Timer? _minDisplayTimer;
  bool _showOverlay = false;
  DateTime? _shownAt;

  @override
  void initState() {
    super.initState();
    _syncState();
  }

  @override
  void didUpdateWidget(CommitOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.committing != widget.committing ||
        oldWidget.consecutiveFailures != widget.consecutiveFailures) {
      _syncState();
    }
  }

  void _syncState() {
    if (widget.committing) {
      _minDisplayTimer?.cancel();
      _minDisplayTimer = null;

      // If retry in progress, show overlay immediately.
      if (widget.consecutiveFailures > 0) {
        _thresholdTimer?.cancel();
        _thresholdTimer = null;
        if (!_showOverlay) {
          setState(() {
            _showOverlay = true;
            _shownAt = DateTime.now();
          });
        }
      } else if (!_showOverlay && _thresholdTimer == null) {
        _thresholdTimer = Timer(widget.threshold, () {
          if (mounted && widget.committing) {
            setState(() {
              _showOverlay = true;
              _shownAt = DateTime.now();
            });
          }
        });
      }
    } else {
      _thresholdTimer?.cancel();
      _thresholdTimer = null;

      if (_showOverlay) {
        final elapsed = _shownAt != null
            ? DateTime.now().difference(_shownAt!)
            : widget.minDuration;
        final remaining = widget.minDuration - elapsed;

        if (remaining > Duration.zero) {
          _minDisplayTimer?.cancel();
          _minDisplayTimer = Timer(remaining, () {
            if (mounted && !widget.committing) {
              setState(() {
                _showOverlay = false;
                _shownAt = null;
              });
            }
          });
        } else {
          setState(() {
            _showOverlay = false;
            _shownAt = null;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _thresholdTimer?.cancel();
    _minDisplayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showOverlay) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final retryCount = widget.consecutiveFailures;
    final text = retryCount > 0
        ? 'Re-attempting device write (Retry $retryCount of 3)...'
        : 'Saving settings to device...';

    return Container(
      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
    final isDark = theme.brightness == Brightness.dark;

    final outlinedButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
      foregroundColor: theme.colorScheme.onSurface,
      minimumSize: const Size(80, 42),
      side: BorderSide(
        color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
        width: 1.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
    );

    final saveCanClick = isDirty && !committing;
    final primaryButtonStyle = saveCanClick
        ? FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 42),
            elevation: 3,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          )
        : OutlinedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
            foregroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.38),
            minimumSize: const Size(80, 42),
            side: BorderSide(
              color:
                  (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD))
                      .withValues(alpha: 0.5),
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          saveCanClick
              ? FilledButton(
                  onPressed: onSave,
                  style: primaryButtonStyle,
                  child: const Text('Save'),
                )
              : OutlinedButton(
                  onPressed: null,
                  style: primaryButtonStyle,
                  child: const Text('Save'),
                ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: committing ? null : onCancel,
            style: outlinedButtonStyle,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Bottom-right action bar for Backlight Setting.
///
Widget _buildScrollablePanel({
  required Widget panel,
  required Widget actionBar,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxHeight < 220) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              panel,
              actionBar,
            ],
          ),
        );
      }
      return Column(
        children: [
          Expanded(child: panel),
          actionBar,
        ],
      );
    },
  );
}

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
    final isDark = theme.brightness == Brightness.dark;

    final outlinedButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
      foregroundColor: theme.colorScheme.onSurface,
      minimumSize: const Size(80, 42),
      side: BorderSide(
        color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
        width: 1.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
    );

    final saveCanClick = isDirty && !committing;
    final primaryButtonStyle = saveCanClick
        ? FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 42),
            elevation: 3,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          )
        : OutlinedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
            foregroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.38),
            minimumSize: const Size(80, 42),
            side: BorderSide(
              color:
                  (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD))
                      .withValues(alpha: 0.5),
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          saveCanClick
              ? FilledButton(
                  onPressed: onSave,
                  style: primaryButtonStyle,
                  child: const Text('Save'),
                )
              : OutlinedButton(
                  onPressed: null,
                  style: primaryButtonStyle,
                  child: const Text('Save'),
                ),
          OutlinedButton(
            onPressed: committing ? null : onCancel,
            style: outlinedButtonStyle,
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
    final isDark = theme.brightness == Brightness.dark;

    final outlinedButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
      foregroundColor: theme.colorScheme.onSurface,
      minimumSize: const Size(80, 42),
      side: BorderSide(
        color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
        width: 1.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
    );

    final saveCanClick = isDirty && !committing;
    final primaryButtonStyle = saveCanClick
        ? FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 42),
            elevation: 3,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          )
        : OutlinedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
            foregroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.38),
            minimumSize: const Size(80, 42),
            side: BorderSide(
              color:
                  (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD))
                      .withValues(alpha: 0.5),
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: committing ? null : onReset,
            style: outlinedButtonStyle,
            child: const Text('Reset to Default'),
          ),
          saveCanClick
              ? FilledButton(
                  onPressed: onSave,
                  style: primaryButtonStyle,
                  child: const Text('Save'),
                )
              : OutlinedButton(
                  onPressed: null,
                  style: primaryButtonStyle,
                  child: const Text('Save'),
                ),
          OutlinedButton(
            onPressed: committing ? null : onCancel,
            style: outlinedButtonStyle,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Smooth width slide animation wrapper for button mapping right panel matching left sidebar curves.
class _AnimatedRightSidebar extends StatelessWidget {
  const _AnimatedRightSidebar({
    required this.isOpen,
    required this.child,
    this.targetWidth = HubButtonMappingPanel.width,
  });

  final bool isOpen;
  final Widget child;
  final double targetWidth;

  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const Curve _animationCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final effectiveW = math.min(HubButtonMappingPanel.width, targetWidth);
    return AnimatedContainer(
      duration: _animationDuration,
      curve: _animationCurve,
      width: isOpen ? effectiveW : 0,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: effectiveW,
          child: SizedBox(
            width: effectiveW,
            child: Row(
              children: [
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
