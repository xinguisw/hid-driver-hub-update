import 'package:driver_hub/layer1_discovery/device_runtime.dart';
import 'package:driver_hub/layer1_discovery/device_settings_gateway.dart';
import 'package:driver_hub/layer1_discovery/device_watcher.dart';
import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer4_domain/app_settings_repository.dart';

/// Lifecycle-free L1 port for domain and widget tests that do not touch HID.
class FakeDeviceRuntime implements DeviceRuntime {
  const FakeDeviceRuntime();

  @override
  Future<List<DiscoveredDevice>> discover() async => const [];

  @override
  Future<List<DiscoveredDevice>> discoverAuthorized() async => const [];

  @override
  Future<DeviceSettingsGateway?> openAndRegister(
    DiscoveredDevice device,
  ) async => null;

  @override
  void startWatching({
    required DeviceGatewayConnectCallback onConnect,
    required DeviceDisconnectCallback onDisconnect,
  }) {}

  @override
  Future<void> stop() async {}
}

class MemoryAppSettingsRepository implements AppSettingsRepository {
  int? savedThreshold;

  @override
  Future<int?> loadLowBatteryThreshold() async => savedThreshold;

  @override
  Future<void> saveLowBatteryThreshold(int threshold) async {
    savedThreshold = threshold;
  }
}
