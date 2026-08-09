import 'package:driver_hub/layer5_codec/device_protocol.dart';

/// Live settings operations that L4 may request from an already-verified
/// device session.
///
/// This port belongs beside the session lifecycle in L1. It deliberately
/// exposes semantic L5 results, not HID handles or transport frames.
abstract interface class DeviceSettingsGateway {
  bool get isAlive;

  Future<bool> rehandshake();

  Future<ButtonMappingResult?> queryButtonMapping();

  Future<ReportRateDpiInfoResult?> queryReportRateDpiInfo();

  Future<DpiTableResult?> queryDpiTable();

  Future<DpiRgbResult?> queryDpiRgb();

  Future<SensorOtherResult?> querySensorOther();

  Future<RgbBacklightResult?> queryRgbBacklight();
}
