import 'package:driver_hub/layer3_ui/widgets/hub_button_mapping_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_left_sidebar.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_mouse_canvas.dart';
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
  const HubLandingScreen({
    super.key,
    required this.card,
    required this.scope,
  });

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

  @override
  void initState() {
    super.initState();
    // why: Scope owns commit hook (L1->L5); L3 never sees sessions
    _settingsBloc = widget.scope.createSettingsBloc(widget.card);
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
                                bloc.add(
                                  const DeviceSettingsCancelRequested(),
                                );
                              },
                            ),
                          ),
                          if (_selectedButtonId != null) ...[
                            const VerticalDivider(thickness: 1, width: 1),
                            HubButtonMappingPanel(
                              selectedButtonId: _selectedButtonId,
                              mouseActionCatalog: display?.mouseActionCatalog,
                            ),
                          ],
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
