import 'package:driver_hub/layer1_discovery/device_connection_manager.dart';
import 'package:driver_hub/layer1_discovery/device_session.dart';
import 'package:driver_hub/layer3_ui/models/discovered_card_state.dart';
import 'package:flutter/material.dart';

/// Settings for one connected mouse. Opens from card tap; GETs config on enter.
/// If that device disconnects, pops back to the home list.
class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({
    super.key,
    required this.card,
    required this.scope,
  });

  final DiscoveredCardState card;
  final DeviceScope scope;

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.scope.cards.addListener(_onCardsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnboardConfig());
  }

  @override
  void dispose() {
    widget.scope.cards.removeListener(_onCardsChanged);
    super.dispose();
  }

  /// Card list lost this device → leave settings (option A).
  void _onCardsChanged() {
    if (!mounted) return;
    if (_sessionStillAlive) return;
    debugPrint(
      '[settings] ${widget.card.displayName}: disconnected — pop',
    );
    Navigator.of(context).maybePop();
  }

  bool get _sessionStillAlive {
    final session = widget.scope.sessionForCard(widget.card);
    return session != null && session.isAlive;
  }

  Future<void> _loadOnboardConfig() async {
    if (!_sessionStillAlive) {
      debugPrint('[settings] ${widget.card.displayName}: no live session');
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    final DeviceSession session =
        widget.scope.sessionForCard(widget.card)!;
    debugPrint(
      '[settings] ${widget.card.displayName}: loading onboard config…',
    );
    await widget.scope.queryOnboardConfig(session);
    if (!mounted) return;
    if (!_sessionStillAlive) {
      Navigator.of(context).maybePop();
      return;
    }
    debugPrint(
      '[settings] ${widget.card.displayName}: onboard config done',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.displayName),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
