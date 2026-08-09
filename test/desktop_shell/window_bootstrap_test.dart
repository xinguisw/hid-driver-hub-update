import 'package:driver_hub/desktop_shell/window_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isOsdWindow', () {
    test('recognizes the desktop_multi_window OSD arguments', () {
      expect(
        isOsdWindow(const <String>[
          'multi_window',
          'window-1',
          'driver_hub.osd',
        ]),
        isTrue,
      );
    });

    test('does not classify the main engine as the OSD window', () {
      expect(isOsdWindow(const <String>[]), isFalse);
      expect(
        isOsdWindow(const <String>['multi_window', 'window-1', 'other']),
        isFalse,
      );
    });
  });
}
