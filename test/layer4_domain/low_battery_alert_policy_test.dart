import 'package:driver_hub/layer4_domain/low_battery_alert_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LowBatteryAlertPolicy', () {
    test('notifies on threshold and re-emits on every 10% step below threshold', () {
      final policy = LowBatteryAlertPolicy();

      // Alert at 20%
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 20,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
      // Same tier (15% is in the same tier 10-19% or between milestones), does not spam
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 15,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isFalse,
      );
      // Drops to next 10% milestone (10%) -> notifies again
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 10,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
      // Drops to 5% (tier 0) -> notifies again
      expect(
        policy.shouldNotify(
          devicePath: 'mouse-a',
          batteryPercent: 5,
          isCharging: false,
          thresholdPercent: 20,
        ),
        isTrue,
      );
      // Separate device
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
