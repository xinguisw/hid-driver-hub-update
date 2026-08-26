import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_backlight_panel.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/i18n/strings.g.dart';

void main() {
  testWidgets('HubBacklightPanel renders cleanly in wide and narrow layouts without unbounded flex assertions', (tester) async {
    LocaleSettings.setLocale(AppLocale.en);

    // Wide layout
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: HubBacklightPanel(
              rgbModes: [
                RgbModeData(id: 0, nameKey: 'off', supportsColor: false),
                RgbModeData(id: 1, nameKey: 'constant', supportsColor: true),
              ],
              rgbModeId: 1,
              rgbBrightnessLevels: 5,
              rgbBrightness: 2,
              rgbSpeedLevels: 3,
              rgbSpeed: 1,
              rgbR: 255,
              rgbG: 0,
              rgbB: 128,
              rgbSleepOptions: [60, 120, 300],
              rgbSleepTime: 1,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(HubBacklightPanel), findsOneWidget);

    // Narrow layout
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 700,
            child: HubBacklightPanel(
              rgbModes: [
                RgbModeData(id: 0, nameKey: 'off', supportsColor: false),
                RgbModeData(id: 1, nameKey: 'constant', supportsColor: true),
              ],
              rgbModeId: 1,
              rgbBrightnessLevels: 5,
              rgbBrightness: 2,
              rgbSpeedLevels: 3,
              rgbSpeed: 1,
              rgbR: 255,
              rgbG: 0,
              rgbB: 128,
              rgbSleepOptions: [60, 120, 300],
              rgbSleepTime: 1,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(HubBacklightPanel), findsOneWidget);
  });

  testWidgets('HubBacklightPanel triggers callbacks on interactions', (tester) async {
    LocaleSettings.setLocale(AppLocale.en);
    int? selectedBrightness;
    int? selectedSpeed;
    int? selectedSleep;
    Color? selectedColor;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 700,
            child: HubBacklightPanel(
              rgbModes: const [
                RgbModeData(id: 0, nameKey: 'off', supportsColor: false),
                RgbModeData(id: 1, nameKey: 'constant', supportsColor: true),
              ],
              rgbModeId: 1,
              rgbBrightnessLevels: 5,
              rgbBrightness: 2,
              rgbSpeedLevels: 3,
              rgbSpeed: 1,
              rgbR: 255,
              rgbG: 0,
              rgbB: 128,
              rgbSleepOptions: const [60, 120, 300],
              rgbSleepTime: 1,
              onBrightnessChanged: (v) => selectedBrightness = v,
              onSpeedChanged: (v) => selectedSpeed = v,
              onSleepChanged: (v) => selectedSleep = v,
              onColorChanged: (c) => selectedColor = c,
            ),
          ),
        ),
      ),
    );

    // Tap brightness 75%
    await tester.ensureVisible(find.text('75%'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('75%'));
    await tester.pumpAndSettle();
    expect(selectedBrightness, 3);

    // Tap speed pill
    await tester.ensureVisible(find.text('100').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('100').first);
    await tester.pumpAndSettle();
    expect(selectedSpeed, 2);

    // Scroll and Tap sleep option 5 min
    await tester.ensureVisible(find.text('5 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min'));
    await tester.pumpAndSettle();
    expect(selectedSleep, 2);

    // Tap a preset color swatch (e.g. red preset swatch)
    final presetSwatch = find.byType(InkWell).at(1);
    await tester.ensureVisible(presetSwatch);
    await tester.pumpAndSettle();
    await tester.tap(presetSwatch);
    await tester.pumpAndSettle();
    expect(selectedColor, isNotNull);
  });
}
