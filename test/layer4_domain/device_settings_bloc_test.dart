import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeviceSettingsState baseSettings() => const DeviceSettingsState(
        devId: 'aa4ecd01',
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

  group('DeviceSettingsBloc chart sandbox', () {
    test('hydrate seeds synced, not dirty', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        autoSaveAfterReset: false,
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      expect(bloc.state.synced?.devId, 'aa4ecd01');
      expect(bloc.state.isDirty, false);
      expect(bloc.state.buttonMappingStaging, isNull);
      await bloc.close();
    });

    test('reset stages only — no commit when autoSave off', () async {
      var commits = 0;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {
          commits++;
        },
        autoSaveAfterReset: false,
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsResetButtonMappingRequested());
      await pumpEventQueue();

      expect(commits, 0);
      expect(bloc.state.isDirty, true);
      expect(bloc.state.buttonMappingStaging, isNotNull);
      expect(bloc.state.buttonMappingStaging!.length, 6);
      expect(bloc.state.buttonMappingStaging![0].action, 0x02); // identity left
      // Chart: L3 would paint staged labels
      expect(bloc.state.displaySettings?.buttons?.first.action, 0x02);
      // Synced still old until Save
      expect(bloc.state.synced?.buttons?.first.action, 0x14);
      await bloc.close();
    });

    test('cancel wipes staging → last synchronized', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {},
        autoSaveAfterReset: false,
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsResetButtonMappingRequested());
      await pumpEventQueue();
      bloc.add(const DeviceSettingsCancelRequested());
      await pumpEventQueue();

      expect(bloc.state.isDirty, false);
      expect(bloc.state.buttonMappingStaging, isNull);
      expect(bloc.state.synced?.buttons?.first.action, 0x14);
      await bloc.close();
    });

    test('save validates and commits then clears dirty', () async {
      List<ButtonMappingEntry>? written;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (buttons) async {
          written = buttons;
        },
        autoSaveAfterReset: false,
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsResetButtonMappingRequested());
      await pumpEventQueue();
      bloc.add(const DeviceSettingsSaveRequested());
      await pumpEventQueue();

      expect(written, isNotNull);
      expect(written!.map((e) => e.action).toList(),
          [0x02, 0x03, 0x04, 0x05, 0x06, 0x0E]);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.buttonMappingStaging, isNull);
      expect(bloc.state.synced?.buttons?.first.action, 0x02);
      expect(bloc.state.committing, false);
      expect(bloc.state.lastError, isNull);
      await bloc.close();
    });

    test('autoSaveAfterReset enqueues Save after stage', () async {
      var commits = 0;
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {
          commits++;
        },
        autoSaveAfterReset: true,
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsResetButtonMappingRequested());
      // allow staged emit + nested Save
      await pumpEventQueue();
      await pumpEventQueue();

      expect(commits, 1);
      expect(bloc.state.isDirty, false);
      expect(bloc.state.synced?.buttons?.first.action, 0x02);
      await bloc.close();
    });

    test('save failure keeps dirty and bumps consecutiveFailures', () async {
      final bloc = DeviceSettingsBloc(
        commitButtonMapping: (_) async {
          throw Exception('nak');
        },
        autoSaveAfterReset: false,
      );
      bloc.add(DeviceSettingsHydrated(baseSettings()));
      await pumpEventQueue();
      bloc.add(const DeviceSettingsResetButtonMappingRequested());
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
  });
}

/// Drain microtasks so bloc async handlers finish in tests.
Future<void> pumpEventQueue([int times = 20]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
