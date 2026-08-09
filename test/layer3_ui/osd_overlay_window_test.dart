import 'package:driver_hub/layer3_ui/widgets/osd_overlay_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a text-only OSD message from window arguments', () {
    final message = OsdOverlayMessage.fromArguments(const <String, Object?>{
      'title': 'Device status',
      'lines': <Object?>['DPI: 800 DPI', 'Report Rate: 1000 Hz'],
    });

    expect(message.title, 'Device status');
    expect(message.lines, <String>['DPI: 800 DPI', 'Report Rate: 1000 Hz']);
  });

  test('uses the fixed three-second toast duration', () {
    expect(osdToastDuration, const Duration(seconds: 3));
  });

  testWidgets('shows the OSD title and performance lines', (tester) async {
    var showCount = 0;
    var hideCount = 0;
    final controller = OsdOverlayWindowController(
      showWindow: () async => showCount++,
      hideWindow: () async => hideCount++,
    );

    await controller.handle(
      const MethodCall('osd_show', <String, Object?>{
        'title': 'Device status',
        'lines': <Object?>['DPI: 800 DPI', 'Report Rate: 1000 Hz'],
      }),
    );
    await tester.pumpWidget(OsdOverlayApp(controller: controller));

    expect(find.text('Device status'), findsOneWidget);
    expect(find.text('DPI: 800 DPI'), findsOneWidget);
    expect(find.text('Report Rate: 1000 Hz'), findsOneWidget);
    expect(showCount, 1);
    expect(hideCount, 0);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    expect(hideCount, 1);
  });
}
