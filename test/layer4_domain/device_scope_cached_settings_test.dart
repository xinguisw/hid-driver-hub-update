import 'dart:async';
import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer1_discovery/device_watcher.dart';
import 'dart:typed_data';

import 'package:driver_hub/layer1_discovery/device_runtime.dart';
import 'package:driver_hub/layer1_discovery/device_settings_gateway.dart';
import 'package:driver_hub/layer4_domain/app_settings_repository.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer5_codec/codecs/osd_codec.dart';
import 'package:driver_hub/layer5_codec/macro_codec.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('settings saves reuse hydrated blocks without second GETs', () async {
    final gateway = _CountingGateway();
    final scope = DeviceScope(
      runtime: _Runtime(gateway),
      macroRepository: InMemoryMacroRepository(),
      appSettingsRepository: _AppSettingsRepository(),
    );

    await scope.start();
    for (var i = 0; i < 5 && scope.cards.value.isEmpty; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final card = scope.cards.value.single;
    await scope.loadOnboardSettings(card);
    final queriesAfterHydration = Map<String, int>.from(gateway.queryCounts);
    await scope.commitReportRate(card, 500);
    await scope.commitParameterSettings(
      card,
      const ParameterSettingsPatch(performanceWire: 2),
    );
    await scope.commitRgbBacklight(
      card,
      const RgbBacklightPatch(brightness: 3),
    );

    expect(gateway.queryCounts, queriesAfterHydration);
    expect(gateway.reportRateSets, 1);
    expect(gateway.sensorOtherSets, 1);
    expect(gateway.rgbBacklightSets, 1);
    expect(gateway.lastReportRateSet, hasLength(3));
    expect(gateway.lastSensorOtherSet, hasLength(18));
    expect(gateway.lastRgbBacklightSet, hasLength(8));
    await scope.dispose();
  });
}

class _Runtime implements DeviceRuntime {
  _Runtime(this.gateway);

  final _CountingGateway gateway;

  @override
  Future<List<DiscoveredDevice>> discoverAuthorized() async => const [];

  @override
  Future<List<DiscoveredDevice>> discover() async => const [];

  @override
  Future<DeviceSettingsGateway?> openAndRegister(
    DiscoveredDevice device,
  ) async => gateway;

  @override
  void startWatching({
    required DeviceGatewayConnectCallback onConnect,
    required DeviceDisconnectCallback onDisconnect,
  }) {
    onConnect(gateway);
  }

  @override
  Future<void> stop() async {}
}

class _AppSettingsRepository implements AppSettingsRepository {
  @override
  Future<int?> loadLowBatteryThreshold() async => null;

  @override
  Future<void> saveLowBatteryThreshold(int threshold) async {}
}

class _CountingGateway implements DeviceSettingsGateway {
  final queryCounts = <String, int>{};
  int reportRateSets = 0;
  int sensorOtherSets = 0;
  int rgbBacklightSets = 0;
  Uint8List? lastReportRateSet;
  Uint8List? lastSensorOtherSet;
  Uint8List? lastRgbBacklightSet;

  @override
  final info = const DeviceGatewayInfo(
    deviceKey: 'cached-settings-test',
    devId: '01_01',
    displayName: 'M7X PRO',
    connectionMode: 0,
    imageSmall: '',
    imageLarge: '',
  );

  @override
  bool get isAlive => true;

  @override
  BatteryResult? get initialBattery => null;

  @override
  FirmwareResult? get initialFirmware => null;

  @override
  Stream<BatteryResult> get batteryPushes => const Stream.empty();

  @override
  Stream<OsdPerformanceResult> get performancePushes => const Stream.empty();

  void _count(String key) => queryCounts[key] = (queryCounts[key] ?? 0) + 1;

  @override
  Future<bool> rehandshake() async => true;

  @override
  Future<BatteryResult?> queryBattery() async {
    _count('battery');
    return const BatteryResult(percent: 80, isCharging: false);
  }

  @override
  Future<FirmwareResult?> queryFirmware() async {
    _count('firmware');
    return const FirmwareResult(
      mouseVersion: [1, 2, 3, 4],
      dongleVersion: [1, 2, 3, 4],
    );
  }

  @override
  Future<ButtonMappingResult?> queryButtonMapping() async {
    _count('buttonMapping');
    return ButtonMappingResult(
      buttons: [
        for (var i = 0; i < 6; i++)
          ButtonMappingEntry(action: i + 2, param1: 0, param2: 0, param3: 0),
      ],
      raw: Uint8List(32),
    );
  }

