import 'package:driver_hub/desktop_shell/window_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('desktop window configuration', () {
    test('default and minimum dimensions are valid', () {
      expect(kDesktopWindowWidth, greaterThanOrEqualTo(kMinDesktopWindowWidth));
      expect(
        kDesktopWindowHeight,
        greaterThanOrEqualTo(kMinDesktopWindowHeight),
      );
      expect(kDesktopWindowWidth, 1256);
      expect(kDesktopWindowHeight, 753);
      expect(kMinDesktopWindowWidth, 1024);
      expect(kMinDesktopWindowHeight, 614);
    });
  });
}
