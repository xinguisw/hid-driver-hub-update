import 'dart:async';

import 'package:driver_hub/desktop_shell/osd_overlay_service.dart';
import 'package:driver_hub/layer3_ui/screens/hub_landing_screen.dart';
import 'package:driver_hub/layer3_ui/widgets/device_card_grid.dart';
import 'package:driver_hub/layer3_ui/widgets/empty_device_state.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/osd_event.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Home screen: one [DeviceCard] per verified device.
///
/// L3 only: reads L4 [DeviceScope] cards. Card tap → [HubLandingScreen].
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, required this.scope});

  final DeviceScope scope;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late final DeviceScope _scope;
  late final OsdOverlayService _osd;
  StreamSubscription<OsdPerformanceEvent>? _osdSubscription;
  StreamSubscription<OsdBatteryLowEvent>? _batteryLowOsdSubscription;

  @override
  void initState() {
    super.initState();
    _scope = widget.scope;
    _osd = OsdOverlayService();
    _osdSubscription = _scope.osdEvents.listen(_showPerformanceOsd);
    _batteryLowOsdSubscription = _scope.batteryLowOsdEvents.listen(
      _showBatteryLowOsd,
    );
    unawaited(_scope.start());
  }

  @override
  void dispose() {
    final osdSubscription = _osdSubscription;
    if (osdSubscription != null) {
      unawaited(osdSubscription.cancel());
    }
    final batteryLowOsdSubscription = _batteryLowOsdSubscription;
    if (batteryLowOsdSubscription != null) {
      unawaited(batteryLowOsdSubscription.cancel());
    }
    _osd.dispose();
    super.dispose();
  }

  Future<void> _showPerformanceOsd(OsdPerformanceEvent event) {
    final dpiText = event.dpiLabel.startsWith('Level ')
        ? event.dpiLabel
        : 'Level ${event.dpiLevel} · ${event.dpiLabel}';
    final lines = <String>['DPI: $dpiText'];
    final reportRate = event.reportRateLabel;
    if (reportRate != null) {
      lines.add('Report Rate: $reportRate');
    }
    return _osd.show(title: 'Device status', lines: lines);
  }

  Future<void> _showBatteryLowOsd(OsdBatteryLowEvent event) {
    return _osd.show(
      title: 'Device status',
      lines: <String>[
        '${event.deviceName}: battery low',
        'Battery: ${event.batteryPercent}%',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // why: Extract current theme colors to dynamically adjust text and icon colors for Light/Dark mode
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ValueListenableBuilder<List<DiscoveredCardState>>(
        valueListenable: _scope.cards,
        builder: (context, cards, _) {
          return Column(
            children: [
              Expanded(
                child: cards.isEmpty
                    ? ValueListenableBuilder<bool>(
                        valueListenable: _scope.busy,
                        builder: (context, busy, _) => EmptyDeviceState(
                          busy: busy,
                          onAddDevice: _scope.addDevice,
                        ),
                      )
                    : DeviceCardGrid(cards: cards, onCardTap: _openHubLanding),
              ),
              if (kIsWeb && cards.isNotEmpty) _addDeviceBar,
            ],
          );
        },
      ),
    );
  }

  bool _openingDevice = false;

  void _openHubLanding(DiscoveredCardState card) {
    if (_openingDevice) return;
    _openingDevice = true;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/hub_landing/${card.devId}'),
        builder: (_) => HubLandingScreen(card: card, scope: _scope),
      ),
    ).then((_) {
      if (mounted) {
        _openingDevice = false;
      }
    });
  }

  /// Always-visible on web so a second device can be added. Disabled while a
  /// scan is in flight.
  Widget get _addDeviceBar {
    final theme = Theme.of(context);
    final buttonBg = theme.brightness == Brightness.dark
        ? theme.colorScheme.primary
        : Colors.black;

    return ValueListenableBuilder<bool>(
      valueListenable: _scope.busy,
      builder: (context, busy, _) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 24,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : _scope.addDevice,
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: Text(
                  busy ? t.devices.working : t.devices.addDevice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: buttonBg,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.26,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.devices.bluetoothWarning,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
