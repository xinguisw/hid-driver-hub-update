import 'package:driver_hub/layer1_discovery/device_catalog.dart';
import 'package:driver_hub/layer1_discovery/device_scanner.dart';
import 'package:driver_hub/layer1_discovery/device_session.dart';
import 'package:driver_hub/layer1_discovery/device_watcher.dart';
import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer5_codec/device_type.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer6_transport/hid_events.dart';
import 'package:driver_hub/layer6_transport/hid_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hid_tool/hid_tool.dart';

/// Teardown contract of [DeviceWatcher]: a session pulled from the registry is
/// disposed exactly once on every exit path (replug, plain disconnect, stop).
void main() {
  const path = 'hid-path-1';
  // Longer than DeviceWatcher's 300ms replug debounce.
  const afterDebounce = Duration(milliseconds: 400);

  late _FakeEvents events;
  late _FakeScanner scanner;
  late DeviceWatcher watcher;
  late List<String> disconnects;
  late _FakeSession session;

  setUp(() {
    events = _FakeEvents();
    scanner = _FakeScanner();
    disconnects = <String>[];
    session = _FakeSession(_discovered(path));
    watcher = DeviceWatcher(
      scanner: scanner,
      protocolFactory: () => const MouseProtocol(),
      sessionFactory: (DiscoveredDevice d) => HidSession(d.hidDevice),
      sessionCtor: ({
        required DiscoveredDevice device,
        required HidSession session,
        required DeviceProtocol protocol,
      }) =>
          _FakeSession(device),
      events: events,
    );
    watcher.start(
      onConnect: (_) {},
      onDisconnect: (p, _, _) => disconnects.add(p),
    );
    watcher.register(session);
  });

  test('replug inside the debounce disposes the orphan and skips onDisconnect',
      () async {
    events.onDisconnect!(path, 1, 2);
    events.onConnect!(path, 1, 2);
    await pumpEventQueue();

    expect(session.disposeCount, 1, reason: 'orphan disposed by _handleConnect');
    expect(disconnects, isEmpty, reason: 'no card flicker on fast replug');

    // The deferred timer must not fire a second dispose after the window.
    await Future<void>.delayed(afterDebounce);
    expect(session.disposeCount, 1);
    expect(disconnects, isEmpty);
  });

  test('disconnect with no replug fires onDisconnect and disposes once',
      () async {
    events.onDisconnect!(path, 1, 2);
    expect(session.disposeCount, 0, reason: 'teardown is deferred');

    await Future<void>.delayed(afterDebounce);
    expect(disconnects, [path]);
    expect(session.disposeCount, 1);
  });

  test('stop disposes an orphan whose deferred dispose is still pending',
      () async {
    events.onDisconnect!(path, 1, 2);
    await watcher.stop();

    expect(session.disposeCount, 1);
    expect(events.stopped, isTrue);
    expect(disconnects, isEmpty, reason: 'stop cancels the deferred callback');
  });
}

DiscoveredDevice _discovered(String path) {
  const mode = DeviceMode(mode: 0, desc: 'USB', vid: 0x248A, pid: 0x8208);
  return DiscoveredDevice(
    entry: const DeviceCatalogEntry(
      devId: '02AA',
      deviceType: DeviceType.mouse,
      model: 'M7X SE',
      deviceAttr: 'mouse_m7x_se',
      interfaceId: 2,
      usagePage: 0xFF02,
      image: DeviceImage(small: 'small.png', large: 'large.png'),
      modes: [mode],
    ),
    mode: mode,
    hidDevice: _FakeHidDevice(path),
  );
}

/// Only [path] and [id] are reached; the rest of the HID surface is unused.
class _FakeHidDevice extends HidDevice {
  _FakeHidDevice(this.path);

  @override
  final String path;

  @override
  String get id => path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSession implements DeviceSession {
  _FakeSession(this.device);

  @override
  final DiscoveredDevice device;

  int disposeCount = 0;

  @override
  Future<bool> start() async => true;

  @override
  Future<void> dispose() async {
    disposeCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEvents implements HidEvents {
  void Function(String path, int vendorId, int productId)? onConnect;
  void Function(String path, int vendorId, int productId)? onDisconnect;
  bool stopped = false;

  @override
  void start({
    required void Function(String path, int vendorId, int productId) onConnect,
    required void Function(String path, int vendorId, int productId)
        onDisconnect,
  }) {
    this.onConnect = onConnect;
    this.onDisconnect = onDisconnect;
  }

  @override
  void stop() => stopped = true;
}

class _FakeScanner implements DeviceScanner {
  List<DiscoveredDevice> devices = const [];

  @override
  Future<List<DiscoveredDevice>> discover() async => devices;

  @override
  Future<List<DiscoveredDevice>> discoverAuthorized() async => devices;
}
