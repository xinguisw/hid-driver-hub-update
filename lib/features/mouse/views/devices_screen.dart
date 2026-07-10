import 'dart:convert';

import 'package:driver_hub/core/device/device_scanner.dart';
import 'package:driver_hub/core/device/discovered_device.dart';
import 'package:driver_hub/core/device/hid_session.dart';
import 'package:driver_hub/core/hid/local_storage.dart';
import 'package:driver_hub/features/mouse/models/discovered_card_state.dart';
import 'package:driver_hub/features/mouse/protocol/device_protocol.dart';
import 'package:driver_hub/features/mouse/repositories/device_session.dart';
import 'package:driver_hub/features/mouse/repositories/device_watcher.dart';
import 'package:driver_hub/features/mouse/views/widgets/device_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Home grid: one [DeviceCard] per verified device.
///
/// Owns the [DeviceWatcher] and mirrors its session set into card states.
/// Multi-device by design — each verified device is its own entry, keyed by
/// device path. The card is pure; this screen owns the data and the lifecycle.
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _scanner = DeviceScanner();
  late final DeviceWatcher _watcher;

  /// Verified devices, keyed by device path. One entry → one card.
  final _cards = <String, DiscoveredCardState>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    _watcher = DeviceWatcher(
      scanner: _scanner,
      protocolFactory: () => const MouseProtocol(),
      sessionFactory: (d) => HidSession(d.hidDevice),
      sessionCtor: DeviceSession.new,
    );

    _watcher.start(
      onConnect: (session) {
        _saveLastDevice(session.device);
        if (mounted) {
          setState(() {
            _cards[session.device.hidDevice.path] =
                _cardStateFor(session);
          });
        }
      },
      onDisconnect: (path, vid, pid) {
        if (mounted) setState(() => _cards.remove(path));
      },
    );

    // Devices present at launch; the watcher only fires on a NEW plug.
    _probeExisting();
  }

  Future<void> _probeExisting() async {
    setState(() => _busy = true);
    try {
      final devices = await _scanner.discoverAuthorized();
      for (final d in devices) {
        await _startAndRegister(d);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Web: first-ever connect needs a user gesture (browser rule).
  Future<void> _addDevice() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final devices = await _scanner.discover();
      for (final d in devices) {
        await _startAndRegister(d);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startAndRegister(DiscoveredDevice d) async {
    final session = DeviceSession(
      device: d,
      session: HidSession(d.hidDevice),
      protocol: const MouseProtocol(),
    );
    final verified = await session.start();
    if (!verified) return;
    _watcher.register(session);
    if (mounted) {
      setState(() {
        _cards[d.hidDevice.path] = _cardStateFor(session);
      });
    }
  }

  /// L1 → L3 bridge: builds the card state from a verified session's catalog
  /// context. Firmware/battery/charging are sentinels until L5 lands.
  DiscoveredCardState _cardStateFor(DeviceSession session) {
    final entry = session.device.entry;
    return DiscoveredCardState(
      devId: entry.devId,
      displayName: entry.model,
      connectionMode: session.device.mode.mode,
      firmwareVersion: '',
      batteryPercentage: -1,
      isCharging: false,
      physicalHandle: session.device.hidDevice,
      imageSmall: entry.image.small,
      imageLarge: entry.image.large,
    );
  }

  @override
  void dispose() {
    _watcher.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAddButton = kIsWeb && _cards.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('driver_hub')),
      body: Column(
        children: [
          if (showAddButton)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _busy ? null : _addDevice,
                icon: const Icon(Icons.add),
                label: Text(_busy ? 'Working…' : 'Add device'),
              ),
            ),
          if (_cards.isEmpty && !showAddButton)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _busy ? 'Working…' : 'No devices',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final state in _cards.values) DeviceCard(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- last-device hint (web localStorage; no-op on non-web) ---

const _lastHidKey = 'driver_hub.lastHid';

void _saveLastDevice(DiscoveredDevice d) {
  if (!kIsWeb) return;
  try {
    final payload = jsonEncode({
      'vendorId': d.mode.vid,
      'productId': d.mode.pid,
      'productName': d.entry.model,
    });
    writeLocalStorage(_lastHidKey, payload);
  } catch (_) {}
}
