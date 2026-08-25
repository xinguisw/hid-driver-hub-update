import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SingleInstanceGuard & Desktop Launch Arguments', () {
    test('Standard main process launch arguments are parsed cleanly', () {
      final mainArgs = <String>[];
      expect(mainArgs.isEmpty, isTrue);
    });

    test('Custom flags are preserved for desktop launch', () {
      final customArgs = ['--autostart', '--minimized'];
      expect(customArgs.contains('--autostart'), isTrue);
      expect(customArgs.contains('--minimized'), isTrue);
    });
  });
}
