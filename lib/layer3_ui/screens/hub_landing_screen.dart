import 'package:driver_hub/layer3_ui/widgets/hub_button_mapping_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_left_sidebar.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_mouse_canvas.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_performance_panel.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
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
  late final DeviceSettingsBloc _settingsBloc;

  static const int _buttonMappingIndex = 0;
  static const int _performanceIndex = 2;

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
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                )
              else if (_selectedIndex == _performanceIndex)
                Expanded(
                  child: BlocBuilder<DeviceSettingsBloc, DeviceSettingsViewState>(
                    buildWhen: (p, n) =>
                        p.displaySettings != n.displaySettings ||
                        p.reportRateStaging != n.reportRateStaging ||
                        p.dpiCurrentLevelStaging != n.dpiCurrentLevelStaging ||
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
                              dpiStages: display?.dpiLevels,
                              dpiCurrentLevel: display?.dpiActiveIndex,
                              dpiCurrentLevelStaging: view.dpiCurrentLevelStaging,
                              onDpiLevelSelected: (level) {
                                bloc.add(
                                  DeviceSettingsDpiLevelRequested(level: level),
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
                          ),
                          _PerformanceActionBar(
                            isDirty: view.isDirty,
                            committing: view.committing,
                            onSave: () {
                              // Save both report rate and DPI if either is staged
                              if (view.reportRateStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSaveReportRateRequested(),
                                );
                              }
                              if (view.dpiCurrentLevelStaging != null) {
                                bloc.add(
                                  const DeviceSettingsSaveDpiLevelRequested(),
                                );
                              }
                            },
                            onCancel: () {
                              bloc.add(
                                const DeviceSettingsCancelRequested(),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                )
              else
                const Expanded(child: Center(child: Text(''))),
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: null, // reset not wired yet
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
