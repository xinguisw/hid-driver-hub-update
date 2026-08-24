import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_webhid/flutter_webhid.dart' as webhid;
import 'package:hid_tool/hid_tool.dart';

import '../hid_scanner.dart';

/// Web discovery: interactive browser permission picker with fallback interop.
class WebHidScanner implements HidScanner {
  const WebHidScanner();

  @override
  Future<List<HidDevice>> scan(List<DeviceFilter> filters) async {
    if (!webhid.WebHID.isSupported) {
      throw UnsupportedError(
        'WebHID is not supported in this browser. Use Chrome or Edge over '
        'HTTPS or localhost.',
      );
    }
    final instance = webhid.WebHID.instance;
    if (instance == null) return const [];

    final webFilters = filters
        .map((f) => webhid.DeviceFilter(
              vendorId: f.vendorId,
              productId: f.productId,
            ))
        .toList();

    debugPrint('[WebHidScanner] scan: requesting device picker with ${webFilters.length} filters...');
    List<webhid.Device> devices = [];
    try {
      devices = await instance.requestDevice(
        webhid.RequestOptions(filters: webFilters),
      );
    } catch (e) {
      debugPrint('[WebHidScanner] scan filtered requestDevice error: $e');
    }

    if (devices.isEmpty) {
      debugPrint('[WebHidScanner] scan: retrying requestDevice with empty filters (all devices)...');
      try {
        devices = await instance.requestDevice(
          webhid.RequestOptions(filters: const []),
        );
      } catch (e) {
        debugPrint('[WebHidScanner] scan unconstrained requestDevice error: $e');
      }
    }

    debugPrint('[WebHidScanner] scan: picker returned ${devices.length} devices');
    final hidDevices = devices.map(_fromWebHidDevice).toList();
    return await _filter(hidDevices, filters);
  }

  @override
  Future<List<HidDevice>> getAuthorized(List<DeviceFilter> filters) async {
    if (!webhid.WebHID.isSupported) return const [];
    final instance = webhid.WebHID.instance;
    if (instance == null) return const [];

    List<webhid.Device> devices = [];
    try {
      devices = await instance.getDevices();
      debugPrint('[WebHidScanner] getAuthorized: browser returned ${devices.length} authorized devices');
      for (final d in devices) {
        debugPrint('  -> Authorized Device: "${d.productName}" (VID: 0x${d.vendorId.toRadixString(16)}, PID: 0x${d.productId.toRadixString(16)})');
      }
    } catch (e) {
      debugPrint('[WebHidScanner] getAuthorized error: $e');
    }

    final hidDevices = devices.map(_fromWebHidDevice).toList();
    return await _filter(hidDevices, filters);
  }


  Future<List<HidDevice>> _filter(
    List<HidDevice> devices,
    List<DeviceFilter> filters,
  ) async {
    if (devices.isEmpty) return devices;

    final out = <HidDevice>[];
    for (final d in devices) {
      final pages = (d is WebHidDeviceAdapter) ? d.usagePages : const <int>{};
      debugPrint('[WebHidScanner] _filter: Device 0x${d.vendorId.toRadixString(16)}:0x${d.productId.toRadixString(16)} collections usagePages=$pages');
      if (_matchesFilter(d, pages, filters)) {
        out.add(d);
      }
    }
    debugPrint('[WebHidScanner] _filter: ${out.length}/${devices.length} devices matched filters');
    return out;
  }

  bool _matchesFilter(
    HidDevice d,
    Set<int> usagePages,
    List<DeviceFilter> filters,
  ) {
    if (filters.isEmpty) {
      return true;
    }
    for (final f in filters) {
      if (f.vendorId != null && d.vendorId != f.vendorId) continue;
      if (f.productId != null && d.productId != f.productId) continue;
      // Catalog usagePage filter: require vendor usagePage (e.g. 0xFF02 / 65282).
      // This explicitly filters out Chrome's protected generic mouse collection (usagePage 1)
      // and selects the unprotected vendor configuration channel (usagePage 0xFF02).
      if (f.usagePage != null && usagePages.isNotEmpty) {
        if (!usagePages.contains(f.usagePage)) continue;
      }
      return true;
    }
    return false;
  }
}

class WebHidDeviceAdapter extends HidDevice {
  final webhid.Device device;
  WebHidDeviceAdapter(this.device);

  Set<int> get usagePages {
    try {
      return device.collections.map((c) => c.usagePage).toSet();
    } catch (_) {
      return const <int>{};
    }
  }

  @override
  int get vendorId => device.vendorId;

  @override
  int get productId => device.productId;

  @override
  String get path => 'web:${device.vendorId}:${device.productId}:${usagePage.toRadixString(16)}';

  @override
  String get productName => device.productName;

  @override
  String get manufacturer => '';

  @override
  String get serialNumber => '';

  @override
  int get releaseNumber => 0;

  @override
  int get usagePage {
    final pages = usagePages;
    for (final page in pages) {
      if (page >= 0xFF00) return page;
    }
    return pages.isNotEmpty ? pages.first : 0;
  }

  @override
  int get usage => 0;

  @override
  int get interfaceNumber => 0;


  @override
  int get busType => 0;

  @override
  String get id => path;

  @override
  bool get isOpen => device.opened;

  @override
  Future<void> open() => device.open();

  @override
  Future<void> close() => device.close();

  @override
  Future<void> sendReport(Uint8List data, {int reportId = 0}) {
    return device.sendReport(reportId, data);
  }

  @override
  Future<void> sendOutputReport(Uint8List data, {int reportId = 0}) {
    return device.sendReport(reportId, data);
  }

  @override
  Future<void> sendFeatureReport(Uint8List data, {int reportId = 0}) {
    return device.sendFeatureReport(reportId, data);
  }

  @override
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout}) async {
    throw UnimplementedError('receiveReport is not used on Web. Use inputStream().');
  }

  @override
  Future<Uint8List> receiveFeatureReport(int reportId, {int bufferSize = 64}) async {
    return device.receiveFeatureReport(reportId);
  }

  @override
  Future<String> getIndexedString(int index, {int maxLength = 255}) async {
    return '';
  }

  @override
  Future<HidReportDescriptor> getReportDescriptor() async {
    throw UnimplementedError();
  }

  @override
  Stream<int> inputStream() {
    return device.onInputReport.expand((event) => event.data);
  }
}

HidDevice _fromWebHidDevice(webhid.Device d) => WebHidDeviceAdapter(d);








