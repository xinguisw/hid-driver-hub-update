import 'package:driver_hub/desktop_shell/osd_overlay_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('driver_hub/osd_overlay');

  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends semantic OSD text to the Windows presentation channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return null;
        });

    final service = OsdOverlayService();
    await service.show(
      title: 'Device status',
      lines: const <String>['DPI: 800 DPI', 'Report Rate: 1000 Hz'],
    );

    expect(received?.method, 'show');
    expect(received?.arguments, <String, Object?>{
      'title': 'Device status',
      'lines': <String>['DPI: 800 DPI', 'Report Rate: 1000 Hz'],
    });
  });
}
