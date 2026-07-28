import 'package:driver_hub/layer3_ui/widgets/hub_left_sidebar.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';

/// Per-device hub shell after card tap on home.
///
/// L3 only: same onboard load as [DeviceSettingsScreen]; composes
/// [HubLeftSidebar]. No L5 codec. Body center stays empty skeleton.
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
  // why: held for later panes; center body stays empty this step
  DeviceSettingsState? _state;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // why: same as settings — seed cache, then refresh via full onboard GET
    _state = widget.scope.settingsFor(widget.card);
    widget.scope.cards.addListener(_onCardsChanged);
    widget.scope.settingsVersion.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnboardConfig());
  }

  @override
  void dispose() {
    widget.scope.cards.removeListener(_onCardsChanged);
    widget.scope.settingsVersion.removeListener(_onSettingsChanged);
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

  void _onSettingsChanged() {
    if (!mounted) return;
    final next = widget.scope.settingsFor(widget.card);
    if (next == null) return;
    setState(() => _state = next);
  }

  Future<void> _loadOnboardConfig() async {
    if (!widget.scope.isCardConnected(widget.card)) {
      debugPrint('[hub] ${widget.card.displayName}: no live session');
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    if (_state == null) {
      setState(() {
        _state = DeviceSettingsState(
          devId: widget.card.devId,
          displayName: widget.card.displayName,
          connectionMode: widget.card.connectionMode,
          loading: true,
        );
      });
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
    setState(() => _state = packed);
    debugPrint('[hub] ${widget.card.displayName}: onboard config done');
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.scope.resolveCard(widget.card);
    // why: no AppBar; left rail (device card + nav) + empty center
    return Scaffold(
      body: Row(
        children: [
          HubLeftSidebar(
            card: selected,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            onDeviceTap: () => Navigator.of(context).maybePop(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          const Expanded(
            child: Center(
              child: Text('Hub landing (empty)'),
            ),
          ),
        ],
      ),
    );
  }
}
