import 'package:driver_hub/layer3_ui/widgets/hub_performance_panel.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const stages = [
    DpiStageData(level: 1, value: 800, color: '#FF0000'),
    DpiStageData(level: 2, value: 1600, color: '#00FF00'),
  ];

  Widget panel({required bool rgbPerStage}) {
    return MaterialApp(
      home: Scaffold(
        body: HubPerformancePanel(
          dpiStages: stages,
          dpiCurrentLevel: 1,
          dpiMin: 50,
          dpiMax: 3200,
          dpiStep: 50,
          dpiActiveLevelCount: 2,
          dpiMaxLevels: 8,
          dpiRgbPerStage: rgbPerStage,
          onDpiLevelSelected: (_) {},
          onDpiValueChanged: (_) {},
          onDpiStageAdd: () {},
          onDpiStageRemove: (_) {},
        ),
      ),
    );
  }

  testWidgets('shows one color control per DPI stage only when supported', (
    tester,
  ) async {
    await tester.pumpWidget(panel(rgbPerStage: true));
    expect(find.byTooltip('DPI stage color'), findsNWidgets(2));

    await tester.pumpWidget(panel(rgbPerStage: false));
    expect(find.byTooltip('DPI stage color'), findsNothing);
  });

  testWidgets('clicking a capable stage color opens the picker', (
    tester,
  ) async {
    await tester.pumpWidget(panel(rgbPerStage: true));

    await tester.tap(find.byTooltip('DPI stage color').first);
    await tester.pumpAndSettle();

    expect(find.text('DPI stage color'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('each DPI slider block shows a delete button when multiple stages exist', (
    tester,
  ) async {
    int? removedLevel;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HubPerformancePanel(
            dpiStages: stages,
            dpiCurrentLevel: 1,
            dpiMin: 50,
            dpiMax: 3200,
            dpiStep: 50,
            dpiActiveLevelCount: 2,
            dpiMaxLevels: 8,
            onDpiLevelSelected: (_) {},
            onDpiValueChanged: (_) {},
            onDpiStageAdd: () {},
            onDpiStageRemove: (lvl) => removedLevel = lvl,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Delete DPI stage 1'), findsOneWidget);
    expect(find.byTooltip('Delete DPI stage 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete DPI stage 2'));
    await tester.pump();
    expect(removedLevel, 2);
  });

  test('snapToStep correctly rounds user inputs to the step size and clamps to min/max', () {
    // Exact step match
    expect(snapToStep(800, min: 50, max: 3200, step: 50), 800);

    // Intermediate input snapped to nearest step
    expect(snapToStep(835, min: 100, max: 26000, step: 50), 850);
    expect(snapToStep(142, min: 100, max: 26000, step: 50), 150);
    expect(snapToStep(120, min: 100, max: 26000, step: 50), 100);

    // Out of bounds inputs clamped to min/max
    expect(snapToStep(10, min: 50, max: 3200, step: 50), 50);
    expect(snapToStep(4000, min: 50, max: 3200, step: 50), 3200);

    // Step null or <= 1 (continuous mode)
    expect(snapToStep(837, min: 50, max: 3200, step: null), 837);
  });
}