  @override
  Future<ReportRateDpiInfoResult?> queryReportRateDpiInfo() async {
    _count('reportRateDpi');
    return ReportRateDpiInfoResult(
      reportRate: 0,
      dpiCurrentLevel: 1,
      dpiActiveLevel: 0x1F,
      raw: Uint8List(32),
    );
  }

  @override
  Future<DpiTableResult?> queryDpiTable() async {
    _count('dpiTable');
    return DpiTableResult(
      stages: [
        for (var i = 0; i < 8; i++) const DpiTableEntry(x: 0x03, y: 0x20),
      ],
      data: Uint8List.fromList([
        for (var i = 0; i < 8; i++) ...[0x03, 0x20],
      ]),
      raw: Uint8List(32),
    );
  }

  @override
  Future<DpiRgbResult?> queryDpiRgb() async {
    _count('dpiRgb');
    return DpiRgbResult(
      stages: [
        for (var i = 0; i < 8; i++)
          const DpiRgbEntry(r: 0x10, g: 0x20, b: 0x30),
      ],
      data: Uint8List.fromList([
        for (var i = 0; i < 8; i++) ...[0x10, 0x20, 0x30],
      ]),
      raw: Uint8List(32),
    );
  }

  @override
  Future<SensorOtherResult?> querySensorOther() async {
    _count('sensorOther');
    return SensorOtherResult(
      rippleControl: 0xFF,
      angleSnap: 0xFF,
      lod: 1,
      angleTune: 0xFF,
      angleValue: 2,
      performance: 1,
      debounceTime: 2,
      sleepTime: 4,
      wheelDirection: 0xFF,
      data: Uint8List.fromList([
        0xFF,
        0,
        0xFF,
        0,
        1,
        0,
        0xFF,
        2,
        0,
        1,
        0,
        0,
        0,
        2,
        0,
        4,
        0,
        0xFF,
      ]),
      raw: Uint8List(32),
    );
  }

  @override
  Future<RgbBacklightResult?> queryRgbBacklight() async {
    _count('rgbBacklight');
    return RgbBacklightResult(
      enable: 0xFF,
      mode: 1,
      brightness: 2,
      speed: 3,
      r: 0x10,
      g: 0x20,
      b: 0x30,
      sleepTime: 4,
      data: Uint8List.fromList([0xFF, 1, 2, 3, 0x10, 0x20, 0x30, 4]),
      raw: Uint8List(32),
    );
  }

  @override
  Future<void> setButtonMapping(List<ButtonMappingEntry> buttons) async {}

  @override
  Future<void> setReportRate(Uint8List dataBlock) async {
    reportRateSets++;
    lastReportRateSet = Uint8List.fromList(dataBlock);
  }

  @override
  Future<void> setDpiTable(Uint8List dataBlock) async {}

  @override
  Future<void> setDpiRgb(Uint8List dataBlock) async {}

  @override
  Future<void> setSensorOther(Uint8List dataBlock) async {
    sensorOtherSets++;
    lastSensorOtherSet = Uint8List.fromList(dataBlock);
  }

  @override
  Future<Uint8List> setSensorOtherPatch(
    Uint8List currentBlock, {
    bool? rippleEnabled,
    bool? angleSnapEnabled,
    bool? angleTuneEnabled,
    int? angleTuneWire,
    int? lodWire,
    int? performanceWire,
    int? debounceWire,
    int? sleepWire,
    bool? wheelInvert,
  }) async {
    await setSensorOther(currentBlock);
    return Uint8List.fromList(currentBlock);
  }

  @override
  Future<void> setRgbBacklight(Uint8List dataBlock) async {
    rgbBacklightSets++;
    lastRgbBacklightSet = Uint8List.fromList(dataBlock);
  }

  @override
  Future<Uint8List> setRgbBacklightPatch(
    Uint8List currentBlock, {
    bool? enabled,
    int? modeId,
    int? brightness,
    int? speed,
    int? red,
    int? green,
    int? blue,
    int? sleepWire,
  }) async {
    await setRgbBacklight(currentBlock);
    return Uint8List.fromList(currentBlock);
  }

  @override
  Future<void> setMacro(MacroTransferDefinition macro) async {}
}
