import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/layer3_ui/widgets/app_settings_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/app_top_bar.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_left_sidebar.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appSettings() {
    return MaterialApp(
      home: Scaffold(
        body: AppSettingsPanel(
          lowBatteryThreshold: ValueNotifier<int>(20),
          onLowBatteryThresholdChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('renders the requested app settings skeleton', (tester) async {
    await tester.pumpWidget(appSettings());

    expect(find.text('System'), findsWidgets);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Help'), findsWidgets);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Customer Service'), findsOneWidget);
    expect(find.text('Key Test'), findsOneWidget);
    expect(find.text('Product Manual'), findsOneWidget);
    expect(find.text('Driver Bug Feedback'), findsOneWidget);
    expect(find.text('NEWMEN HUB Communities'), findsOneWidget);
    expect(find.text('Performance Settings'), findsWidgets);
    expect(find.text('About NEWMEN HUB'), findsWidgets);
    expect(find.text('Current Version: 1.0.0'), findsOneWidget);
    expect(find.text('Official Website: xxxx.com'), findsOneWidget);
  });

  testWidgets('offers the requested low battery threshold choices', (
    tester,
  ) async {
    final threshold = ValueNotifier<int>(20);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSettingsPanel(
            lowBatteryThreshold: threshold,
            onLowBatteryThresholdChanged: (value) => threshold.value = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('app-setting-threshold')));
    await tester.pumpAndSettle();

    expect(find.text('10%'), findsWidgets);
    expect(find.text('20%'), findsWidgets);
    expect(find.text('30%'), findsWidgets);
    expect(find.text('40%'), findsWidgets);

    await tester.tap(find.text('30%').first);
    await tester.pump();
    expect(threshold.value, 30);
  });

  testWidgets('left sidebar excludes App Setting as it moved to top bar', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HubLeftSidebar(
            card: const DiscoveredCardState(
              devId: 'test',
              displayName: 'Test Mouse',
              connectionMode: 0,
              firmwareVersion: '0.0',
              batteryPercentage: 100,
              isCharging: false,
              physicalHandle: null,
              imageSmall: '',
              imageLarge: '',
            ),
            hasRgbBacklight: true,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              selectedIndex = index;
            },
          ),
        ),
      ),
    );

    expect(find.text('Button Mapping'), findsOneWidget);
    expect(find.text('Macro Setting'), findsOneWidget);
    expect(find.text('Performance Setting'), findsOneWidget);
    expect(find.text('Parameter Setting'), findsOneWidget);
    expect(find.text('Backlight Setting'), findsOneWidget);
    expect(find.text('Profile Management'), findsOneWidget);
    expect(find.text('Device Setting'), findsOneWidget);
    expect(find.text('App Setting'), findsNothing);
  });

  testWidgets(
    'AppTopBar Settings button navigates to full-page AppSettingsScreen',
    (tester) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              appBar: const AppTopBar(),
              body: const Center(child: Text('Main Page')),
            ),
          ),
        ),
      );

      expect(find.text('Main Page'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsWidgets);
      expect(find.text('Back'), findsOneWidget);

      // Tap back button in the left sidebar to return
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Main Page'), findsOneWidget);
    },
  );
}
