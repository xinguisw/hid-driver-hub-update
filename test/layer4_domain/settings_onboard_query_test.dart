import 'dart:typed_data';

import 'package:driver_hub/layer4_domain/device_repository.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/settings_onboard_query.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'hydrates Performance, Parameter, and Backlight blocks with one GET each',
    () async {
      final repository = _CountingRepository();

      final state = await queryOnboardConfig(repository, _card);

      expect(state.error, isNull);
      expect(state.hasPerformance, isFalse);
      expect(state.hasRgbBacklight, isTrue);
      expect(repository.counts, {
        'buttonMapping': 1,
        'reportRateDpi': 1,
        'dpiTable': 1,
        'dpiRgb': 1,
        'sensorOther': 1,
        'rgbBacklight': 1,
      });
      expect(state.rawBlocks, isNotNull);
      expect(state.rawBlocks!.reportRateDpi, [0, 1, 0x1F]);
      expect(state.rawBlocks!.dpiTable, hasLength(16));
      expect(state.rawBlocks!.dpiRgb, hasLength(24));
      expect(state.rawBlocks!.sensorOther, hasLength(18));
      expect(state.rawBlocks!.rgbBacklight, hasLength(8));
    },
  );

  test(
    'queryOnboardConfig aborts and returns error state when a query receives NAK',
    () async {
      final repository = _NakRepository();

      final state = await queryOnboardConfig(repository, _card);

      expect(state.error, isNotNull);
      expect(state.error, contains('NAK'));
      expect(state.loading, isFalse);
    },
  );
  test(
    'queryOnboardConfig soft-fails gracefully when rgbBacklight query receives NAK',
    () async {
      final repository = _BacklightNakRepository();

      final state = await queryOnboardConfig(repository, _card);

      expect(state.error, isNull);
      expect(state.loading, isFalse);
      expect(state.rawBlocks?.rgbBacklight, isNull);
    },
  );
}

class _NakRepository extends _CountingRepository {
  @override
  Future<ReportRateDpiInfoResult?> queryReportRateDpiInfo() async {
    _count('reportRateDpi');
    throw const FormatException('reportRateDpi NAK: NAK reason 0x01');
  }
}

class _BacklightNakRepository extends _CountingRepository {
  @override
  Future<RgbBacklightResult?> queryRgbBacklight() async {
    _count('rgbBacklight');
    throw const FormatException('rgbBacklight NAK: NAK reason 0x02');
  }
}

const _card = DiscoveredCardState(
  devId: '01_01',
  displayName: 'M7X PRO',
  connectionMode: 0,
  firmwareVersion: '',
  batteryPercentage: -1,
  isCharging: false,
  physicalHandle: null,
  imageSmall: '',
  imageLarge: '',
);

class _CountingRepository implements DeviceRepository {
  final counts = <String, int>{};

  void _count(String key) => counts[key] = (counts[key] ?? 0) + 1;

  @override
  bool get isAlive => true;

  @override
  DiscoveredCardState get card => _card;

  @override
  Future<bool> rehandshake() async => true;

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
      data: Uint8List(16),
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
      data: Uint8List(18),
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
      data: Uint8List(8),
      raw: Uint8List(32),
    );
  }
}
