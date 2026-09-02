import 'package:driver_hub/app_updater/bloc/app_update_bloc.dart';
import 'package:driver_hub/app_updater/bloc/app_update_state.dart';
import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:driver_hub/app_updater/services/auto_updater_service.dart';
import 'package:driver_hub/app_updater/ui/updater_action_button.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/layer3_ui/widgets/app_settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockAutoUpdaterService implements AutoUpdaterService {
  bool _initialized = true;
  int checkCount = 0;
  bool shouldThrow = false;

  @override
  bool get isInitialized => _initialized;

  @override
  UpdaterConfig? get config => const UpdaterConfig();

  @override
  Future<void> initialize(UpdaterConfig config) async {
    _initialized = true;
  }

  @override
  Future<void> checkForUpdates({bool isManual = true}) async {
    if (shouldThrow) throw Exception('Simulated network error');
    checkCount++;
  }

  @override
  Future<void> setScheduledCheckInterval(int seconds) async {}
}

void main() {
  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
    PackageInfo.setMockInitialValues(
      appName: 'driver_hub',
      packageName: 'com.driver_hub',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Widget buildTestApp({required Widget child, AppUpdateBloc? bloc}) {
    return TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: bloc != null
              ? BlocProvider<AppUpdateBloc>.value(value: bloc, child: child)
              : child,
        ),
      ),
    );
  }

  group('UpdaterActionButton Widget Tests', () {
    testWidgets('renders idle state with check icon and text without emojis', (tester) async {
      final mockService = MockAutoUpdaterService();
      final bloc = AppUpdateBloc(autoUpdaterService: mockService);

      await tester.pumpWidget(buildTestApp(
        child: UpdaterActionButton(appUpdateBloc: bloc),
      ));

      expect(find.text('Check for Updates'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await bloc.close();
    });

    testWidgets('clicking button dispatches check to AutoUpdaterService', (tester) async {
      final mockService = MockAutoUpdaterService();
      final bloc = AppUpdateBloc(autoUpdaterService: mockService);

      await tester.pumpWidget(buildTestApp(
        child: UpdaterActionButton(appUpdateBloc: bloc),
      ));

      await tester.tap(find.text('Check for Updates'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(mockService.checkCount, equals(1));

      await bloc.close();
    });

    testWidgets('shows progress indicator and disables tapping while in AppUpdateChecking state', (tester) async {
      final mockService = MockAutoUpdaterService();
      final bloc = AppUpdateBloc(autoUpdaterService: mockService);

      // Emit checking state
      bloc.emit(const AppUpdateChecking(isManual: true));

      await tester.pumpWidget(buildTestApp(
        child: UpdaterActionButton(appUpdateBloc: bloc),
      ));
      await tester.pump();

      expect(find.text('Checking for updates...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);

      await bloc.close();
    });

    testWidgets('shows snackbar when AppUpdateCheckFailure is emitted', (tester) async {
      final mockService = MockAutoUpdaterService();
      final bloc = AppUpdateBloc(autoUpdaterService: mockService);

      await tester.pumpWidget(buildTestApp(
        child: UpdaterActionButton(appUpdateBloc: bloc),
      ));

      bloc.emit(const AppUpdateCheckFailure(
        message: 'No internet connection',
        isManual: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Failed to check for updates'), findsOneWidget);
      expect(find.textContaining('No internet connection'), findsOneWidget);

      await bloc.close();
    });
  });

  group('AppSettingsPanel Integration with Updater', () {
    testWidgets('renders dynamic version and update button in About section', (tester) async {
      final mockService = MockAutoUpdaterService();
      final bloc = AppUpdateBloc(autoUpdaterService: mockService);

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: AppSettingsPanel(
                lowBatteryThreshold: ValueNotifier<int>(20),
                onLowBatteryThresholdChanged: (_) {},
                appUpdateBloc: bloc,
                version: '1.2.3',
              ),
            ),
          ),
        ),
      );

      // Verify custom version is rendered
      expect(find.text('Current Version: 1.2.3'), findsOneWidget);

      // Verify UpdaterActionButton is present in the layout
      expect(find.byType(UpdaterActionButton), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);

      await bloc.close();
    });
  });
}
