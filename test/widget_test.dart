import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driver_hub/main.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';

import 'test_support/fake_device_runtime.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    final scope = DeviceScope(
      runtime: const FakeDeviceRuntime(),
      macroRepository: InMemoryMacroRepository(),
      appSettingsRepository: MemoryAppSettingsRepository(),
    );
    await tester.pumpWidget(
      TranslationProvider(child: DriverHubApp(scope: scope)),
    );
    expect(find.byType(DriverHubApp), findsOneWidget);
  });
}
