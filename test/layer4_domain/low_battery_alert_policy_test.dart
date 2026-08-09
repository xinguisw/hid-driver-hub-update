import 'package:driver_hub/layer4_domain/low_battery_alert_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LowBatteryAlertPolicy', () {
    test('notifies once per device while it remains low', () {
      final policy = LowBatteryAlertPolicy();

      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 20,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 15,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isFalse,
      );
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-b',
          batteryPercent: 20,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
    });

    test('re-arms after recovery above the threshold', () {
      final policy = LowBatteryAlertPolicy();

      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 10,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 21,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isFalse,
      );
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 20,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
    });

    test('charging suppresses and re-arms the alert', () {
      final policy = LowBatteryAlertPolicy();

      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 10,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 10,
          isCharging: true,
          thresholdPercent: 20,
        ),
        isFalse,
      );
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 10,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
    });
  });
}
