import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/layer3_ui/widgets/device_card.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const awakeState = DiscoveredCardState(
    devId: '01_01',
    displayName: 'M7X PRO',
    connectionMode: 1,
    batteryPercentage: 85,
    isCharging: false,
    isAwake: true,
    physicalHandle: null,
    imageSmall: '',
    imageLarge: '',
  );

  const sleepingState = DiscoveredCardState(
    devId: '01_01',
    displayName: 'M7X PRO',
    connectionMode: 1,
    batteryPercentage: 85,
    isCharging: false,
    isAwake: false,
    physicalHandle: null,
    imageSmall: '',
    imageLarge: '',
  );

  group('DeviceCard', () {
    testWidgets('fires onTap when awake', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: DeviceCard(
                state: awakeState,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
      expect(find.byIcon(Icons.bedtime_outlined), findsNothing);

      await tester.tap(find.byType(DeviceCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('does not fire onTap and displays sleeping label when asleep', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: DeviceCard(
                state: sleepingState,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('85%'), findsNothing);
      expect(find.text(t.devices.sleeping), findsOneWidget);
      expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);

      await tester.tap(find.byType(DeviceCard));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    test('verifies Chinese translation for sleeping', () async {
      await LocaleSettings.setLocale(AppLocale.zh);
      expect(t.devices.sleeping, '休眠中');
      await LocaleSettings.setLocale(AppLocale.en);
      expect(t.devices.sleeping, 'Sleeping');
    });
  });
}
