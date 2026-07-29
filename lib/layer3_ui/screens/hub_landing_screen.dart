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
/// L3 only: onboard load + [DeviceSettingsBloc] events; composes
/// [HubLeftSidebar], [HubMouseCanvas], [HubButtonMappingPanel]. No L5 codec.
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
  // why: 0 = Button Mapping (only page that shows mouse canvas)
  int _selectedIndex = 0;
  // why: null = mapping panel hidden; set only on canvas **label** tap
  int? _selectedButtonId;
  late final DeviceSettingsBloc _settingsBloc;

  static const int _buttonMappingIndex = 0;

  @override
  void initState() {
    super.initState();
    _settingsBloc = DeviceSettingsBloc(
      commitButtonMapping: (buttons) async {
        final session = widget.scope.sessionFor(widget.card);
        if (session == null || !session.isAlive) {
          throw StateError('no session');
        }
        await session.setButtonMapping(buttons);
      },
      // why: no Save button yet — chart Save still runs as SaveRequested event
      autoSaveAfterReset: true,
    );
    // Seed from cache if present (instant paint); full GET follows.
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
      debugPrint('[hub] ${widget.card.displayName}: disconnected — pop');
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
    debugPrint('[hub] ${widget.card.displayName}: loading onboard config…');
    final packed = await widget.scope.loadOnboardSettings(widget.card);
    if (!mounted) return;
    if (!widget.scope.isCardConnected(widget.card) || packed.error != null) {
      debugPrint(
        '[hub] ${widget.card.displayName}: load failed '
        '(${packed.error ?? 'no session'}) — pop home',
      );
      Navigator.of(context).maybePop();
      return;
    }
    // Chart hydrate → BLoC synced (clears any stale staging).
    _settingsBloc.add(DeviceSettingsHydrated(packed));
    debugPrint('[hub] ${widget.card.displayName}: onboard config done');
  }

  /// L3 only: Tip Confirm already done on canvas → dispatch BLoC event.
  void _onResetToDefault() {
    debugPrint('[hub] ${widget.card.displayName}: dispatch reset event');
    _settingsBloc.add(const DeviceSettingsResetButtonMappingRequested());
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.scope.resolveCard(widget.card);
    // why: no AppBar; mouse canvas only on Button Mapping nav
    return BlocProvider<DeviceSettingsBloc>.value(
      value: _settingsBloc,
      child: BlocListener<DeviceSettingsBloc, DeviceSettingsViewState>(
        listenWhen: (prev, next) =>
            prev.synced != next.synced &&
            next.synced != null &&
            !next.isDirty &&
            next.lastError == null,
        listener: (context, state) {
          // Mirror successful Save / hydrate into scope cache for re-entry.
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
              Expanded(
                child: _selectedIndex == _buttonMappingIndex
                    ? BlocBuilder<DeviceSettingsBloc, DeviceSettingsViewState>(
                        buildWhen: (p, n) =>
                            p.displaySettings != n.displaySettings ||
                            p.committing != n.committing ||
                            p.lastError != n.lastError,
                        builder: (context, view) {
                          final buttons =
                              view.displaySettings?.buttons ?? const [];
                          return HubMouseCanvas(
                            imageLarge: selected.imageLarge,
                            buttons: buttons,
                            selectedButtonId: _selectedButtonId,
                            onButtonSelected: (id) {
                              setState(() => _selectedButtonId = id);
                            },
                            // Chart: dispatch only — staging/Save live in BLoC.
                            onResetToDefault:
                                view.committing ? null : _onResetToDefault,
                          );
                        },
                      )
                    : const Center(
                        child: Text(''),
                      ),
              ),
              if (_selectedIndex == _buttonMappingIndex &&
                  _selectedButtonId != null) ...[
                const VerticalDivider(thickness: 1, width: 1),
                HubButtonMappingPanel(selectedButtonId: _selectedButtonId),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
