import 'package:flutter_test/flutter_test.dart';

import 'package:driver_hub/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const DriverHubApp());
    expect(find.text('driver_hub'), findsOneWidget);
  });
}
