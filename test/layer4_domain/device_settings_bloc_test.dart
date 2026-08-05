import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeviceSettingsState baseSettings() => const DeviceSettingsState(
    devId: '02AA',
    displayName: 'M7XSE',
    connectionMode: 0,
    loading: false,
    buttonCount: 6,
    buttons: [
      ButtonData(
        id: 1,
        labelKey: 'button.left_click',
        remappable: true,
        action: 0x14,
        param1: 1,
        actionLabel: 'Macro play (#1)',
      ),
      ButtonData(
        id: 2,
        labelKey: 'button.right_click',
        remappable: true,
        action: 0x03,
        param1: 0,
      ),
      ButtonData(
        id: 3,
        labelKey: 'button.middle_click',
        remappable: true,
        action: 0x04,
      ),
      ButtonData(
        id: 4,
        labelKey: 'button.forward',
        remappable: true,
        action: 0x05,
      ),
      ButtonData(
        id: 5,
        labelKey: 'button.back',
        remappable: true,
        action: 0x06,
      ),
      ButtonData(
        id: 6,
        labelKey: 'button.dpi_cycle',
        remappable: true,
        action: 0x0E,
      ),
    ],
  );

  group('DeviceSettingsBloc button mapping', () {
    test('hydrate seeds synced, not dirty', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      expect(bloc.state.synced?.devId, '02AA');
      expect(bloc.state.isDirty, false);
      expect(bloc.state.buttonMappingStaging, isNull);
      await bloc.close();
    });

    test('reset commits defaults immediately and synchronizes state', () async {
      List<ButtonMappingSlot>? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (slots) async {
          written = List<ButtonMappingSlot>.from(slots);
        },
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsResetButtonMappingRequested());
      await pumpEventQueue();
      await pumpEventQueue();

      expect(written?.map((slot) => slot.action), [
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x0E,
      ]);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.buttonMappingStaging, isNull);
      expect(bloc.state.displaySettings?.buttons?.first.action, 0x02);
      expect(bloc.state.synced?.buttons?.first.action, 0x02);
      expect(bloc.state.committing, false);
      expect(bloc.state.lastError, isNull);
      await bloc.close();
    });

    test(
      'cancel wipes staged action and restores synchronized state',
      () async {
        final bloc = DeviceSettingsBloc(
          commitButtonMapping: (_) async {},
          commitReportRate: (_) async {},
          commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
        );
        bloc.add(DeviceSettingsHydrated(baseSettings()));
        await pumpEventQueue();
        bloc.add(
          const DeviceSettingsButtonMappingSlotRequested(
            buttonId: 1,
            catalogId: 'mouse.left',
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.isDirty, true);
        expect(bloc.state.displaySettings?.buttons?.first.action, 0x02);
        expect(bloc.state.synced?.buttons?.first.action, 0x14);

        bloc.add(const DeviceSettingsCancelRequested());
        await pumpEventQueue();

        expect(bloc.state.isDirty, false);
        expect(bloc.state.buttonMappingStaging, isNull);
        expect(bloc.state.synced?.buttons?.first.action, 0x14);
        await bloc.close();
      },
    );

    test('save validates staged action, commits, and clears dirty', () async {
      List<ButtonMappingSlot>? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (slots) async {
          written = slots;
        },
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      bloc.add(
        const DeviceSettingsButtonMappingSlotRequested(
          buttonId: 1,
          catalogId: 'mouse.left',
        ),
      );
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveRequested());
      await pumpEventQueue();

      expect(written, isNotNull);
      expect(written!.map((slot) => slot.action), [
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x0E,
      ]);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.buttonMappingStaging, isNull);
      expect(bloc.state.synced?.buttons?.first.action, 0x02);
      expect(bloc.state.committing, false);
      expect(bloc.state.lastError, isNull);
      await bloc.close();
    });

    test('save failure keeps dirty and bumps consecutiveFailures', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {
          throw Exception('nak');
        },
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      bloc.add(
        const DeviceSettingsButtonMappingSlotRequested(
          buttonId: 1,
          catalogId: 'mouse.left',
        ),
      );
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveRequested());
      await pumpEventQueue();

      expect(bloc.state.isDirty, true);
      expect(bloc.state.buttonMappingStaging, isNotNull);
      expect(bloc.state.consecutiveFailures, 1);
      expect(bloc.state.lastError, contains('nak'));
      expect(bloc.state.committing, false);
      await bloc.close();
    });

    test(
      'reset failure preserves synchronized state and records failure',
      () async {
        final bloc = DeviceSettingsBloc(
          commitButtonMapping: (_) async {
            throw Exception('nak');
          },
          commitReportRate: (_) async {},
          commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
        );
        bloc.add(DeviceSettingsHydrated(baseSettings()));
        await pumpEventQueue();
        bloc.add(const DeviceSettingsResetButtonMappingRequested());
        await pumpEventQueue();

        expect(bloc.state.isDirty, false);
        expect(bloc.state.buttonMappingStaging, isNull);
        expect(bloc.state.synced?.buttons?.first.action, 0x14);
        expect(bloc.state.consecutiveFailures, 1);
        expect(bloc.state.lastError, contains('nak'));
        expect(bloc.state.committing, false);
        await bloc.close();
      },
    );

    test('save rejects bad length without commit', () async {
      var commits = 0;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {
          commits++;
        },
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
        initial: DeviceSettingsViewState(
          synced: baseSettings(),
          buttonMappingStaging: const [ButtonMappingSlot(action: 0x02)],
          isDirty: true,
        ),
      );
      bloc.add(const DeviceSettingsSaveRequested());
      await pumpEventQueue();

      expect(commits, 0);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.lastError, contains('expected 6'));
      await bloc.close();
    });
  });

  group('DeviceSettingsBloc capabilities lookup', () {
    const dpiCaps = DeviceCapabilities(
      devId: '02AA',
      displayNameKey: 'device.m7xse',
      dpi: DpiCapabilities(
        maxLevels: 4,
        defaultLevel: 1,
        maxDpi: 3200,
        independentXY: false,
        rgbPerStage: false,
        levels: [
          DpiLevel(level: 1, value: 800, color: '#FF0000'),
          DpiLevel(level: 2, value: 1600, color: '#00FF00'),
          DpiLevel(level: 3, value: 2400, color: '#0000FF'),
          DpiLevel(level: 4, value: 3200, color: '#FFFF00'),
        ],
      ),
    );

    // why: reproduces the real wiring — caps are null when the bloc is built
    // and only resolve once L2 finishes loading.
    test('lookup resolved after construction gates DPI level', () async {
      DeviceCapabilities? caps;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
        capabilitiesLookup: () => caps,
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();

      caps = dpiCaps;
      bloc.add(const DeviceSettingsDpiLevelRequested(level: 9));
      await pumpEventQueue();

      expect(bloc.state.dpiCurrentLevelStaging, isNull);
      expect(bloc.state.lastError, isNotNull);

      bloc.add(const DeviceSettingsDpiLevelRequested(level: 3));
      await pumpEventQueue();

      expect(bloc.state.dpiCurrentLevelStaging, 3);
      await bloc.close();
    });

    test('constructor capabilities win over the lookup', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
        capabilities: dpiCaps,
        capabilitiesLookup: () => null,
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();

      expect(bloc.activeCapabilities, same(dpiCaps));
      bloc.add(const DeviceSettingsDpiLevelRequested(level: 9));
      await pumpEventQueue();

      expect(bloc.state.dpiCurrentLevelStaging, isNull);
      await bloc.close();
    });
  });

  group('DeviceSettingsBloc decode-error guard', () {
    DeviceSettingsBloc blocWith(Set<String> decodeErrors) {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(
        DeviceSettingsHydrated(
          baseSettings().copyWith(
            reportRateOptions: const [125, 250, 500, 1000],
            reportRateHz: 250,
            decodeErrors: decodeErrors,
          ),
        ),
      );
      return bloc;
    }

    test('locked reportRateDpi refuses report rate staging', () async {
      final bloc = blocWith({'reportRateDpi'});
      await pumpEventQueue();
      bloc.add(const DeviceSettingsReportRateRequested(hz: 500));
      await pumpEventQueue();

      expect(bloc.state.reportRateStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, contains('decode error'));
      await bloc.close();
    });

    test('locked reportRateDpi refuses DPI level staging', () async {
      final bloc = blocWith({'reportRateDpi'});
      await pumpEventQueue();
      bloc.add(const DeviceSettingsDpiLevelRequested(level: 5));
      await pumpEventQueue();

      expect(bloc.state.dpiCurrentLevelStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, contains('decode error'));
      await bloc.close();
    });

    test('locked buttonMapping refuses slot staging', () async {
      final bloc = blocWith({'buttonMapping'});
      await pumpEventQueue();
      bloc.add(
        const DeviceSettingsButtonMappingSlotRequested(
          buttonId: 1,
          catalogId: 'mouse.left',
        ),
      );
      await pumpEventQueue();

      expect(bloc.state.buttonMappingStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, contains('decode error'));
      await bloc.close();
    });

    // why: a lock on one block must not freeze an unrelated one.
    test('locked buttonMapping still allows report rate staging', () async {
      final bloc = blocWith({'buttonMapping'});
      await pumpEventQueue();
      bloc.add(const DeviceSettingsReportRateRequested(hz: 500));
      await pumpEventQueue();

      expect(bloc.state.reportRateStaging, 500);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.lastError, isNull);
      await bloc.close();
    });

    test('no decode error leaves staging unblocked', () async {
      final bloc = blocWith(const <String>{});
      await pumpEventQueue();
      bloc.add(const DeviceSettingsReportRateRequested(hz: 500));
      await pumpEventQueue();

      expect(bloc.state.reportRateStaging, 500);
      expect(bloc.state.isDirty, true);
      await bloc.close();
    });

    test('locked sensorOther refuses ripple staging', () async {
      final bloc = blocWith({'sensorOther'});
      await pumpEventQueue();
      bloc.add(const DeviceSettingsRippleControlRequested(enabled: true));
      await pumpEventQueue();

      expect(bloc.state.rippleControlStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, contains('decode error'));
      await bloc.close();
    });

    test('locked sensorOther refuses angle snap staging', () async {
      final bloc = blocWith({'sensorOther'});
      await pumpEventQueue();
      bloc.add(const DeviceSettingsAngleSnapRequested(enabled: true));
      await pumpEventQueue();

      expect(bloc.state.angleSnapStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, contains('decode error'));
      await bloc.close();
    });
  });

  group('DeviceSettingsBloc sensor tuning', () {
    DeviceSettingsState sensorSettings() => baseSettings().copyWith(
      hasSensorTuning: true,
      rippleOn: false,
      angleSnapOn: false,
    );

    test('ripple staging marks dirty and leaves synced alone', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(sensorSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsRippleControlRequested(enabled: true));
      await pumpEventQueue();

      expect(bloc.state.rippleControlStaging, true);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.synced?.rippleOn, false);
      await bloc.close();
    });

    test('save commits both bytes and syncs state', () async {
      bool? ripple;
      bool? angleSnap;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (r, a) async {
          ripple = r;
          angleSnap = a;
        },
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(sensorSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsRippleControlRequested(enabled: true));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveSensorTuningRequested());
      await pumpEventQueue();

      expect(ripple, true);
      // why: unstaged byte must carry the synced value, not a default.
      expect(angleSnap, false);
      expect(bloc.state.synced?.rippleOn, true);
      expect(bloc.state.rippleControlStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, isNull);
      await bloc.close();
    });

    test('save failure keeps staging and records the failure', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {
          throw Exception('nak');
        },
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(sensorSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsAngleSnapRequested(enabled: true));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveSensorTuningRequested());
      await pumpEventQueue();

      expect(bloc.state.angleSnapStaging, true);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.synced?.angleSnapOn, false);
      expect(bloc.state.consecutiveFailures, 1);
      expect(bloc.state.lastError, contains('nak'));
      expect(bloc.state.committing, false);
      await bloc.close();
    });

    test('cancel wipes sensor staging', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(sensorSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsRippleControlRequested(enabled: true));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsCancelRequested());
      await pumpEventQueue();

      expect(bloc.state.rippleControlStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.synced?.rippleOn, false);
      await bloc.close();
    });
  });

  group('DeviceSettingsBloc angle tune', () {
    DeviceSettingsState angleTuneSettings() => baseSettings().copyWith(
      hasAngleTune: true,
      angleTune: 2,
      angleTuneLabel: '0°',
    );

    test('toggle stages enabled flag, keeps value, marks dirty', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(angleTuneSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsAngleTuneToggled(enabled: true));
      await pumpEventQueue();

      expect(bloc.state.angleTuneEnabledStaging, true);
      expect(bloc.state.angleTuneStaging, isNull);
      expect(bloc.state.isDirty, true);
      // why: value always shows live data, independent of the toggle.
      expect(bloc.state.synced?.angleTune, 2);
      expect(bloc.state.synced?.angleTuneLabel, '0°');
      await bloc.close();
    });

    test('toggle off stages false, keeps value, still dirty', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(angleTuneSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsAngleTuneToggled(enabled: false));
      await pumpEventQueue();

      expect(bloc.state.angleTuneEnabledStaging, false);
      expect(bloc.state.isDirty, true);
      // why: value is unaffected by toggling — live data stays visible.
      expect(bloc.state.synced?.angleTune, 2);
      expect(bloc.state.synced?.angleTuneLabel, '0°');
      await bloc.close();
    });

    test('value change stages the wire index and marks dirty', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(angleTuneSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsAngleTuneValueChanged(wireValue: 4));
      await pumpEventQueue();

      expect(bloc.state.angleTuneStaging, 4);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.synced?.angleTune, 2);
      await bloc.close();
    });

    test('save commits wire value and syncs state', () async {
      int? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (wire) async {
          written = wire;
        },
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(angleTuneSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsAngleTuneValueChanged(wireValue: 4));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveAngleTuneRequested());
      await pumpEventQueue();

      expect(written, 4);
      expect(bloc.state.synced?.angleTune, 4);
      expect(bloc.state.angleTuneStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, isNull);
      await bloc.close();
    });

    test('save failure keeps staging and records failure', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {
          throw Exception('nak');
        },
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(angleTuneSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsAngleTuneValueChanged(wireValue: 3));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveAngleTuneRequested());
      await pumpEventQueue();

      expect(bloc.state.angleTuneStaging, 3);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.consecutiveFailures, 1);
      expect(bloc.state.lastError, contains('nak'));
      expect(bloc.state.committing, false);
      await bloc.close();
    });

    test('decode error on sensorOther blocks angle tune staging', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(
        angleTuneSettings().copyWith(decodeErrors: {'sensorOther'}),
      ));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsAngleTuneValueChanged(wireValue: 1));
      await pumpEventQueue();

      expect(bloc.state.angleTuneStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, contains('decode error'));
      await bloc.close();
    });
  });

  group('DeviceSettingsBloc LOD', () {
    DeviceSettingsState lodSettings() => baseSettings().copyWith(
      hasLod: true,
      lodMm: 1,
      lodLabel: '1mm',
    );

    test('selecting an LOD stage marks dirty and leaves synced alone', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(lodSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsLodRequested(wire: 2));
      await pumpEventQueue();

      expect(bloc.state.lodStaging, 2);
      expect(bloc.state.isDirty, true);
      // why: staging leaves the synced live value alone.
      expect(bloc.state.synced?.lodMm, 1);
      expect(bloc.state.synced?.lodLabel, '1mm');
      await bloc.close();
    });

    test('decode error on sensorOther blocks LOD staging', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(
        lodSettings().copyWith(decodeErrors: {'sensorOther'}),
      ));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsLodRequested(wire: 2));
      await pumpEventQueue();

      expect(bloc.state.lodStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, contains('decode error'));
      await bloc.close();
    });

    test('cancel wipes LOD staging', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(lodSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsLodRequested(wire: 2));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsCancelRequested());
      await pumpEventQueue();

      expect(bloc.state.lodStaging, isNull);
      expect(bloc.state.isDirty, false);
      await bloc.close();
    });

    test('save commits LOD wire and syncs state', () async {
      int? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (wire) async {
          written = wire;
        },
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(lodSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsLodRequested(wire: 2));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveLodRequested());
      await pumpEventQueue();

      expect(written, 2);
      expect(bloc.state.synced?.lodMm, 2);
      expect(bloc.state.lodStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, isNull);
      await bloc.close();
    });

    test('save failure keeps staging and records failure', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {
          throw Exception('nak');
        },
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(lodSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsLodRequested(wire: 2));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveLodRequested());
      await pumpEventQueue();

      expect(bloc.state.lodStaging, 2);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.consecutiveFailures, 1);
      expect(bloc.state.lastError, contains('nak'));
      expect(bloc.state.committing, false);
      await bloc.close();
    });
  });

  group('DeviceSettingsBloc performance', () {
    DeviceSettingsState perfSettings() => baseSettings().copyWith(
      hasPerformance: true,
      performance: 0,
    );

    test('selecting a mode marks dirty and leaves synced alone', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(perfSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsPerformanceRequested(wire: 2));
      await pumpEventQueue();

      expect(bloc.state.performanceStaging, 2);
      expect(bloc.state.isDirty, true);
      // why: staging leaves the synced live value alone.
      expect(bloc.state.synced?.performance, 0);
      await bloc.close();
    });

    test('save commits wire value and syncs state', () async {
      int? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (wire) async {
          written = wire;
        },
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(perfSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsPerformanceRequested(wire: 1));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSavePerformanceRequested());
      await pumpEventQueue();

      expect(written, 1);
      expect(bloc.state.synced?.performance, 1);
      expect(bloc.state.performanceStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, isNull);
      await bloc.close();
    });

    test('save failure keeps staging and records failure', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {
          throw Exception('nak');
        },
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(perfSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsPerformanceRequested(wire: 2));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSavePerformanceRequested());
      await pumpEventQueue();

      expect(bloc.state.performanceStaging, 2);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.consecutiveFailures, 1);
      expect(bloc.state.lastError, contains('nak'));
      expect(bloc.state.committing, false);
      await bloc.close();
    });

    test('decode error on sensorOther blocks performance staging', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(
        perfSettings().copyWith(decodeErrors: {'sensorOther'}),
      ));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsPerformanceRequested(wire: 1));
      await pumpEventQueue();

      expect(bloc.state.performanceStaging, isNull);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.lastError, contains('decode error'));
      await bloc.close();
    });
  });

  group('DeviceSettingsBloc other features (debounce/sleep/wheel)', () {
    DeviceSettingsState otherSettings() => baseSettings().copyWith(
      hasButtonDebounce: true,
      debounceMs: 0,
      hasSleepTime: true,
      sleepSeconds: 0,
      hasWheelInvert: true,
      wheelInvert: false,
    );

    test('debounce selection marks dirty and leaves synced alone', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(otherSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsButtonDebounceRequested(wire: 4));
      await pumpEventQueue();

      expect(bloc.state.debounceStaging, 4);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.synced?.debounceMs, 0);
      await bloc.close();
    });

    test('sleep selection marks dirty and leaves synced alone', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(otherSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSleepTimeRequested(wire: 5));
      await pumpEventQueue();

      expect(bloc.state.sleepStaging, 5);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.synced?.sleepSeconds, 0);
      await bloc.close();
    });

    test('wheel invert toggle stages bool and marks dirty', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(otherSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsWheelInvertRequested(invert: true));
      await pumpEventQueue();

      expect(bloc.state.wheelInvertStaging, true);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.synced?.wheelInvert, false);
      await bloc.close();
    });

    test('save debounce commits wire and syncs state', () async {
      int? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (wire) async {
          written = wire;
        },
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(otherSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsButtonDebounceRequested(wire: 4));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveButtonDebounceRequested());
      await pumpEventQueue();

      expect(written, 4);
      expect(bloc.state.synced?.debounceMs, 4);
      expect(bloc.state.debounceStaging, isNull);
      expect(bloc.state.isDirty, false);
      await bloc.close();
    });

    test('save sleep commits wire and syncs state', () async {
      int? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (wire) async {
          written = wire;
        },
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(otherSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSleepTimeRequested(wire: 5));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveSleepTimeRequested());
      await pumpEventQueue();

      expect(written, 5);
      expect(bloc.state.synced?.sleepSeconds, 5);
      expect(bloc.state.sleepStaging, isNull);
      expect(bloc.state.isDirty, false);
      await bloc.close();
    });

    test('save wheel invert commits bool and syncs state', () async {
      bool? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {},
        commitSleep: (_) async {},
        commitWheelInvert: (invert) async {
          written = invert;
        },
      );
      bloc.add(DeviceSettingsHydrated(otherSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsWheelInvertRequested(invert: true));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveWheelInvertRequested());
      await pumpEventQueue();

      expect(written, true);
      expect(bloc.state.synced?.wheelInvert, true);
      expect(bloc.state.wheelInvertStaging, isNull);
      expect(bloc.state.isDirty, false);
      await bloc.close();
    });

    test('save failure keeps debounce staging and records failure', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        commitReportRate: (_) async {},
        commitDpiLevel: (_) async {},
        commitSensorTuning: (_, _) async {},
        commitAngleTune: (_) async {},
        commitLod: (_) async {},
        commitPerformance: (_) async {},
        commitDebounce: (_) async {
          throw Exception('nak');
        },
        commitSleep: (_) async {},
        commitWheelInvert: (_) async {},
      );
      bloc.add(DeviceSettingsHydrated(otherSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsButtonDebounceRequested(wire: 4));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveButtonDebounceRequested());
      await pumpEventQueue();

      expect(bloc.state.debounceStaging, 4);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.consecutiveFailures, 1);
      expect(bloc.state.lastError, contains('nak'));
      await bloc.close();
    });
  });
}

Future<void> pumpEventQueue([int times = 20]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
