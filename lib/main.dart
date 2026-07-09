import 'dart:convert';

import 'package:driver_hub/core/device/device_scanner.dart';
import 'package:driver_hub/core/device/discovered_device.dart';
import 'package:driver_hub/core/device/hid_session.dart';
import 'package:driver_hub/core/hid/local_storage.dart';
import 'package:driver_hub/features/mouse/protocol/device_protocol.dart';
import 'package:driver_hub/features/mouse/repositories/device_session.dart';
import 'package:driver_hub/features/mouse/repositories/device_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DriverHubApp());
}

class DriverHubApp extends StatelessWidget {
  const DriverHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'driver_hub',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const ScanTestScreen(),
    );
  }
}

class ScanTestScreen extends StatefulWidget {
  const ScanTestScreen({super.key});

  @override
  State<ScanTestScreen> createState() => _ScanTestScreenState();
}

class _ScanTestScreenState extends State<ScanTestScreen> {
  final _scanner = DeviceScanner();
  late final DeviceWatcher _watcher;
  final _log = <String>[];
  bool _busy = false;

  /// Whether a remembered+verified device is currently active. On web this
  /// hides the "Add device" button once we're connected.
  bool _verifiedActive = false;

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
        _addLog('  [watcher] connected+verified: ${session.device.entry.devId} '
            '(${session.device.mode.desc})');
        _saveLastDevice(session.device);
        if (mounted) setState(() => _verifiedActive = true);
      },
      onDisconnect: (vid, pid) {
        _addLog('  [watcher] disconnected: 0x${vid.toRadixString(16)}/0x${pid.toRadixString(16)}');
        if (mounted) setState(() => _verifiedActive = false);
      },
    );
    _addLog('watcher started');

    // Startup probe. On both platforms we look for an already-present device;
    // the watcher's connect event only fires on a NEW plug, not for devices
    // present at launch.
    // Web uses the gesture-free authorized path (getDevices); desktop has no
    // grant model so it enumerates directly.
    _probeExisting();
  }

  Future<void> _probeExisting() async {
    setState(() => _busy = true);
    try {
      final devices = await _scanner.discoverAuthorized();
      _addLog('probe (authorized): found ${devices.length} device(s)');
      for (final d in devices) {
        await _startAndRegister(d);
      }
    } catch (e) {
      _addLog('probe FAILED: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Web: the first-ever connect needs a user gesture (browser rule). Tap
  /// "Add device" → picker → grant → open → handshake → verify → register with
  /// the watcher so subsequent unplug/replug and page reload are automatic.
  Future<void> _addDevice() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final devices = await _scanner.discover();
      for (final d in devices) {
        await _startAndRegister(d);
      }
    } catch (e) {
      _addLog('add device FAILED: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startAndRegister(DiscoveredDevice d) async {
    _addLog('  -> opening ${d.entry.devId} (${d.mode.desc})…');
    final session = DeviceSession(
      device: d,
      session: HidSession(d.hidDevice),
      protocol: const MouseProtocol(),
    );
    final sub = session.state.listen((s) {
      _addLog('    state: ${s.status} (${s.name} / ${s.mode})'
          '${s.error != null ? " err=${s.error}" : ""}');
    });
    final verified = await session.start();
    await sub.cancel();
    if (!verified) return;
    _watcher.register(session);
  }

  void _addLog(String msg) {
    debugPrint('[flow] $msg');
    if (mounted) setState(() => _log.add(msg));
  }

  @override
  void dispose() {
    _watcher.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Web: show "Add device" only when nothing is verified+active. Once a
    // remembered device reconnects and verifies, hide it.
    final showAddButton = kIsWeb && !_verifiedActive;

    return Scaffold(
      appBar: AppBar(title: const Text('driver_hub — verify test')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: showAddButton
                ? FilledButton.icon(
                    onPressed: _busy ? null : _addDevice,
                    icon: const Icon(Icons.add),
                    label: Text(_busy ? 'Working…' : 'Add device'),
                  )
                : Text(_verifiedActive
                    ? 'Connected (verified)'
                    : _busy
                        ? 'Working…'
                        : 'Watching for devices'),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _log.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(_log[i],
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
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
