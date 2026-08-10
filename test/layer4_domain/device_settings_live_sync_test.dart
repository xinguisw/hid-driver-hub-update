import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'live performance updates active DPI and report rate without dropping staging',
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
        initial: DeviceSettingsViewState(
          synced: const DeviceSettingsState(
            devId: '02AA',
            displayName: 'M7XSE',
            connectionMode: 0,
            reportRateHz: 1000,
            reportRateLabel: '1000 Hz',
            dpiActiveIndex: 1,
          ),
          reportRateStaging: 500,
          dpiCurrentLevelStaging: 3,
          isDirty: true,
        ),
      );

      bloc.add(
        const DeviceSettingsLivePerformanceUpdated(
          dpiLevel: 2,
          reportRateHz: 125,
          reportRateLabel: '125 Hz',
        ),
      );
      await pumpEventQueue();

      expect(bloc.state.synced?.dpiActiveIndex, 2);
      expect(bloc.state.synced?.reportRateHz, 125);
      expect(bloc.state.synced?.reportRateLabel, '125 Hz');
      expect(bloc.state.reportRateStaging, 500);
      expect(bloc.state.dpiCurrentLevelStaging, 3);
      expect(bloc.state.isDirty, isTrue);

      await bloc.close();
    },
  );
}
