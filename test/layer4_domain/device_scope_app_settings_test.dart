import 'package:driver_hub/layer4_domain/app_settings_repository.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryAppSettingsRepository implements AppSettingsRepository {
  int? savedThreshold;

  @override
  Future<int?> loadLowBatteryThreshold() async => savedThreshold;

  @override
  Future<void> saveLowBatteryThreshold(int threshold) async {
    savedThreshold = threshold;
  }
}

void main() {
  test(
    'DeviceScope validates and persists the global low-battery threshold',
    () async {
      final repository = _MemoryAppSettingsRepository();
      final scope = DeviceScope(appSettingsRepository: repository);

      expect(
        scope.batteryLowThreshold.value,
        DeviceScope.defaultLowBatteryThreshold,
      );

      await scope.setLowBatteryThreshold(30);

      expect(scope.batteryLowThreshold.value, 30);
      expect(repository.savedThreshold, 30);
      await expectLater(scope.setLowBatteryThreshold(25), throwsArgumentError);

      await scope.dispose();
    },
  );
}
