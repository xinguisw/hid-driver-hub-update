import 'package:driver_hub/desktop_shell/window_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SingleInstanceGuard & Process Classification', () {
    test('OSD sub-window arguments bypass single instance check', () {
      final osdArgs = ['multi_window', '101', 'driver_hub.osd'];
      expect(isOsdWindow(osdArgs), isTrue);
    });

    test('Standard main process launch arguments are subject to single instance check', () {
      final mainArgs = <String>[];
      expect(isOsdWindow(mainArgs), isFalse);
    });

    test('Custom app flags do not match OSD sub-window signature', () {
      final customArgs = ['--autostart', '--minimized'];
      expect(isOsdWindow(customArgs), isFalse);
    });
  });
}
