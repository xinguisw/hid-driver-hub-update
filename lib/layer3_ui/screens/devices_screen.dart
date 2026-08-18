import 'dart:async';

import 'package:driver_hub/desktop_shell/osd_overlay_service.dart';
import 'package:driver_hub/layer3_ui/screens/hub_landing_screen.dart';
import 'package:driver_hub/layer3_ui/widgets/device_card_grid.dart';
import 'package:driver_hub/layer3_ui/widgets/empty_device_state.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/osd_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:driver_hub/i18n/strings.g.dart';

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
    _scope.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('driver_hub'),
        actions: [
          PopupMenuButton<AppLocale>(
            icon: const Icon(Icons.translate, size: 20),
            tooltip: t.common.language,
            initialValue: TranslationProvider.of(context).locale,
            onSelected: (AppLocale locale) {
              LocaleSettings.setLocale(locale);
            },
            itemBuilder: (BuildContext context) {
              return AppLocale.values.map((AppLocale locale) {
                String name = locale.languageTag.toUpperCase();
                if (locale.languageTag == 'en') name = 'English';
                if (locale.languageTag == 'zh') name = '简体中文';
                return PopupMenuItem<AppLocale>(
                  value: locale,
                  child: Text(name),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (kIsWeb) _addDeviceBar,
          Expanded(
            child: ValueListenableBuilder<List<DiscoveredCardState>>(
              valueListenable: _scope.cards,
              builder: (context, cards, _) {
                if (cards.isEmpty) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _scope.busy,
                    builder: (context, busy, _) => EmptyDeviceState(busy: busy),
                  );
                }
                return DeviceCardGrid(cards: cards, onCardTap: _openHubLanding);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openHubLanding(DiscoveredCardState card) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HubLandingScreen(card: card, scope: _scope),
      ),
    );
  }

  /// Always-visible on web so a second device can be added. Disabled while a
  /// scan is in flight.
  Widget get _addDeviceBar {
    return ValueListenableBuilder<bool>(
      valueListenable: _scope.busy,
      builder: (context, busy, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: busy ? null : _scope.addDevice,
          icon: const Icon(Icons.add),
          label: Text(busy ? 'Working…' : 'Add device'),
        ),
      ),
    );
  }
}
