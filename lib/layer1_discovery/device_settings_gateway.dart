import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/codecs/osd_codec.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer5_codec/macro_codec.dart';

/// Stable, non-HID identity data exposed across the L1/L4 boundary.
///
/// L4 needs this data to key per-device state and build a card, but it must not
/// receive a concrete Layer 1 session or a Layer 6 HID handle.
class DeviceGatewayInfo {
  const DeviceGatewayInfo({
    required this.deviceKey,
    required this.devId,
    required this.displayName,
    required this.connectionMode,
    required this.imageSmall,
    required this.imageLarge,
  });

  final String deviceKey;
  final String devId;
  final String displayName;
  final int connectionMode;
  final String imageSmall;
  final String imageLarge;
}

typedef DeviceGatewayConnectCallback =
    void Function(DeviceSettingsGateway gateway);

/// Live settings operations that L4 may request from an already-verified
/// device session.
///
/// This port belongs beside the session lifecycle in L1. It deliberately
/// exposes semantic L5 results, not HID handles or transport frames.
abstract interface class DeviceSettingsGateway {
  DeviceGatewayInfo get info;

  bool get isAlive;

  Stream<BatteryResult> get batteryPushes;

  Stream<OsdPerformanceResult> get performancePushes;

  Future<bool> rehandshake();

  Future<BatteryResult?> queryBattery();

  Future<FirmwareResult?> queryFirmware();

  Future<ButtonMappingResult?> queryButtonMapping();

  Future<ReportRateDpiInfoResult?> queryReportRateDpiInfo();

  Future<DpiTableResult?> queryDpiTable();

  Future<DpiRgbResult?> queryDpiRgb();

  Future<SensorOtherResult?> querySensorOther();

  Future<RgbBacklightResult?> queryRgbBacklight();

  Future<void> setButtonMapping(List<ButtonMappingEntry> buttons);

  Future<void> setReportRate(Uint8List dataBlock);

  Future<void> setDpiTable(Uint8List dataBlock);

  Future<void> setDpiRgb(Uint8List dataBlock);

  Future<void> setSensorOther(Uint8List dataBlock);

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
  });

  Future<void> setRgbBacklight(Uint8List dataBlock);

  Future<Uint8List> setRgbBacklightPatch(
    Uint8List currentBlock, {
    int? modeId,
    int? brightness,
    int? speed,
    int? red,
    int? green,
    int? blue,
    int? sleepWire,
  });

  Future<void> setMacro(MacroTransferDefinition macro);
}
