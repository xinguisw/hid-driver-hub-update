import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeviceSettingsState baseSettings() => const DeviceSettingsState(
    devId: '02AA',
    displayName: 'M7X SE',
    connectionMode: 0,
    loading: false,
    buttonCount: 6,
    reportRateHz: 1000,
    dpiActiveIndex: 2,
    dpiLevels: [
      DpiStageData(level: 1, value: 800, color: '#FF0000'),
      DpiStageData(level: 2, value: 1600, color: '#0000FF'),
    ],
    hasRgbBacklight: true,
    rgbEnable: true,
    rgbModeId: 1,
    rgbBrightness: 2,
    rgbSpeed: 1,
    rgbR: 255,
    rgbG: 0,
    rgbB: 0,
    rippleOn: false,
    angleSnapOn: false,
    lodMm: 1,
    performance: 0,
    debounceMs: 4,
    sleepSeconds: 60,
    wheelInvert: false,
  );

  group('DeviceSettingsBloc Staging Guard (FR-OPS-004 & FR-OPS-005)', () {
    test(
      'NavigationRequested wipes staging across all features (dirty sweep)',
      () async {
        final bloc = DeviceSettingsBloc(
          commitButtonMapping: (_) async {},
          commitReportRate: (_) async {},
          commitDpiLevel: (_) async {},
          commitDpiValues: (_) async {},
          commitDpiStages: (_, _) async {},
          commitSensorTuning: (_, _) async {},
          commitAngleTune: (_) async {},
          commitLod: (_) async {},
          commitPerformance: (_) async {},
          commitDebounce: (_) async {},
          commitSleep: (_) async {},
          commitWheelInvert: (_) async {},
          commitRgbBacklight: (_) async {},
        );

        bloc.add(DeviceSettingsHydrated(baseSettings()));
        await Future<void>.delayed(Duration.zero);

        // Stage report rate change
        bloc.add(const DeviceSettingsReportRateRequested(hz: 500));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.isDirty, isTrue);
        expect(bloc.state.reportRateStaging, equals(500));

        // Trigger navigation requested
        bloc.add(const DeviceSettingsNavigationRequested());
        await Future<void>.delayed(Duration.zero);

        // Verify staging is completely cleared and isDirty is false
        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.reportRateStaging, null);

        // Stage RGB backlight change
        bloc.add(const DeviceSettingsBacklightEnableRequested(enable: false));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.isDirty, isTrue);
        expect(bloc.state.rgbEnableStaging, isFalse);

        // Trigger navigation requested
        bloc.add(const DeviceSettingsNavigationRequested());
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.rgbEnableStaging, null);

        await bloc.close();
      },
    );

    test(
      'Save failure clears staging and reverts UI to synced state (Report Rate)',
      () async {
        final bloc = DeviceSettingsBloc(
          commitButtonMapping: (_) async {},
          commitReportRate: (_) async => throw Exception('Transport error'),
          commitDpiLevel: (_) async {},
          commitDpiValues: (_) async {},
          commitDpiStages: (_, _) async {},
          commitSensorTuning: (_, _) async {},
          commitAngleTune: (_) async {},
          commitLod: (_) async {},
          commitPerformance: (_) async {},
          commitDebounce: (_) async {},
          commitSleep: (_) async {},
          commitWheelInvert: (_) async {},
          commitRgbBacklight: (_) async {},
        );

        bloc.add(DeviceSettingsHydrated(baseSettings()));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const DeviceSettingsReportRateRequested(hz: 500));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.reportRateStaging, equals(500));

        bloc.add(const DeviceSettingsSaveReportRateRequested());
        await Future<void>.delayed(Duration.zero);

        // On save failure, staging must be cleared and lastError populated
        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.reportRateStaging, isNull);
        expect(bloc.state.lastError, contains('report rate save failed'));
        expect(bloc.state.synced?.reportRateHz, equals(1000));

        await bloc.close();
      },
    );

    test(
      'Save failure clears staging and reverts UI to synced state (RGB Backlight)',
      () async {
        final bloc = DeviceSettingsBloc(
          commitButtonMapping: (_) async {},
          commitReportRate: (_) async {},
          commitDpiLevel: (_) async {},
          commitDpiValues: (_) async {},
          commitDpiStages: (_, _) async {},
          commitSensorTuning: (_, _) async {},
          commitAngleTune: (_) async {},
          commitLod: (_) async {},
          commitPerformance: (_) async {},
          commitDebounce: (_) async {},
          commitSleep: (_) async {},
          commitWheelInvert: (_) async {},
          commitRgbBacklight: (_) async => throw Exception('Hardware timeout'),
        );

        bloc.add(DeviceSettingsHydrated(baseSettings()));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const DeviceSettingsBacklightEnableRequested(enable: false));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.rgbEnableStaging, isFalse);

        bloc.add(const DeviceSettingsSaveBacklightRequested());
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.rgbEnableStaging, isNull);
        expect(bloc.state.lastError, contains('backlight save failed'));
        expect(bloc.state.synced?.rgbEnable, isTrue);

        await bloc.close();
      },
    );
  });
}
